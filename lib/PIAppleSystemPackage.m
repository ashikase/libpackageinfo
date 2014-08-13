/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIAppleSystemPackage.h"

@implementation PIAppleSystemPackage

#pragma mark - Creation and Destruction

#pragma mark - Properties

- (NSString *)author {
    return [[self identifier] hasPrefix:@"com.apple."] ? @"Apple Inc." : nil;
}

- (NSString *)libraryPath {
    NSString *containerPath = [self containerPath];
    if (containerPath != nil) {
        return [containerPath stringByAppendingPathComponent:@"Library"];
    } else {
        return @"/var/mobile/Library";
    }
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
