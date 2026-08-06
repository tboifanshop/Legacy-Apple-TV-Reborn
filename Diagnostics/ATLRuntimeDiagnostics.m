#import "ATLRuntimeDiagnostics.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <mach-o/dyld.h>

#import "../Utilities/ATLLog.h"

static NSString *const ATLRuntimeDiagnosticsLogDir = @"/var/mobile/Library/Logs";
static NSString *const ATLRuntimeDiagnosticsReportPath = @"/var/mobile/Library/Logs/ATLRuntimeReport.txt";
static NSString *const ATLRuntimeDiagnosticsModuleVersion = @"2.0.0";

static const NSUInteger ATLNormalMethodLimitPerClass = 80;
static const NSUInteger ATLPriorityMethodLimitPerClass = 220;
static const NSUInteger ATLProtocolMethodLimit = 120;
static const NSUInteger ATLClassLimitPerPrefix = 120;

@implementation ATLRuntimeDiagnostics

+ (void)runOnceAfterLaunch {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            [self _generateRuntimeReport];
        }
    });
}

+ (void)_generateRuntimeReport {
    NSMutableString *report = [NSMutableString string];
    if (!report) {
        ATLLogError(@"Diagnostics: nie mozna utworzyc bufora raportu");
        return;
    }

    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *bundleID = [mainBundle bundleIdentifier] ?: @"(null)";
    NSString *executablePath = [mainBundle executablePath];
    if (executablePath.length == 0) {
        executablePath = [[processInfo arguments] firstObject] ?: @"(null)";
    }
    NSString *processName = [processInfo processName] ?: @"(null)";
    NSString *osVersion = [processInfo operatingSystemVersionString] ?: @"(null)";

    [report appendString:@"Legacy Apple TV Reborn Runtime Diagnostics\n"];
    [report appendString:@"========================================\n"];
    [report appendFormat:@"Diagnostics module version: %@\n", ATLRuntimeDiagnosticsModuleVersion];
    [report appendFormat:@"Timestamp: %@\n", [NSDate date]];
    [report appendFormat:@"Bundle identifier: %@\n", bundleID];
    [report appendFormat:@"Executable path: %@\n", executablePath];
    [report appendFormat:@"Process name: %@\n", processName];
    [report appendFormat:@"OS version: %@\n", osVersion];
    [report appendFormat:@"Limits: normal methods/class=%lu, priority methods/class=%lu, protocol methods/group=%lu, classes/prefix=%lu\n\n",
     (unsigned long)ATLNormalMethodLimitPerClass,
     (unsigned long)ATLPriorityMethodLimitPerClass,
     (unsigned long)ATLProtocolMethodLimit,
     (unsigned long)ATLClassLimitPerPrefix];

    [self _appendRequiredClassChecksToReport:report];
    [self _appendPriorityClassPresenceToReport:report];
    [self _appendDyldImageEnumerationToReport:report];
    [self _appendBundleEnumerationToReport:report];
    [self _appendRuntimeProtocolEnumerationToReport:report];
    [self _appendPrefixedClassDiagnosticsToReport:report];
    [self _appendPriorityClassDeepDiagnosticsToReport:report];
    [self _appendCriticalSelectorChecksToReport:report];

    NSError *dirError = nil;
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:ATLRuntimeDiagnosticsLogDir
                                              withIntermediateDirectories:YES
                                                               attributes:nil
                                                                    error:&dirError];
    if (!created) {
        ATLLogError(@"Diagnostics: nie mozna utworzyc katalogu logow %@ error=%@", ATLRuntimeDiagnosticsLogDir, dirError);
        return;
    }

    NSError *writeError = nil;
    BOOL written = [report writeToFile:ATLRuntimeDiagnosticsReportPath
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:&writeError];
    if (!written) {
        ATLLogError(@"Diagnostics: nie mozna zapisac raportu %@ error=%@", ATLRuntimeDiagnosticsReportPath, writeError);
        return;
    }

    ATLLogInfo(@"Diagnostics: raport zapisany do %@", ATLRuntimeDiagnosticsReportPath);
}

