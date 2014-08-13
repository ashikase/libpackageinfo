TOOL_NAME = packageinfo
PKG_ID = jp.ashikase.packageinfo

packageinfo_OBJC_FILES = \
    ../lib/PIPackage.m \
    ../lib/PIDebianPackage.m \
    ../lib/PIApplePackage.m \
    ../lib/PIAppleSystemPackage.m \
    ../lib/PIAppleDeveloperPackage.m \
    ../lib/PIAppleStorePackage.m \
    main.mm
ADDITIONAL_CFLAGS = -DPKG_ID=\"$(PKG_ID)\" -I../include

export ARCHS = armv6
export TARGET = iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tool.mk

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(PKG_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
