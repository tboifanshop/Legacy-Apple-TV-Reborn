//  ATLSafeMode.h
//  Legacy Apple TV Reborn
//
//  Safe-mode / disable-file check.
//  If /var/mobile/Library/Preferences/com.legacyappletvreborn.disable-theme
//  exists, Reborn loads in bypass mode (stock Apple TV, no theme hooks).
//
//  Recovery is also always possible via SSH by removing:
//  /Library/MobileSubstrate/DynamicLibraries/AppleTVLauncher.plist

#import <Foundation/Foundation.h>

extern NSString *const ATLSafeModeDisableFilePath;

/// Returns YES if Reborn should run in safe / bypass mode.
/// Result is cached after the first call.
BOOL ATLSafeModeIsActive(void);
