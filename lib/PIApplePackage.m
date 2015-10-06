/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIApplePackage.h"

#import "PIAppleDeveloperPackage.h"
#import "PIAppleStorePackage.h"
#import "PIAppleSystemPackage.h"

#include <dlfcn.h>
#include <objc/runtime.h>

@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (id)allInstalledApplications;
@end

@interface LSApplicationProxy : NSObject // LSBundleProxy <NSSecureCoding>
@property(readonly, nonatomic) NSString *applicationDSID;
@property(readonly, nonatomic) NSString *applicationIdentifier;
@property(readonly, nonatomic) NSString *applicationType;
@property(readonly, nonatomic) BOOL isContainerized;
@property(readonly, nonatomic) NSString *shortVersionString;
- (long)bundleModTime;
- (id)localizedName;
- (id)resourcesDirectoryURL;
@end

@implementation PIApplePackage

static NSDictionary *cachedPackageDetails$ = nil;
static NSDictionary *reverseLookupTable$ = nil;

static void cachePackageDetails_iOS7() {
    NSData *data = [[NSData alloc] initWithContentsOfFile:@"/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
    if (data != nil) {
        id plist = nil;
        if ([NSPropertyListSerialization respondsToSelector:@selector(propertyListWithData:options:format:error:)]) {
            plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
#if TARGET_OS_IPHONE
        } else {
            plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:NULL errorDescription:NULL];
#endif
        }

        if (plist != nil) {
            Class $NSDictionary = [NSDictionary class];
            if ([plist isKindOfClass:$NSDictionary]) {
                // TODO: Consider only storing needed keys in order to
                //       reduce required memory.
                //       Also consider checking types of each key to ensure
                //       they are correct.
                NSMutableDictionary *cachedPackageDetails = [[NSMutableDictionary alloc] init];

                // Process system apps.
                id object;
                object = [plist objectForKey:@"System"];
                if ([object isKindOfClass:$NSDictionary]) {
                    [cachedPackageDetails addEntriesFromDictionary:object];
                } else {
                    fprintf(stderr, "ERROR: Required key \"System\" not found or incorrect type.\n");
                }

                // Process user apps.
                object = [plist objectForKey:@"User"];
                if ([object isKindOfClass:$NSDictionary]) {
                    [cachedPackageDetails addEntriesFromDictionary:object];
                } else {
                    fprintf(stderr, "ERROR: Required key \"User\" not found or incorrect type.\n");
                }

                cachedPackageDetails$ = cachedPackageDetails;
            } else {
                fprintf(stderr, "ERROR: Unable to parse mobile installation property list.\n");
            }
        } else {
            fprintf(stderr, "ERROR: Unable to open or read mobile installation file.\n");
        }
    }
}

static void cachePackageDetails_iOS8() {
    void *handle = dlopen("/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices", RTLD_LAZY);
    if (handle != NULL) {
        NSMutableDictionary *cachedPackageDetails = [[NSMutableDictionary alloc] init];

        Class $LSApplicationWorkspace = objc_getClass("LSApplicationWorkspace");
        LSApplicationWorkspace *workspace = [$LSApplicationWorkspace defaultWorkspace];
        for (LSApplicationProxy *proxy in [workspace allInstalledApplications]) {
            NSString *applicationIdentifier = [proxy applicationIdentifier];
            if (applicationIdentifier != nil) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

                [dict setObject:applicationIdentifier forKey:@"CFBundleIdentifier"];

                NSString *applicationDSID = [proxy applicationDSID];
                if (applicationDSID != nil) {
                    [dict setObject:[NSNumber numberWithLongLong:[applicationDSID longLongValue]] forKey:@"ApplicationDSID"];
                }

                NSString *applicationType = [proxy applicationType];
                if (applicationType != nil) {
                    [dict setObject:applicationType forKey:@"ApplicationType"];
                }

                NSString *localizedName = [proxy localizedName];
                if (localizedName != nil) {
                    [dict setObject:localizedName forKey:@"CFBundleDisplayName"];
                }

                NSString *shortVersion = [proxy shortVersionString];
                if (shortVersion != nil) {
                    [dict setObject:shortVersion forKey:@"CFBundleShortVersionString"];
                }

                long value = [proxy bundleModTime];
                if (value > 0) {
                    // NOTE: Returned value is relative to "reference date" (2001-01-01 GMT).
                    //       Make relative to unix epoch to match format used by CFBundleTimestamp.
                    value += 978307200;
                    [dict setObject:[NSNumber numberWithLong:value] forKey:@"BundleTimestamp"];
                }

                NSURL *url = [proxy resourcesDirectoryURL];
                if (url != nil) {
                    NSString *path = [url path];
                    [dict setObject:path forKey:@"Path"];

                    if ([proxy isContainerized]) {
                        [dict setObject:[path stringByDeletingLastPathComponent] forKey:@"Container"];
                    }
                }

                [cachedPackageDetails setObject:dict forKey:applicationIdentifier];
                [dict release];
            }
        }

        cachedPackageDetails$ = cachedPackageDetails;

        dlclose(handle);
    }
}

