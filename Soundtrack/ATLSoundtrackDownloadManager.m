//  ATLSoundtrackDownloadManager.m
//  Legacy Apple TV Reborn

#import "ATLSoundtrackDownloadManager.h"
#import "../Utilities/ATLLog.h"

// ---------------------------------------------------------------------------
// Directory where Kodi looks for music (best-effort; skipped if absent).
static NSString *const ATLKodiMusicPath =
    @"/var/mobile/Library/Application Support/Kodi/userdata/Music";

// ---------------------------------------------------------------------------
// Internal state for a single in-flight download.
@interface ATLDownloadTask : NSObject
@property (nonatomic, copy)   NSString                          *entryID;
@property (nonatomic, strong) ATLSoundtrackEntry                *entry;
@property (nonatomic, strong) NSURLSessionDownloadTask          *task;
@property (nonatomic, copy)   ATLSoundtrackDownloadProgress      progressBlock;
@property (nonatomic, copy)   ATLSoundtrackDownloadCompletion    completionBlock;
@property (nonatomic, copy)   NSString                          *tempPath;
@property (nonatomic, copy)   NSString                          *finalPath;
@end

@implementation ATLDownloadTask
@end

// ---------------------------------------------------------------------------
@interface ATLSoundtrackDownloadManager () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession                 *session;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ATLDownloadTask *> *activeTasks;
// Maps NSURLSessionTask.taskIdentifier (as NSNumber) → entryID
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *>        *taskIDMap;
@end

@implementation ATLSoundtrackDownloadManager

+ (instancetype)sharedManager {
    static ATLSoundtrackDownloadManager *mgr = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ mgr = [[ATLSoundtrackDownloadManager alloc] _init]; });
    return mgr;
}

- (instancetype)_init {
    self = [super init];
    if (self) {
        _activeTasks = [NSMutableDictionary dictionary];
        _taskIDMap   = [NSMutableDictionary dictionary];

        NSURLSessionConfiguration *cfg =
            [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest  = 30.0;
        cfg.timeoutIntervalForResource = 300.0;

        // Use a background-compatible delegate queue so we never block the main thread.
        NSOperationQueue *q = [[NSOperationQueue alloc] init];
        q.maxConcurrentOperationCount = 1;
        q.name = @"com.legacyappletvreborn.downloadmanager";

        _session = [NSURLSession sessionWithConfiguration:cfg
                                                 delegate:self
                                            delegateQueue:q];
    }
    return self;
}

// ---------------------------------------------------------------------------
#pragma mark - Public API

- (BOOL)isEntryDownloaded:(ATLSoundtrackEntry *)entry {
    if (!entry.filePath.length) return NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:entry.filePath]) return NO;
    // Treat zero-byte files as invalid.
    NSDictionary *attrs = [fm attributesOfItemAtPath:entry.filePath error:nil];
    return ([attrs fileSize] > 0);
}

- (float)progressForEntryID:(NSString *)entryID {
    ATLDownloadTask *dt = _activeTasks[entryID];
    return dt ? dt.entry.downloadProgress : 0.0f;
}

