#import <UIKit/UIKit.h>

#import "../Utilities/ATLLog.h"
#import "../Launcher/ATLLauncherCoordinator.h"

static BOOL ATLDidAttemptInstall = NO;

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    if (!ATLDidAttemptInstall) {
        ATLDidAttemptInstall = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ATLLauncherCoordinator sharedCoordinator] installIfPossible];
            [[ATLLauncherCoordinator sharedCoordinator] showLauncher];
        });
    }
    %orig;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ATLLauncherCoordinator sharedCoordinator] installIfPossible];
        [[ATLLauncherCoordinator sharedCoordinator] showLauncher];
    });
}

%end

%ctor {
    @autoreleasepool {
        ATLLogInfo(@"AppleTVLauncher loaded into AppleTV process");
    }
}
