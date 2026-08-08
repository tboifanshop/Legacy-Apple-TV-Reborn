#import "ATLWallpaperDescriptor.h"

@implementation ATLWallpaperDescriptor

+ (instancetype)descriptorWithPath:(NSString *)path type:(ATLWallpaperType)type {
    ATLWallpaperDescriptor *d = [[ATLWallpaperDescriptor alloc] init];
    d.filePath = path;
    d.type     = type;
    return d;
}

@end
