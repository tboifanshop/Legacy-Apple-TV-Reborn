//  ATLSoundtrackDownloadManager.h
//  Legacy Apple TV Reborn
//
//  Handles one-shot caching downloads for manifest-backed soundtrack entries.
//
//  Compatibility: iOS 8 / ARMv7 — uses NSURLSession (available iOS 7+).
//
//  Security rules enforced here:
//    - Only https:// URLs accepted.
//    - File names sanitized; no path separators allowed.
//    - Final files written only inside ATLSoundtrackLibraryRootPath.
//    - Downloads go to a .download temp file; atomic rename on success.
//
//  Threading: all completion/progress callbacks are delivered on the main queue.

#import <Foundation/Foundation.h>
#import "ATLSoundtrackLibrary.h"

NS_ASSUME_NONNULL_BEGIN

/// Called when a download completes or fails.
/// @param entry   The entry that was requested (state updated in-place).
/// @param success YES if the file is now available at entry.filePath.
/// @param error   Non-nil on failure.
typedef void (^ATLSoundtrackDownloadCompletion)(ATLSoundtrackEntry *entry,
                                                BOOL success,
                                                NSError * _Nullable error);

/// Called periodically during download.
typedef void (^ATLSoundtrackDownloadProgress)(ATLSoundtrackEntry *entry,
                                              float progress);

@interface ATLSoundtrackDownloadManager : NSObject

+ (instancetype)sharedManager;

/// Download the audio file for the given entry if it is not already cached.
/// If the file already exists and is valid, completion is called immediately
/// with success=YES.  Otherwise a background NSURLSessionDownloadTask is
/// started.
///
/// @param entry       Manifest entry; must have a valid downloadURL.
/// @param progress    Optional progress callback (main queue, may be nil).
/// @param completion  Required completion callback (main queue).
- (void)downloadEntryIfNeeded:(ATLSoundtrackEntry *)entry
                     progress:(nullable ATLSoundtrackDownloadProgress)progress
                   completion:(ATLSoundtrackDownloadCompletion)completion;

/// Cancel any in-progress download for the given entryID.
- (void)cancelDownloadForEntryID:(NSString *)entryID;

/// Returns YES if the given entry has a valid local file.
- (BOOL)isEntryDownloaded:(ATLSoundtrackEntry *)entry;

/// Returns the current download progress (0.0–1.0) for an entryID,
/// or 0 if not currently downloading.
- (float)progressForEntryID:(NSString *)entryID;

@end

NS_ASSUME_NONNULL_END
