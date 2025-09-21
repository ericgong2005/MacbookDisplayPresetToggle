#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <stdio.h>

static BOOL strMatch(NSString *s, NSString *needle) {
    if (!needle.length) return YES;
    if (!s.length) return NO;
    return [s rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Load the private framework (weak linking also works; dlopen makes the failure explicit)
        void *h = dlopen("/System/Library/PrivateFrameworks/MonitorPanel.framework/MonitorPanel", RTLD_LAZY);
        if (!h) {
            fprintf(stderr, "Failed to load MonitorPanel.framework: %s\n", dlerror());
            return 1;
        }

        Class MPDisplayMgr = NSClassFromString(@"MPDisplayMgr");
        if (!MPDisplayMgr) {
            fprintf(stderr, "MPDisplayMgr class not found. Your macOS may not expose this private API.\n");
            return 2;
        }

        NSString *filter = nil;
        if (argc > 1) filter = [NSString stringWithUTF8String:argv[1]];

        id mgr = [MPDisplayMgr new];
        NSArray *displays = [mgr valueForKey:@"displays"];
        if (![displays isKindOfClass:[NSArray class]] || displays.count == 0) {
            fprintf(stderr, "No displays found.\n");
            return 3;
        }

        BOOL anyPrinted = NO;
        for (id d in displays) {
            NSString *name = [d valueForKey:@"displayName"]; // NSString*
            if (!strMatch(name ?: @"", filter ?: @"")) continue;

            anyPrinted = YES;
            printf("Display: %s\n", (name ?: @"(Unnamed Display)").UTF8String);

            NSNumber *hasPresets = [d valueForKey:@"hasPresets"]; // NSNumber*
            if (![hasPresets boolValue]) {
                printf("  (no presets)\n\n");
                continue;
            }

            NSArray *presets = [d valueForKey:@"presets"];       // [MPDisplayPreset]
            id activePreset = [d valueForKey:@"activePreset"];   // MPDisplayPreset*
            NSString *activeName = [activePreset valueForKey:@"presetName"] ?: @"";

            for (id p in presets) {
                NSString *pn = [p valueForKey:@"presetName"] ?: @"(unnamed preset)";
                printf("  - %s%s\n", pn.UTF8String, [pn isEqualToString:activeName] ? " *" : "");
            }
            printf("\n");
        }

        if (!anyPrinted && filter.length > 0) {
            fprintf(stderr, "No display matched \"%s\".\n", filter.UTF8String);
            return 4;
        }
    }
    return 0;
}
