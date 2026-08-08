//  ATLThemeEngine.m
//  Legacy Apple TV Reborn
//  Frutiger Aero theme engine — production, no diagnostics.

#import "ATLThemeEngine.h"
#import "../Utilities/ATLLog.h"
#import <objc/runtime.h>

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------
UIColor *ATLColorBackground(void) {
    return [UIColor colorWithRed:0.04f green:0.10f blue:0.22f alpha:1.0f];
}
UIColor *ATLColorSkyGradientTop(void) {
    return [UIColor colorWithRed:0.38f green:0.66f blue:0.90f alpha:1.0f];
}
UIColor *ATLColorSkyGradientBottom(void) {
    return [UIColor colorWithRed:0.08f green:0.26f blue:0.52f alpha:1.0f];
}
UIColor *ATLColorAqua(void) {
    return [UIColor colorWithRed:0.18f green:0.76f blue:0.90f alpha:1.0f];
}
UIColor *ATLColorGlossTint(void) {
    return [UIColor colorWithWhite:1.0f alpha:0.30f];
}
UIColor *ATLColorTextPrimary(void) {
    return [UIColor colorWithWhite:1.0f alpha:0.95f];
}
UIColor *ATLColorTextSecondary(void) {
    return [UIColor colorWithRed:0.70f green:0.82f blue:0.95f alpha:1.0f];
}
UIColor *ATLColorFocusRing(void) {
    return [UIColor colorWithRed:0.55f green:0.92f blue:1.00f alpha:1.0f];
}

// ---------------------------------------------------------------------------
// Private key for associated shimmer layers
// ---------------------------------------------------------------------------
static const void *kATLShimmerLayerKey = &kATLShimmerLayerKey;
static const void *kATLGlossLayerKey   = &kATLGlossLayerKey;
static const void *kATLGradLayerKey    = &kATLGradLayerKey;
static const void *kATLFocusLayerKey   = &kATLFocusLayerKey;
static const void *kATLCardBgLayerKey  = &kATLCardBgLayerKey;

// ---------------------------------------------------------------------------
@implementation ATLThemeEngine

+ (instancetype)sharedEngine {
    static ATLThemeEngine *engine = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        engine = [[ATLThemeEngine alloc] init];
        ATLLogInfo(@"ATLThemeEngine initialised (Frutiger Aero)");
    });
    return engine;
}