+ (void)_appendRequiredClassChecksToReport:(NSMutableString *)report {
    NSArray *requiredClasses = @[
        @"UIApplication",
        @"UIWindow",
        @"UIView",
        @"UILabel",
        @"UIImageView",
        @"UICollectionView",
        @"UITableView",
        @"AVPlayer",
        @"AVPlayerLayer",
        @"BRController",
        @"BRMenuController",
        @"BRControl",
        @"BRTextControl",
        @"BRImageControl",
        @"BRTableView",
        @"ATVNavigationBar",
        @"ATVTextEntryTextControl",
        @"MEYTController",
        @"MEYTControllerSectionHandler",
        @"RUIYTAuthenticationManager",
        @"RUIYTSearchController",
        @"RUIYTVideosDocument",
        @"RUIYTVideoPlaybackAspect"
    ];

    [report appendString:@"[0] Required Class Presence\n"];
    [report appendString:@"----------------------------------------\n"];

    for (NSString *className in requiredClasses) {
        if (![className isKindOfClass:[NSString class]] || className.length == 0) {
            continue;
        }

        Class cls = NSClassFromString(className);
        [report appendFormat:@"%@ : %@\n", className, cls ? @"FOUND" : @"MISSING"];
    }

    [report appendString:@"\n"];
}

+ (void)_appendPrefixedClassDiagnosticsToReport:(NSMutableString *)report {
    [report appendString:@"[4] Class Properties, Ivars, Protocols and Methods (Prefixed)\n"];
    [report appendString:@"----------------------------------------\n"];
    [report appendString:@"Prefixes: BR, ATV, RUI, RUIYT, MEYT, YT\n\n"];

    NSArray *prefixes = @[@"BR", @"ATV", @"RUI", @"RUIYT", @"MEYT", @"YT"];
    NSMutableDictionary *truncationInfo = [NSMutableDictionary dictionary];
    NSDictionary *classesByPrefix = [self _classesByPrefixForPrefixes:prefixes
                                                       limitPerPrefix:ATLClassLimitPerPrefix
                                                        truncationInfo:truncationInfo];

    for (NSString *prefix in prefixes) {
        NSArray *classes = classesByPrefix[prefix];
        if (![classes isKindOfClass:[NSArray class]]) {
            classes = @[];
        }

        NSDictionary *prefixInfo = truncationInfo[prefix];
        NSUInteger total = [[prefixInfo objectForKey:@"total"] unsignedIntegerValue];
        NSUInteger kept = [[prefixInfo objectForKey:@"kept"] unsignedIntegerValue];
        if (total == 0 && kept == 0) {
            total = classes.count;
            kept = classes.count;
        }

        [report appendFormat:@"Prefix %@: total=%lu kept=%lu\n", prefix, (unsigned long)total, (unsigned long)kept];
        if (kept < total) {
            [report appendFormat:@"TRUNCATED: Prefix %@ limited to %lu classes.\n", prefix, (unsigned long)kept];
        }

        for (NSString *className in classes) {
            [self _appendClassDetailsForName:className
                                    toReport:report
                         methodLimitInstance:ATLNormalMethodLimitPerClass
                            methodLimitClass:ATLNormalMethodLimitPerClass
                              includeFullTag:NO];
        }

        [report appendString:@"\n"];
    }
}

+ (void)_appendRuntimeProtocolEnumerationToReport:(NSMutableString *)report {
    [report appendString:@"[3] Objective-C Protocols (Prefixed)\n"];
    [report appendString:@"----------------------------------------\n"];
    [report appendString:@"Prefixes: BR, ATV, RUI, RUIYT, MEYT, YT\n\n"];

    unsigned int protocolCount = 0;
    Protocol *__unsafe_unretained *protocolList = objc_copyProtocolList(&protocolCount);
    if (protocolList == NULL || protocolCount == 0) {
        if (protocolList != NULL) {
            free(protocolList);
        }

        [report appendString:@"Protocols: 0\n\n"];
        return;
    }

    NSArray *prefixes = @[@"BR", @"ATV", @"RUI", @"RUIYT", @"MEYT", @"YT"];
    NSMutableArray *protocols = [NSMutableArray arrayWithCapacity:protocolCount];
    for (unsigned int i = 0; i < protocolCount; i++) {
        Protocol *protocol = protocolList[i];
        if (protocol == NULL) {
            continue;
        }

        const char *nameC = protocol_getName(protocol);
        if (nameC == NULL) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:nameC] ?: @"";
        if (name.length == 0) {
            continue;
        }

        if ([self _matchingPrefixForName:name prefixes:prefixes] != nil) {
            [protocols addObject:protocol];
        }
    }

    free(protocolList);

    [protocols sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Protocol *p1 = (Protocol *)obj1;
        Protocol *p2 = (Protocol *)obj2;
        const char *n1c = protocol_getName(p1);
        const char *n2c = protocol_getName(p2);
        NSString *n1 = (n1c != NULL) ? [NSString stringWithUTF8String:n1c] : @"";
        NSString *n2 = (n2c != NULL) ? [NSString stringWithUTF8String:n2c] : @"";
        return [n1 compare:n2];
    }];

    [report appendFormat:@"Protocols matched: %lu\n\n", (unsigned long)protocols.count];
    for (Protocol *protocol in protocols) {
        [self _appendProtocolDetails:protocol toReport:report methodLimit:ATLProtocolMethodLimit];
    }

    [report appendString:@"\n"];
}

