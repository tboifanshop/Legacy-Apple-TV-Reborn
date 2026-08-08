#import <Foundation/Foundation.h>

#ifndef ATLLog_h
#define ATLLog_h

#ifdef DEBUG
    #define ATLLogInfo(fmt, ...)  NSLog(@"[ATL] INFO: " fmt, ##__VA_ARGS__)
    #define ATLLogWarn(fmt, ...)  NSLog(@"[ATL] WARN: " fmt, ##__VA_ARGS__)
    #define ATLLogError(fmt, ...) NSLog(@"[ATL] ERROR: " fmt, ##__VA_ARGS__)
#else
    #define ATLLogInfo(fmt, ...)  do {} while(0)
    #define ATLLogWarn(fmt, ...)  do {} while(0)
    #define ATLLogError(fmt, ...) NSLog(@"[ATL] ERROR: " fmt, ##__VA_ARGS__)
#endif

#endif /* ATLLog_h */
