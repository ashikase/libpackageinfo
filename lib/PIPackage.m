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

#include <time.h>

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

- (id)initWithDetailsFromJSONDictionary:(NSDictionary *)dictionary {
    // NOTE: Subclasses should completely override this method in order to
    //       perform any necessary conversion on the contained keys and values.
    fprintf(stderr, "ERROR: PIPackage's implementation of 'initWithDetailsFromJSONDictionary:' should never be called.\n");
    [self release];
    return nil;
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
        return [self initWithDetailsFromJSONDictionary:object];
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
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    NSString *identifier = [self identifier];
    if (identifier != nil) {
        [dictionary setObject:identifier forKey:@"identifier"];
    }

    NSString *name = [self name];
    if (name != nil) {
        [dictionary setObject:name forKey:@"name"];
    }

    NSString *author = [self author];
    if (author != nil) {
        [dictionary setObject:author forKey:@"author"];
    }

    NSString *version = [self version];
    if (version != nil) {
        [dictionary setObject:version forKey:@"version"];
    }

    NSDate *date = [self installDate];
    if (date != nil) {
        // Convert date to string.
        char buf[29];
        const char *format = "%Y-%m-%d %H:%M:%S %z";
        time_t interval = (time_t)[date timeIntervalSince1970];
        if (strftime(buf, 29, format, localtime(&interval)) > 0) {
            NSString *string = [[NSString alloc] initWithCString:buf encoding:NSUTF8StringEncoding];
            [dictionary setObject:string forKey:@"install_date"];
            [string release];
        }
    }

    return dictionary;
}

- (NSString *)JSONRepresentation {
    NSString *string = nil;

    NSDictionary *dictionary = [self dictionaryRepresentation];
    if (IOS_LT(6_0)) {
        string = [dictionary JSONString];
        if (string == nil) {
            fprintf(stderr, "ERROR: Unable to convert dictionary to JSON string.\n");
        }
    } else {
        Class $NSJSONSerialization = NSClassFromString(@"NSJSONSerialization");
        if ($NSJSONSerialization != Nil) {
            NSError *error = nil;
            if ([$NSJSONSerialization isValidJSONObject:dictionary]) {
                NSData *data = [$NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
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