+ (void)_appendBundleEnumerationToReport:(NSMutableString *)report {
    [report appendString:@"[2] Loaded Bundles and Frameworks\n"];
    [report appendString:@"----------------------------------------\n"];

    NSArray *allBundles = [NSBundle allBundles];
    NSArray *allFrameworks = [NSBundle allFrameworks];

    [report appendFormat:@"All bundles: %lu\n", (unsigned long)allBundles.count];
    for (NSBundle *bundle in allBundles) {
        if (![bundle isKindOfClass:[NSBundle class]]) {
            continue;
        }

        NSString *bundlePath = [bundle bundlePath] ?: @"(null)";
        NSString *bundleID = [bundle bundleIdentifier] ?: @"(null)";
        NSString *execPath = [bundle executablePath] ?: @"(null)";
        [report appendFormat:@"  - path=%@ | id=%@ | exec=%@\n", bundlePath, bundleID, execPath];
    }

    [report appendFormat:@"Framework bundles: %lu\n", (unsigned long)allFrameworks.count];
    for (NSBundle *bundle in allFrameworks) {
        if (![bundle isKindOfClass:[NSBundle class]]) {
            continue;
        }

        NSString *bundlePath = [bundle bundlePath] ?: @"(null)";
        NSString *bundleID = [bundle bundleIdentifier] ?: @"(null)";
        NSString *execPath = [bundle executablePath] ?: @"(null)";
        [report appendFormat:@"  - path=%@ | id=%@ | exec=%@\n", bundlePath, bundleID, execPath];
    }

    [report appendString:@"\n"];
}

