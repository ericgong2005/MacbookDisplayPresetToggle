// toggle_preset_hotkey_hud.m
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>
#import <stdio.h>

// --- Presets to toggle ---
static NSString *const kPresetXDR1600 = @"Apple XDR Display (P3-1600 nits)";
static NSString *const kPresetApple500 = @"Apple Display (P3-500 nits)";

static NSString *gDisplayFilter = nil;

// ---------- HUD ----------
static void ShowHUD(NSString *title, NSString *subtitle) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSScreen *screen = [NSScreen mainScreen] ?: NSScreen.screens.firstObject;
        if (!screen) return;

        const CGFloat width = 300, height = 100, radius = 16;
        NSRect vf = screen.visibleFrame;
        NSRect rect = NSMakeRect(NSMidX(vf) - width/2.0,
                                 NSMidY(vf) - height/2.0,
                                 width, height);

        NSWindow *win = [[NSWindow alloc] initWithContentRect:rect
                                                    styleMask:NSWindowStyleMaskBorderless
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        win.opaque = NO;
        win.backgroundColor = [NSColor clearColor];
        win.level = NSScreenSaverWindowLevel;
        win.ignoresMouseEvents = YES;
        win.hasShadow = NO;

        NSView *container = [[NSView alloc] initWithFrame:win.contentView.bounds];
        container.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        container.wantsLayer = YES;
        container.layer.shadowOpacity = 0.25;
        container.layer.shadowRadius  = 8.0;
        container.layer.shadowOffset  = CGSizeMake(0, -1);
        [win.contentView addSubview:container];

        NSView *card = [[NSView alloc] initWithFrame:container.bounds];
        card.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        card.wantsLayer = YES;
        card.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;
        card.layer.cornerRadius = radius;
        card.layer.masksToBounds = YES;
        if ([card.layer respondsToSelector:@selector(setCornerCurve:)]) {
            card.layer.cornerCurve = kCACornerCurveContinuous;
        }
        [container addSubview:card];

        // Title (regular system font)
        NSTextField *titleLbl = [[NSTextField alloc] initWithFrame:NSMakeRect(20, height-52, width-40, 26)];
        titleLbl.bezeled = NO; titleLbl.drawsBackground = NO; titleLbl.editable = NO; titleLbl.selectable = NO;
        titleLbl.font = [NSFont systemFontOfSize:18];
        titleLbl.textColor = [NSColor labelColor];
        titleLbl.alignment = NSTextAlignmentCenter;
        titleLbl.stringValue = title ?: @"Preset changed";

        // Subtitle (regular system font)
        NSTextField *subLbl = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 24, width-40, 22)];
        subLbl.bezeled = NO; subLbl.drawsBackground = NO; subLbl.editable = NO; subLbl.selectable = NO;
        subLbl.font = [NSFont systemFontOfSize:14];
        subLbl.textColor = [NSColor secondaryLabelColor];
        subLbl.alignment = NSTextAlignmentCenter;
        subLbl.stringValue = subtitle ?: @"";

        [card addSubview:titleLbl];
        [card addSubview:subLbl];

        [win makeKeyAndOrderFront:nil];
        win.alphaValue = 0.0;

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
            ctx.duration = 0.15;
            [[win animator] setAlphaValue:1.0];
        } completionHandler:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
                    ctx.duration = 0.2;
                    [[win animator] setAlphaValue:0.0];
                } completionHandler:^{
                    [win orderOut:nil];
                }];
            });
        }];
    });
}

// ---------- Helpers ----------
static BOOL Match(NSString *s, NSString *needle) {
    if (!needle.length) return YES;
    if (!s.length) return NO;
    return [s rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static id FindPresetByExactName(NSArray *presets, NSString *name) {
    for (id p in presets) {
        NSString *pn = [p valueForKey:@"presetName"];
        if ([pn isKindOfClass:[NSString class]] && [pn isEqualToString:name]) return p;
    }
    return nil;
}

// ---------- Toggle ----------
static NSString * TogglePresetOnce(void) {
    void *h = dlopen("/System/Library/PrivateFrameworks/MonitorPanel.framework/MonitorPanel", RTLD_LAZY);
    if (!h) { fprintf(stderr, "dlopen MonitorPanel failed: %s\n", dlerror()); return nil; }

    Class MPDisplayMgr = NSClassFromString(@"MPDisplayMgr");
    if (!MPDisplayMgr) { fprintf(stderr, "MPDisplayMgr class not found.\n"); return nil; }

    id mgr = [MPDisplayMgr new];
    NSArray *displays = [mgr valueForKey:@"displays"];
    if (![displays isKindOfClass:[NSArray class]] || displays.count == 0) return nil;

    for (id d in displays) {
        NSString *name = [d valueForKey:@"displayName"] ?: @"(Unnamed Display)";
        if (!Match(name, gDisplayFilter ?: @"")) continue;
        if (![[d valueForKey:@"hasPresets"] boolValue]) continue;

        NSArray *presets = [d valueForKey:@"presets"];
        NSString *activeName = [[d valueForKey:@"activePreset"] valueForKey:@"presetName"] ?: @"";

        NSString *targetName = nil;
        if ([activeName isEqualToString:kPresetXDR1600]) {
            targetName = kPresetApple500;
        } else if ([activeName isEqualToString:kPresetApple500]) {
            targetName = kPresetXDR1600;
        } else {
            continue;
        }

        id targetPreset = FindPresetByExactName(presets, targetName);
        if (!targetPreset) continue;

        [d setValue:targetPreset forKey:@"activePreset"];
        usleep(250000);

        NSString *confirmed = [[d valueForKey:@"activePreset"] valueForKey:@"presetName"] ?: @"";
        if ([confirmed isEqualToString:targetName]) return confirmed;
    }
    return nil;
}

// ---------- Hotkey ----------
static OSStatus HotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    NSString *newPreset = TogglePresetOnce();
    if (newPreset) {
        ShowHUD(@"Display preset switched", newPreset);
    } else {
        ShowHUD(@"Preset switch failed", @"Check display/preset names");
    }
    return noErr;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        if (argc > 1) gDisplayFilter = [NSString stringWithUTF8String:argv[1]];

        EventTypeSpec evt = { kEventClassKeyboard, kEventHotKeyPressed };
        InstallApplicationEventHandler(&HotKeyHandler, 1, &evt, NULL, NULL);

        EventHotKeyID hk = { 'TPHK', 1 };
        EventHotKeyRef ref = NULL;
        UInt32 keyCode = kVK_ANSI_P;
        UInt32 modifiers = controlKey | optionKey | cmdKey; // Ctrl+Opt+Cmd+P

        OSStatus err = RegisterEventHotKey(keyCode, modifiers, hk, GetApplicationEventTarget(), 0, &ref);
        if (err != noErr) { fprintf(stderr, "RegisterEventHotKey failed: %d\n", (int)err); return 2; }

        NSLog(@"Hotkey ready: Control+Option+Command+P");
        [NSApp run];
    }
    return 0;
}