- (void)downloadEntryIfNeeded:(ATLSoundtrackEntry *)entry
                     progress:(ATLSoundtrackDownloadProgress)progress
                   completion:(ATLSoundtrackDownloadCompletion)completion {
    // Already cached?
    if ([self isEntryDownloaded:entry]) {
        entry.downloadState    = ATLSoundtrackDownloadStateDownloaded;
        entry.downloadProgress = 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry, YES, nil);
        });
        return;
    }

    // Validate URL — HTTPS only.
    NSString *urlString = entry.downloadURL;
    if (!urlString.length) {
        NSError *err = [NSError errorWithDomain:@"ATLDownload"
                                           code:1
                                       userInfo:@{NSLocalizedDescriptionKey: @"No download URL"}];
        entry.downloadState = ATLSoundtrackDownloadStateFailed;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry, NO, err);
        });
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url || ![url.scheme isEqualToString:@"https"]) {
        NSError *err = [NSError errorWithDomain:@"ATLDownload"
                                           code:2
                                       userInfo:@{NSLocalizedDescriptionKey:
                                                      @"Download URL must use https://"}];
        entry.downloadState = ATLSoundtrackDownloadStateFailed;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry, NO, err);
        });
        return;
    }

    // Already in-flight?
    if (_activeTasks[entry.entryID]) {
        ATLLogInfo(@"ATLSoundtrackDownloadManager: %@ already downloading", entry.entryID);
        return;
    }

    // Sanitize the final path.
    NSString *finalPath = [self _sanitizedFinalPathForEntry:entry];
    if (!finalPath) {
        NSError *err = [NSError errorWithDomain:@"ATLDownload"
                                           code:3
                                       userInfo:@{NSLocalizedDescriptionKey:
                                                      @"Unsafe file path rejected"}];
        entry.downloadState = ATLSoundtrackDownloadStateFailed;
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(entry, NO, err);
        });
        return;
    }

    NSString *tempPath = [finalPath stringByAppendingString:@".download"];

    // Remove any stale temp file.
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];

    // Ensure download directory exists.
    [[NSFileManager defaultManager] createDirectoryAtPath:[finalPath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    entry.downloadState    = ATLSoundtrackDownloadStateDownloading;
    entry.downloadProgress = 0.0f;

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *task = [_session downloadTaskWithRequest:request];

    ATLDownloadTask *dt  = [[ATLDownloadTask alloc] init];
    dt.entryID           = entry.entryID;
    dt.entry             = entry;
    dt.task              = task;
    dt.progressBlock     = progress;
    dt.completionBlock   = completion;
    dt.tempPath          = tempPath;
    dt.finalPath         = finalPath;

    _activeTasks[entry.entryID]             = dt;
    _taskIDMap[@(task.taskIdentifier)]      = entry.entryID;

    [task resume];
    ATLLogInfo(@"ATLSoundtrackDownloadManager: started download for %@ → %@",
               entry.entryID, finalPath);
}

- (void)cancelDownloadForEntryID:(NSString *)entryID {
    ATLDownloadTask *dt = _activeTasks[entryID];
    if (!dt) return;
    [dt.task cancel];
    [[NSFileManager defaultManager] removeItemAtPath:dt.tempPath error:nil];
    dt.entry.downloadState    = ATLSoundtrackDownloadStateNotDownloaded;
    dt.entry.downloadProgress = 0.0f;
    [_taskIDMap removeObjectForKey:@(dt.task.taskIdentifier)];
    [_activeTasks removeObjectForKey:entryID];
    ATLLogInfo(@"ATLSoundtrackDownloadManager: cancelled %@", entryID);
}

// ---------------------------------------------------------------------------
#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *entryID = _taskIDMap[@(downloadTask.taskIdentifier)];
    ATLDownloadTask *dt = entryID ? _activeTasks[entryID] : nil;
    if (!dt) return;

    float p = (totalBytesExpectedToWrite > 0)
        ? (float)totalBytesWritten / (float)totalBytesExpectedToWrite
        : 0.0f;
    dt.entry.downloadProgress = p;

    ATLSoundtrackDownloadProgress progressBlock = dt.progressBlock;
    ATLSoundtrackEntry *entry = dt.entry;
    if (progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressBlock(entry, p);
        });
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSString *entryID = _taskIDMap[@(downloadTask.taskIdentifier)];
    ATLDownloadTask *dt = entryID ? _activeTasks[entryID] : nil;
    if (!dt) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;

    // Move system temp → our own temp path so it survives session cleanup.
    [fm removeItemAtPath:dt.tempPath error:nil];
    BOOL moved = [fm moveItemAtURL:location
                             toURL:[NSURL fileURLWithPath:dt.tempPath]
                             error:&err];
    if (!moved) {
        ATLLogError(@"ATLSoundtrackDownloadManager: failed to move temp file for %@: %@",
                    entryID, err);
        // Don't call completion here; URLSession:task:didCompleteWithError: handles it.
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    NSString *entryID = _taskIDMap[@(task.taskIdentifier)];
    ATLDownloadTask *dt = entryID ? _activeTasks[entryID] : nil;
    if (!dt) return;

    // Clean up tracking tables regardless of outcome.
    [_taskIDMap removeObjectForKey:@(task.taskIdentifier)];
    [_activeTasks removeObjectForKey:entryID];

    NSFileManager *fm = [NSFileManager defaultManager];

    if (error) {
        ATLLogError(@"ATLSoundtrackDownloadManager: download failed for %@: %@", entryID, error);
        [fm removeItemAtPath:dt.tempPath error:nil];
        dt.entry.downloadState    = ATLSoundtrackDownloadStateFailed;
        dt.entry.downloadProgress = 0.0f;

        ATLSoundtrackDownloadCompletion cb = dt.completionBlock;
        ATLSoundtrackEntry *entry = dt.entry;
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(entry, NO, error);
        });
        return;
    }

    // Validate temp file.
    if (![fm fileExistsAtPath:dt.tempPath]) {
        NSError *missing = [NSError errorWithDomain:@"ATLDownload"
                                               code:4
                                           userInfo:@{NSLocalizedDescriptionKey:
                                                          @"Downloaded file missing after transfer"}];
        dt.entry.downloadState    = ATLSoundtrackDownloadStateFailed;
        dt.entry.downloadProgress = 0.0f;
        ATLSoundtrackDownloadCompletion cb = dt.completionBlock;
        ATLSoundtrackEntry *entry = dt.entry;
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(entry, NO, missing);
        });
        return;
    }

    NSDictionary *attrs = [fm attributesOfItemAtPath:dt.tempPath error:nil];
    if ([attrs fileSize] == 0) {
        [fm removeItemAtPath:dt.tempPath error:nil];
        NSError *empty = [NSError errorWithDomain:@"ATLDownload"
                                             code:5
                                         userInfo:@{NSLocalizedDescriptionKey:
                                                        @"Downloaded file is empty"}];
        dt.entry.downloadState    = ATLSoundtrackDownloadStateFailed;
        dt.entry.downloadProgress = 0.0f;
        ATLSoundtrackDownloadCompletion cb = dt.completionBlock;
        ATLSoundtrackEntry *entry = dt.entry;
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(entry, NO, empty);
        });
        return;
    }

    // Atomic move temp → final path.
    [fm removeItemAtPath:dt.finalPath error:nil];
    NSError *moveErr = nil;
    BOOL ok = [fm moveItemAtPath:dt.tempPath toPath:dt.finalPath error:&moveErr];
    if (!ok) {
        [fm removeItemAtPath:dt.tempPath error:nil];
        dt.entry.downloadState    = ATLSoundtrackDownloadStateFailed;
        dt.entry.downloadProgress = 0.0f;
        ATLSoundtrackDownloadCompletion cb = dt.completionBlock;
        ATLSoundtrackEntry *entry = dt.entry;
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(entry, NO, moveErr);
        });
        return;
    }

    dt.entry.filePath         = dt.finalPath;
    dt.entry.downloadState    = ATLSoundtrackDownloadStateDownloaded;
    dt.entry.downloadProgress = 1.0f;
    ATLLogInfo(@"ATLSoundtrackDownloadManager: cached %@ → %@", entryID, dt.finalPath);

    // Best-effort: copy to Kodi music directory so Kodi users can find it.
    [self _copyToKodiIfPossible:dt.finalPath];

    ATLSoundtrackDownloadCompletion cb = dt.completionBlock;
    ATLSoundtrackEntry *entry = dt.entry;
    dispatch_async(dispatch_get_main_queue(), ^{
        cb(entry, YES, nil);
    });
}

