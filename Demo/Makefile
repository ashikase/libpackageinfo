TOOL_NAME = packageinfo
PKG_ID = jp.ashikase.packageinfo

packageinfo_OBJC_FILES = main.mm
packageinfo_LIBRARIES = packageinfo
ADDITIONAL_CFLAGS = -DPKG_ID=\"$(PKG_ID)\"

export ARCHS = armv6
export TARGET = iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tool.mk

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(PKG_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
