#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ATLAppItem : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, assign) BOOL isHidden;

- (instancetype)initWithIdentifier:(NSString *)identifier displayName:(NSString *)name;

@end
