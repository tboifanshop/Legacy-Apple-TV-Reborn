#import "ATLFileBrowserService.h"
#import "../Utilities/ATLLog.h"

@implementation ATLFileBrowserService

+ (instancetype)sharedService {
    static ATLFileBrowserService *svc = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ svc = [[ATLFileBrowserService alloc] init]; });
    return svc;
}

- (void)listDirectory:(NSString *)path completion:(ATLFileBrowserCompletion)completion {
    if (!completion) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *err = nil;
        NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
        NSArray *full = nil;
        if (items) {
            NSMutableArray *m = [NSMutableArray arrayWithCapacity:items.count];
            for (NSString *name in items) {
                [m addObject:[path stringByAppendingPathComponent:name]];
            }
            full = [m copy];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(full, err); });
    });
}

- (BOOL)moveItemAtPath:(NSString *)src toPath:(NSString *)dst error:(NSError **)error {
    BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:src toPath:dst error:error];
    if (!ok) ATLLogError(@"ATLFileBrowserService: move failed %@→%@", src, dst);
    return ok;
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
    BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:path error:error];
    if (!ok) ATLLogError(@"ATLFileBrowserService: remove failed %@", path);
    return ok;
}

@end