+ (void)_appendDyldImageEnumerationToReport:(NSMutableString *)report {
    [report appendString:@"[1] Loaded dyld Images\n"];
    [report appendString:@"----------------------------------------\n"];

    NSArray *importantTokens = @[
        @"UIKit",
        @"AVFoundation",
        @"FrontBoard",
        @"FrontBoardServices",
        @"AppleTVServices",
        @"ITMLKit",
        @"JavaScriptCore",
        @"YouTubeATV",
        @"QuartzCore",
        @"CoreMedia",
        @"MediaToolbox"
    ];

    uint32_t imageCount = _dyld_image_count();
    [report appendFormat:@"Loaded images: %u\n", imageCount];

    for (uint32_t i = 0; i < imageCount; i++) {
        const char *imageName = _dyld_get_image_name(i);
        NSString *resolvedName = @"(null)";
        if (imageName != NULL) {
            NSString *candidate = [NSString stringWithUTF8String:imageName];
            if (candidate.length > 0) {
                resolvedName = candidate;
            }
        }

        NSMutableArray *hits = [NSMutableArray array];
        for (NSString *token in importantTokens) {
            if ([resolvedName rangeOfString:token options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [hits addObject:token];
            }
        }

        if (hits.count > 0) {
            [report appendFormat:@"  - [%u] [HIGHLIGHT %@] %@\n", i, [hits componentsJoinedByString:@","], resolvedName];
        } else {
            [report appendFormat:@"  - [%u] %@\n", i, resolvedName];
        }
    }

    [report appendString:@"\n"];
}

+ (void)_appendPriorityClassPresenceToReport:(NSMutableString *)report {
    [report appendString:@"[5] Priority Classes Presence\n"];
    [report appendString:@"----------------------------------------\n"];

    NSArray *priorityClasses = @[
        @"MEYTController",
        @"MEYTControllerSectionHandler",
        @"RUIYTSearchController",
        @"RUIYTAuthenticationManager",
        @"RUIYTVideosDocument",
        @"RUIYTVideoPlaybackAspect",
        @"BRController",
        @"BRMenuController",
        @"BRControl",
        @"ATVNavigationBar",
        @"UIApplication",
        @"UIWindow"
    ];

    for (NSString *className in priorityClasses) {
        Class cls = NSClassFromString(className);
        [report appendFormat:@"%@ : %@\n", className, cls ? @"FOUND" : @"MISSING"];
    }

    [report appendString:@"\n"];
}

+ (void)_appendPriorityClassDeepDiagnosticsToReport:(NSMutableString *)report {
    [report appendString:@"[6] Priority Classes Deep Diagnostics\n"];
    [report appendString:@"----------------------------------------\n"];

    NSArray *priorityClasses = @[
        @"MEYTController",
        @"MEYTControllerSectionHandler",
        @"RUIYTSearchController",
        @"RUIYTAuthenticationManager",
        @"RUIYTVideosDocument",
        @"RUIYTVideoPlaybackAspect",
        @"BRController",
        @"BRMenuController",
        @"BRControl",
        @"ATVNavigationBar",
        @"UIApplication",
        @"UIWindow"
    ];

    for (NSString *className in priorityClasses) {
        [self _appendClassDetailsForName:className
                                toReport:report
                     methodLimitInstance:ATLPriorityMethodLimitPerClass
                        methodLimitClass:ATLPriorityMethodLimitPerClass
                          includeFullTag:YES];
    }

    [report appendString:@"\n"];
}

+ (void)_appendCriticalSelectorChecksToReport:(NSMutableString *)report {
     [report appendString:@"[7] Critical Selector Checks (respondsToSelector)\n"];
     [report appendString:@"----------------------------------------\n"];

     NSArray *checks = @[
          @{ @"class": @"UIApplication",
              @"instance": @[ @"delegate", @"keyWindow", @"sendEvent:", @"applicationState" ],
              @"classMethods": @[ @"sharedApplication" ] },
          @{ @"class": @"UIWindow",
              @"instance": @[ @"rootViewController", @"setRootViewController:", @"addSubview:" ],
              @"classMethods": @[] },
          @{ @"class": @"BRController",
              @"instance": @[ @"loadView", @"setView:" ],
              @"classMethods": @[] },
          @{ @"class": @"BRMenuController",
              @"instance": @[ @"init" ],
              @"classMethods": @[] },
          @{ @"class": @"BRControl",
              @"instance": @[ @"setFrame:", @"setHidden:" ],
              @"classMethods": @[] },
          @{ @"class": @"ATVNavigationBar",
              @"instance": @[ @"setDelegate:", @"setTitle:" ],
              @"classMethods": @[] },
          @{ @"class": @"MEYTController",
              @"instance": @[ @"init", @"dealloc" ],
              @"classMethods": @[] },
          @{ @"class": @"RUIYTSearchController",
              @"instance": @[ @"init", @"setDelegate:" ],
              @"classMethods": @[] },
          @{ @"class": @"RUIYTAuthenticationManager",
              @"instance": @[ @"init" ],
              @"classMethods": @[] },
          @{ @"class": @"RUIYTVideosDocument",
              @"instance": @[ @"init" ],
              @"classMethods": @[] },
          @{ @"class": @"RUIYTVideoPlaybackAspect",
              @"instance": @[ @"setDelegate:" ],
              @"classMethods": @[] }
     ];

     for (NSDictionary *entry in checks) {
          NSString *className = entry[@"class"];
          if (![className isKindOfClass:[NSString class]] || className.length == 0) {
                continue;
          }

          Class cls = NSClassFromString(className);
          [report appendFormat:@"Class: %@ (%@)\n", className, cls ? @"FOUND" : @"MISSING"];

          NSArray *instanceSelectors = entry[@"instance"];
          if ([instanceSelectors isKindOfClass:[NSArray class]]) {
                for (NSString *selectorName in instanceSelectors) {
                     SEL selector = NSSelectorFromString(selectorName ?: @"");
                     BOOL responds = (cls != Nil && selector != NULL) ? [cls instancesRespondToSelector:selector] : NO;
                     [report appendFormat:@"  -[%@ %@] : %@\n", className, selectorName ?: @"(null)", responds ? @"YES" : @"NO"];
                }
          }

          NSArray *classSelectors = entry[@"classMethods"];
          if ([classSelectors isKindOfClass:[NSArray class]]) {
                id classObject = (cls != Nil) ? (id)cls : nil;
                for (NSString *selectorName in classSelectors) {
                     SEL selector = NSSelectorFromString(selectorName ?: @"");
                     BOOL responds = (classObject != nil && selector != NULL) ? [classObject respondsToSelector:selector] : NO;
                     [report appendFormat:@"  +[%@ %@] : %@\n", className, selectorName ?: @"(null)", responds ? @"YES" : @"NO"];
                }
          }

          [report appendString:@"\n"];
     }
}

+ (NSDictionary *)_classesByPrefixForPrefixes:(NSArray *)prefixes
                               limitPerPrefix:(NSUInteger)limitPerPrefix
                                truncationInfo:(NSMutableDictionary *)truncationInfo {
    if (![prefixes isKindOfClass:[NSArray class]] || prefixes.count == 0) {
        return @{};
    }

    NSMutableDictionary *collected = [NSMutableDictionary dictionaryWithCapacity:prefixes.count];
    for (NSString *prefix in prefixes) {
        collected[prefix] = [NSMutableArray array];
    }

    unsigned int classCount = 0;
    Class *classList = objc_copyClassList(&classCount);
    if (classList == NULL || classCount == 0) {
        if (classList != NULL) {
            free(classList);
        }
        return collected;
    }

    for (unsigned int i = 0; i < classCount; i++) {
        Class cls = classList[i];
        if (cls == Nil) {
            continue;
        }

        const char *nameC = class_getName(cls);
        if (nameC == NULL) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:nameC] ?: @"";
        if (name.length == 0) {
            continue;
        }

        NSString *prefix = [self _matchingPrefixForName:name prefixes:prefixes];
        if (prefix.length == 0) {
            continue;
        }

        NSMutableArray *array = collected[prefix];
        if (![array isKindOfClass:[NSMutableArray class]]) {
            continue;
        }

        [array addObject:name];
    }

    free(classList);

    NSMutableDictionary *finalResult = [NSMutableDictionary dictionaryWithCapacity:prefixes.count];
    for (NSString *prefix in prefixes) {
        NSArray *names = [collected[prefix] sortedArrayUsingSelector:@selector(compare:)];
        if (![names isKindOfClass:[NSArray class]]) {
            names = @[];
        }

        NSUInteger total = names.count;
        NSUInteger kept = MIN(total, limitPerPrefix);
        NSArray *limited = names;
        if (kept < total) {
            limited = [names subarrayWithRange:NSMakeRange(0, kept)];
        }

        finalResult[prefix] = limited ?: @[];
        if (truncationInfo != nil) {
            truncationInfo[prefix] = @{ @"total": @(total), @"kept": @(kept) };
        }
    }

    return finalResult;
}

