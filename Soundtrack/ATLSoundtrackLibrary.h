//  ATLSoundtrackLibrary.h
//  Legacy Apple TV Reborn
//
//  Tracks available soundtrack entries.  Entries may be locally cached
//  (user-supplied) or declared in SoundtrackManifest.plist with a remote
//  download URL.  Does NOT redistribute copyrighted content.
//
//  Audio file root: /var/mobile/Library/LegacyAppleTVReborn/Soundtracks/
//  Supported formats: anything AVAudioPlayer accepts (m4a, mp3, aac, wav).

#import <Foundation/Foundation.h>

extern NSString *const ATLSoundtrackLibraryRootPath;

/// Download state for a manifest-backed entry.
typedef NS_ENUM(NSUInteger, ATLSoundtrackDownloadState) {
    ATLSoundtrackDownloadStateNotDownloaded = 0,
    ATLSoundtrackDownloadStateDownloading,
    ATLSoundtrackDownloadStateDownloaded,
    ATLSoundtrackDownloadStateFailed,
};

@interface ATLSoundtrackEntry : NSObject <NSCopying>
/// Unique identifier, e.g. "stevia-sphere-going-up".
@property (nonatomic, copy) NSString *entryID;
/// Human-readable title.
@property (nonatomic, copy) NSString *displayName;
/// Absolute path to local cached audio file (may not exist yet).
@property (nonatomic, copy) NSString *filePath;
/// Remote HTTPS URL for automatic download.  Nil for user-supplied tracks.
@property (nonatomic, copy, nullable) NSString *downloadURL;
/// License description kept with the entry (informational).
@property (nonatomic, copy, nullable) NSString *licenseInfo;
/// Current download state (for manifest-backed entries).
@property (nonatomic, assign) ATLSoundtrackDownloadState downloadState;
/// Download progress 0.0–1.0 (meaningful only while Downloading).
@property (nonatomic, assign) float downloadProgress;
@end

@interface ATLSoundtrackLibrary : NSObject

+ (instancetype)sharedLibrary;

/// All known entries (manifest entries + locally scanned files).
@property (nonatomic, strong, readonly) NSArray<ATLSoundtrackEntry *> *entries;

/// Finds an entry by entryID.  Returns nil if not present.
- (nullable ATLSoundtrackEntry *)entryWithID:(NSString *)entryID;

/// Reloads manifest and rescans the local soundtracks directory.
- (void)reload;

@end
