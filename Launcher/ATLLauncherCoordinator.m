#import "ATLLauncherCoordinator.h"
#import "ATLLauncherRootView.h"
#import "ATLLauncherAppGridView.h"
#import "ATLLauncherState.h"
#import "../Utilities/ATLLog.h"
#import <UIKit/UIKit.h>

@interface ATLLauncherCoordinator ()
@property (nonatomic, strong) ATLLauncherRootView    *rootView;
@property (nonatomic, strong) ATLLauncherAppGridView *gridView;
@property (nonatomic, assign) BOOL installed;
@end

@implementation ATLLauncherCoordinator

+ (instancetype)sharedCoordinator {
    static ATLLauncherCoordinator *coord = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ coord = [[ATLLauncherCoordinator alloc] init]; });
    return coord;
}

- (void)installIfPossible {
    if (self.installed) return;

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        ATLLogWarn(@"ATLLauncherCoordinator: no key window yet");
        return;
    }

    CGRect bounds = window.bounds;

    self.rootView = [[ATLLauncherRootView alloc] initWithFrame:bounds];
    self.rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    ATLLauncherState *state = [ATLLauncherState sharedState];
    self.gridView = [[ATLLauncherAppGridView alloc]
        initWithFrame:CGRectMake(0, 40, bounds.size.width, bounds.size.height - 40)
                state:state];
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.rootView addSubview:self.gridView];

    self.rootView.hidden = YES;
    [window addSubview:self.rootView];

    self.installed = YES;
    ATLLogInfo(@"ATLLauncherCoordinator: installed into window");
}

- (void)showLauncher {
    if (!self.installed) {
        [self installIfPossible];
    }
    self.rootView.hidden = NO;
    [ATLLauncherState sharedState].visible = YES;
    [self.gridView reload];
    ATLLogInfo(@"ATLLauncherCoordinator: launcher visible");
}

- (void)hideLauncher {
    self.rootView.hidden = YES;
    [ATLLauncherState sharedState].visible = NO;
    ATLLogInfo(@"ATLLauncherCoordinator: launcher hidden");
}

@end
