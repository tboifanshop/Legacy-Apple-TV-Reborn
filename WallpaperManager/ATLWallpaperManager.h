#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ATLWallpaperDescriptor.h"

@interface ATLWallpaperManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) ATLWallpaperDescriptor *currentDescriptor;

- (void)applyWallpaper:(ATLWallpaperDescriptor *)descriptor toView:(UIView *)view;
- (void)clearWallpaperFromView:(UIView *)view;

@end
