//  ATLSoundtrackLibrary.m
//  Legacy Apple TV Reborn

#import "ATLSoundtrackLibrary.h"
#import "../Utilities/ATLLog.h"

NSString *const ATLSoundtrackLibraryRootPath =
    @"/var/mobile/Library/LegacyAppleTVReborn/Soundtracks";

// Path to the bundled manifest plist installed by the package.
static NSString *const ATLSoundtrackManifestPath =
    @"/Library/Application Support/LegacyAppleTVReborn/SoundtrackManifest.plist";

// ---------------------------------------------------------------------------
@implementation ATLSoundtrackEntry

- (id)copyWithZone:(NSZone *)zone {
    ATLSoundtrackEntry *copy = [[ATLSoundtrackEntry allocWithZone:zone] init];
    copy.entryID          = self.entryID;
    copy.displayName      = self.displayName;
    copy.filePath         = self.filePath;
    copy.downloadURL      = self.downloadURL;
    copy.licenseInfo      = self.licenseInfo;
    copy.downloadState    = self.downloadState;
    copy.downloadProgress = self.downloadProgress;
    return copy;
}

@end

// ---------------------------------------------------------------------------
@interface ATLSoundtrackLibrary ()
@property (nonatomic, strong) NSMutableArray<ATLSoundtrackEntry *> *mutableEntries;
@end

@implementation ATLSoundtrackLibrary

+ (instancetype)sharedLibrary {
    static ATLSoundtrackLibrary *lib = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ lib = [[ATLSoundtrackLibrary alloc] _init]; });
    return lib;
}

- (instancetype)_init {
    self = [super init];
    if (self) {
        _mutableEntries = [NSMutableArray array];
        [self reload];
    }
    return self;
}

- (NSArray<ATLSoundtrackEntry *> *)entries {
    return [_mutableEntries copy];
}

// ---------------------------------------------------------------------------
- (void)reload {
    NSFileManager *fm = [NSFileManager defaultManager];

    // Ensure cache directory exists.
    [fm createDirectoryAtPath:ATLSoundtrackLibraryRootPath
  withIntermediateDirectories:YES attributes:nil error:nil];

    NSMutableArray<ATLSoundtrackEntry *> *result = [NSMutableArray array];

    // 1. Load manifest entries (may have remote download URLs).
    [self _loadManifestInto:result];

    // 2. Scan local directory for any additional user-supplied files not in manifest.
    NSError *err = nil;
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:ATLSoundtrackLibraryRootPath error:&err];
    if (err) {
        ATLLogWarn(@"ATLSoundtrackLibrary: cannot read %@: %@", ATLSoundtrackLibraryRootPath, err);
    } else {
        NSArray *supported = @[@"m4a", @"mp3", @"aac", @"wav", @"caf"];
        for (NSString *file in files) {
            // Skip temp download files.
            if ([file hasSuffix:@".download"]) continue;
            NSString *ext = file.pathExtension.lowercaseString;
            if (![supported containsObject:ext]) continue;

            NSString *eid = [file stringByDeletingPathExtension];
            // Skip if already added via manifest.
            BOOL found = NO;
            for (ATLSoundtrackEntry *e in result) {
                if ([e.entryID isEqualToString:eid]) { found = YES; break; }
            }
            if (found) continue;

            ATLSoundtrackEntry *e = [[ATLSoundtrackEntry alloc] init];
            e.entryID          = eid;
            e.displayName      = [eid stringByReplacingOccurrencesOfString:@"-" withString:@" "];
            e.filePath         = [ATLSoundtrackLibraryRootPath stringByAppendingPathComponent:file];
            e.downloadState    = ATLSoundtrackDownloadStateDownloaded;
            e.downloadProgress = 1.0f;
            [result addObject:e];
        }
    }

    _mutableEntries = result;
    ATLLogInfo(@"ATLSoundtrackLibrary: loaded %lu entries", (unsigned long)_mutableEntries.count);
}

// ---------------------------------------------------------------------------
- (void)_loadManifestInto:(NSMutableArray<ATLSoundtrackEntry *> *)result {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:ATLSoundtrackManifestPath]) {
        ATLLogInfo(@"ATLSoundtrackLibrary: no manifest at %@", ATLSoundtrackManifestPath);
        return;
    }

    NSArray *manifest = [NSArray arrayWithContentsOfFile:ATLSoundtrackManifestPath];
    if (!manifest) {
        ATLLogWarn(@"ATLSoundtrackLibrary: failed to parse manifest plist");
        return;
    }

    NSArray *supported = @[@"m4a", @"mp3", @"aac", @"wav", @"caf"];

    for (NSDictionary *dict in manifest) {
        NSString *eid = dict[@"entryID"];
        if (!eid.length) continue;

        ATLSoundtrackEntry *e = [[ATLSoundtrackEntry alloc] init];
        e.entryID     = eid;
        e.displayName = dict[@"displayName"] ?: [eid stringByReplacingOccurrencesOfString:@"-" withString:@" "];
        e.downloadURL = dict[@"downloadURL"];
        e.licenseInfo = dict[@"licenseInfo"];

        // Determine local file path from manifest or derive from entryID + URL extension.
        NSString *localFile = dict[@"localFileName"];
        if (!localFile.length && e.downloadURL.length) {
            // Derive filename from the last URL path component, sanitized.
            NSString *urlFile = [[NSURL URLWithString:e.downloadURL] lastPathComponent];
            urlFile = [urlFile stringByRemovingPercentEncoding] ?: urlFile;
            // Sanitize: strip any path separators.
            urlFile = [urlFile lastPathComponent];
            NSString *ext = urlFile.pathExtension.lowercaseString;
            if ([supported containsObject:ext]) {
                localFile = [NSString stringWithFormat:@"%@.%@", eid, ext];
            }
        }
        if (!localFile.length) {
            localFile = [NSString stringWithFormat:@"%@.mp3", eid];
        }
        e.filePath = [ATLSoundtrackLibraryRootPath stringByAppendingPathComponent:localFile];

        // Determine current download state.
        if ([fm fileExistsAtPath:e.filePath]) {
            e.downloadState    = ATLSoundtrackDownloadStateDownloaded;
            e.downloadProgress = 1.0f;
        } else {
            e.downloadState    = ATLSoundtrackDownloadStateNotDownloaded;
            e.downloadProgress = 0.0f;
        }

        [result addObject:e];
    }
}

// ---------------------------------------------------------------------------
- (ATLSoundtrackEntry *)entryWithID:(NSString *)entryID {
    for (ATLSoundtrackEntry *e in _mutableEntries) {
        if ([e.entryID isEqualToString:entryID]) return e;
    }
    return nil;
}

@end
