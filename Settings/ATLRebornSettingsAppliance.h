//  ATLRebornSettingsAppliance.h
//  Legacy Apple TV Reborn
//
//  Inserts a "Reborn Settings" icon into the Apple TV main menu.
//
//  Implementation notes:
//    - BRApplianceManager — CONFIRMED runtime class.
//    - All private selectors are guarded with respondsToSelector: before call.
//    - Never hard-links BackRow.framework or ApplianceKit.framework.
//    - Uses NSClassFromString + objc_msgSend pattern for private classes.
//
//  The Reborn Settings appliance provides at minimum:
//    Themes / Soundtrack / Screensaver / Sounds / Accessibility / About

#import <Foundation/Foundation.h>

@interface ATLRebornSettingsAppliance : NSObject

/// Attempt to register the Reborn Settings entry with BRApplianceManager.
/// Safe to call multiple times — guards internally.
+ (void)registerIfPossible;

@end
