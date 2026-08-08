//  ATLGlassOverlayView.h
//  Legacy Apple TV Reborn
//
//  Frutiger Aero white/gray semi-transparent glass overlay for a single
//  standard Apple TV app tile (288 × 154 pt).
//
//  Design rules (from spec):
//    - No blue tint.  Glass color = white/gray + alpha only.
//    - Corner radius matches ATLThemeConfig.tileCornerRadius.
//    - Top highlight (lighter white sheen on upper third).
//    - Underlying icon/artwork must remain clearly visible.
//    - No realtime blur (A5 limitation) — pure CALayer compositing.
//    - Use prerendered PNG assets where possible.
//
//  API note: CONFIRMED — UIView, CALayer, CAGradientLayer exist on target.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ATLThemeConfig.h"

@interface ATLGlassOverlayView : UIView

/// Create a glass overlay sized to `frame` with the given theme config.
- (instancetype)initWithFrame:(CGRect)frame config:(ATLThemeConfig *)config;

/// Update corner radius and alpha if the theme changes.
- (void)applyConfig:(ATLThemeConfig *)config;

@end
