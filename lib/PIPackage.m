/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIPackage.h"

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
    return nil;
}

- (NSString *)JSONRepresentation {
    return nil;
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
