//  ATLThemeConfig.h
//  Legacy Apple TV Reborn
//
//  Describes a theme's visual parameters.
//  Frutiger Aero ships with shelfBannersHidden = YES and white/gray glass only.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// --- Theme identifiers (always present) ---
extern NSString *const ATLThemeIDOriginal;      // bypass / stock Apple TV
extern NSString *const ATLThemeIDFrutigerAero;  // Frutiger Aero production theme

@interface ATLThemeConfig : NSObject <NSCopying>

/// Unique identifier for the theme.
@property (nonatomic, copy) NSString *themeID;

/// Human-readable display name.
@property (nonatomic, copy) NSString *displayName;

/// Name of a prerendered PNG background inside Resources/Themes/<themeID>/.
/// Nil means use the system default background.
@property (nonatomic, copy, nullable) NSString *backgroundImageName;

/// Glass overlay alpha (0.0 – 1.0).  Applied as white semi-transparent layer.
/// Set to 0 to disable glass entirely.
@property (nonatomic, assign) CGFloat glassAlpha;

/// Corner radius applied to each standard 288×154 px app tile (pt).
@property (nonatomic, assign) CGFloat tileCornerRadius;

/// When YES, shelf/top-shelf banners (1920×440) are hidden.
@property (nonatomic, assign) BOOL shelfBannersHidden;

/// When YES all Reborn visual hooks are disabled — pure stock experience.
@property (nonatomic, assign) BOOL isBypassMode;

/// Default soundtrack name to auto-load (may be nil; user can override).
@property (nonatomic, copy, nullable) NSString *defaultSoundtrackName;

// --- Factories ---
+ (instancetype)originalAppleTVTheme;
+ (instancetype)frutigerAeroTheme;

@end
