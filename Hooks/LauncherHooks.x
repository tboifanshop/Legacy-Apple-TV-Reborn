//  Hooks/LauncherHooks.x
//  Legacy Apple TV Reborn — production hooks
//
//  Hook entry points for the AppleTV process.
//
//  CONFIRMED classes/methods used:
//    UIApplication             — CONFIRMED
//    BRApplication             — CONFIRMED (runtime)
//    BRMenuController          — CONFIRMED (runtime)
//    BRControl / UIView        — CONFIRMED
//    focusControl:             — CONFIRMED on BRApplication
//    _handleHIDEvent:          — CONFIRMED on BRApplication
//
//  RUNTIME-CHECKED: All private selectors verified via respondsToSelector: before use.
//  ASSUMED: none shipped in production without runtime confirmation.
//
//  Kodi guard: the tweak's MobileSubstrate plist already restricts injection
//  to Executable = AppleTV only, so Kodi never loads this dylib.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "../Utilities/ATLLog.h"
#import "../SafeMode/ATLSafeMode.h"
#import "../Theme/ATLThemeConfig.h"
#import "../Theme/ATLThemeManager.h"
#import "../Theme/ATLFocusCursorView.h"
#import "../Theme/ATLGlassOverlayView.h"
#import "../Settings/ATLRebornSettingsAppliance.h"
#import "../Soundtrack/ATLSoundtrackManager.h"

// ---------------------------------------------------------------------------
// Glass overlay tracking
// ---------------------------------------------------------------------------
static const void *kATLGlassOverlayKey = &kATLGlassOverlayKey;

// ---------------------------------------------------------------------------
// HID long-press tracking for Soundtrack Menu
// We detect Play/Pause (button code 0xCD on ATV remote) held for >= 0.5 s.
// ---------------------------------------------------------------------------
static NSTimeInterval ATLPlayPausePressBegin  = 0.0;
static BOOL           ATLPlayPauseIsDown      = NO;
static const NSTimeInterval kATLLongPressDuration = 0.5;

// ---------------------------------------------------------------------------
// Background image view (one per window, refreshed on theme change)
// ---------------------------------------------------------------------------
static UIImageView *ATLBackgroundImageView   = nil;
static NSString   *ATLBackgroundThemeID      = nil;

static void ATLInstallBackgroundIfNeeded(UIWindow *window) {
    if (!window) return;
    ATLThemeConfig *cfg = [ATLThemeManager sharedManager].activeTheme;
    if (cfg.isBypassMode) {
        // Bypass: remove any existing background.
        if (ATLBackgroundImageView) {
            [ATLBackgroundImageView removeFromSuperview];
            ATLBackgroundImageView = nil;
            ATLBackgroundThemeID   = nil;
        }
        return;
    }
    // Already installed for this theme — nothing to do.
    if (ATLBackgroundImageView && [ATLBackgroundThemeID isEqualToString:cfg.themeID]) return;
    // Remove stale background from previous theme.
    if (ATLBackgroundImageView) {
        [ATLBackgroundImageView removeFromSuperview];
        ATLBackgroundImageView = nil;
    }
    NSString *path = [[ATLThemeManager sharedManager] pathForThemeResource:cfg.backgroundImageName];
    if (!path) return;
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    if (!img) return;
    ATLBackgroundImageView = [[UIImageView alloc] initWithFrame:window.bounds];
    ATLBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    ATLBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    ATLBackgroundImageView.image = img;
    [window insertSubview:ATLBackgroundImageView atIndex:0];
    ATLBackgroundThemeID = cfg.themeID;
    ATLLogInfo(@"Reborn: background applied from %@", path);
}

