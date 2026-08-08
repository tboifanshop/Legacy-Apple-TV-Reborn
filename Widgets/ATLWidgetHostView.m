#import "ATLWidgetHostView.h"
#import "../Theme/ATLThemeEngine.h"
#import "../Utilities/ATLLog.h"

@interface ATLWidgetHostView ()
@property (nonatomic, strong) NSMutableArray<id<ATLWidget>> *widgets;
@end

@implementation ATLWidgetHostView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _widgets = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)registerWidget:(id<ATLWidget>)widget {
    if (!widget) return;
    [self.widgets addObject:widget];
    UIView *wv = [widget widgetView];
    if (wv) {
        [self addSubview:wv];
        [[ATLThemeEngine sharedEngine] styleCardView:wv cornerRadius:10.0f];
    }
    if ([widget respondsToSelector:@selector(widgetDidBecomeActive)]) {
        [widget widgetDidBecomeActive];
    }
    ATLLogInfo(@"ATLWidgetHostView: registered widget %@", [widget widgetIdentifier]);
}

- (void)unregisterWidgetWithIdentifier:(NSString *)identifier {
    id<ATLWidget> found = nil;
    for (id<ATLWidget> w in self.widgets) {
        if ([[w widgetIdentifier] isEqualToString:identifier]) { found = w; break; }
    }
    if (!found) return;
    if ([found respondsToSelector:@selector(widgetWillResignActive)]) {
        [found widgetWillResignActive];
    }
    [[found widgetView] removeFromSuperview];
    [self.widgets removeObject:found];
    ATLLogInfo(@"ATLWidgetHostView: unregistered widget %@", identifier);
}

@end