// ---------------------------------------------------------------------------
#pragma mark - Helpers

/// Returns the sanitized absolute final path for the entry, or nil if unsafe.
- (nullable NSString *)_sanitizedFinalPathForEntry:(ATLSoundtrackEntry *)entry {
    NSString *proposed = entry.filePath;

    // Derive from entryID + URL extension if filePath not set.
    if (!proposed.length && entry.downloadURL.length) {
        NSString *urlFile = [[NSURL URLWithString:entry.downloadURL] lastPathComponent];
        urlFile = [urlFile stringByRemovingPercentEncoding] ?: urlFile;
        urlFile = [urlFile lastPathComponent]; // strip any injected slashes
        NSString *ext = urlFile.pathExtension.lowercaseString;
        NSArray *ok = @[@"m4a", @"mp3", @"aac", @"wav", @"caf"];
        if (![ok containsObject:ext]) ext = @"mp3";
        proposed = [NSString stringWithFormat:@"%@/%@.%@",
                    ATLSoundtrackLibraryRootPath, entry.entryID, ext];
    }

    if (!proposed.length) return nil;

    // Resolve symlinks / .. to get canonical path.
    // On iOS 8 we don't have stringByResolvingSymlinksInPath reliably for
    // non-existent paths, so normalise manually.
    proposed = proposed.stringByStandardizingPath;

    // Must stay within the soundtracks root.
    NSString *root = ATLSoundtrackLibraryRootPath.stringByStandardizingPath;
    if (![proposed hasPrefix:[root stringByAppendingString:@"/"]]) {
        ATLLogError(@"ATLSoundtrackDownloadManager: path escape rejected: %@", proposed);
        return nil;
    }

    // Filename portion must not contain path separators.
    NSString *filename = proposed.lastPathComponent;
    if ([filename containsString:@"/"] || [filename containsString:@".."]) {
        ATLLogError(@"ATLSoundtrackDownloadManager: unsafe filename rejected: %@", filename);
        return nil;
    }

    return proposed;
}

/// Best-effort copy of a downloaded soundtrack into Kodi's music directory.
- (void)_copyToKodiIfPossible:(NSString *)sourcePath {
    NSFileManager *fm = [NSFileManager defaultManager];

    // Only proceed if Kodi's userdata directory exists (Kodi is installed).
    NSString *kodiUserdata = @"/var/mobile/Library/Application Support/Kodi/userdata";
    if (![fm fileExistsAtPath:kodiUserdata]) return;

    NSError *err = nil;
    [fm createDirectoryAtPath:ATLKodiMusicPath
  withIntermediateDirectories:YES attributes:nil error:&err];
    if (err) {
        ATLLogWarn(@"ATLSoundtrackDownloadManager: could not create Kodi music dir: %@", err);
        return;
    }

    NSString *dest = [ATLKodiMusicPath stringByAppendingPathComponent:sourcePath.lastPathComponent];
    if ([fm fileExistsAtPath:dest]) return; // already there

    BOOL copied = [fm copyItemAtPath:sourcePath toPath:dest error:&err];
    if (copied) {
        ATLLogInfo(@"ATLSoundtrackDownloadManager: copied to Kodi: %@", dest);
    } else {
        ATLLogWarn(@"ATLSoundtrackDownloadManager: Kodi copy failed: %@", err);
    }
}

@end
