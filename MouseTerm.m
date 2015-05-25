#import <Cocoa/Cocoa.h>
#import <objc/objc-class.h>
#import "JRSwizzle.h"
#import "MouseTerm.h"
#import "MTView.h"
#import "Terminal.h"

NSMutableDictionary* MouseTerm_ivars = nil;

@implementation MouseTerm

#define EXISTS(cls, sel)                                                 \
    do {                                                                 \
        if (!class_getInstanceMethod(cls, sel))                          \
        {                                                                \
            NSLog(@"[MouseTerm] ERROR: Got nil Method for [%@ %@]", cls, \
                  NSStringFromSelector(sel));                            \
            return;                                                      \
        }                                                                \
    } while (0)

#define SWIZZLE(cls, sel1, sel2)                                        \
    do {                                                                \
        NSError *err = nil;                                             \
        if (![cls jr_swizzleMethod: sel1 withMethod: sel2 error: &err]) \
        {                                                               \
            NSLog(@"[MouseTerm] ERROR: Failed to swizzle [%@ %@]: %@",  \
                  cls, NSStringFromSelector(sel1), err);                \
        }                                                               \
    } while (0)

+ (void) load
{
    Class controller = NSClassFromString(@"TTTabController");
    if (!controller)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTTabController");
        return;
    }

    EXISTS(controller, @selector(shellDidReceiveData:));

    Class logicalScreen = NSClassFromString(@"TTLogicalScreen");
    if (!logicalScreen)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTLogicalScreen");
        return;
    }

    EXISTS(logicalScreen, @selector(isAlternateScreenActive));

    Class shell = NSClassFromString(@"TTShell");
    if (!shell)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTShell");
        return;
    }

    EXISTS(shell, @selector(writeData:));
    EXISTS(shell, @selector(dealloc));

    Class view = NSClassFromString(@"TTView");
    if (!view)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTView");
        return;
    }

    EXISTS(view, @selector(scrollWheel:));
    EXISTS(view, @selector(rowCount));
    EXISTS(view, @selector(controller));
    EXISTS(view, @selector(logicalScreen));

    Class prefs = NSClassFromString(@"TTAppPrefsController");
    if (!prefs)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTAppPrefsController");
        return;
    }

    EXISTS(prefs, @selector(windowDidLoad));

    Class profile = NSClassFromString(@"TTProfile");
    if (!profile)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTProfile");
        return;
    }

    EXISTS(profile, @selector(valueForKey:));
    EXISTS(profile, @selector(setValue:forKey:));
    EXISTS(profile, @selector(propertyListRepresentation));

    Class windowController = NSClassFromString(@"TTWindowController");
    if (!windowController)
    {
        NSLog(@"[MouseTerm] ERROR: Got nil Class for TTWindowController");
        return;
    }

    EXISTS(windowController, @selector(makeTabWithProfile:customFont:command:
                                               runAsShell:restorable:
                                         workingDirectory:sessionClass:
                                           restoreSession:));

    // Initialize instance vars before any swizzling so nothing bad happens
    // if some methods are swizzled but not others.
    MouseTerm_ivars = [[NSMutableDictionary alloc] init];

    SWIZZLE(shell, @selector(dealloc), @selector(MouseTerm_dealloc));
    SWIZZLE(shell, @selector(writeData:), @selector(MouseTerm_writeData:));
    SWIZZLE(view, @selector(scrollWheel:), @selector(MouseTerm_scrollWheel:));
    SWIZZLE(view, @selector(mouseDown:), @selector(MouseTerm_mouseDown:));
    SWIZZLE(view, @selector(mouseMoved:), @selector(MouseTerm_mouseMoved:));
    SWIZZLE(view, @selector(mouseDragged:),
            @selector(MouseTerm_mouseDragged:));
    SWIZZLE(view, @selector(mouseUp:), @selector(MouseTerm_mouseUp:));
    SWIZZLE(view, @selector(rightMouseDown:),
            @selector(MouseTerm_rightMouseDown:));
    SWIZZLE(view, @selector(rightMouseDragged:),
            @selector(MouseTerm_rightMouseDragged:));
    SWIZZLE(view, @selector(rightMouseUp:),
            @selector(MouseTerm_rightMouseUp:));
    SWIZZLE(view, @selector(otherMouseDown:),
            @selector(MouseTerm_otherMouseDown:));
    SWIZZLE(view, @selector(otherMouseDragged:),
            @selector(MouseTerm_otherMouseDragged:));
    SWIZZLE(view, @selector(otherMouseUp:),
            @selector(MouseTerm_otherMouseUp:));
    SWIZZLE(view, @selector(windowDidBecomeKey:),
            @selector(MouseTerm_windowDidBecomeKey:));
    SWIZZLE(view, @selector(windowDidResignKey:),
            @selector(MouseTerm_windowDidResignKey:));
    SWIZZLE(view, @selector(acceptsFirstResponder),
            @selector(MouseTerm_acceptsFirstResponder));
    SWIZZLE(view, @selector(becomeFirstResponder),
            @selector(MouseTerm_becomeFirstResponder));
    SWIZZLE(view, @selector(resignFirstResponder),
            @selector(MouseTerm_resignFirstResponder));
    SWIZZLE(controller, @selector(shellDidReceiveData:),
            @selector(MouseTerm_shellDidReceiveData:));
    SWIZZLE(controller, @selector(dealloc),
            @selector(MouseTerm_tabControllerDealloc));
    SWIZZLE(prefs, @selector(windowDidLoad),
            @selector(MouseTerm_windowDidLoad));
    SWIZZLE(profile, @selector(valueForKey:),
            @selector(MouseTerm_valueForKey:));
    SWIZZLE(profile, @selector(setValue:forKey:),
            @selector(MouseTerm_setValue:forKey:));
    SWIZZLE(profile, @selector(propertyListRepresentation),
            @selector(MouseTerm_propertyListRepresentation));
    SWIZZLE(logicalScreen, @selector(logicalWidthForCharacter:),
            @selector(MouseTerm_logicalWidthForCharacter:));
    SWIZZLE(logicalScreen, @selector(displayWidthForCharacter:),
            @selector(MouseTerm_displayWidthForCharacter:));
    SWIZZLE(view, @selector(colorForANSIColor:),
            @selector(MouseTerm_colorForANSIColor:));
    SWIZZLE(view, @selector(colorForANSIColor:adjustedRelativeToColor:),
            @selector(MouseTerm_colorForANSIColor:adjustedRelativeToColor:));
    SWIZZLE(view, @selector(colorForExtendedANSIColor:adjustedRelativeToColor:withProfile:),
            @selector(MouseTerm_colorForExtendedANSIColor:adjustedRelativeToColor:withProfile:));
    SWIZZLE(windowController, @selector(makeTabWithProfile:customFont:command:
                                               runAsShell:restorable:
                                         workingDirectory:sessionClass:
                                           restoreSession:),
            @selector(MouseTerm_makeTabWithProfile:customFont:command:
                                        runAsShell:restorable:workingDirectory:
                                      sessionClass:restoreSession:));
    [self insertMenuItem];
    [self updateProfileOfAlreadyRunningTabs];
}

