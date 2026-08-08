//  ATLThemeEngine.h
//  Legacy Apple TV Reborn
//  Frutiger Aero theme engine for AppleTV3,2 (armv7 / iOS 8.4.4)

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// ---------------------------------------------------------------------------
// Colour palette — Frutiger Aero (sky blues, aqua accents, white gloss)
// ---------------------------------------------------------------------------
extern UIColor *ATLColorBackground(void);       // deep midnight-blue sky
extern UIColor *ATLColorSkyGradientTop(void);   // light sky blue highlight
extern UIColor *ATLColorSkyGradientBottom(void);// darker teal-blue base
extern UIColor *ATLColorAqua(void);             // aqua / water accent
extern UIColor *ATLColorGlossTint(void);        // translucent white gloss
extern UIColor *ATLColorTextPrimary(void);      // bright white text
extern UIColor *ATLColorTextSecondary(void);    // soft blue-grey text
extern UIColor *ATLColorFocusRing(void);        // focus ring: pale cyan

// ---------------------------------------------------------------------------
// ATLThemeEngine
// Singleton theme engine.  All UI components call into this to apply the
// Frutiger Aero look rather than hard-coding colours / radii / fonts.
// ---------------------------------------------------------------------------

@interface ATLThemeEngine : NSObject

+ (instancetype)sharedEngine;

// ---- Layer helpers --------------------------------------------------------

/// Adds a two-stop sky-gradient to the given layer (resizes on bounds change).
- (void)applyBackgroundGradientToLayer:(CALayer *)layer;

/// Applies a gloss overlay (white → clear top-half sheen) on top of a layer.
- (void)applyGlossOverlayToLayer:(CALayer *)layer;

/// Applies aqua-glass card styling: rounded corners, subtle border, gloss.
- (void)applyCardStyleToLayer:(CALayer *)layer cornerRadius:(CGFloat)radius;

/// Adds an animated shimmer (Aero "living" highlight) to a layer.
- (void)applyShimmerToLayer:(CALayer *)layer;

/// Draws the Aero focus-ring border on the supplied layer.
- (void)applyFocusRingToLayer:(CALayer *)layer;

/// Removes the focus-ring from the supplied layer.
- (void)removeFocusRingFromLayer:(CALayer *)layer;

// ---- View helpers ---------------------------------------------------------

/// Styles a view's background as the Aero sky gradient.
- (void)styleRootView:(UIView *)view;

/// Styles a cell / card view with glass-card appearance.
- (void)styleCardView:(UIView *)view cornerRadius:(CGFloat)radius;

// ---- Typography -----------------------------------------------------------

- (UIFont *)titleFont;
- (UIFont *)bodyFont;
- (UIFont *)badgeFont;

@end
