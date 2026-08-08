#import <Foundation/Foundation.h>
#import "ATLAppItem.h"

@interface ATLLauncherState : NSObject

@property (nonatomic, strong, readonly) NSArray<ATLAppItem *> *apps;
@property (nonatomic, assign, getter=isVisible) BOOL visible;

+ (instancetype)sharedState;

- (void)addApp:(ATLAppItem *)app;
- (void)removeAppWithIdentifier:(NSString *)identifier;
- (void)setHidden:(BOOL)hidden forIdentifier:(NSString *)identifier;

@end
