#import "ATLLauncherRootView.h"
#import "../Theme/ATLThemeManager.h"
#import "../Theme/ATLThemeConfig.h"
#import "../Utilities/ATLLog.h"

@interface ATLLauncherRootView ()
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ATLLauncherRootView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _buildSubviews];
    }
    return self;
}

- (void)_buildSubviews {
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.72f];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, 300, 24)];
    _statusLabel.text      = @"Legacy Apple TV Reborn";
    _statusLabel.textColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    _statusLabel.font      = [UIFont systemFontOfSize:14.0f];
    [self addSubview:_statusLabel];
}

- (void)layoutForBounds:(CGRect)bounds {
    self.frame = bounds;
    _statusLabel.frame = CGRectMake(16, 8, bounds.size.width - 32, 24);
}

- (void)applyTheme {
    ATLThemeConfig *cfg = [ATLThemeManager sharedManager].activeTheme;
    if (cfg.isBypassMode) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
    }
    ATLLogInfo(@"ATLLauncherRootView: theme applied (%@)", cfg.displayName);
}

@end
