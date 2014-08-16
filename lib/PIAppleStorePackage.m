/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIAppleStorePackage.h"

@implementation PIAppleStorePackage {
    NSDictionary *metadata_;
}

#pragma mark - Creation and Destruction

- (id)initWithDetails:(NSDictionary *)details {
    self = [super initWithDetails:details];
    if (self != nil) {
        NSString *metadataPath = [[self containerPath] stringByAppendingPathComponent:@"iTunesMetadata.plist"];
        NSDictionary *metadata = [[NSDictionary alloc] initWithContentsOfFile:metadataPath];
        if (metadata != nil) {
            metadata_ = metadata;
        } else {
            fprintf(stderr, "ERROR: Failed to load metadata for package with identifer: %s.\n", [[self identifier] UTF8String]);
        }
    }
    return self;
}

- (void)dealloc {
    [metadata_ release];
    [super dealloc];
}

#pragma mark - Properties

- (NSString *)storeIdentifier {
    return [[metadata_ objectForKey:@"itemId"] stringValue];
}

- (NSString *)author {
    return [metadata_ objectForKey:@"artistName"];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
