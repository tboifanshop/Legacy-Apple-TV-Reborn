//  ATLThemeConfig.m
//  Legacy Apple TV Reborn

#import "ATLThemeConfig.h"

NSString *const ATLThemeIDOriginal      = @"com.legacyappletvreborn.theme.original";
NSString *const ATLThemeIDFrutigerAero  = @"com.legacyappletvreborn.theme.frutigeraero";

@implementation ATLThemeConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _themeID            = @"";
        _displayName        = @"";
        _backgroundImageName = nil;
        _glassAlpha         = 0.0f;
        _tileCornerRadius   = 0.0f;
        _shelfBannersHidden = NO;
        _isBypassMode       = NO;
        _defaultSoundtrackName = nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ATLThemeConfig *copy = [[ATLThemeConfig allocWithZone:zone] init];
    copy.themeID              = self.themeID;
    copy.displayName          = self.displayName;
    copy.backgroundImageName  = self.backgroundImageName;
    copy.glassAlpha           = self.glassAlpha;
    copy.tileCornerRadius     = self.tileCornerRadius;
    copy.shelfBannersHidden   = self.shelfBannersHidden;
    copy.isBypassMode         = self.isBypassMode;
    copy.defaultSoundtrackName = self.defaultSoundtrackName;
    return copy;
}

// ---------------------------------------------------------------------------
// Frutiger Aero
//   - white/gray semi-transparent glass overlay (no blue tint)
//   - shelf banners hidden
//   - 10pt corner radius on 288×154 tiles
//   - Frutiger Aero sky PNG as background
//   - Wii U Mii Editing as default soundtrack hint (user must supply file)
// ---------------------------------------------------------------------------
+ (instancetype)frutigerAeroTheme {
    ATLThemeConfig *cfg = [[ATLThemeConfig alloc] init];
    cfg.themeID              = ATLThemeIDFrutigerAero;
    cfg.displayName          = @"Frutiger Aero";
    cfg.backgroundImageName  = @"FrutigerAeroBackground.png";
    cfg.glassAlpha           = 0.28f;
    cfg.tileCornerRadius     = 10.0f;
    cfg.shelfBannersHidden   = YES;
    cfg.isBypassMode         = NO;
    // Wii U GamePad Mii Editing — user supplies the audio file; never bundled.
    cfg.defaultSoundtrackName = @"WiiU_MiiEditing";
    return cfg;
}

// ---------------------------------------------------------------------------
// Original Apple TV — pure bypass, nothing changed.
// ---------------------------------------------------------------------------
+ (instancetype)originalAppleTVTheme {
    ATLThemeConfig *cfg = [[ATLThemeConfig alloc] init];
    cfg.themeID       = ATLThemeIDOriginal;
    cfg.displayName   = @"Original Apple TV";
    cfg.isBypassMode  = YES;
    return cfg;
}

@end
