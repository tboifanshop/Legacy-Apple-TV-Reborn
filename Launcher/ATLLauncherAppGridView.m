#import "ATLLauncherAppGridView.h"
#import "ATLLauncherState.h"
#import "ATLAppItem.h"
#import "../Theme/ATLThemeEngine.h"
#import "../Utilities/ATLLog.h"

static const CGFloat kATLCellSize   = 120.0f;
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
        ATLThemeEngine *theme = [ATLThemeEngine sharedEngine];
        [theme styleCardView:self cornerRadius:14.0f];

        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 12, 96, 72)];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconView];

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 88, frame.size.width - 8, 20)];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.textColor     = ATLColorTextPrimary();
        _nameLabel.font          = [theme badgeFont];
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_nameLabel];

        [theme applyShimmerToLayer:self.layer];
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

    CGFloat x = kATLCellSpacing;
    CGFloat y = kATLCellSpacing;
    CGFloat rowHeight = kATLCellSize + kATLCellSpacing;
    CGFloat maxX = self.bounds.size.width - kATLCellSpacing;

    for (ATLAppItem *item in visible) {
        if (x + kATLCellSize > maxX) {
            x  = kATLCellSpacing;
            y += rowHeight;
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