+ (NSString *)_matchingPrefixForName:(NSString *)name prefixes:(NSArray *)prefixes {
    if (name.length == 0 || ![prefixes isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *sortedPrefixes = [prefixes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *p1 = (NSString *)obj1;
        NSString *p2 = (NSString *)obj2;
        if (p1.length > p2.length) {
            return NSOrderedAscending;
        }
        if (p1.length < p2.length) {
            return NSOrderedDescending;
        }
        return [p1 compare:p2];
    }];

    for (NSString *prefix in sortedPrefixes) {
        if ([name hasPrefix:prefix]) {
            return prefix;
        }
    }

    return nil;
}

+ (void)_appendClassDetailsForName:(NSString *)className
                          toReport:(NSMutableString *)report
               methodLimitInstance:(NSUInteger)methodLimitInstance
                  methodLimitClass:(NSUInteger)methodLimitClass
                    includeFullTag:(BOOL)includeFullTag {
    if (className.length == 0 || report == nil) {
        return;
    }

    Class cls = NSClassFromString(className);
    if (cls == Nil) {
        [report appendFormat:@"Class: %@\n", className];
        [report appendString:@"Superclass: (missing at runtime)\n"];
        [report appendString:@"Protocols count: 0\n"];
        [report appendString:@"Properties count: 0\n"];
        [report appendString:@"Ivars count: 0\n"];
        [report appendString:@"Instance methods count: 0\n"];
        [report appendString:@"Class methods count: 0\n"];
        [report appendString:@"----------------------------------------\n"];
        return;
    }

    NSString *superclassName = @"(none)";
    Class superCls = class_getSuperclass(cls);
    if (superCls != Nil) {
        const char *superC = class_getName(superCls);
        if (superC != NULL) {
            NSString *resolved = [NSString stringWithUTF8String:superC];
            if (resolved.length > 0) {
                superclassName = resolved;
            }
        }
    }

    BOOL instanceTruncated = NO;
    BOOL classTruncated = NO;
    NSArray *instanceMethods = [self _methodNamesForClass:cls
                                       includeClassMethods:NO
                                                     limit:methodLimitInstance
                                                 truncated:&instanceTruncated];
    NSArray *classMethods = [self _methodNamesForClass:cls
                                    includeClassMethods:YES
                                                  limit:methodLimitClass
                                              truncated:&classTruncated];
    NSArray *propertyNames = [self _propertyNamesForClass:cls];
    NSArray *ivarDescriptions = [self _ivarDescriptionsForClass:cls];
    NSArray *protocolNames = [self _protocolNamesForClass:cls];

    [report appendFormat:@"Class: %@%@\n", className, includeFullTag ? @" [PRIORITY]" : @""];
    [report appendFormat:@"Superclass: %@\n", superclassName];

    if (includeFullTag) {
        [report appendString:@"Superclass chain: "];
        [report appendString:[self _superclassChainForClass:cls]];
        [report appendString:@"\n"];
    }

    [report appendFormat:@"Protocols count: %lu\n", (unsigned long)protocolNames.count];
    for (NSString *protocolName in protocolNames) {
        [report appendFormat:@"  @protocol %@\n", protocolName];
    }

    [report appendFormat:@"Properties count: %lu\n", (unsigned long)propertyNames.count];
    for (NSString *propertyName in propertyNames) {
        [report appendFormat:@"  @property %@\n", propertyName];
    }

    [report appendFormat:@"Ivars count: %lu\n", (unsigned long)ivarDescriptions.count];
    for (NSString *ivarDescription in ivarDescriptions) {
        [report appendFormat:@"  ivar %@\n", ivarDescription];
    }

    [report appendFormat:@"Instance methods count: %lu\n", (unsigned long)instanceMethods.count];
    for (NSString *methodName in instanceMethods) {
        [report appendFormat:@"  - %@\n", methodName];
    }
    if (instanceTruncated) {
        [report appendFormat:@"  TRUNCATED: instance methods limited to %lu\n", (unsigned long)methodLimitInstance];
    }

    [report appendFormat:@"Class methods count: %lu\n", (unsigned long)classMethods.count];
    for (NSString *methodName in classMethods) {
        [report appendFormat:@"  + %@\n", methodName];
    }
    if (classTruncated) {
        [report appendFormat:@"  TRUNCATED: class methods limited to %lu\n", (unsigned long)methodLimitClass];
    }

    [report appendString:@"----------------------------------------\n"];
}

+ (NSString *)_superclassChainForClass:(Class)cls {
    if (cls == Nil) {
        return @"(none)";
    }

    NSMutableArray *chain = [NSMutableArray array];
    Class cursor = cls;
    while (cursor != Nil) {
        const char *nameC = class_getName(cursor);
        NSString *name = (nameC != NULL) ? [NSString stringWithUTF8String:nameC] : nil;
        if (name.length == 0) {
            break;
        }

        [chain addObject:name];
        cursor = class_getSuperclass(cursor);
    }

    if (chain.count == 0) {
        return @"(none)";
    }

    return [chain componentsJoinedByString:@" -> "];
}

+ (NSArray *)_methodNamesForClass:(Class)cls
               includeClassMethods:(BOOL)includeClassMethods
                             limit:(NSUInteger)limit
                         truncated:(BOOL *)truncated {
    if (truncated != NULL) {
        *truncated = NO;
    }

    if (cls == Nil) {
        return @[];
    }

    Class target = cls;
    if (includeClassMethods) {
        target = object_getClass((id)cls);
    }

    if (target == Nil) {
        return @[];
    }

    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(target, &methodCount);
    if (methods == NULL || methodCount == 0) {
        if (methods != NULL) {
            free(methods);
        }
        return @[];
    }

    NSMutableArray *names = [NSMutableArray arrayWithCapacity:methodCount];
    for (unsigned int i = 0; i < methodCount; i++) {
        Method m = methods[i];
        if (m == NULL) {
            continue;
        }

        SEL sel = method_getName(m);
        if (sel == NULL) {
            continue;
        }

        const char *selName = sel_getName(sel);
        if (selName == NULL) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:selName];
        if (name.length > 0) {
            [names addObject:name];
        }
    }

    free(methods);
    [names sortUsingSelector:@selector(compare:)];

    if (limit > 0 && names.count > limit) {
        if (truncated != NULL) {
            *truncated = YES;
        }

        return [names subarrayWithRange:NSMakeRange(0, limit)];
    }

    return names;
}

