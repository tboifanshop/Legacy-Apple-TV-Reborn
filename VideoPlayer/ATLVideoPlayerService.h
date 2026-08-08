#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, ATLVideoPlayerState) {
    ATLVideoPlayerStateStopped,
    ATLVideoPlayerStatePlaying,
    ATLVideoPlayerStatePaused,
};

@interface ATLVideoPlayerService : NSObject

+ (instancetype)sharedService;

@property (nonatomic, assign, readonly) ATLVideoPlayerState state;

- (void)loadURL:(NSURL *)url;
- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToSeconds:(NSTimeInterval)seconds;
- (void)setVolume:(float)volume;
- (void)setLooping:(BOOL)looping;

@end
