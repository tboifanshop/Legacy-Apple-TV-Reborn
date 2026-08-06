#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "../Utilities/ATLLog.h"
#import "../Launcher/ATLLauncherCoordinator.h"
#import "../Diagnostics/ATLRuntimeDiagnostics.h"

static BOOL ATLDidLogSendEventHook = NO;
static BOOL ATLDidAttemptInstall = NO;

static void ATLLogRuntimeEnvironment(void) {
    const char *candidateClasses[] = {
        "BRApplication",
        "BRController",
        "BRMainMenuController",
        "ATVMainMenuController"
    };

    size_t count = sizeof(candidateClasses) / sizeof(candidateClasses[0]);
    for (size_t i = 0; i < count; i++) {
        const char *className = candidateClasses[i];
        Class cls = objc_getClass(className);
        ATLLogInfo(@"Runtime check: class %s = %@", className, cls ? @"FOUND" : @"MISSING");
    }
}

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    if (!ATLDidLogSendEventHook) {
        ATLDidLogSendEventHook = YES;
        ATLLogInfo(@"Hook aktywny: UIApplication sendEvent:");
    }

    if (!ATLDidAttemptInstall) {
        ATLDidAttemptInstall = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [ATLRuntimeDiagnostics runOnceAfterLaunch];
            [[ATLLauncherCoordinator sharedCoordinator] installIfPossible];
            [[ATLLauncherCoordinator sharedCoordinator] showLauncher];
        });
    }

    %orig;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ATLRuntimeDiagnostics runOnceAfterLaunch];
        [[ATLLauncherCoordinator sharedCoordinator] installIfPossible];
        [[ATLLauncherCoordinator sharedCoordinator] showLauncher];
    });
}

%end

%ctor {
    @autoreleasepool {
        ATLLogInfo(@"AppleTVLauncher zaladowany do procesu AppleTV");
        ATLLogRuntimeEnvironment();
    }
}
