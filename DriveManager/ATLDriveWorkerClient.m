#import "ATLDriveWorkerClient.h"
#import "../Utilities/ATLLog.h"

// Worker endpoint — override via settings if needed.
static NSString *const ATLWorkerBaseURL = @"https://atv-worker.tboifanshop.workers.dev";

@interface ATLDriveWorkerClient ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation ATLDriveWorkerClient

+ (instancetype)sharedClient {
    static ATLDriveWorkerClient *client = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ client = [[ATLDriveWorkerClient alloc] init]; });
    return client;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.timeoutIntervalForRequest = 30.0;
        _session = [NSURLSession sessionWithConfiguration:cfg];
    }
    return self;
}

- (void)fetchFileAtPath:(NSString *)remotePath completion:(ATLDriveCompletionBlock)completion {
    if (!remotePath || !completion) return;
    NSString *urlStr = [ATLWorkerBaseURL stringByAppendingPathComponent:remotePath];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) { completion(nil, [NSError errorWithDomain:@"ATLDrive" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}]); return; }
    NSURLSessionDataTask *task = [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        NSInteger status = [resp isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)resp statusCode] : -1;
        ATLLogInfo(@"ATLDriveWorkerClient: fetch %@ status=%ld", remotePath, (long)status);
        // Only pass data to the caller on HTTP 2xx; otherwise surface an error.
        NSError *callbackError = err;
        NSData  *callbackData  = data;
        if (!callbackError && (status < 200 || status > 299)) {
            callbackError = [NSError errorWithDomain:@"ATLDrive" code:status
                userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)status]}];
            callbackData = nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(callbackData, callbackError); });
    }];
    [task resume];
}

- (void)uploadData:(NSData *)data toPath:(NSString *)remotePath completion:(ATLDriveCompletionBlock)completion {
    if (!data || !remotePath || !completion) return;
    NSString *urlStr = [ATLWorkerBaseURL stringByAppendingPathComponent:remotePath];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) { completion(nil, [NSError errorWithDomain:@"ATLDrive" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}]); return; }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"PUT";
    req.HTTPBody   = data;
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:req completionHandler:^(NSData *rdata, NSURLResponse *resp, NSError *err) {
        NSInteger status = [resp isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)resp statusCode] : -1;
        ATLLogInfo(@"ATLDriveWorkerClient: upload %@ status=%ld", remotePath, (long)status);
        dispatch_async(dispatch_get_main_queue(), ^{ completion(rdata, err); });
    }];
    [task resume];
}

@end
