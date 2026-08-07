export THEOS ?= $(HOME)/theos

TARGET := iphone:clang:10.3:7.0
ARCHS := armv7
FINALPACKAGE := 1
DEBUG := 0
INSTALL_TARGET_PROCESSES = AppleTV

ATL_RUNTIME_ONLY ?= 0

include $(THEOS)/makefiles/common.mk

ifeq ($(ATL_RUNTIME_ONLY),1)

TWEAK_NAME = ATLRuntimeProbe

ATLRuntimeProbe_FILES = \
	Hooks/ATLRuntimeProbeEntry.m \
	Diagnostics/ATLRuntimeDiagnostics.m

ATLRuntimeProbe_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
ATLRuntimeProbe_FRAMEWORKS = Foundation

else

TWEAK_NAME = AppleTVLauncher

AppleTVLauncher_FILES = \
	Hooks/LauncherHooks.x \
	Utilities/ATLLog.m \
	Launcher/ATLAppItem.m \
	Launcher/ATLLauncherState.m \
	Launcher/ATLLauncherAppGridView.m \
	Launcher/ATLLauncherCoordinator.m \
	Launcher/ATLLauncherRootView.m \
	Animations/ATLAnimationCoordinator.m \
	Settings/ATLSettingsStore.m \
	WallpaperManager/ATLWallpaperDescriptor.m \
	WallpaperManager/ATLWallpaperManager.m \
	VideoPlayer/ATLVideoPlayerService.m \
	DriveManager/ATLDriveWorkerClient.m \
	FileManager/ATLFileBrowserService.m \
	Widgets/ATLWidgetHostView.m

AppleTVLauncher_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
AppleTVLauncher_FRAMEWORKS = Foundation UIKit CoreGraphics QuartzCore AVFoundation

endif

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	chmod 0755 $(THEOS_STAGING_DIR)/DEBIAN || true
	chmod 0644 $(THEOS_STAGING_DIR)/DEBIAN/control || true

after-install::
	install.exec "killall -9 AppleTV || true"