// ---------------------------------------------------------------------------
// Background gradient
// ---------------------------------------------------------------------------
- (void)applyBackgroundGradientToLayer:(CALayer *)layer {
    if (!layer) return;

    CAGradientLayer *existing = objc_getAssociatedObject(layer, kATLGradLayerKey);
    if (existing) {
        existing.frame = layer.bounds;
        return;
    }

    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = layer.bounds;
    grad.colors = @[
        (id)[ATLColorSkyGradientTop()    CGColor],
        (id)[ATLColorSkyGradientBottom() CGColor],
    ];
    grad.locations = @[@0.0f, @1.0f];
    grad.startPoint = CGPointMake(0.5f, 0.0f);
    grad.endPoint   = CGPointMake(0.5f, 1.0f);
    [layer insertSublayer:grad atIndex:0];
    objc_setAssociatedObject(layer, kATLGradLayerKey, grad, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// ---------------------------------------------------------------------------
// Gloss overlay (top-half white sheen)
// ---------------------------------------------------------------------------
- (void)applyGlossOverlayToLayer:(CALayer *)layer {
    if (!layer) return;

    CAGradientLayer *existing = objc_getAssociatedObject(layer, kATLGlossLayerKey);
    if (existing) return;

    CGFloat halfH = layer.bounds.size.height * 0.5f;
    CAGradientLayer *gloss = [CAGradientLayer layer];
    gloss.frame = CGRectMake(0, 0, layer.bounds.size.width, halfH);
    gloss.colors = @[
        (id)[[UIColor colorWithWhite:1.0f alpha:0.40f] CGColor],
        (id)[[UIColor colorWithWhite:1.0f alpha:0.05f] CGColor],
    ];
    gloss.locations = @[@0.0f, @1.0f];
    gloss.startPoint = CGPointMake(0.5f, 0.0f);
    gloss.endPoint   = CGPointMake(0.5f, 1.0f);
    [layer addSublayer:gloss];
    objc_setAssociatedObject(layer, kATLGlossLayerKey, gloss, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// ---------------------------------------------------------------------------
// Card style
// ---------------------------------------------------------------------------
- (void)applyCardStyleToLayer:(CALayer *)layer cornerRadius:(CGFloat)radius {
    if (!layer) return;

    layer.cornerRadius  = radius;
    layer.masksToBounds = YES;
    layer.borderWidth   = 1.0f;
    layer.borderColor   = [[UIColor colorWithWhite:1.0f alpha:0.25f] CGColor];

    CAGradientLayer *existing = objc_getAssociatedObject(layer, kATLCardBgLayerKey);
    if (!existing) {
        CAGradientLayer *bg = [CAGradientLayer layer];
        bg.frame = layer.bounds;
        bg.cornerRadius = radius;
        bg.colors = @[
            (id)[[UIColor colorWithWhite:1.0f alpha:0.18f] CGColor],
            (id)[[UIColor colorWithWhite:1.0f alpha:0.06f] CGColor],
        ];
        bg.locations  = @[@0.0f, @1.0f];
        bg.startPoint = CGPointMake(0.5f, 0.0f);
        bg.endPoint   = CGPointMake(0.5f, 1.0f);
        [layer insertSublayer:bg atIndex:0];
        objc_setAssociatedObject(layer, kATLCardBgLayerKey, bg, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [self applyGlossOverlayToLayer:layer];
}

// ---------------------------------------------------------------------------
// Shimmer ("living highlight") animation
// ---------------------------------------------------------------------------
- (void)applyShimmerToLayer:(CALayer *)layer {
    if (!layer) return;

    CALayer *existing = objc_getAssociatedObject(layer, kATLShimmerLayerKey);
    if (existing) return;

    CAGradientLayer *shimmer = [CAGradientLayer layer];
    CGFloat w = layer.bounds.size.width;
    CGFloat h = layer.bounds.size.height;
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
    anim.fromValue = @(-w);
    anim.toValue   = @(w * 2.0f);
    anim.duration  = 2.4;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.repeatCount    = HUGE_VALF;
    anim.autoreverses   = NO;
    [shimmer addAnimation:anim forKey:@"atlShimmer"];
}

// ---------------------------------------------------------------------------
// Focus ring
// ---------------------------------------------------------------------------
- (void)applyFocusRingToLayer:(CALayer *)layer {
    if (!layer) return;
    [self removeFocusRingFromLayer:layer];

    CALayer *ring = [CALayer layer];
    ring.frame = CGRectInset(layer.bounds, -3.0f, -3.0f);
    ring.borderColor  = [ATLColorFocusRing() CGColor];
    ring.borderWidth  = 3.0f;
    ring.cornerRadius = layer.cornerRadius + 3.0f;
    ring.opacity      = 0.0f;
    [layer addSublayer:ring];
    objc_setAssociatedObject(layer, kATLFocusLayerKey, ring, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.toValue        = @1.0f;
    fade.duration       = 0.18;
    fade.fillMode       = kCAFillModeForwards;
    fade.removedOnCompletion = NO;
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
// View helpers
// ---------------------------------------------------------------------------
- (void)styleRootView:(UIView *)view {
    if (!view) return;
    view.backgroundColor = ATLColorBackground();
    [self applyBackgroundGradientToLayer:view.layer];
}

- (void)styleCardView:(UIView *)view cornerRadius:(CGFloat)radius {
    if (!view) return;
    view.backgroundColor = [UIColor clearColor];
    [self applyCardStyleToLayer:view.layer cornerRadius:radius];
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------
- (UIFont *)titleFont {
    return [UIFont boldSystemFontOfSize:18.0f];
}

- (UIFont *)bodyFont {
    return [UIFont systemFontOfSize:14.0f];
}

- (UIFont *)badgeFont {
    return [UIFont boldSystemFontOfSize:11.0f];
}

@end
