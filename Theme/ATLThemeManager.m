//  ATLThemeManager.m
//  Legacy Apple TV Reborn

#import "ATLThemeManager.h"
#import "../Settings/ATLSettingsStore.h"
#import "../Utilities/ATLLog.h"

NSString *const ATLThemeManagerDidChangeThemeNotification = @"ATLThemeManagerDidChangeTheme";

static NSString *const ATLThemeResourcesRoot =
    @"/Library/Application Support/LegacyAppleTVReborn/Themes";
static NSString *const ATLSettingsKeyActiveThemeID = @"ATLActiveThemeID";

@interface ATLThemeManager ()
@property (nonatomic, strong) ATLThemeConfig *activeTheme;
@property (nonatomic, strong) NSArray<ATLThemeConfig *> *availableThemes;
@end

@implementation ATLThemeManager

+ (instancetype)sharedManager {
    static ATLThemeManager *mgr = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ mgr = [[ATLThemeManager alloc] _init]; });
    return mgr;
}

- (instancetype)_init {
    self = [super init];
    if (self) {
        // Always present themes — Original must always be available.
        _availableThemes = @[
            [ATLThemeConfig originalAppleTVTheme],
            [ATLThemeConfig frutigerAeroTheme],
        ];
        [self _loadPersistedTheme];
    }
    return self;
}

- (void)_loadPersistedTheme {
    NSString *savedID = [[ATLSettingsStore sharedStore] objectForKey:ATLSettingsKeyActiveThemeID];
    if (savedID.length > 0) {
        for (ATLThemeConfig *cfg in _availableThemes) {
            if ([cfg.themeID isEqualToString:savedID]) {
                _activeTheme = cfg;
                ATLLogInfo(@"ATLThemeManager: restored theme %@", savedID);
                return;
            }
        }
    }
    // Default: Frutiger Aero.
    _activeTheme = [ATLThemeConfig frutigerAeroTheme];
    ATLLogInfo(@"ATLThemeManager: default theme Frutiger Aero");
}

- (void)activateThemeWithID:(NSString *)themeID {
    if (!themeID) return;
    for (ATLThemeConfig *cfg in _availableThemes) {
        if ([cfg.themeID isEqualToString:themeID]) {
            _activeTheme = cfg;
            [[ATLSettingsStore sharedStore] setObject:themeID forKey:ATLSettingsKeyActiveThemeID];
            [[ATLSettingsStore sharedStore] synchronize];
            ATLLogInfo(@"ATLThemeManager: activated theme %@", themeID);
            [[NSNotificationCenter defaultCenter]
                postNotificationName:ATLThemeManagerDidChangeThemeNotification
                              object:self];
            return;
        }
    }
    ATLLogWarn(@"ATLThemeManager: unknown themeID %@", themeID);
}

- (NSString *)pathForThemeResource:(NSString *)filename {
    if (!filename.length) return nil;
    NSString *path = [[ATLThemeResourcesRoot
        stringByAppendingPathComponent:_activeTheme.themeID]
        stringByAppendingPathComponent:filename];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

@end
