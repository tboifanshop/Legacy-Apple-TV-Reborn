//  ATLSoundtrackManager.m
//  Legacy Apple TV Reborn

#import "ATLSoundtrackManager.h"
#import "ATLSoundtrackDownloadManager.h"
#import "../Theme/ATLThemeManager.h"
#import "../Settings/ATLSettingsStore.h"
#import "../Utilities/ATLLog.h"

static NSString *const ATLSettingsKeyCurrentTrackID = @"ATLCurrentTrackID";
static NSString *const ATLSettingsKeyVolume          = @"ATLSoundtrackVolume";
static NSString *const ATLSettingsKeyShuffleEnabled  = @"ATLSoundtrackShuffle";
static NSString *const ATLSettingsKeyRepeatMode      = @"ATLSoundtrackRepeat";

@interface ATLSoundtrackManager () <AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer     *player;
@property (nonatomic, strong) ATLSoundtrackEntry *currentEntry;
@property (nonatomic, assign) BOOL               playing;
// Index into the library entries (for next/previous navigation).
@property (nonatomic, assign) NSInteger          currentIndex;
- (void)_startPlaybackOfEntry:(ATLSoundtrackEntry *)entry;
@end

@implementation ATLSoundtrackManager

+ (instancetype)sharedManager {
    static ATLSoundtrackManager *mgr = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ mgr = [[ATLSoundtrackManager alloc] _init]; });
    return mgr;
}

- (instancetype)_init {
    self = [super init];
    if (self) {
        ATLSettingsStore *s = [ATLSettingsStore sharedStore];
        _volume         = [[s objectForKey:ATLSettingsKeyVolume] floatValue];
        if (_volume < 0.01f) _volume = 0.75f;   // first-run default
        _shuffleEnabled = [s boolForKey:ATLSettingsKeyShuffleEnabled];
        _repeatMode     = (ATLSoundtrackRepeatMode)[[s objectForKey:ATLSettingsKeyRepeatMode] unsignedIntegerValue];
        _currentIndex   = -1;
    }
    return self;
}

// ---------------------------------------------------------------------------
- (void)playEntry:(ATLSoundtrackEntry *)entry {
    if (!entry) return;

    // If the file is already present locally, play it immediately.
    if ([[ATLSoundtrackDownloadManager sharedManager] isEntryDownloaded:entry]) {
        [self _startPlaybackOfEntry:entry];
        return;
    }

    // Need to download first.  Update state so UI can show a spinner.
    ATLLogInfo(@"ATLSoundtrackManager: track %@ not cached; queuing download", entry.entryID);

    __weak ATLSoundtrackManager *weakSelf = self;
    [[ATLSoundtrackDownloadManager sharedManager]
        downloadEntryIfNeeded:entry
                     progress:nil
                   completion:^(ATLSoundtrackEntry *e, BOOL success, NSError *err) {
        ATLSoundtrackManager *s = weakSelf;
        if (!s) return;
        if (success) {
            [s _startPlaybackOfEntry:e];
        } else {
            ATLLogError(@"ATLSoundtrackManager: download failed for %@: %@", e.entryID, err);
            // Fall back to next track if available, silently.
            NSArray<ATLSoundtrackEntry *> *entries =
                [[ATLSoundtrackLibrary sharedLibrary] entries];
            if (entries.count > 1) {
                [s skipNext];
            }
        }
    }];
}

- (void)_startPlaybackOfEntry:(ATLSoundtrackEntry *)entry {
    if (!entry.filePath.length) return;
    [self _stopPlayer];

    NSURL *url = [NSURL fileURLWithPath:entry.filePath];
    NSError *err = nil;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
    if (err || !_player) {
        ATLLogError(@"ATLSoundtrackManager: cannot open %@: %@", entry.filePath, err);
        return;
    }
    _player.delegate = self;
    _player.volume   = _volume;
    _player.numberOfLoops = (_repeatMode == ATLSoundtrackRepeatOne) ? -1 : 0;
    [_player prepareToPlay];
    [_player play];
    _currentEntry = entry;
    _playing      = YES;

    // Persist last played track.
    [[ATLSettingsStore sharedStore] setObject:entry.entryID forKey:ATLSettingsKeyCurrentTrackID];

    // Find index in library for skip navigation.
    NSArray *entries = [[ATLSoundtrackLibrary sharedLibrary] entries];
    NSUInteger found = [entries indexOfObjectPassingTest:^BOOL(ATLSoundtrackEntry *e, NSUInteger i, BOOL *stop) {
        return [e.entryID isEqualToString:entry.entryID];
    }];
    _currentIndex = (found == NSNotFound) ? -1 : (NSInteger)found;

    ATLLogInfo(@"ATLSoundtrackManager: playing %@", entry.entryID);
}

