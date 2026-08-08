//  ATLGlassOverlayView.m
//  Legacy Apple TV Reborn
//
//  CONFIRMED APIs used:
//    UIView, CALayer, CAGradientLayer — CONFIRMED on target.
//  No BackRow, no blur, no Metal.

#import "ATLGlassOverlayView.h"

@interface ATLGlassOverlayView ()
@property (nonatomic, strong) CAGradientLayer *glassGradient;
@property (nonatomic, strong) CALayer         *borderLayer;
@end

@implementation ATLGlassOverlayView

- (instancetype)initWithFrame:(CGRect)frame config:(ATLThemeConfig *)config {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        [self _buildLayers];
        [self applyConfig:config];
    }
    return self;
}

- (void)_buildLayers {
    // Top-to-bottom white gradient: stronger highlight on upper third.
    _glassGradient = [CAGradientLayer layer];
    _glassGradient.frame = self.bounds;
    // Colors: pure white at top, slightly gray at mid, nearly clear at bottom.
    // No blue component anywhere — white/gray only.
    _glassGradient.colors = @[
        (id)[[UIColor colorWithWhite:1.0f alpha:0.55f] CGColor],  // top sheen
        (id)[[UIColor colorWithWhite:0.9f alpha:0.18f] CGColor],  // upper-mid
        (id)[[UIColor colorWithWhite:0.8f alpha:0.08f] CGColor],  // lower-mid
        (id)[[UIColor colorWithWhite:0.7f alpha:0.04f] CGColor],  // base
    ];
    _glassGradient.locations = @[@0.0f, @0.35f, @0.65f, @1.0f];
    _glassGradient.startPoint = CGPointMake(0.5f, 0.0f);
    _glassGradient.endPoint   = CGPointMake(0.5f, 1.0f);
    [self.layer addSublayer:_glassGradient];

    // Subtle 1px white border to reinforce glass edge.
    _borderLayer = [CALayer layer];
    _borderLayer.frame = self.bounds;
    _borderLayer.backgroundColor = [UIColor clearColor].CGColor;
    _borderLayer.borderWidth = 1.0f;
    _borderLayer.borderColor = [[UIColor colorWithWhite:1.0f alpha:0.30f] CGColor];
    [self.layer addSublayer:_borderLayer];
}

- (void)applyConfig:(ATLThemeConfig *)config {
    if (!config) return;
    CGFloat r = config.tileCornerRadius;
    self.layer.cornerRadius     = r;
    self.layer.masksToBounds    = YES;
    _glassGradient.cornerRadius = r;
    _borderLayer.cornerRadius   = r;
    // Scale overall opacity by the theme's glassAlpha.
    self.alpha = config.glassAlpha;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _glassGradient.frame = self.bounds;
    _borderLayer.frame   = self.bounds;
}

@end
