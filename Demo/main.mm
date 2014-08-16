#import <Foundation/Foundation.h>

#import <libpackageinfo/libpackageinfo.h>

static void print_usage() {
    fprintf(stderr,
            "Usage: packageinfo -f <filepath>\n"
            "       packageinfo -i <identifier>\n"
            "\n"
            "Options:\n"
            "    -f <filepath>     Show information for package containing filepath.\n"
            "    -i <identifier>   Show information for package with identifier.\n"
            "\n"
           );
}

int main(int argc, char **argv, char **envp) {
    @autoreleasepool {
        if (argc < 3) {
            print_usage();
        } else {
            NSString *identifier = nil;
            NSString *filepath = nil;

            int c;
            while ((c = getopt(argc, argv, "f:i:")) != -1) {
                switch (c) {
                    case 'f':
                        filepath = [[NSString alloc] initWithUTF8String:optarg];
                        break;
                    case 'i':
                        identifier = [[NSString alloc] initWithUTF8String:optarg];
                        break;
                    default:
                        print_usage();
                        goto exit;
                }
            }

            if ((identifier == nil) && (filepath == nil)) {
                print_usage();
            } else {
                // Parse the log file.
                PIPackage *package = nil;
                if (identifier != nil) {
                    package = [PIPackage packageWithIdentifier:identifier];
                } else if (filepath != nil) {
                    package = [PIPackage packageForFile:filepath];
                }

                if (package != nil) {
                    const char *type = NULL;
                    Class klass = [package class];
                    if (klass == [PIDebianPackage class]) {
                        type = "Debian Package";
                    } else if (klass == [PIAppleDeveloperPackage class]) {
                        type = "Apple Developer Package";
                    } else if (klass == [PIAppleSystemPackage class]) {
                        type = "Apple System Package";
                    } else if (klass == [PIAppleStorePackage class]) {
                        type = "Apple Store Package";
                    } else {
                        type = "<unknown>";
                    }

                    fprintf(stderr, "Type:              %s\n", type);
                    fprintf(stderr, "Identifier:        %s\n", [[package identifier] UTF8String]);
                    fprintf(stderr, "Store Identifier:  %s\n", [[package storeIdentifier] UTF8String]);
                    fprintf(stderr, "Name:              %s\n", [[package name] UTF8String]);
                    fprintf(stderr, "Author:            %s\n", [[package author] UTF8String]);
                    fprintf(stderr, "Version:           %s\n", [[package version] UTF8String]);
                    fprintf(stderr, "Date Installed:    %s\n", [[[package installDate] description] UTF8String]);
                    fprintf(stderr, "Bundle Path:       %s\n", [[package bundlePath] UTF8String]);
                    fprintf(stderr, "Library Path:      %s\n", [[package libraryPath] UTF8String]);
                } else {
                    fprintf(stderr, "ERROR: Package not found.\n");
                }

                [filepath release];
                [identifier release];
            }
        }
    }

exit:
    return 0;
}

// vim:ft=objc
