#import "ATLAppItem.h"

@implementation ATLAppItem

- (instancetype)initWithIdentifier:(NSString *)identifier displayName:(NSString *)name {
    self = [super init];
    if (self) {
        _identifier  = [identifier copy];
        _displayName = [name copy];
        _isHidden    = NO;
    }
    return self;
}

@end
