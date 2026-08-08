#import <Foundation/Foundation.h>

@interface ATLSettingsStore : NSObject

+ (instancetype)sharedStore;

- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)synchronize;

@end
