/**
 * Name: libpackageinfo
 * Type: iOS library
 * Desc: iOS library for retrieving information regarding installed packages.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

// Referenced searchfiles() of query.c of the dpkg source package.

#import "PIDebianPackage.h"

#include <sys/stat.h>

static NSString * const kDebianPackageInfoPath = @"/var/lib/dpkg/info";

static NSSet *filesFromDebianPackages$ = nil;

static NSSet *setOfFilesFromDebianPackages() {
    NSMutableString *filelist = [NSMutableString new];

    // Retrieve a list of all files that come from Debian packages.
    // NOTE: List will contain files of all types, not just binaries with
    //       executable code.
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileMan contentsOfDirectoryAtPath:kDebianPackageInfoPath error:&error];
    if (contents != nil) {
        for (NSString *file in contents) {
            if ([file hasSuffix:@".list"]) {
                NSString *filepath = [kDebianPackageInfoPath stringByAppendingPathComponent:file];
                NSString *string = [[NSString alloc] initWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
                if (string != nil) {
                    [filelist appendString:string];
                } else {
                    fprintf(stderr, "ERROR: Failed to read contents of file \"%s\": %s.\n",
                            [filepath UTF8String], [[error localizedDescription] UTF8String]);
                }
                [string release];
            }
        }
    } else {
        fprintf(stderr, "ERROR: Failed to get contents of dpkg info directory: %s.\n", [[error localizedDescription] UTF8String]);
    }

    // Convert list into a unique set.
    NSSet *set = [[NSSet alloc] initWithArray:[filelist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];

    // Clean-up.
    [filelist release];

    return [set autorelease];
}

static NSDictionary *detailsFromDebianPackageQuery(FILE *f) {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];

    NSMutableData *data = [NSMutableData new];
    char buf[1025];
    size_t maxSize = (sizeof(buf) - 1);
    while (!feof(f)) {
        if (fgets(buf, maxSize, f)) {
            buf[maxSize] = '\0';

            char *newlineLocation = strrchr(buf, '\n');
            if (newlineLocation != NULL) {
                [data appendBytes:buf length:(NSUInteger)(newlineLocation - buf)];

                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSUInteger firstColon = [string rangeOfString:@":"].location;
                if (firstColon != NSNotFound) {
                    NSUInteger length = [string length];
                    if (length > (firstColon + 1)) {
                        NSString *key = [string substringToIndex:firstColon];
                        NSString *value = [string substringFromIndex:(firstColon + 1)];
                        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        if ([value length] > 0) {
                            [details setObject:value forKey:key];
                        }
                    }
                }
                [string release];
                [data setLength:0];
            } else {
                [data appendBytes:buf length:maxSize];
            }
        }
    }
    [data release];

    return details;
}

static NSDictionary *detailsForDebianPackageWithIdentifier(NSString *identifier) {
    NSDictionary *details = nil;

    // Backup stderr.
    int devStderr = dup(STDERR_FILENO);
    if (devStderr == -1) {
        fprintf(stderr, "ERROR: Failed to backup stderr: errno = %d.\n", errno);
    }

    // Redirect stderr to /dev/null.
    int devNull = open("/dev/null", O_WRONLY);
    if (dup2(devNull, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to redirect stderr to /dev/null for dpkg-query command: errno = %d.\n", errno);
    }

    // NOTE: Query using -p switch (/var/lib/dpkg/available) first, as package
    //       might have been uninstalled recently due to some issue.
    //       (Uninstalled packages will appear in 'status', but without any
    //       name/author information).
    FILE *f;
    NSString *query;

    query = [[NSString alloc] initWithFormat:@"dpkg-query -p \"%@\"", identifier];
    f = popen([query UTF8String], "r");
    [query release];

    int stat_loc = 0;
    if (f != NULL) {
        details = detailsFromDebianPackageQuery(f);
        stat_loc = pclose(f);
    }

    // Check the exit status to determine if the operation was successful.
    BOOL succeeded = NO;
    if (WIFEXITED(stat_loc)) {
        if (WEXITSTATUS(stat_loc) == 0) {
            succeeded = YES;
        }
    }

    // If command failed, try again using "-s" (/var/lib/dpkg/status) switch.
    if (!succeeded) {
        query = [[NSString alloc] initWithFormat:@"dpkg-query -s \"%@\"", identifier];
        f = popen([query UTF8String], "r");
        [query release];

        int stat_loc = 0;
        if (f != NULL) {
            // Determine name, author and version.
            details = detailsFromDebianPackageQuery(f);
            stat_loc = pclose(f);
        }
    }

    // Restore stderr.
    if (dup2(devStderr, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to restore stderr: errno = %d.\n", errno);
    }

    // Close duplicate file descriptors.
    close(devNull);
    close(devStderr);

    return details;
}

static NSString *identifierForDebianPackageContainingFile(NSString *filepath) {
    NSString *identifier = nil;

    // Backup stderr.
    int devStderr = dup(STDERR_FILENO);
    if (devStderr == -1) {
        fprintf(stderr, "ERROR: Failed to backup stderr: errno = %d.\n", errno);
    }

    // Redirect stderr to /dev/null.
    int devNull = open("/dev/null", O_WRONLY);
    if (dup2(devNull, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to redirect stderr to /dev/null for dpkg-query command: errno = %d.\n", errno);
    }

    // Determine identifier of the package that contains the specified file.
    // NOTE: We need the slow way or we need to compile the whole dpkg.
    //       Not worth it for a minor feature like this.
    FILE *f = popen([[NSString stringWithFormat:@"dpkg-query -S \"%@\" | head -1", filepath] UTF8String], "r");
    if (f != NULL) {
        // NOTE: Since there's only 1 line, we can read until a , or : is hit.
        NSMutableData *data = [NSMutableData new];
        char buf[1025];
        size_t maxSize = (sizeof(buf) - 1);
        while (!feof(f)) {
            size_t actualSize = fread(buf, 1, maxSize, f);
            buf[actualSize] = '\0';
            size_t identifierSize = strcspn(buf, ",:");
            [data appendBytes:buf length:identifierSize];

            // TODO: What is the purpose of this line?
            if (identifierSize != maxSize) {
                break;
            }
        }
        if ([data length] > 0) {
            identifier = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        [data release];
        pclose(f);
    }

    // Restore stderr.
    if (dup2(devStderr, STDERR_FILENO) == -1) {
        fprintf(stderr, "ERROR: Failed to restore stderr: errno = %d.\n", errno);
    }

    // Close duplicate file descriptors.
    close(devNull);
    close(devStderr);

    return identifier;
}

static NSDate *installDateForDebianPackageWithIdentifier(NSString *identifier) {
    NSDate *date = nil;

    // Determine the date that the package was installed (or last updated).
    // NOTE: Determined by looking at the modification date of the package
    //       contents list file.
    // XXX: If someone were to manually touch or edit this file, the "install
    //      date" would no longer be accurate.
    NSString *listPath = [[NSString alloc] initWithFormat:@"/var/lib/dpkg/info/%@.list", identifier];
    NSError *error = nil;
    NSDictionary *attrib = [[NSFileManager defaultManager] attributesOfItemAtPath:listPath error:&error];
    if (attrib != nil) {
        date = [attrib fileModificationDate];
    } else {
        fprintf(stderr, "ERROR: Failed to get attributes of package's info file: %s.\n",
                [[error localizedDescription] UTF8String]);
    }
    [listPath release];

    return date;
}

@implementation PIDebianPackage {
    NSDate *installDate_;
}

+ (void)initialize {
    if (self == [PIDebianPackage class]) {
        filesFromDebianPackages$ = [setOfFilesFromDebianPackages() retain];
    }
}

+ (BOOL)isDebianPackage:(NSString *)identifier {
    NSString *filepath = [[NSString alloc] initWithFormat:@"/var/lib/dpkg/info/%@.list", identifier];
    struct stat buf;
    BOOL isDebianPackage = (stat([filepath UTF8String], &buf) == 0);
    [filepath release];
    return isDebianPackage;
}

+ (BOOL)isFromDebianPackage:(NSString *)filepath {
    return [filesFromDebianPackages$ containsObject:filepath];
}

#pragma mark - Creation & Destruction

// NOTE: Should *not* call super's implementation.
+ (instancetype)packageForFile:(NSString *)filepath {
    NSString *identifier = identifierForDebianPackageContainingFile(filepath);
    return [self packageWithIdentifier:identifier];
}

// NOTE: Should *not* call super's implementation.
+ (instancetype)packageWithIdentifier:(NSString *)identifier {
    NSDictionary *packageDetails = detailsForDebianPackageWithIdentifier(identifier);
    return [[[self alloc] initWithDetails:packageDetails] autorelease];
}

- (void)dealloc {
    [installDate_ release];
    [super dealloc];
}

#pragma mark - Properties (Overrides)

- (NSString *)identifier {
    return [packageDetails_ objectForKey:@"Package"];
}

- (NSString *)storeIdentifier {
    return [self identifier];
}

- (NSString *)name {
    return [packageDetails_ objectForKey:@"Name"];
}

- (NSString *)author {
    return [packageDetails_ objectForKey:@"Author"];
}

- (NSString *)version {
    return [packageDetails_ objectForKey:@"Version"];
}

- (NSDate *)installDate {
    if (installDate_ == nil) {
        // NOTE: "InstallDate" is not a key produced by the dpkg utility; it is
        //       a custom key created for this library to allow manually setting
        //       an install date.
        installDate_ = [packageDetails_ objectForKey:@"InstallDate"];
        if (installDate_ == nil) {
            NSString *identifier = [self identifier];
            installDate_ = installDateForDebianPackageWithIdentifier(identifier);
        }
        [installDate_ retain];
    }
    return installDate_;
}

- (NSString *)libraryPath {
    return @"/var/mobile/Library";
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
