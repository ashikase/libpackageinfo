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
    id object = [string objectFromJSONString];
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
    return [packageDetails_ JSONString];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
