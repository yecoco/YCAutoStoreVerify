ARCHS = arm64
export TARGET_CODESIGN_FLAGS="-SEntitlements.plist"
THEOS_DEVICE_IP=10.0.1.99
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppleIDVerify
AppleIDVerify_FILES = Tweak.xm AppStoreVerifyManager.m AppleAccount.m SBAutoVerifyEmailManager.m LotoWebViewManager.m
AppleIDVerify_FRAMEWORKS = Foundation UIKit CoreGraphics CoreFoundation
AppleIDVerify_PRIVATE_FRAMEWORKS = IOKit
AppleIDVerify_LDFLAGS += -force_load PTFakeTouch.framework/PTFakeTouch

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 AppStore & killall -9 itunesstored & killall -9 SpringBoard & killall -9 itunescloudd & killall -9 storebookkeeperd & killall -9 akd"
