#import "ATLLauncherState.h"

@interface ATLLauncherState ()
@property (nonatomic, strong) NSMutableArray<ATLAppItem *> *mutableApps;
@end

@implementation ATLLauncherState

+ (instancetype)sharedState {
    static ATLLauncherState *state = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ state = [[ATLLauncherState alloc] init]; });
    return state;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableApps = [NSMutableArray array];
        _visible     = NO;
    }
    return self;
}

- (NSArray<ATLAppItem *> *)apps {
    return [self.mutableApps copy];
}

- (void)addApp:(ATLAppItem *)app {
    if (!app) return;
    [self.mutableApps addObject:app];
}

- (void)removeAppWithIdentifier:(NSString *)identifier {
    NSUInteger idx = [self.mutableApps indexOfObjectPassingTest:^BOOL(ATLAppItem *obj, NSUInteger i, BOOL *stop) {
        return [obj.identifier isEqualToString:identifier];
    }];
    if (idx != NSNotFound) {
        [self.mutableApps removeObjectAtIndex:idx];
    }
}

- (void)setHidden:(BOOL)hidden forIdentifier:(NSString *)identifier {
    for (ATLAppItem *item in self.mutableApps) {
        if ([item.identifier isEqualToString:identifier]) {
            item.isHidden = hidden;
            break;
        }
    }
}

@end
