#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ATLWallpaperType) {
    ATLWallpaperTypeStatic,
    ATLWallpaperTypeAnimated,
};

@interface ATLWallpaperDescriptor : NSObject

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) ATLWallpaperType type;

+ (instancetype)descriptorWithPath:(NSString *)path type:(ATLWallpaperType)type;

@end