+ (NSArray *)_propertyNamesForClass:(Class)cls {
    if (cls == Nil) {
        return @[];
    }

    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    if (properties == NULL || propertyCount == 0) {
        if (properties != NULL) {
            free(properties);
        }
        return @[];
    }

    NSMutableArray *names = [NSMutableArray arrayWithCapacity:propertyCount];
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        if (property == NULL) {
            continue;
        }

        const char *nameC = property_getName(property);
        const char *attributesC = property_getAttributes(property);
        if (nameC == NULL) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:nameC] ?: @"";
        NSString *attributes = @"";
        if (attributesC != NULL) {
            NSString *tmp = [NSString stringWithUTF8String:attributesC];
            if (tmp.length > 0) {
                attributes = tmp;
            }
        }

        if (name.length > 0) {
            if (attributes.length > 0) {
                [names addObject:[NSString stringWithFormat:@"%@ (%@)", name, attributes]];
            } else {
                [names addObject:name];
            }
        }
    }

    free(properties);
    [names sortUsingSelector:@selector(compare:)];
    return names;
}

+ (NSArray *)_ivarDescriptionsForClass:(Class)cls {
    if (cls == Nil) {
        return @[];
    }

    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    if (ivars == NULL || ivarCount == 0) {
        if (ivars != NULL) {
            free(ivars);
        }
        return @[];
    }

    NSMutableArray *descriptions = [NSMutableArray arrayWithCapacity:ivarCount];
    for (unsigned int i = 0; i < ivarCount; i++) {
        Ivar ivar = ivars[i];
        if (ivar == NULL) {
            continue;
        }

        const char *nameC = ivar_getName(ivar);
        const char *typeC = ivar_getTypeEncoding(ivar);
        if (nameC == NULL) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:nameC] ?: @"";
        NSString *type = @"";
        if (typeC != NULL) {
            NSString *tmp = [NSString stringWithUTF8String:typeC];
            if (tmp.length > 0) {
                type = tmp;
            }
        }

        if (name.length > 0) {
            if (type.length > 0) {
                ptrdiff_t offset = ivar_getOffset(ivar);
                [descriptions addObject:[NSString stringWithFormat:@"%@ : %@ (offset=%td)", name, type, offset]];
            } else {
                ptrdiff_t offset = ivar_getOffset(ivar);
                [descriptions addObject:[NSString stringWithFormat:@"%@ (offset=%td)", name, offset]];
            }
        }
    }

    free(ivars);
    [descriptions sortUsingSelector:@selector(compare:)];
    return descriptions;
}

