//  ATLSafeMode.m
//  Legacy Apple TV Reborn

#import "ATLSafeMode.h"
#import "../Utilities/ATLLog.h"

NSString *const ATLSafeModeDisableFilePath =
    @"/var/mobile/Library/Preferences/com.legacyappletvreborn.disable-theme";

BOOL ATLSafeModeIsActive(void) {
    static BOOL active = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        active = [[NSFileManager defaultManager] fileExistsAtPath:ATLSafeModeDisableFilePath];
        if (active) {
            ATLLogError(@"[ATL] Safe mode active — disable-theme file found. All theme hooks skipped.");
        }
    });
    return active;
}
