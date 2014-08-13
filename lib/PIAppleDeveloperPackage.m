/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIAppleDeveloperPackage.h"

@implementation PIAppleDeveloperPackage

#pragma mark - Properties

- (NSString *)libraryPath {
    return [[self containerPath] stringByAppendingPathComponent:@"Library"];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
