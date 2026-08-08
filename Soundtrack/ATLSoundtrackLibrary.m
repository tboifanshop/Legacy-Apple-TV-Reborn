//  ATLSoundtrackLibrary.m
//  Legacy Apple TV Reborn

#import "ATLSoundtrackLibrary.h"
#import "../Utilities/ATLLog.h"

NSString *const ATLSoundtrackLibraryRootPath =
    @"/var/mobile/Library/LegacyAppleTVReborn/Soundtracks";

// ---------------------------------------------------------------------------
@implementation ATLSoundtrackEntry

- (id)copyWithZone:(NSZone *)zone {
    ATLSoundtrackEntry *copy = [[ATLSoundtrackEntry allocWithZone:zone] init];
    copy.entryID     = self.entryID;
    copy.displayName = self.displayName;
    copy.filePath    = self.filePath;
    return copy;
}

@end

// ---------------------------------------------------------------------------
@interface ATLSoundtrackLibrary ()
@property (nonatomic, strong) NSArray<ATLSoundtrackEntry *> *entries;
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
        _entries = @[];
        [self reload];
    }
    return self;
}

- (void)reload {
    NSFileManager *fm = [NSFileManager defaultManager];

    // Ensure directory exists.
    [fm createDirectoryAtPath:ATLSoundtrackLibraryRootPath
  withIntermediateDirectories:YES attributes:nil error:nil];

    NSError *err = nil;
    NSArray *files = [fm contentsOfDirectoryAtPath:ATLSoundtrackLibraryRootPath error:&err];
    if (err) {
        ATLLogWarn(@"ATLSoundtrackLibrary: cannot read %@: %@", ATLSoundtrackLibraryRootPath, err);
        _entries = @[];
        return;
    }

    NSArray *supported = @[@"m4a", @"mp3", @"aac", @"wav", @"caf"];
    NSMutableArray<ATLSoundtrackEntry *> *result = [NSMutableArray array];
    for (NSString *file in files) {
        NSString *ext = file.pathExtension.lowercaseString;
        if (![supported containsObject:ext]) continue;

        ATLSoundtrackEntry *e = [[ATLSoundtrackEntry alloc] init];
        // entryID = filename without extension.
        e.entryID     = [file stringByDeletingPathExtension];
        e.displayName = [e.entryID stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        e.filePath    = [ATLSoundtrackLibraryRootPath stringByAppendingPathComponent:file];
        [result addObject:e];
    }
    _entries = [result copy];
    ATLLogInfo(@"ATLSoundtrackLibrary: loaded %lu entries", (unsigned long)_entries.count);
}

- (ATLSoundtrackEntry *)entryWithID:(NSString *)entryID {
    for (ATLSoundtrackEntry *e in _entries) {
        if ([e.entryID isEqualToString:entryID]) return e;
    }
    return nil;
}

@end