- (void)playDefaultForActiveTheme {
    NSString *trackID = [ATLThemeManager sharedManager].activeTheme.defaultSoundtrackName;
    if (!trackID) return;

    [[ATLSoundtrackLibrary sharedLibrary] reload];
    ATLSoundtrackEntry *entry = [[ATLSoundtrackLibrary sharedLibrary] entryWithID:trackID];
    if (!entry) {
        ATLLogWarn(@"ATLSoundtrackManager: track '%@' not found in library (user must supply file)", trackID);
        return;
    }
    [self playEntry:entry];
}

- (void)pause {
    if (!_player.isPlaying) return;
    [_player pause];
    _playing = NO;
    ATLLogInfo(@"ATLSoundtrackManager: paused");
}

- (void)resume {
    if (!_player || _player.isPlaying) return;
    [_player play];
    _playing = YES;
    ATLLogInfo(@"ATLSoundtrackManager: resumed");
}

- (void)stop {
    [self _stopPlayer];
    _currentEntry = nil;
    _currentIndex = -1;
    ATLLogInfo(@"ATLSoundtrackManager: stopped");
}

- (void)setVolume:(float)volume {
    _volume = MAX(0.0f, MIN(1.0f, volume));
    _player.volume = _volume;
    [[ATLSettingsStore sharedStore] setObject:@(_volume) forKey:ATLSettingsKeyVolume];
}

- (void)setShuffleEnabled:(BOOL)shuffleEnabled {
    _shuffleEnabled = shuffleEnabled;
    [[ATLSettingsStore sharedStore] setBool:shuffleEnabled forKey:ATLSettingsKeyShuffleEnabled];
}

- (void)setRepeatMode:(ATLSoundtrackRepeatMode)repeatMode {
    _repeatMode = repeatMode;
    _player.numberOfLoops = (repeatMode == ATLSoundtrackRepeatOne) ? -1 : 0;
    [[ATLSettingsStore sharedStore] setObject:@(repeatMode) forKey:ATLSettingsKeyRepeatMode];
}

// ---------------------------------------------------------------------------
- (void)skipNext {
    NSArray<ATLSoundtrackEntry *> *entries = [[ATLSoundtrackLibrary sharedLibrary] entries];
    if (entries.count == 0) return;
    NSInteger idx = [self _nextIndex:entries];
    [self playEntry:entries[idx]];
}

- (void)skipPrevious {
    NSArray<ATLSoundtrackEntry *> *entries = [[ATLSoundtrackLibrary sharedLibrary] entries];
    if (entries.count == 0) return;
    NSInteger idx = _currentIndex - 1;
    if (idx < 0) idx = (NSInteger)entries.count - 1;
    [self playEntry:entries[idx]];
}

- (NSInteger)_nextIndex:(NSArray<ATLSoundtrackEntry *> *)entries {
    if (_shuffleEnabled) {
        return arc4random_uniform((uint32_t)entries.count);
    }
    NSInteger idx = _currentIndex + 1;
    if (idx >= (NSInteger)entries.count) {
        idx = (_repeatMode == ATLSoundtrackRepeatAll) ? 0 : _currentIndex;
    }
    return MAX(0, idx);
}

// ---------------------------------------------------------------------------
- (void)_stopPlayer {
    if (_player) {
        [_player stop];
        _player   = nil;
        _playing  = NO;
    }
}

// ---------------------------------------------------------------------------
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (_repeatMode == ATLSoundtrackRepeatOne) return;  // handled by numberOfLoops = -1
    [self skipNext];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    ATLLogError(@"ATLSoundtrackManager: decode error: %@", error);
    [self skipNext];
}

@end