+ (void)initialize {
    if (self == [PIApplePackage class]) {
        Class $NSDictionary = [NSDictionary class];
        Class $NSString = [NSString class];

        // Parse and cache app details from mobile installation file.
        if (IOS_LT(8_0)) {
            cachePackageDetails_iOS7();
        } else {
            cachePackageDetails_iOS8();
        }

        // Create a reverse lookup table for determing identifiers from paths.
        NSMutableDictionary *reverseLookupTable = [[NSMutableDictionary alloc] init];
        for (id key in cachedPackageDetails$) {
            if ([key isKindOfClass:$NSString]) {
                id object = [cachedPackageDetails$ objectForKey:key];
                if ([object isKindOfClass:$NSDictionary]) {
                    id path = [object objectForKey:@"Path"];
                    if ([path isKindOfClass:$NSString]) {
                        [reverseLookupTable setObject:key forKey:path];
                    }
                }
            }
        }
        reverseLookupTable$ = reverseLookupTable;
    }
}

#pragma mark - Creation and Destruction

// NOTE: Should *not* call super's implementation.
+ (instancetype)packageForFile:(NSString *)filepath {
    // Check if any component in the path has a .app suffix.
    NSString *bundlePath = filepath;
    for (;;) {
        NSString *lastPathComponent = [bundlePath lastPathComponent];

        if ([lastPathComponent isEqualToString:bundlePath]) {
            // No more path components.
            break;
        }

        if ([lastPathComponent hasSuffix:@".app"]) {
            // Manually 'resolve' /var symbolic link.
            // NOTE: NSString's stringByResolvingSymlinksInPath won't work here
            //       as it removes "/private" (documented behavior).
            // TODO: Find a better way to do this, or at least check first if
            //       /var really is a symbolic link.
            if ([bundlePath hasPrefix:@"/var/"]) {
                bundlePath = [@"/private" stringByAppendingPathComponent:bundlePath];
            }

            // Lookup identifier for determined bundle path.
            NSString *identifier = [reverseLookupTable$ objectForKey:bundlePath];
            if (identifier != nil) {
                return [self packageWithIdentifier:identifier];
            } else {
                break;
            }
        } else {
            bundlePath = [bundlePath stringByDeletingLastPathComponent];
        }
    }

    return nil;
}

// NOTE: Should *not* call super's implementation.
+ (instancetype)packageWithIdentifier:(NSString *)identifier {
    Class $NSDictionary = [NSDictionary class];
    Class $NSString = [NSString class];
    Class $NSNumber = [NSNumber class];

    id object = [cachedPackageDetails$ objectForKey:identifier];
    if ([object isKindOfClass:$NSDictionary]) {
        id applicationType = [object objectForKey:@"ApplicationType"];
        if ([applicationType isKindOfClass:$NSString]) {
            if ([applicationType isEqualToString:@"System"]) {
                return [[[PIAppleSystemPackage alloc] initWithDetails:object] autorelease];
            } else {
                id applicationDSID = [object objectForKey:@"ApplicationDSID"];
                if ([applicationDSID isKindOfClass:$NSNumber]) {
                    return [[[PIAppleStorePackage alloc] initWithDetails:object] autorelease];
                } else {
                    return [[[PIAppleDeveloperPackage alloc] initWithDetails:object] autorelease];
                }
            }
        }
    }

    return nil;
}

