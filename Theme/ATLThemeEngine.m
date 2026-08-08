//  ATLThemeEngine.m
//  Legacy Apple TV Reborn
//
//  Low-level CALayer helper utilities.
//  No theme palette here — palette decisions belong in ATLThemeConfig.

#import "ATLThemeEngine.h"
#import "../Utilities/ATLLog.h"
#import <objc/runtime.h>

static const void *kATLShimmerLayerKey = &kATLShimmerLayerKey;
static const void *kATLFocusLayerKey   = &kATLFocusLayerKey;

@implementation ATLThemeEngine

+ (instancetype)sharedEngine {
    static ATLThemeEngine *engine = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ engine = [[ATLThemeEngine alloc] init]; });
    return engine;
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------
- (void)applyShimmerToLayer:(CALayer *)layer {
    if (!layer) return;
    CALayer *existing = objc_getAssociatedObject(layer, kATLShimmerLayerKey);
    if (existing) return;

    CGFloat w = layer.bounds.size.width;
    CGFloat h = layer.bounds.size.height;
    CAGradientLayer *shimmer = [CAGradientLayer layer];
    shimmer.frame = CGRectMake(-w, 0, w * 3.0f, h);
    shimmer.colors = @[
        (id)[[UIColor colorWithWhite:1.0f alpha:0.00f] CGColor],
        (id)[[UIColor colorWithWhite:1.0f alpha:0.22f] CGColor],
        (id)[[UIColor colorWithWhite:1.0f alpha:0.00f] CGColor],
    ];
    shimmer.locations  = @[@0.3f, @0.5f, @0.7f];
    shimmer.startPoint = CGPointMake(0.0f, 0.5f);
    shimmer.endPoint   = CGPointMake(1.0f, 0.5f);
    [layer addSublayer:shimmer];
    objc_setAssociatedObject(layer, kATLShimmerLayerKey, shimmer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position.x"];
    anim.fromValue      = @(-w);
    anim.toValue        = @(w * 2.0f);
    anim.duration       = 2.4;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.repeatCount    = HUGE_VALF;
    [shimmer addAnimation:anim forKey:@"atlShimmer"];
}

// ---------------------------------------------------------------------------
// Focus ring
// ---------------------------------------------------------------------------
- (void)applyFocusRingToLayer:(CALayer *)layer color:(UIColor *)color {
    if (!layer || !color) return;
    [self removeFocusRingFromLayer:layer];

    CALayer *ring = [CALayer layer];
    ring.frame        = CGRectInset(layer.bounds, -3.0f, -3.0f);
    ring.borderColor  = [color CGColor];
    ring.borderWidth  = 3.0f;
    ring.cornerRadius = layer.cornerRadius + 3.0f;
    ring.opacity      = 0.0f;
    [layer addSublayer:ring];
    objc_setAssociatedObject(layer, kATLFocusLayerKey, ring, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.toValue               = @1.0f;
    fade.duration              = 0.18;
    fade.fillMode              = kCAFillModeForwards;
    fade.removedOnCompletion   = NO;
    [ring addAnimation:fade forKey:@"atlFocusFade"];
    ring.opacity = 1.0f;
}

- (void)removeFocusRingFromLayer:(CALayer *)layer {
    if (!layer) return;
    CALayer *ring = objc_getAssociatedObject(layer, kATLFocusLayerKey);
    if (ring) {
        [ring removeFromSuperlayer];
        objc_setAssociatedObject(layer, kATLFocusLayerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------
- (UIFont *)titleFont { return [UIFont boldSystemFontOfSize:18.0f]; }
- (UIFont *)bodyFont  { return [UIFont systemFontOfSize:14.0f]; }
- (UIFont *)badgeFont { return [UIFont boldSystemFontOfSize:11.0f]; }

@end
