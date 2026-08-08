#import <Foundation/Foundation.h>

@interface ATLLauncherCoordinator : NSObject

+ (instancetype)sharedCoordinator;

- (void)installIfPossible;
- (void)showLauncher;
- (void)hideLauncher;

@end