+ (NSArray *)_protocolNamesForClass:(Class)cls {
    if (cls == Nil) {
        return @[];
    }

    unsigned int protocolCount = 0;
    Protocol *__unsafe_unretained *protocols = class_copyProtocolList(cls, &protocolCount);
    if (protocols == NULL || protocolCount == 0) {
        if (protocols != NULL) {
            free(protocols);
        }
        return @[];
    }

    NSMutableArray *names = [NSMutableArray arrayWithCapacity:protocolCount];
    for (unsigned int i = 0; i < protocolCount; i++) {
        Protocol *protocol = protocols[i];
        if (protocol == NULL) {
            continue;
        }

        const char *nameC = protocol_getName(protocol);
        if (nameC == NULL) {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:nameC];
        if (name.length > 0) {
            [names addObject:name];
        }
    }

    free(protocols);
    [names sortUsingSelector:@selector(compare:)];
    return names;
}

+ (void)_appendProtocolDetails:(Protocol *)protocol
                      toReport:(NSMutableString *)report
                   methodLimit:(NSUInteger)methodLimit {
    if (protocol == NULL || report == nil) {
        return;
    }

    const char *nameC = protocol_getName(protocol);
    NSString *name = (nameC != NULL) ? [NSString stringWithUTF8String:nameC] : @"";
    if (name.length == 0) {
        return;
    }

    [report appendFormat:@"Protocol: %@\n", name];

    unsigned int inheritedCount = 0;
    Protocol *__unsafe_unretained *inherited = protocol_copyProtocolList(protocol, &inheritedCount);
    if (inherited != NULL && inheritedCount > 0) {
        [report appendFormat:@"Inherited protocols count: %u\n", inheritedCount];
        for (unsigned int i = 0; i < inheritedCount; i++) {
            Protocol *p = inherited[i];
            if (p == NULL) {
                continue;
            }

            const char *pc = protocol_getName(p);
            if (pc == NULL) {
                continue;
            }

            NSString *pname = [NSString stringWithUTF8String:pc];
            if (pname.length > 0) {
                [report appendFormat:@"  inherits %@\n", pname];
            }
        }
    } else {
        [report appendString:@"Inherited protocols count: 0\n"];
    }
    if (inherited != NULL) {
        free(inherited);
    }

    [self _appendProtocolMethodGroupToReport:report
                                     protocol:protocol
                                     required:YES
                              instanceMethods:YES
                                        label:@"Required instance methods"
                                        limit:methodLimit];

    [self _appendProtocolMethodGroupToReport:report
                                     protocol:protocol
                                     required:NO
                              instanceMethods:YES
                                        label:@"Optional instance methods"
                                        limit:methodLimit];

    [self _appendProtocolMethodGroupToReport:report
                                     protocol:protocol
                                     required:YES
                              instanceMethods:NO
                                        label:@"Required class methods"
                                        limit:methodLimit];

    [self _appendProtocolMethodGroupToReport:report
                                     protocol:protocol
                                     required:NO
                              instanceMethods:NO
                                        label:@"Optional class methods"
                                        limit:methodLimit];

    [report appendString:@"----------------------------------------\n"];
}

