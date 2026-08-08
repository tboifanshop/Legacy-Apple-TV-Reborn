//  ATLRebornSettingsAppliance.m
//  Legacy Apple TV Reborn
//
//  Private API usage classification:
//    BRApplianceManager    — CONFIRMED (runtime class, ATL diagnostic data)
//    -appliances           — CONFIRMED (ATL diagnostic data)
//    -loadAppliances       — CONFIRMED (ATL diagnostic data)
//    BRApplianceInfo       — CONFIRMED (runtime class)
//    BRApplianceCategory   — CONFIRMED (runtime class)
//    All selector calls below are RUNTIME-CHECKED via respondsToSelector:.

#import "ATLRebornSettingsAppliance.h"
#import "../Utilities/ATLLog.h"
#import <objc/runtime.h>
#import <objc/message.h>

static BOOL ATLSettingsApplianceRegistered = NO;

// ---------------------------------------------------------------------------
// Reborn Settings menu controller
// Uses only UIKit — no BackRow dependency.
// ---------------------------------------------------------------------------

@interface ATLRebornSettingsMenuController : UITableViewController

@end

@implementation ATLRebornSettingsMenuController {
    NSArray *_sections;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Reborn Settings";
    _sections = @[@"Themes", @"Soundtrack", @"Screensaver", @"Sounds",
                  @"Accessibility", @"About"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)_sections.count;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"RebornCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"RebornCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = _sections[ip.row];
    return cell;
}

@end

// ---------------------------------------------------------------------------
@implementation ATLRebornSettingsAppliance

+ (void)registerIfPossible {
    if (ATLSettingsApplianceRegistered) return;

    // RUNTIME-CHECKED: BRApplianceManager must exist before we proceed.
    Class brMgr = NSClassFromString(@"BRApplianceManager");
    if (!brMgr) {
        ATLLogWarn(@"ATLRebornSettingsAppliance: BRApplianceManager not found — deferring");
        return;
    }

    // RUNTIME-CHECKED: Check -sharedInstance selector before calling.
    SEL sharedSel = NSSelectorFromString(@"sharedInstance");
    if (![brMgr respondsToSelector:sharedSel]) {
        ATLLogWarn(@"ATLRebornSettingsAppliance: BRApplianceManager has no +sharedInstance");
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id mgr = [brMgr performSelector:sharedSel];
#pragma clang diagnostic pop
    if (!mgr) {
        ATLLogWarn(@"ATLRebornSettingsAppliance: BRApplianceManager +sharedInstance returned nil");
        return;
    }

    // NOTE: -registerCustomAppliance:withKey: and its expected dictionary key names
    // are NOT yet confirmed by live runtime introspection.
    // Until on-device verification provides the correct key names, we do NOT call
    // this method to avoid silently registering a broken/invisible entry.
    // Reborn Settings is accessible via the Reborn overlay in the meantime.
    //
    // TODO: capture BRApplianceInfo ivar/property names from runtime report, then
    //       confirm keys before enabling the block below.
    //
    // SEL regSel = NSSelectorFromString(@"registerCustomAppliance:withKey:");
    // if ([mgr respondsToSelector:regSel]) { ... }

    ATLLogWarn(@"ATLRebornSettingsAppliance: appliance registration deferred "
               @"(BRApplianceManager key names not yet confirmed). "
               @"Settings accessible via Reborn overlay.");
    ATLSettingsApplianceRegistered = YES;
}

/// Called from anywhere in Reborn (e.g. overlay button) to present settings UI.
+ (void)presentFromViewController:(UIViewController *)presenter {
    if (!presenter) return;
    ATLRebornSettingsMenuController *vc = [[ATLRebornSettingsMenuController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [presenter presentViewController:nav animated:YES completion:nil];
}

@end
