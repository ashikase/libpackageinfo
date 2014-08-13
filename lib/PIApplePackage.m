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

@implementation PIApplePackage {
    NSDictionary *packageDetails_;
}

static NSDictionary *cachedPackageDetails$ = nil;
static NSDictionary *reverseLookupTable$ = nil;

+ (void)initialize {
    if (self == [PIApplePackage class]) {
        Class $NSDictionary = [NSDictionary class];
        Class $NSString = [NSString class];

        // Parse and cache app details from mobile installation file.
        NSData *data = [[NSData alloc] initWithContentsOfFile:@"/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
        if (data != nil) {
            id plist = nil;
            if ([NSPropertyListSerialization respondsToSelector:@selector(propertyListWithData:options:format:error:)]) {
                plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
            } else {
                plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:NULL errorDescription:NULL];
            }

            if (plist != nil) {
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
    do {
        bundlePath = [bundlePath stringByDeletingLastPathComponent];
        if ([bundlePath hasSuffix:@".app"]) {
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
        }
    } while ([bundlePath length] != 0);

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
                return [[[PIAppleSystemPackage alloc] initWithPackageDetails:object] autorelease];
            } else {
                id applicationDSID = [object objectForKey:@"ApplicationDSID"];
                if ([applicationDSID isKindOfClass:$NSNumber]) {
                    return [[[PIAppleStorePackage alloc] initWithPackageDetails:object] autorelease];
                } else {
                    return [[[PIAppleDeveloperPackage alloc] initWithPackageDetails:object] autorelease];
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

- (id)initWithPackageDetails:(NSDictionary *)packageDetails {
    self = [super init];
    if (self != nil) {
        packageDetails_ = [packageDetails copy];
    }
    return self;
}

- (void)dealloc {
    [packageDetails_ release];
    [super dealloc];
}

#pragma mark - Properties

- (NSString *)identifier {
    return [packageDetails_ objectForKey:(NSString *)kCFBundleIdentifierKey];
}

- (NSString *)name {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:[self bundlePath]];
    NSDictionary *info = [bundle localizedInfoDictionary];
    NSString *name = [info objectForKey:@"CFBundleDisplayName"];
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
    NSNumber *bundleTimestamp = [packageDetails_ objectForKey:@"BundleTimestamp"];
    return (bundleTimestamp != nil) ?
        [NSDate dateWithTimeIntervalSince1970:[bundleTimestamp doubleValue]] :
        nil;
}

- (NSString *)bundlePath {
    return [packageDetails_ objectForKey:@"Path"];
}

- (NSString *)containerPath {
    return [packageDetails_ objectForKey:@"Container"];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
