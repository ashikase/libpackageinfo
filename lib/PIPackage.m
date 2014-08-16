/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIPackage.h"

#import <JSONKit/JSONKit.h>
#import "PIApplePackage.h"
#import "PIDebianPackage.h"

@implementation PIPackage

@dynamic identifier;
@dynamic storeIdentifier;
@dynamic name;
@dynamic author;
@dynamic version;
@dynamic installDate;
@dynamic bundlePath;
@dynamic libraryPath;

#pragma mark - Creation and Destruction

+ (instancetype)packageForFile:(NSString *)filepath {
    // NOTE: Subclasses should *not* call super's method.
    if (self == [PIPackage class]) {
        if ([PIDebianPackage isFromDebianPackage:filepath]) {
            return [PIDebianPackage packageForFile:filepath];
        } else {
            return [PIApplePackage packageForFile:filepath];
        }
    } else {
        return nil;
    }
}

+ (instancetype)packageWithIdentifier:(NSString *)identifier {
    // NOTE: Subclasses should *not* call super's method.
    if (self == [PIPackage class]) {
        if ([PIDebianPackage isDebianPackage:identifier]) {
            return [PIDebianPackage packageWithIdentifier:identifier];
        } else {
            return [PIApplePackage packageWithIdentifier:identifier];
        }
    } else {
        return nil;
    }
}

+ (id)alloc {
    if (self == [PIPackage class]) {
        fprintf(stderr, "ERROR: PIPackage is a base class and cannot be allocated.\n");
        return nil;
    } else {
        return [super alloc];
    }
}

+ (id)allocWithZone:(NSZone *)zone {
    if (self == [PIPackage class]) {
        fprintf(stderr, "ERROR: PIPackage is a base class and cannot be allocated.\n");
        return nil;
    } else {
        return [super allocWithZone:zone];
    }
}

- (id)initWithDetails:(NSDictionary *)details {
    if ([details count] > 0) {
        self = [super init];
        if (self != nil) {
            packageDetails_ = [details copy];
        }
        return self;
    } else {
        [self release];
        return nil;
    }
}

- (id)initWithDetailsFromJSONString:(NSString *)string {
    // Parse the JSON into a dictionary.
    id object = nil;
    if (IOS_LT(6_0)) {
        object = [string objectFromJSONString];
    } else {
        Class $NSJSONSerialization = NSClassFromString(@"NSJSONSerialization");
        if ($NSJSONSerialization != Nil) {
            NSError *error= nil;
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            object = [$NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (object == nil) {
                fprintf(stderr, "ERROR: Unable to parse JSON string: %s.\n", [[error localizedDescription] UTF8String]);
            }
        } else {
            fprintf(stderr, "ERROR: NSJSONSerialization class not available.\n");
        }
    }
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [self initWithDetails:object];
    } else {
        fprintf(stderr, "ERROR: JSON string could not be parsed or is not a dictionary.\n");
        [self release];
        return nil;
    }
}

- (void)dealloc {
    [packageDetails_ release];
    [super dealloc];
}

#pragma mark - Properties

- (NSString *)identifier {
    return nil;
}

- (NSString *)storeIdentifier {
    return nil;
}

- (NSString *)name {
    return nil;
}

- (NSString *)author {
    return nil;
}

- (NSString *)version {
    return nil;
}

- (NSDate *)installDate {
    return nil;
}

- (NSString *)bundlePath {
    return nil;
}

- (NSString *)libraryPath {
    return nil;
}

#pragma mark - Representations

- (NSDictionary *)dictionaryRepresentation {
    return [[packageDetails_ copy] autorelease];
}

- (NSString *)JSONRepresentation {
    NSString *string = nil;
    if (IOS_LT(6_0)) {
        string = [packageDetails_ JSONString];
        if (string == nil) {
            fprintf(stderr, "ERROR: Unable to convert dictionary to JSON string.\n");
        }
    } else {
        Class $NSJSONSerialization = NSClassFromString(@"NSJSONSerialization");
        if ($NSJSONSerialization != Nil) {
            NSError *error = nil;
            if ([$NSJSONSerialization isValidJSONObject:packageDetails_]) {
                NSData *data = [$NSJSONSerialization dataWithJSONObject:packageDetails_ options:NSJSONWritingPrettyPrinted error:&error];
                if (data != nil) {
                    string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                } else {
                    fprintf(stderr, "ERROR: Unable to convert dictionary to JSON string: %s.\n", [[error localizedDescription] UTF8String]);
                }
            } else {
                fprintf(stderr, "ERROR: Dictionary is not valid JSON object.\n");
            }
        } else {
            fprintf(stderr, "ERROR: NSJSONSerialization class not available.\n");
        }
    }
    return string;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
