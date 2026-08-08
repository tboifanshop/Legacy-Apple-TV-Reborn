#import <Foundation/Foundation.h>

typedef void(^ATLFileBrowserCompletion)(NSArray<NSString *> * _Nullable paths, NSError * _Nullable error);

@interface ATLFileBrowserService : NSObject

+ (instancetype)sharedService;

- (void)listDirectory:(NSString *)path completion:(ATLFileBrowserCompletion)completion;
- (BOOL)moveItemAtPath:(NSString *)src toPath:(NSString *)dst error:(NSError **)error;
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;

@end
