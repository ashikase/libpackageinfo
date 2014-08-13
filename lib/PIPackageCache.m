/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import "PIPackageCache.h"

#import "PIPackage.h"

#include <dlfcn.h>

@implementation PIPackageCache {
    NSMutableDictionary *filepathBasedCache_;
    NSMutableDictionary *identifierBasedCache_;
}

+ (instancetype)sharedCache {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        filepathBasedCache_ = [NSMutableDictionary new];
        identifierBasedCache_ = [NSMutableDictionary new];

        // If being used in a UIKit application, listen for memory warnings.
        // NOTE: Determine symbol for notification name dynamically to prevent
        //       loading UIKit framework into non-UIKit processes.
        void *handle = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_NOLOAD);
        if (handle != NULL) {
            NSString **UIApplicationDidReceiveMemoryWarningNotification =
                (NSString **)dlsym(handle, "UIApplicationDidReceiveMemoryWarningNotification");
            if (UIApplicationDidReceiveMemoryWarningNotification != NULL) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning)
                    name:*UIApplicationDidReceiveMemoryWarningNotification object:nil];
            }
            dlclose(handle);
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [filepathBasedCache_ release];
    [identifierBasedCache_ release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [self removeAllObjects];
}

- (PIPackage *)packageForFile:(NSString *)filepath {
    PIPackage *package = [filepathBasedCache_ objectForKey:filepath];
    if (package == nil) {
        package = [PIPackage packageForFile:filepath];
        [self cachePackage:package forFile:filepath];
    }
    return package;
}

- (PIPackage *)packageWithIdentifier:(NSString *)identifier {
    PIPackage *package = [identifierBasedCache_ objectForKey:identifier];
    if (package == nil) {
        package = [PIPackage packageWithIdentifier:identifier];
        [self cachePackage:package forIdentifier:identifier];
    }
    return package;
}

- (void)cachePackage:(PIPackage *)package forFile:(NSString *)filepath {
    if (package != nil) {
        [filepathBasedCache_ setObject:package forKey:filepath];
    }
}

- (void)cachePackage:(PIPackage *)package forIdentifier:(NSString *)identifier {
    if (package != nil) {
        [identifierBasedCache_ setObject:package forKey:identifier];
    }
}

- (void)removeAllObjects {
    [filepathBasedCache_ removeAllObjects];
    [identifierBasedCache_ removeAllObjects];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
