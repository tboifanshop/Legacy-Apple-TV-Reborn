//  ATLSoundtrackLibrary.h
//  Legacy Apple TV Reborn
//
//  Tracks available soundtrack entries (user-supplied audio files).
//  Does NOT redistribute copyrighted content — users supply audio files.
//
//  Audio file root: /var/mobile/Library/LegacyAppleTVReborn/Soundtracks/
//  Supported formats: anything AVAudioPlayer accepts (m4a, mp3, aac, wav).

#import <Foundation/Foundation.h>

extern NSString *const ATLSoundtrackLibraryRootPath;

@interface ATLSoundtrackEntry : NSObject <NSCopying>
@property (nonatomic, copy) NSString *entryID;       ///< e.g. "WiiU_MiiEditing"
@property (nonatomic, copy) NSString *displayName;   ///< Human-readable title
@property (nonatomic, copy) NSString *filePath;      ///< Absolute path to audio
@end

@interface ATLSoundtrackLibrary : NSObject

+ (instancetype)sharedLibrary;

/// All known entries (re-scanned each call for simplicity).
@property (nonatomic, strong, readonly) NSArray<ATLSoundtrackEntry *> *entries;

/// Finds an entry by entryID.  Returns nil if not present.
- (nullable ATLSoundtrackEntry *)entryWithID:(NSString *)entryID;

/// Scans ATLSoundtrackLibraryRootPath and refreshes entries.
- (void)reload;

@end
