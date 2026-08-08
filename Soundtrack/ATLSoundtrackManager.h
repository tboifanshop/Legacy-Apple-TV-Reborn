//  ATLSoundtrackManager.h
//  Legacy Apple TV Reborn
//
//  Controls audio playback for the Reborn theme soundtrack.
//
//  Rules:
//    - Plays in: Main Menu, Reborn Settings, Soundtrack Menu, Screensaver.
//    - Pauses/stops outside the Reborn shell.
//    - NEVER interferes with Kodi, YouTube, Movies, Music, games.
//    - Holding Play/Pause on Reborn main menu → open Soundtrack Menu.
//      (The HID hook is managed in LauncherHooks.x, not here.)
//
//  CONFIRMED APIs: AVAudioPlayer (Foundation/AVFoundation) — CONFIRMED.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ATLSoundtrackLibrary.h"

typedef NS_ENUM(NSUInteger, ATLSoundtrackRepeatMode) {
    ATLSoundtrackRepeatNone,
    ATLSoundtrackRepeatOne,
    ATLSoundtrackRepeatAll,
};

@interface ATLSoundtrackManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) ATLSoundtrackEntry *currentEntry;
@property (nonatomic, assign, getter=isPlaying) BOOL playing;
@property (nonatomic, assign) BOOL  shuffleEnabled;
@property (nonatomic, assign) ATLSoundtrackRepeatMode repeatMode;
@property (nonatomic, assign) float volume;  // 0.0 – 1.0

/// Load and begin playback of a specific entry.
- (void)playEntry:(ATLSoundtrackEntry *)entry;

/// Play the default soundtrack for the active theme (if available).
- (void)playDefaultForActiveTheme;

/// Pause playback (e.g. entering media player, Kodi, games).
- (void)pause;

/// Resume a previously paused soundtrack.
- (void)resume;

/// Stop and unload current track.
- (void)stop;

/// Skip to next track (respects shuffle and repeat mode).
- (void)skipNext;

/// Skip to previous track.
- (void)skipPrevious;

@end
