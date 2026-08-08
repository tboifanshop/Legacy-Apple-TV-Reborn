#!/bin/bash
# build.sh — Direct clang build for Legacy Apple TV Reborn
#
# Requirements:
#   macOS High Sierra 10.13.6
#   Xcode 10.1 (iPhoneOS 12.1 SDK)
#   ldid available at /usr/local/bin/ldid or via PATH
#
# Usage:
#   ./build.sh                         # build dylib
#   ./build.sh install USER@<device>   # build + scp + ldid -S + killall
#
# Do NOT require Homebrew, Theos, or any modern package manager.
# ---------------------------------------------------------------------------

set -e

PRODUCT="AppleTVLauncher.dylib"
DEVICE_DYLIB_PATH="/Library/MobileSubstrate/DynamicLibraries/${PRODUCT}"
DEVICE_PLIST_PATH="/Library/MobileSubstrate/DynamicLibraries/AppleTVLauncher.plist"

SDK="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)"
if [ -z "$SDK" ]; then
    echo "ERROR: Could not locate iPhoneOS SDK. Is Xcode 10.1 installed?"
    exit 1
fi
echo "SDK: $SDK"

# ---------------------------------------------------------------------------
# Source files — must match Makefile AppleTVLauncher_FILES (non-.x sources).
# LauncherHooks.x is pre-processed by Logos (or stub-compiled via clang directly
# if Theos is absent — Logos %hook/%orig must be expanded before passing to clang).
# If building without Theos, you must run the Logos preprocessor separately or
# convert LauncherHooks.x to plain Objective-C.  A pre-processed fallback file
# Hooks/LauncherHooks_processed.m can be placed alongside and selected here.
# ---------------------------------------------------------------------------

HOOKS_FILE="Hooks/LauncherHooks.x"
if [ ! -f "$HOOKS_FILE" ]; then
    echo "ERROR: $HOOKS_FILE not found"
    exit 1
fi

# If Theos Logos preprocessor is available, use it.  Otherwise use the plain .x
# (clang will error on %hook — you must pre-process it separately).
LOGOS="$(command -v logos.pl 2>/dev/null || true)"
HOOKS_COMPILED="Hooks/LauncherHooks.m"
if [ -n "$LOGOS" ]; then
    echo "Logos preprocessor found — preprocessing $HOOKS_FILE"
    "$LOGOS" "$HOOKS_FILE" > "$HOOKS_COMPILED"
else
    echo "WARNING: logos.pl not found — $HOOKS_FILE must be manually pre-processed."
    echo "         Attempting to compile $HOOKS_FILE directly (will fail on %hook syntax)."
    HOOKS_COMPILED="$HOOKS_FILE"
fi

SRCS=(
    "$HOOKS_COMPILED"
    Utilities/ATLLog.m
    SafeMode/ATLSafeMode.m
    Theme/ATLThemeConfig.m
    Theme/ATLThemeManager.m
    Theme/ATLThemeEngine.m
    Theme/ATLGlassOverlayView.m
    Theme/ATLFocusCursorView.m
    Launcher/ATLAppItem.m
    Launcher/ATLLauncherState.m
    Launcher/ATLLauncherAppGridView.m
    Launcher/ATLLauncherCoordinator.m
    Launcher/ATLLauncherRootView.m
    Animations/ATLAnimationCoordinator.m
    Settings/ATLSettingsStore.m
    Settings/ATLRebornSettingsAppliance.m
    Soundtrack/ATLSoundtrackLibrary.m
    Soundtrack/ATLSoundtrackManager.m
    WallpaperManager/ATLWallpaperDescriptor.m
    WallpaperManager/ATLWallpaperManager.m
    VideoPlayer/ATLVideoPlayerService.m
    DriveManager/ATLDriveWorkerClient.m
    FileManager/ATLFileBrowserService.m
    Widgets/ATLWidgetHostView.m
)

CFLAGS=(
    -arch armv7
    -miphoneos-version-min=8.0
    -isysroot "$SDK"
    -fobjc-arc
    -fmodules
    -Wno-deprecated-declarations
    -Wno-unused-variable
    -O2
    -dynamiclib
    -install_name "$DEVICE_DYLIB_PATH"
    -framework Foundation
    -framework UIKit
    -framework CoreGraphics
    -framework QuartzCore
    -framework AVFoundation
    -framework AudioToolbox
    -lobjc
)

echo "Compiling ${#SRCS[@]} source files..."
clang "${CFLAGS[@]}" "${SRCS[@]}" -o "$PRODUCT"
echo "Built: $PRODUCT"

# Pseudo-sign (no entitlements needed for MobileSubstrate dylibs).
LDID="$(command -v ldid 2>/dev/null || true)"
if [ -n "$LDID" ]; then
    "$LDID" -S "$PRODUCT"
    echo "ldid -S applied"
else
    echo "WARNING: ldid not found — you must run 'ldid -S $PRODUCT' on-device or before installation."
fi

# ---------------------------------------------------------------------------
# Optional: install to device over SSH.
# Usage: ./build.sh install root@192.168.x.x
# ---------------------------------------------------------------------------
if [ "$1" = "install" ] && [ -n "$2" ]; then
    DEVICE="$2"
    echo "Installing to $DEVICE..."
    scp "$PRODUCT" "${DEVICE}:${DEVICE_DYLIB_PATH}"
    scp "layout/Library/MobileSubstrate/DynamicLibraries/AppleTVLauncher.plist" \
        "${DEVICE}:${DEVICE_PLIST_PATH}"
    # Sign on-device and restart AppleTV.
    ssh "$DEVICE" "ldid -S '${DEVICE_DYLIB_PATH}' && killall -9 AppleTV || true"
    echo "Done — AppleTV restarted."
fi

# Cleanup preprocessed file if generated.
if [ -n "$LOGOS" ] && [ -f "$HOOKS_COMPILED" ] && [ "$HOOKS_COMPILED" != "$HOOKS_FILE" ]; then
    rm -f "$HOOKS_COMPILED"
fi