+ (void)_appendProtocolMethodGroupToReport:(NSMutableString *)report
                                   protocol:(Protocol *)protocol
                                   required:(BOOL)required
                            instanceMethods:(BOOL)instanceMethods
                                      label:(NSString *)label
                                      limit:(NSUInteger)limit {
    if (report == nil || protocol == NULL || label.length == 0) {
        return;
    }

    unsigned int count = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, required, instanceMethods, &count);
    if (methods == NULL || count == 0) {
        if (methods != NULL) {
            free(methods);
        }
        [report appendFormat:@"%@: 0\n", label];
        return;
    }

    NSMutableArray *descriptions = [NSMutableArray arrayWithCapacity:count];
    for (unsigned int i = 0; i < count; i++) {
        SEL sel = methods[i].name;
        if (sel == NULL) {
            continue;
        }

        const char *selC = sel_getName(sel);
        if (selC == NULL) {
            continue;
        }

        NSString *selName = [NSString stringWithUTF8String:selC] ?: @"";
        if (selName.length == 0) {
            continue;
        }

        NSString *types = @"";
        if (methods[i].types != NULL) {
            NSString *tmp = [NSString stringWithUTF8String:methods[i].types];
            if (tmp.length > 0) {
                types = tmp;
            }
        }

        if (types.length > 0) {
            [descriptions addObject:[NSString stringWithFormat:@"%@ (%@)", selName, types]];
        } else {
            [descriptions addObject:selName];
        }
    }

    free(methods);
    [descriptions sortUsingSelector:@selector(compare:)];

    BOOL truncated = NO;
    NSArray *finalMethods = descriptions;
    if (limit > 0 && descriptions.count > limit) {
        truncated = YES;
        finalMethods = [descriptions subarrayWithRange:NSMakeRange(0, limit)];
    }

    [report appendFormat:@"%@: %lu\n", label, (unsigned long)finalMethods.count];
    for (NSString *entry in finalMethods) {
        [report appendFormat:@"  - %@\n", entry];
    }

    if (truncated) {
        [report appendFormat:@"  TRUNCATED: %@ limited to %lu\n", label, (unsigned long)limit];
    }
}

@end
