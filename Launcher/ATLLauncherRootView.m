#import "ATLLauncherRootView.h"
#import "../Theme/ATLThemeEngine.h"
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
    ATLThemeEngine *theme = [ATLThemeEngine sharedEngine];
    [theme styleRootView:self];

    // Minimal status bar label
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, 300, 24)];
    _statusLabel.text      = @"Legacy Apple TV Reborn";
    _statusLabel.textColor = ATLColorTextSecondary();
    _statusLabel.font      = [theme bodyFont];
    [self addSubview:_statusLabel];
}

- (void)layoutForBounds:(CGRect)bounds {
    self.frame = bounds;
    _statusLabel.frame = CGRectMake(16, 8, bounds.size.width - 32, 24);

    // Refresh gradient size
    ATLThemeEngine *theme = [ATLThemeEngine sharedEngine];
    [theme applyBackgroundGradientToLayer:self.layer];
}

- (void)applyTheme {
    ATLThemeEngine *theme = [ATLThemeEngine sharedEngine];
    [theme styleRootView:self];
    ATLLogInfo(@"ATLLauncherRootView: theme applied");
}

@end
