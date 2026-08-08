#import "ATLWallpaperManager.h"
#import "../Utilities/ATLLog.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

static const void *kATLWallpaperImageViewKey  = &kATLWallpaperImageViewKey;
static const void *kATLWallpaperPlayerViewKey = &kATLWallpaperPlayerViewKey;

@interface ATLWallpaperManager ()
@property (nonatomic, strong) ATLWallpaperDescriptor *currentDescriptor;
@property (nonatomic, strong) AVPlayer *videoPlayer;
@end

@implementation ATLWallpaperManager

+ (instancetype)sharedManager {
    static ATLWallpaperManager *mgr = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ mgr = [[ATLWallpaperManager alloc] init]; });
    return mgr;
}

- (void)applyWallpaper:(ATLWallpaperDescriptor *)descriptor toView:(UIView *)view {
    if (!descriptor || !view) return;
    [self clearWallpaperFromView:view];
    _currentDescriptor = descriptor;

    if (descriptor.type == ATLWallpaperTypeStatic) {
        UIImage *img = [UIImage imageWithContentsOfFile:descriptor.filePath];
        if (!img) { ATLLogWarn(@"ATLWallpaperManager: image not found at %@", descriptor.filePath); return; }
        UIImageView *iv = [[UIImageView alloc] initWithFrame:view.bounds];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        iv.image = img;
        [view insertSubview:iv atIndex:0];
        objc_setAssociatedObject(view, kATLWallpaperImageViewKey, iv, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ATLLogInfo(@"ATLWallpaperManager: static wallpaper applied");
    } else {
        NSURL *url = [NSURL fileURLWithPath:descriptor.filePath];
        _videoPlayer = [AVPlayer playerWithURL:url];
        _videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_videoDidEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:_videoPlayer.currentItem];
        AVPlayerLayer *pl = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
        pl.frame = view.bounds;
        pl.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [view.layer insertSublayer:pl atIndex:0];
        objc_setAssociatedObject(view, kATLWallpaperPlayerViewKey, pl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_videoPlayer play];
        ATLLogInfo(@"ATLWallpaperManager: animated wallpaper applied");
    }
}

- (void)clearWallpaperFromView:(UIView *)view {
    if (!view) return;
    UIImageView *iv = objc_getAssociatedObject(view, kATLWallpaperImageViewKey);
    if (iv) { [iv removeFromSuperview]; objc_setAssociatedObject(view, kATLWallpaperImageViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    AVPlayerLayer *pl = objc_getAssociatedObject(view, kATLWallpaperPlayerViewKey);
    if (pl) { [pl removeFromSuperlayer]; objc_setAssociatedObject(view, kATLWallpaperPlayerViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
    if (_videoPlayer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_videoPlayer.currentItem];
        [_videoPlayer pause];
        _videoPlayer = nil;
    }
    _currentDescriptor = nil;
}

- (void)_videoDidEnd:(NSNotification *)note {
    [_videoPlayer seekToTime:kCMTimeZero];
    [_videoPlayer play];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
