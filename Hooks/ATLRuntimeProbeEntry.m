#import <Foundation/Foundation.h>

#import "../Diagnostics/ATLRuntimeDiagnostics.h"

__attribute__((constructor)) static void ATLRuntimeProbeEntryPoint(void) {
    @autoreleasepool {
        NSString *processName = [[NSProcessInfo processInfo] processName];
        if (![processName isEqualToString:@"AppleTV"]) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [ATLRuntimeDiagnostics runOnceAfterLaunch];
        });
    }
}