#import <Foundation/Foundation.h>

typedef void(^ATLDriveCompletionBlock)(NSData * _Nullable data, NSError * _Nullable error);

@interface ATLDriveWorkerClient : NSObject

+ (instancetype)sharedClient;

- (void)fetchFileAtPath:(NSString *)remotePath completion:(ATLDriveCompletionBlock)completion;
- (void)uploadData:(NSData *)data toPath:(NSString *)remotePath completion:(ATLDriveCompletionBlock)completion;

@end
