#import "ATLLauncherAppGridView.h"
#import "ATLLauncherState.h"
#import "ATLAppItem.h"
#import "../Theme/ATLThemeEngine.h"
#import "../Theme/ATLGlassOverlayView.h"
#import "../Theme/ATLThemeManager.h"
#import "../Utilities/ATLLog.h"

static const CGFloat kATLCellSize    = 120.0f;
static const CGFloat kATLCellSpacing = 16.0f;

@interface ATLAppCellView : UIView
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel     *nameLabel;
- (void)configureWithItem:(ATLAppItem *)item;
@end

@implementation ATLAppCellView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius  = 10.0f;
        self.layer.masksToBounds = YES;
        self.backgroundColor     = [UIColor colorWithWhite:0.1f alpha:0.6f];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 12, 96, 72)];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconView];

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 88, frame.size.width - 8, 20)];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor     = [UIColor whiteColor];
        _nameLabel.font          = [[ATLThemeEngine sharedEngine] badgeFont];
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_nameLabel];

        // Add glass overlay via ATLGlassOverlayView
        ATLThemeConfig *cfg = [ATLThemeManager sharedManager].activeTheme;
        if (!cfg.isBypassMode && cfg.glassAlpha > 0.01f) {
            ATLGlassOverlayView *glass = [[ATLGlassOverlayView alloc] initWithFrame:self.bounds config:cfg];
            glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            glass.userInteractionEnabled = NO;
            [self addSubview:glass];
        }
    }
    return self;
}

- (void)configureWithItem:(ATLAppItem *)item {
    self.nameLabel.text = item.displayName;
    self.iconView.image = item.icon;
}

@end

// ---------------------------------------------------------------------------
@interface ATLLauncherAppGridView ()
@property (nonatomic, weak)   ATLLauncherState *state;
@property (nonatomic, strong) NSMutableArray<ATLAppCellView *> *cellViews;
@end

@implementation ATLLauncherAppGridView

- (instancetype)initWithFrame:(CGRect)frame state:(ATLLauncherState *)state {
    self = [super initWithFrame:frame];
    if (self) {
        _state     = state;
        _cellViews = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)reload {
    for (ATLAppCellView *cell in self.cellViews) {
        [cell removeFromSuperview];
    }
    [self.cellViews removeAllObjects];

    NSArray<ATLAppItem *> *visible = [self.state.apps filteredArrayUsingPredicate:
        [NSPredicate predicateWithFormat:@"isHidden == NO"]];

    CGFloat x    = kATLCellSpacing;
    CGFloat y    = kATLCellSpacing;
    CGFloat rowH = kATLCellSize + kATLCellSpacing;
    CGFloat maxX = self.bounds.size.width - kATLCellSpacing;

    for (ATLAppItem *item in visible) {
        if (x + kATLCellSize > maxX) {
            x  = kATLCellSpacing;
            y += rowH;
        }
        ATLAppCellView *cell = [[ATLAppCellView alloc]
            initWithFrame:CGRectMake(x, y, kATLCellSize, kATLCellSize)];
        [cell configureWithItem:item];
        [self addSubview:cell];
        [self.cellViews addObject:cell];
        x += kATLCellSize + kATLCellSpacing;
    }

    ATLLogInfo(@"ATLLauncherAppGridView: reloaded %lu cells", (unsigned long)visible.count);
}

@end
