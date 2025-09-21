#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <stdio.h>

static NSString *const kPresetXDR1600 = @"Apple XDR Display (P3-1600 nits)";
static NSString *const kPresetApple500 = @"Apple Display (P3-500 nits)";

static BOOL match(NSString *s, NSString *needle) {
    if (!needle.length) return YES;
    if (!s.length) return NO;
    return [s rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static id findPresetByExactName(NSArray *presets, NSString *name) {
    for (id p in presets) {
        NSString *pn = [p valueForKey:@"presetName"];
        if ([pn isKindOfClass:[NSString class]] && [pn isEqualToString:name]) return p;
    }
    return nil;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Load the private framework at runtime (no headers/modules needed)
        void *h = dlopen("/System/Library/PrivateFrameworks/MonitorPanel.framework/MonitorPanel", RTLD_LAZY);
        if (!h) { fprintf(stderr, "Failed to load MonitorPanel.framework: %s\n", dlerror()); return 1; }

        Class MPDisplayMgr = NSClassFromString(@"MPDisplayMgr");
        if (!MPDisplayMgr) { fprintf(stderr, "MPDisplayMgr class not found.\n"); return 2; }

        NSString *filter = (argc > 1) ? [NSString stringWithUTF8String:argv[1]] : nil;

        id mgr = [MPDisplayMgr new];
        NSArray *displays = [mgr valueForKey:@"displays"];
        if (![displays isKindOfClass:[NSArray class]] || displays.count == 0) {
            fprintf(stderr, "No displays found.\n");
            return 3;
        }

        BOOL acted = NO;
        for (id d in displays) {
            NSString *name = [d valueForKey:@"displayName"] ?: @"(Unnamed Display)";
            if (!match(name, filter ?: @"")) continue;

            NSNumber *hasPresets = [d valueForKey:@"hasPresets"];
            if (![hasPresets boolValue]) {
                printf("Display: %s — no presets available.\n", name.UTF8String);
                continue;
            }

            NSArray *presets = [d valueForKey:@"presets"];
            id activePreset = [d valueForKey:@"activePreset"];
            NSString *activeName = [activePreset valueForKey:@"presetName"] ?: @"";

            printf("Display: %s\n", name.UTF8String);
            printf("  Current preset: %s\n", activeName.UTF8String);

            // Decide target
            NSString *targetName = nil;
            if ([activeName isEqualToString:kPresetXDR1600]) {
                targetName = kPresetApple500;
            } else if ([activeName isEqualToString:kPresetApple500]) {
                targetName = kPresetXDR1600;
            } else {
                printf("  Not one of the two target presets; no change made.\n\n");
                continue;
            }

            id targetPreset = findPresetByExactName(presets, targetName);
            if (!targetPreset) {
                printf("  Target preset \"%s\" not found on this display; no change made.\n\n", targetName.UTF8String);
                continue;
            }

            // Apply (invokes underlying setActivePreset:)
            [d setValue:targetPreset forKey:@"activePreset"];

            // Verify
            usleep(300000);
            NSString *confirmed = [[d valueForKey:@"activePreset"] valueForKey:@"presetName"] ?: @"";
            if ([confirmed isEqualToString:targetName]) {
                printf("  Switched to: %s\n\n", confirmed.UTF8String);
                acted = YES;
            } else {
                printf("  Warning: preset change not confirmed (still \"%s\").\n\n", confirmed.UTF8String);
            }
        }

        if (!acted && filter.length > 0) {
            fprintf(stderr, "No matching display acted upon for filter \"%s\".\n", filter.UTF8String);
            return 4;
        }
    }
    return 0;
}
