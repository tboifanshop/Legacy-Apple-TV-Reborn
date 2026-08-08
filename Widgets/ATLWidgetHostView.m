#import "ATLWidgetHostView.h"
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
        wv.layer.cornerRadius  = 10.0f;
        wv.layer.masksToBounds = YES;
        [self addSubview:wv];
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
