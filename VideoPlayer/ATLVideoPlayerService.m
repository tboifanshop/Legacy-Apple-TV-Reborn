#import "ATLVideoPlayerService.h"
#import "../Utilities/ATLLog.h"

@interface ATLVideoPlayerService ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *observedItem;
@property (nonatomic, assign) BOOL looping;
@property (nonatomic, assign) ATLVideoPlayerState state;
@end

@implementation ATLVideoPlayerService

+ (instancetype)sharedService {
    static ATLVideoPlayerService *svc = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ svc = [[ATLVideoPlayerService alloc] init]; });
    return svc;
}

- (instancetype)init {
    self = [super init];
    if (self) { _state = ATLVideoPlayerStateStopped; }
    return self;
}

- (void)loadURL:(NSURL *)url {
    if (!url) return;
    [self stop];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:item];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _observedItem = item;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_itemDidEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_observedItem];
    ATLLogInfo(@"ATLVideoPlayerService: loaded %@", url);
}

- (void)play {
    [_player play];
    _state = ATLVideoPlayerStatePlaying;
}

- (void)pause {
    [_player pause];
    _state = ATLVideoPlayerStatePaused;
}

- (void)stop {
    if (_observedItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_observedItem];
        _observedItem = nil;
    }
    [_player pause];
    _player = nil;
    _state  = ATLVideoPlayerStateStopped;
}

- (void)seekToSeconds:(NSTimeInterval)seconds {
    if (!_player) return;
    [_player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC)];
}

- (void)setVolume:(float)volume {
    _player.volume = MAX(0.0f, MIN(1.0f, volume));
}

- (void)setLooping:(BOOL)looping {
    _looping = looping;
}

- (void)_itemDidEnd:(NSNotification *)note {
    if (_looping) {
        [_player seekToTime:kCMTimeZero];
        [_player play];
    } else {
        _state = ATLVideoPlayerStateStopped;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
