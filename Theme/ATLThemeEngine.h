//  ATLThemeEngine.h
//  Legacy Apple TV Reborn
//
//  Low-level CALayer / UIView helpers shared across theme modules.
//  This is a utility layer — theme decisions live in ATLThemeConfig/ATLThemeManager.
//
//  All APIs here are non-themed helpers (shimmer, focus ring, etc.) that
//  can be called by any module without coupling to a specific theme palette.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ATLThemeEngine : NSObject

+ (instancetype)sharedEngine;

// ---- Layer helpers --------------------------------------------------------

/// Adds an animated shimmer (horizontal highlight sweep) to a layer.
/// Safe to call multiple times — guarded by associated object.
- (void)applyShimmerToLayer:(CALayer *)layer;

/// Draws a focus-ring border on the supplied layer with the given color.
- (void)applyFocusRingToLayer:(CALayer *)layer color:(UIColor *)color;

/// Removes the focus-ring from the supplied layer.
- (void)removeFocusRingFromLayer:(CALayer *)layer;

// ---- Typography -----------------------------------------------------------

- (UIFont *)titleFont;
- (UIFont *)bodyFont;
- (UIFont *)badgeFont;

@end
