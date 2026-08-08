#import <UIKit/UIKit.h>

@class ATLLauncherState;

@interface ATLLauncherAppGridView : UIView

- (instancetype)initWithFrame:(CGRect)frame state:(ATLLauncherState *)state;
- (void)reload;

@end