+ (void) updateProfileOfAlreadyRunningTabs
{
    Class shellMetaClass = NSClassFromString(@"TTShell");
    NSArray *runningShells = [objc_msgSend(shellMetaClass, @selector(runningShells)) allValues];
    if((runningShells != nil) && ([runningShells count] != 0)) {
        Class sharedProfileControllerMetaclass = objc_getClass("TTProfileManager");
        TTProfileManager *sharedProfileManager \
            = (TTProfileManager*) objc_msgSend(sharedProfileControllerMetaclass, \
                    @selector(sharedProfileManager));
        for(id shell in runningShells) {
            TTTabController *tabController = [shell controller];
            TTProfile *newProfile = [[sharedProfileManager profileWithName:[[tabController profile] name]] copy];
            [tabController setProfile:newProfile];
        }
    }
}

+ (void) toggleMouse: (NSMenuItem*) sender
{
    [sender setState: ![sender state]];
    [NSView MouseTerm_setMouseEnabled: [sender state]];
}

+ (void) toggleBase64Copy: (NSMenuItem*) sender
{
    [sender setState: ![sender state]];
    [NSView MouseTerm_setBase64CopyEnabled: [sender state]];
}

+ (void) toggleBase64Paste: (NSMenuItem*) sender
{
    [sender setState: ![sender state]];
    [NSView MouseTerm_setBase64PasteEnabled: [sender state]];
}

