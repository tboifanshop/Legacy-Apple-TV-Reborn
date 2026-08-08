#import "ATLSettingsStore.h"
#import "../Utilities/ATLLog.h"

static NSString *const ATLSettingsPath = @"/var/mobile/Library/Preferences/com.tboifanshop.atv-reborn.plist";

@interface ATLSettingsStore ()
@property (nonatomic, strong) NSMutableDictionary *store;
@end

@implementation ATLSettingsStore

+ (instancetype)sharedStore {
    static ATLSettingsStore *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[ATLSettingsStore alloc] init]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *loaded = [NSDictionary dictionaryWithContentsOfFile:ATLSettingsPath];
        _store = loaded ? [loaded mutableCopy] : [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)objectForKey:(NSString *)key { return key ? self.store[key] : nil; }

- (void)setObject:(id)object forKey:(NSString *)key {
    if (!key) return;
    if (object) self.store[key] = object; else [self.store removeObjectForKey:key];
}

- (BOOL)boolForKey:(NSString *)key {
    return [[self objectForKey:key] boolValue];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)synchronize {
    NSError *err = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.store
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&err];
    if (err) { ATLLogError(@"ATLSettingsStore: serialize error %@", err); return; }
    if (![data writeToFile:ATLSettingsPath atomically:YES]) {
        ATLLogError(@"ATLSettingsStore: write failed to %@", ATLSettingsPath);
    }
}

@end
