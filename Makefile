build:
	make -f Makefile.x86_64
	make -f Makefile.arm
	lipo -create obj/libpackageinfo.dylib obj/macosx/libpackageinfo.dylib -output libpackageinfo.dylib
	mv libpackageinfo.dylib obj/libpackageinfo.dylib

clean:
	make -f Makefile.x86_64 clean
	make -f Makefile.arm clean

distclean:
	make -f Makefile.x86_64 distclean
	make -f Makefile.arm distclean

package: build
	make -f Makefile.arm package

install:
	make -f Makefile.arm install