+ (void) insertMenuItem;
{
    NSMenu* shellMenu = [[[NSApp mainMenu] itemAtIndex: 1] submenu];
    if (!shellMenu)
    {
        NSLog(@"[MouseTerm] ERROR: Shell menu not found");
        return;
    }

    [shellMenu addItem: [NSMenuItem separatorItem]];
    NSBundle *bundle = [NSBundle bundleForClass: self];
    NSString* t1 = NSLocalizedStringFromTableInBundle(@"Send Mouse Events", nil,
                                                     bundle, nil);
    NSMenuItem* itemToggleMouse = [shellMenu addItemWithTitle: t1
                                                       action: @selector(toggleMouse:)
                                                keyEquivalent: @"m"];
    if (!itemToggleMouse)
    {
        NSLog(@"[MouseTerm] ERROR: Unable to create menu item: toggleMouse");
        return;
    }

    [itemToggleMouse setKeyEquivalentModifierMask: (NSShiftKeyMask | NSCommandKeyMask)];
    [itemToggleMouse setTarget: self];
    [itemToggleMouse setState: NSOnState];
    [itemToggleMouse setEnabled: YES];

    NSString* t2 = NSLocalizedStringFromTableInBundle(@"Enable Base64 Copy", nil,
                                                      bundle, nil);
    NSMenuItem* itemToggleBase64Copy = [shellMenu addItemWithTitle: t2
                                                            action: @selector(toggleBase64Copy:)
                                                     keyEquivalent: @"c"];
    if (!itemToggleBase64Copy)
    {
        NSLog(@"[MouseTerm] ERROR: Unable to create menu item: toggleBase64Copy");
        return;
    }

    [itemToggleBase64Copy setKeyEquivalentModifierMask: (NSShiftKeyMask | NSCommandKeyMask)];
    [itemToggleBase64Copy setTarget: self];
    [itemToggleBase64Copy setState: NSOnState];
    [itemToggleBase64Copy setEnabled: YES];

    NSString* t3 = NSLocalizedStringFromTableInBundle(@"Enable Base64 Paste", nil,
                                                      bundle, nil);
    NSMenuItem* itemToggleBase64Paste = [shellMenu addItemWithTitle: t3
                                                             action: @selector(toggleBase64Paste:)
                                                      keyEquivalent: @"p"];
    if (!itemToggleBase64Paste)
    {
        NSLog(@"[MouseTerm] ERROR: Unable to create menu item: toggleBase64Paste");
        return;
    }

    [itemToggleBase64Paste setKeyEquivalentModifierMask: (NSShiftKeyMask | NSCommandKeyMask)];
    [itemToggleBase64Paste setTarget: self];
    [itemToggleBase64Paste setState: NSOffState];
    [itemToggleBase64Paste setEnabled: NO];
}

+ (MouseTerm*) sharedInstance
{
    static MouseTerm* plugin = nil;
    if (!plugin)
        plugin = [[MouseTerm alloc] init];

    return plugin;
}

- (void) orderFrontMouseConfiguration: (id) sender
{
    if (![self window] &&
        ![NSBundle loadNibNamed: @"Configuration" owner: self])
    {
        NSLog(@"[MouseTerm] ERROR: Failed to load Configuration.nib");
        return;
    }

    [NSApp beginSheet: [self window] modalForWindow: [sender window]
        modalDelegate: nil didEndSelector: nil contextInfo: nil];
}

- (void) orderOutConfiguration: (id) sender
{
    [NSApp endSheet: [sender window]];
    [[sender window] orderOut: self];
}

- (TTProfileArrayController*) profilesController
{
    Class cls = NSClassFromString(@"TTAppPrefsController");
    TTProfileArrayController* controller = [[cls sharedPreferencesController]
                                               profilesController];
    return controller;
}

// Deletes instance variables dictionary
- (BOOL) unload
{
    if (MouseTerm_ivars)
    {
        [MouseTerm_ivars release];
        MouseTerm_ivars = nil;
    }

    return YES;
}

@end
