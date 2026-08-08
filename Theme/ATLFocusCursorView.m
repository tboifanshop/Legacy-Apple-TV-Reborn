//  ATLFocusCursorView.m
//  Legacy Apple TV Reborn
//
//  CONFIRMED APIs used: UIView, UIImageView, UIWindow, CABasicAnimation.
//  Theme resource path via ATLThemeManager.

#import "ATLFocusCursorView.h"
#import "ATLThemeManager.h"
#import "../Utilities/ATLLog.h"

// Cursor image size in points.
static const CGFloat kATLCursorWidth  = 32.0f;
static const CGFloat kATLCursorHeight = 40.0f;
// Overlap into the tile (positive = inside corner).
static const CGFloat kATLCursorInset  = 4.0f;
// Animation duration for focus movement.
static const NSTimeInterval kATLCursorMoveDuration = 0.22;

@interface ATLFocusCursorView ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL        suppressed;
@end

@implementation ATLFocusCursorView

+ (instancetype)sharedCursor {
    static ATLFocusCursorView *cursor = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cursor = [[ATLFocusCursorView alloc] _initCursor];
    });
    return cursor;
}

- (instancetype)_initCursor {
    // Start with zero frame; will be positioned on first focus change.
    self = [super initWithFrame:CGRectMake(0, 0, kATLCursorWidth, kATLCursorHeight)];
    if (self) {
        self.backgroundColor      = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.hidden = YES;

        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_imageView];

        [self _loadCursorImage];

        // Listen for theme changes to reload cursor image.
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(_themeChanged:)
                   name:ATLThemeManagerDidChangeThemeNotification
                 object:nil];
    }
    return self;
}

- (void)_loadCursorImage {
    NSString *path = [[ATLThemeManager sharedManager] pathForThemeResource:@"FrutigerAeroCursor.png"];
    UIImage *img   = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (!img) {
        // Fallback: draw a simple white arrow shape using CoreGraphics.
        img = [self _renderFallbackCursorImage];
    }
    _imageView.image = img;
}

- (void)_themeChanged:(NSNotification *)note {
    [self _loadCursorImage];
}

// ---------------------------------------------------------------------------
// Position
// ---------------------------------------------------------------------------
- (void)moveToBRCornerOfView:(UIView *)focusedView {
    if (_suppressed || !focusedView) {
        [self hide];
        return;
    }

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) { [self hide]; return; }

    // Add cursor to the window if not already there.
    if (self.superview != window) {
        [window addSubview:self];
    }
    [window bringSubviewToFront:self];

    // Convert focused view's bottom-right corner to window coordinates.
    CGRect rect    = [focusedView convertRect:focusedView.bounds toView:window];
    CGFloat destX  = CGRectGetMaxX(rect) - kATLCursorWidth  + kATLCursorInset;
    CGFloat destY  = CGRectGetMaxY(rect) - kATLCursorHeight + kATLCursorInset;

    CGRect newFrame = CGRectMake(destX, destY, kATLCursorWidth, kATLCursorHeight);

    if (self.hidden) {
        // First appearance — no animation, just snap into place.
        self.frame  = newFrame;
        self.hidden = NO;
        self.alpha  = 0.0f;
        [UIView animateWithDuration:0.15 animations:^{ self.alpha = 1.0f; }];
    } else {
        [UIView animateWithDuration:kATLCursorMoveDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ self.frame = newFrame; }
                         completion:nil];
    }
}

- (void)hide {
    if (self.hidden) return;
    [UIView animateWithDuration:0.12 animations:^{ self.alpha = 0.0f; }
                     completion:^(BOOL f) { self.hidden = YES; self.alpha = 1.0f; }];
}

- (void)show {
    _suppressed = NO;
    // Cursor will reappear on next focusedView update.
}

// ---------------------------------------------------------------------------
// Fallback cursor drawing — white arrow, no external asset needed.
// CONFIRMED: UIGraphicsBeginImageContextWithOptions / CoreGraphics available.
// ---------------------------------------------------------------------------
- (UIImage *)_renderFallbackCursorImage {
    CGSize size = CGSizeMake(kATLCursorWidth, kATLCursorHeight);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Simple arrow polygon (pointing up-left, tip at 0,0).
    CGContextSetFillColorWithColor(ctx, [[UIColor colorWithWhite:1.0f alpha:0.90f] CGColor]);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor colorWithWhite:0.2f alpha:0.80f] CGColor]);
    CGContextSetLineWidth(ctx, 1.5f);

    CGContextMoveToPoint(ctx,    2,  2);
    CGContextAddLineToPoint(ctx, 2, 28);
    CGContextAddLineToPoint(ctx, 10, 22);
    CGContextAddLineToPoint(ctx, 14, 32);
    CGContextAddLineToPoint(ctx, 18, 30);
    CGContextAddLineToPoint(ctx, 14, 20);
    CGContextAddLineToPoint(ctx, 22, 20);
    CGContextClosePath(ctx);

    CGContextDrawPath(ctx, kCGPathFillStroke);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