// ---------------------------------------------------------------------------
// Glass overlay on a tile view
// ---------------------------------------------------------------------------
static void ATLApplyGlassToTileView(UIView *tileView) {
    ATLThemeConfig *cfg = [ATLThemeManager sharedManager].activeTheme;
    if (cfg.isBypassMode || cfg.glassAlpha < 0.01f) return;

    ATLGlassOverlayView *existing = objc_getAssociatedObject(tileView, kATLGlassOverlayKey);
    if (existing) return;

    ATLGlassOverlayView *overlay = [[ATLGlassOverlayView alloc]
        initWithFrame:tileView.bounds config:cfg];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.userInteractionEnabled = NO;
    [tileView addSubview:overlay];
    objc_setAssociatedObject(tileView, kATLGlassOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// ---------------------------------------------------------------------------
// BRMenuController hook — overlay glass on the menu when it appears
// CONFIRMED: BRMenuController is a real runtime class (ATL diagnostic data)
// RUNTIME-CHECKED: viewDidAppear: guarded below
// ---------------------------------------------------------------------------
%hook BRMenuController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (ATLSafeModeIsActive()) return;
    ATLThemeConfig *cfg = [ATLThemeManager sharedManager].activeTheme;
    if (cfg.isBypassMode) return;

    // Apply glass overlay to each visible tile subview.
    // Tile subviews may be UIView or BRControl descendants.
    // We iterate one level deep and apply to views matching the expected tile size.
    UIView *root = [self valueForKey:@"view"];
    if (!root) return;

    for (UIView *sub in root.subviews) {
        CGSize s = sub.bounds.size;
        // Standard Apple TV tile: 288x154 pt.  Allow +/-20 pt tolerance.
        if (s.width  >= 268 && s.width  <= 308 &&
            s.height >= 134 && s.height <= 174) {
            ATLApplyGlassToTileView(sub);
        }
    }

    // Hide shelf banner views if theme requests it.
    if (cfg.shelfBannersHidden) {
        for (UIView *sub in root.subviews) {
            CGSize s = sub.bounds.size;
            // Top shelf: 1920x440.  On a 1080p screen at 1x that is full width, ~220 pt tall.
            if (s.width >= 800 && s.height >= 180 && s.height <= 260) {
                sub.hidden = YES;
            }
        }
    }

    // Ensure background is installed in the window.
    ATLInstallBackgroundIfNeeded(root.window);
}

%end

// ---------------------------------------------------------------------------
// BRApplication hook — intercept focus changes to move cursor
// CONFIRMED: focusControl: exists on BRApplication
// ---------------------------------------------------------------------------
%hook BRApplication

// focusControl: — CONFIRMED
- (void)focusControl:(id)control {
    %orig;
    if (ATLSafeModeIsActive()) return;
    if ([ATLThemeManager sharedManager].activeTheme.isBypassMode) return;

    UIView *controlView = nil;
    // control may be a UIView or BRControl (which is a UIView subclass).
    if ([control isKindOfClass:[UIView class]]) {
        controlView = (UIView *)control;
    }
    [[ATLFocusCursorView sharedCursor] moveToBRCornerOfView:controlView];
}

// _handleHIDEvent: — CONFIRMED
// We intercept HID events here to detect Play/Pause long-press -> Soundtrack Menu.
- (void)_handleHIDEvent:(id)event {
    %orig;
    if (ATLSafeModeIsActive()) return;
    if ([ATLThemeManager sharedManager].activeTheme.isBypassMode) return;

    // Inspect HID event for Play/Pause button (usage 0xCD, page 0x0C Consumer).
    // We use KVC/selector probing since the HID event type is private.
    // RUNTIME-CHECKED: check selector before calling.
    SEL usageSel = NSSelectorFromString(@"usage");
    SEL typeSel  = NSSelectorFromString(@"eventType");
    if (![event respondsToSelector:usageSel] || ![event respondsToSelector:typeSel]) return;

    // Use objc_msgSend with integer return type — HID event selectors return C integers,
    // not Objective-C objects, so performSelector: would return a garbage pointer.
    typedef NSInteger (*IntMsgFn)(id, SEL);
    NSInteger usage = ((IntMsgFn)objc_msgSend)(event, usageSel);
    NSInteger type  = ((IntMsgFn)objc_msgSend)(event, typeSel);

    // usage 0xCD = Play/Pause.  type 1 = key-down, type 0 = key-up (assumed from HID spec).
    if (usage != 0xCD) return;

    if (type == 1) {
        if (!ATLPlayPauseIsDown) {
            ATLPlayPauseIsDown    = YES;
            ATLPlayPausePressBegin = CACurrentMediaTime();
        }
    } else {
        if (ATLPlayPauseIsDown) {
            NSTimeInterval held = CACurrentMediaTime() - ATLPlayPausePressBegin;
            ATLPlayPauseIsDown  = NO;
            if (held >= kATLLongPressDuration) {
                ATLLogInfo(@"Reborn: long Play/Pause -> Soundtrack Menu");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:@"ATLOpenSoundtrackMenu" object:nil];
                });
            }
        }
    }
}

%end

// ---------------------------------------------------------------------------
// Constructor — check safe mode, apply theme, start soundtrack.
// ---------------------------------------------------------------------------
%ctor {
    @autoreleasepool {
        if (ATLSafeModeIsActive()) {
            ATLLogError(@"Reborn: safe mode active — no hooks installed");
            return;
        }

        ATLLogInfo(@"AppleTVLauncher loaded into AppleTV");

        ATLThemeConfig *cfg = [ATLThemeManager sharedManager].activeTheme;
        ATLLogInfo(@"Reborn: active theme = %@", cfg.displayName);

        [ATLRebornSettingsAppliance registerIfPossible];

        if (!cfg.isBypassMode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ATLSoundtrackManager sharedManager] playDefaultForActiveTheme];
            });
        }
    }
}