+ (id)alloc {
    if (self == [PIApplePackage class]) {
        fprintf(stderr, "ERROR: PIApplePackage is a base class and cannot be allocated.\n");
        return nil;
    } else {
        return [super alloc];
    }
}

+ (id)allocWithZone:(NSZone *)zone {
    if (self == [PIApplePackage class]) {
        fprintf(stderr, "ERROR: PIApplePackage is a base class and cannot be allocated.\n");
        return nil;
    } else {
        return [super allocWithZone:zone];
    }
}

- (id)initWithDetailsFromJSONDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];

    id object;
    Class $NSString = [NSString class];

    object = [dictionary objectForKey:@"identifier"];
    if ([object isKindOfClass:$NSString]) {
        [details setObject:object forKey:(NSString *)kCFBundleIdentifierKey];
    }

    object = [dictionary objectForKey:@"name"];
    if ([object isKindOfClass:$NSString]) {
        [details setObject:object forKey:@"Name"];
    }

    object = [dictionary objectForKey:@"version"];
    if ([object isKindOfClass:$NSString]) {
        [details setObject:object forKey:@"CFBundleShortVersionString"];
    }

    object = [dictionary objectForKey:@"install_date"];
    if ([object isKindOfClass:$NSString]) {
        struct tm time;
        const char *format = "%Y-%m-%d %H:%M:%S %z";
        if (strptime([object UTF8String], format, &time) != NULL) {
            NSNumber *number = [[NSNumber alloc] initWithLong:mktime(&time)];
            if (number != nil) {
                [details setObject:number forKey:@"BundleTimestamp"];
                [number release];
            }
        } else {
            fprintf(stderr, "WARNING: Unable to parse date: \"%s\".\n", [object UTF8String]);
        }
    }

    return [self initWithDetails:details];
}

#pragma mark - Properties

- (NSString *)identifier {
    return [packageDetails_ objectForKey:(NSString *)kCFBundleIdentifierKey];
}

- (NSString *)name {
    NSString *name = [packageDetails_ objectForKey:@"Name"];
    if (name == nil) {
        NSBundle *bundle = [[NSBundle alloc] initWithPath:[self bundlePath]];
        NSDictionary *info = [bundle localizedInfoDictionary];
        name = [info objectForKey:@"CFBundleDisplayName"];
        if (name == nil) {
            name = [info objectForKey:(NSString *)kCFBundleNameKey];
        }
        if (name == nil) {
            info = [bundle infoDictionary];
            name = [info objectForKey:@"CFBundleDisplayName"];
        }
        if (name == nil) {
            name = [info objectForKey:(NSString *)kCFBundleNameKey];
        }
        [bundle release];

        if (name != nil) {
            [packageDetails_ setObject:name forKey:@"Name"];
        }
    }

    return name;
}

- (NSString *)version {
    NSString *version = [packageDetails_ objectForKey:@"CFBundleShortVersionString"];
    if (version == nil) {
        version = [packageDetails_ objectForKey:(NSString *)kCFBundleVersionKey];
    }
    return version;
}

- (NSDate *)installDate {
    NSDate *installDate = [packageDetails_ objectForKey:@"InstallDate"];
    if (installDate == nil) {
        NSNumber *bundleTimestamp = [packageDetails_ objectForKey:@"BundleTimestamp"];
        if (bundleTimestamp != nil) {
            installDate = [NSDate dateWithTimeIntervalSince1970:[bundleTimestamp doubleValue]];
            if (installDate != nil) {
                [packageDetails_ setObject:installDate forKey:@"InstallDate"];
            }
        }
    }
    return installDate;
}

- (NSString *)bundlePath {
    return [packageDetails_ objectForKey:@"Path"];
}

- (NSString *)containerPath {
    return [packageDetails_ objectForKey:@"Container"];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
