#import "ATLAnimationCoordinator.h"
#import <QuartzCore/QuartzCore.h>
#import "../Theme/ATLThemeEngine.h"
#import "../Utilities/ATLLog.h"

@implementation ATLAnimationCoordinator

+ (instancetype)sharedCoordinator {
    static ATLAnimationCoordinator *coord = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ coord = [[ATLAnimationCoordinator alloc] init]; });
    return coord;
}

- (void)animateFocusOnView:(UIView *)view {
    if (!view) return;
    UIColor *ringColor = [UIColor colorWithWhite:1.0f alpha:0.8f];
    [[ATLThemeEngine sharedEngine] applyFocusRingToLayer:view.layer color:ringColor];
    [UIView animateWithDuration:0.18 animations:^{
        view.transform = CGAffineTransformMakeScale(1.06f, 1.06f);
    }];
}

- (void)animateUnfocusOnView:(UIView *)view {
    if (!view) return;
    [[ATLThemeEngine sharedEngine] removeFocusRingFromLayer:view.layer];
    [UIView animateWithDuration:0.18 animations:^{
        view.transform = CGAffineTransformIdentity;
    }];
}

- (void)animateTransitionToView:(UIView *)toView
                       fromView:(UIView *)fromView
                     completion:(void(^)(void))completion {
    if (!toView) { if (completion) completion(); return; }
    toView.alpha = 0.0f;
    [UIView animateWithDuration:0.30
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        if (fromView) fromView.alpha = 0.0f;
        toView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if (completion) completion();
        ATLLogInfo(@"ATLAnimationCoordinator: transition complete");
    }];
}

@end
