> # Version 1.1.0.1
> - - -
> * FIX: iOS 9
>     * As per Jay Freeman (saurik): "iOS 9 changed the 32-bit pagesize on 64-bit CPUs from 4096 bytes to 16384: all 32-bit binaries must now be compiled with -Wl,-segalign,4000.".

- - -

> # Version 1.1.0
> - - -
> * NEW: Added property for obtaining maintainer of a package.

- - -

> # Version 1.0.1
> - - -
> * FIX: Querying Apple-type packages would return an empty result on iOS 8.
> * FIX: Searching for the filepath of a bundle would result in an infinite loop in certain cases.

- - -

> # Version 1.0.0
> - - -
> * Initial release.
