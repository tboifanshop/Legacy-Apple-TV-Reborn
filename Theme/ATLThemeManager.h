//  ATLThemeManager.h
//  Legacy Apple TV Reborn
//
//  Central controller for the active theme.
//  Reads persisted theme selection from ATLSettingsStore,
//  exposes the active ATLThemeConfig, and notifies observers on change.

#import <Foundation/Foundation.h>
#import "ATLThemeConfig.h"

extern NSString *const ATLThemeManagerDidChangeThemeNotification;

@interface ATLThemeManager : NSObject

+ (instancetype)sharedManager;

/// The currently active theme configuration.
@property (nonatomic, strong, readonly) ATLThemeConfig *activeTheme;

/// All available themes in display order.
@property (nonatomic, strong, readonly) NSArray<ATLThemeConfig *> *availableThemes;

/// Switch to the theme with the given themeID.  Posts ATLThemeManagerDidChangeThemeNotification.
- (void)activateThemeWithID:(NSString *)themeID;

/// Full filesystem path to a resource inside the active theme bundle.
/// Returns nil if the file does not exist.
- (nullable NSString *)pathForThemeResource:(NSString *)filename;

@end
