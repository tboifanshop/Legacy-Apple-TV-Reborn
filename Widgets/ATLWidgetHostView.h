#import <UIKit/UIKit.h>

@protocol ATLWidget <NSObject>
@required
- (UIView *)widgetView;
- (NSString *)widgetIdentifier;
@optional
- (void)widgetDidBecomeActive;
- (void)widgetWillResignActive;
@end

@interface ATLWidgetHostView : UIView

- (void)registerWidget:(id<ATLWidget>)widget;
- (void)unregisterWidgetWithIdentifier:(NSString *)identifier;

@end
