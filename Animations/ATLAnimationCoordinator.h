#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ATLAnimationCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (void)animateFocusOnView:(UIView *)view;
- (void)animateUnfocusOnView:(UIView *)view;
- (void)animateTransitionToView:(UIView *)toView fromView:(UIView *)fromView completion:(void(^)(void))completion;

@end
