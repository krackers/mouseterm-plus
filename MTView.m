#import <Cocoa/Cocoa.h>
#import <math.h>
#import "MTProfile.h"
#import "MTShell.h"
#import "MTView.h"
#import "Mouse.h"
#import "Terminal.h"
#import "MouseTerm.h"

@implementation NSObject (TTLogicalScreen)

- (NSValue*) MouseTerm_initVars2
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [MouseTerm_ivars setObject: dict forKey: ptr];
        [dict setObject: [NSNumber numberWithInt: NO]
                 forKey: @"emojiFix"];
    }
    return ptr;
}

- (void) MouseTerm_setNaturalEmojiWidth: (BOOL) emojiFix
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [MouseTerm_ivars setObject: dict forKey: ptr];
        [dict setObject: [NSNumber numberWithInt: emojiFix]
                 forKey: @"emojiFix"];
    } else {
        [[MouseTerm_ivars objectForKey: ptr]
            setObject: [NSNumber numberWithBool: emojiFix]
               forKey: @"emojiFix"];
    }
}

- (BOOL) MouseTerm_getNaturalEmojiWidth
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        return NO;
    }
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"emojiFix"] boolValue];
}

- (unsigned long long)MouseTerm_logicalWidthForCharacter:(int)code
{
    if ((code & 0x1f0000) == 0x10000)
        if ([self MouseTerm_getNaturalEmojiWidth])
            return 2;
    return [self MouseTerm_logicalWidthForCharacter:code];
}

- (unsigned long long)MouseTerm_displayWidthForCharacter:(int)code
{
    if ((code & 0x1f0000) == 0x10000)
        if ([self MouseTerm_getNaturalEmojiWidth])
            return 2;
    return [self MouseTerm_displayWidthForCharacter:code];
}

@end

@implementation NSView (MTView)

static BOOL mouseEnabled = YES;
static BOOL base64CopyEnabled = YES;
static BOOL base64PasteEnabled = YES;

- (id) MouseTerm_colorForANSIColor:(unsigned int)index;
{
    id colour = nil;
    MTShell *shell = [[(TTView*)self controller] shell];
    NSMutableDictionary *palette = [(MTShell*)shell MouseTerm_getPalette];
    int n;

    if (palette) {
        if (index < 17) {
            n = index - 1;
        } else if (index < 1000) {
            n = index;
        } else {
            n = index - 1000;
        }
        colour = [palette objectForKey:[NSNumber numberWithInt: n]];
        if (colour) {
            return colour;
        }
    }
    return [self MouseTerm_colorForANSIColor: index];
}

- (id) MouseTerm_colorForANSIColor:(unsigned int)index adjustedRelativeToColor:(id)bgColor;
{
    id colour = nil;
    MTShell *shell = [[(TTView*) self controller] shell];
    NSMutableDictionary *palette = [(MTShell*)shell MouseTerm_getPalette];
    int n;

    if (palette) {
        if (index == 0) {
            if (bgColor) {
                n = -1;
            } else {
                n = -3;
            }
        } else if (index < 17) {
            n = index - 1;
        } else if (index < 1000) {
            n = index;
        } else {
            n = index - 1000;
        }
        colour = [palette objectForKey:[NSNumber numberWithInt: n]];
    }
    if (colour)
    {
        colour = [(TTView *)self adjustedColorWithColor: colour
                                    withBackgroundColor: bgColor
                                                  force: YES];
        return colour;
    }
    colour = [self MouseTerm_colorForANSIColor: index
                       adjustedRelativeToColor: bgColor];
    return colour;
}

- (id) MouseTerm_colorForExtendedANSIColor:(unsigned long long)index adjustedRelativeToColor:(id)bgColor withProfile:(id)profile
{
    id colour = nil;
    MTShell *shell = [[(TTView*) self controller] shell];
    NSMutableDictionary *palette = [(MTShell*)shell MouseTerm_getPalette];
    int n;

    if (palette) {
        if (index < 17) {
            n = index - 1;
        } else if (index < 1000) {
            n = index;
        } else {
            n = index - 1000;
        }
        colour = [palette objectForKey: [NSNumber numberWithInt: n]];
        if (colour)
        {
            colour = [(TTView *)self adjustedColorWithColor: colour
                                        withBackgroundColor: bgColor
                                                      force: YES];
            return colour;
        }
    }
    colour = [self MouseTerm_colorForExtendedANSIColor: index
                               adjustedRelativeToColor: bgColor
                                           withProfile: profile];
    return colour;
}

- (NSData*) MouseTerm_codeForEvent: (NSEvent*) event
                            button: (MouseButton) button
                            motion: (BOOL) motion
                           release: (BOOL) release
{
    // get mouse position, the origin coodinate is (1, 1).
    Position pos = [self MouseTerm_currentPosition: event];
    unsigned int x = pos.x;
    unsigned int y = pos.y;
    char cb = button;
    char modflag = [event modifierFlags];

    if (modflag & NSShiftKeyMask) cb |= 4;
    if (modflag & NSAlternateKeyMask) cb |= 8;
    if (modflag & NSControlKeyMask) cb |= 16;
    if (motion) cb += 32;

    MTShell* shell = [[(TTView*) self controller] shell];
    MouseProtocol mouseProtocol = [shell MouseTerm_getMouseProtocol];
    unsigned int len;
    const size_t BUFFER_LENGTH = 256;
    char buf[BUFFER_LENGTH];

    switch (mouseProtocol) {

    case URXVT_PROTOCOL:
        if (release)
            cb |= MOUSE_RELEASE;
        cb += 32; // base offset +32 (to make it printable)
        snprintf(buf, BUFFER_LENGTH, "\e[%d;%d;%dM", cb, x, y);
        len = strlen(buf);
        break;

    case SGR_PROTOCOL:
        if (release) // release
            snprintf(buf, BUFFER_LENGTH, "\e[<%d;%d;%dm", cb, x, y);
        else
            snprintf(buf, BUFFER_LENGTH, "\e[<%d;%d;%dM", cb, x, y);
        len = strlen(buf);
        break;

    case NORMAL_PROTOCOL:
    default:
        // add base offset +32 (to make it printable)
        cb += 32;
        x += 32;
        y += 32;
        if (release)
            cb |= MOUSE_RELEASE;
        x = MIN(x, 255);
        y = MIN(y, 255);
        len = MOUSE_RESPONSE_LEN;

        snprintf(buf, len + 1, MOUSE_RESPONSE, cb, x, y);
        break;
    }
    return [NSData dataWithBytes: buf length: len];
}

+ (void) MouseTerm_setMouseEnabled: (BOOL) value
{
    mouseEnabled = value;
}

+ (BOOL) MouseTerm_getMouseEnabled
{
    return mouseEnabled;
}

+ (void) MouseTerm_setBase64CopyEnabled: (BOOL) value
{
    base64CopyEnabled = value;
}

+ (BOOL) MouseTerm_getBase64CopyEnabled
{
    return base64CopyEnabled;
}

+ (void) MouseTerm_setBase64PasteEnabled: (BOOL) value
{
    base64PasteEnabled = value;
}

+ (BOOL) MouseTerm_getBase64PasteEnabled
{
    return base64PasteEnabled;
}

- (NSScroller*) MouseTerm_scroller
{
    if ([self respondsToSelector: @selector(pane)])
        return [[(TTView*) self pane] scroller];
    else
        return [(TTTabController*) [(TTView*) self controller] scroller];
}

- (BOOL) MouseTerm_shouldIgnore: (NSEvent*) event button: (MouseButton) button
{
    if (![NSView MouseTerm_getMouseEnabled])
        return YES;

    // Don't handle if alt/option/control is pressed
    if ([event modifierFlags] & (NSAlternateKeyMask | NSControlKeyMask))
        return YES;

    TTLogicalScreen* screen = [(TTView*) self logicalScreen];
    // Don't handle if the scroller isn't at the bottom
    linecount_t scrollback =
        (linecount_t) [screen lineCount] -
        (linecount_t) [(TTView*) self rowCount];
    if (scrollback > 0 && [[self MouseTerm_scroller] floatValue] < 1.0)
        return YES;

    // Don't handle if a profile option is disabled
    MTProfile* profile = [(TTTabController*) [(TTView*) self controller]
                                             profile];
    if (![profile MouseTerm_buttonEnabled: button])
        return YES;

    return NO;
}

- (BOOL) MouseTerm_shouldIgnoreDown: (NSEvent*) event
                             button: (MouseButton) button
{
    if ([self MouseTerm_shouldIgnore: event button: button])
        return YES;

    MTShell* shell = [[(TTView*) self controller] shell];
    if (![shell MouseTerm_getIsMouseDown])
        return YES;

    return NO;
}

- (BOOL) MouseTerm_shouldIgnoreMoved: (NSEvent*) event
{
    // check if the mouse location is in the bounds of window.
    NSPoint location = [event locationInWindow];
    NSRect bounds = [(NSView*) self bounds];
    if (NSPointInRect(location, bounds))
        return NO;
    return YES;
}

- (Position) MouseTerm_currentPosition: (NSEvent*) event
{
    linecount_t scrollback =
        (linecount_t) [[(TTView*) self logicalScreen] lineCount] -
        (linecount_t) [(TTView*) self rowCount];
    NSPoint viewloc = [self convertPoint: [event locationInWindow]
                                fromView: nil];
    Position pos = [(TTView*) self displayPositionForPoint: viewloc];
    // The above method returns the position *including* scrollback,
    // so we have to compensate for that.
    pos.y -= scrollback;
    pos.y += 1; // origin offset +1
    // pos.x may not indicate correct coordinate value if the tail
    // cells of line buffer are empty, so we calculate it from the cell size.
    CGSize size = [(TTView*) self cellSize];
    pos.x = (linecount_t)round(viewloc.x / size.width);

    // treat negative position value as 1.
    pos.x = MAX(1, (int)pos.x);
    pos.y = MAX(1, (int)pos.y);

    return pos;
}

- (BOOL) MouseTerm_buttonDown: (NSEvent*) event button: (MouseButton) button
{
    if ([self MouseTerm_shouldIgnore: event button: button])
        goto ignored;

    MTShell* shell = [[(TTView*) self controller] shell];
    switch ([shell MouseTerm_getMouseMode])
    {
    case NO_MODE:
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        [shell MouseTerm_setIsMouseDown: YES];
        NSData* data = [self MouseTerm_codeForEvent: event
                                             button: button
                                             motion: NO
                                            release: NO];
        [(TTShell*) shell writeData: data];

        goto handled;
    }
    }

handled:
    [(TTView*) self clearTextSelection];
    return YES;
ignored:
    return NO;
}

- (BOOL) MouseTerm_buttonMoved: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnoreMoved: event])
        goto ignored;

    MTShell* shell = [[(TTView*) self controller] shell];
    switch ([shell MouseTerm_getMouseMode])
    {
    case NO_MODE:
        goto ignored;
    case NORMAL_MODE:
    case HILITE_MODE:
    case BUTTON_MODE:
        goto handled;
    case ALL_MODE:
    {
        NSData* data = [self MouseTerm_codeForEvent: event
                                             button: MOUSE_RELEASE + 32
                                             motion: NO
                                            release: NO];
        [(TTShell*) shell writeData: data];
        goto handled;
    }
    }
handled:
    [(TTView*) self clearTextSelection];
    return YES;
ignored:
    return NO;
}


- (BOOL) MouseTerm_buttonDragged: (NSEvent*) event button: (MouseButton) button
{
    if ([self MouseTerm_shouldIgnoreDown: event button: button])
        goto ignored;

    MTShell* shell = [[(TTView*) self controller] shell];
    switch ([shell MouseTerm_getMouseMode])
    {
    case NO_MODE:
        goto ignored;
    case NORMAL_MODE:
    case HILITE_MODE:
        goto handled;
    case BUTTON_MODE:
    case ALL_MODE:
    {
        NSData* data = [self MouseTerm_codeForEvent: event
                                             button: button
                                             motion: YES
                                            release: NO];
        [(TTShell*) shell writeData: data];
        goto handled;
    }
    }
handled:
    [(TTView*) self clearTextSelection];
    return YES;
ignored:
    return NO;
}

- (BOOL) MouseTerm_buttonUp: (NSEvent*) event button: (MouseButton) button
{
    if ([self MouseTerm_shouldIgnoreDown: event button: button])
        goto ignored;

    MTShell* shell = [[(TTView*) self controller] shell];
    switch ([shell MouseTerm_getMouseMode])
    {
    case NO_MODE:
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        [shell MouseTerm_setIsMouseDown: NO];
        NSData* data = [self MouseTerm_codeForEvent: event
                                             button: button
                                             motion: NO
                                            release: YES];
        [(TTShell*) shell writeData: data];

        goto handled;
    }
    }
handled:
    [(TTView*) self clearTextSelection];
    return YES;
ignored:
    return NO;
}

- (void) MouseTerm_mouseDown: (NSEvent*) event
{
    MouseButton button;
    if ([event modifierFlags] & NSCommandKeyMask)
        button = MOUSE_BUTTON3;
    else
        button = MOUSE_BUTTON1;

    if (![self MouseTerm_buttonDown: event button: button])
        [self MouseTerm_mouseDown: event];
}

- (void) MouseTerm_mouseMoved: (NSEvent*) event
{
    [self MouseTerm_buttonMoved: event];
}

- (void) MouseTerm_mouseDragged: (NSEvent*) event
{
    MouseButton button;
    if ([event modifierFlags] & NSCommandKeyMask)
        button = MOUSE_BUTTON3;
    else
        button = MOUSE_BUTTON1;

    if (![self MouseTerm_buttonDragged: event button: button])
        [self MouseTerm_mouseDragged: event];
}

- (void) MouseTerm_mouseUp: (NSEvent*) event
{
    MouseButton button;
    if ([event modifierFlags] & NSCommandKeyMask)
        button = MOUSE_BUTTON3;
    else
        button = MOUSE_BUTTON1;

    if (![self MouseTerm_buttonUp: event button: button])
        [self MouseTerm_mouseUp: event];
}

- (void) MouseTerm_rightMouseDown: (NSEvent*) event
{
    if (![self MouseTerm_buttonDown: event button: MOUSE_BUTTON2])
        [self MouseTerm_rightMouseDown: event];
}

- (void) MouseTerm_rightMouseDragged: (NSEvent*) event
{
    if (![self MouseTerm_buttonDragged: event button: MOUSE_BUTTON2])
        [self MouseTerm_rightMouseDragged: event];
}

- (void) MouseTerm_rightMouseUp: (NSEvent*) event
{
    if (![self MouseTerm_buttonUp: event button: MOUSE_BUTTON2])
        [self MouseTerm_rightMouseUp: event];
}

- (void) MouseTerm_otherMouseDown: (NSEvent*) event
{
    if (![self MouseTerm_buttonDown: event button: MOUSE_BUTTON3])
        [self MouseTerm_otherMouseDown: event];
}

- (void) MouseTerm_otherMouseDragged: (NSEvent*) event
{
    if (![self MouseTerm_buttonDragged: event button: MOUSE_BUTTON3])
        [self MouseTerm_otherMouseDragged: event];
}

- (void) MouseTerm_otherMouseUp: (NSEvent*) event
{
    if (![self MouseTerm_buttonUp: event button: MOUSE_BUTTON3])
        [self MouseTerm_otherMouseUp: event];
}

// Intercepts all scroll wheel movements (one wheel "tick" at a time)
- (void) MouseTerm_scrollWheel: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnore: event button: MOUSE_WHEEL_UP])
        goto ignored;

    TTLogicalScreen* screen = [(TTView*) self logicalScreen];
    MTShell* shell = [[(TTView*) self controller] shell];

    switch ([shell MouseTerm_getMouseMode])
    {
    case NO_MODE:
    {
        MTProfile* profile = [(TTTabController*) [(TTView*) self controller]
                                                 profile];
        if ([NSView MouseTerm_getMouseEnabled] &&
            [profile MouseTerm_emulationEnabled] &&
            [screen isAlternateScreenActive] &&
            [shell MouseTerm_getAppCursorMode])
        {
            // Calculate how many lines to scroll by (takes acceleration
            // into account)
            NSData* data;
            // deltaY returns CGFloat, which can be float or double
            // depending on the architecture. Upcasting floats to doubles
            // seems like an easier compromise than detecting what the
            // type really is.
            double delta = [event deltaY];

            // Trackpads seem to return a lot of 0.0 events, which
            // shouldn't trigger scrolling anyway.
            if (delta == 0.0)
                goto handled;
            else if (delta < 0.0)
            {
                delta = fabs(delta);
                data = [NSData dataWithBytes: DOWN_ARROW_APP
                                      length: ARROW_LEN];
            }
            else
            {
                data = [NSData dataWithBytes: UP_ARROW_APP
                                      length: ARROW_LEN];
            }

            linecount_t i;
            linecount_t lines = lround(delta) + 1;
            for (i = 0; i < lines; ++i)
                [(TTShell*) shell writeData: data];

            goto handled;
        }
        else
            goto ignored;
    }
    // FIXME: Unhandled at the moment
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        MouseButton button;
        double delta = [event deltaY];
        if (delta == 0.0)
            goto handled;
        else if (delta < 0.0)
        {
            delta = fabs(delta);
            button = MOUSE_WHEEL_DOWN;
        }
        else
            button = MOUSE_WHEEL_UP;

        NSData* data = [self MouseTerm_codeForEvent: event
                                             button: button
                                             motion: NO
                                            release: NO];

        long i;
        long lines = lround(delta) + 1;
        for (i = 0; i < lines; ++i)
            [(TTShell*) shell writeData: data];

        goto handled;
    }
    }

handled:
    [(TTView*) self clearTextSelection];
    return;
ignored:
    [self MouseTerm_scrollWheel: event];
}

- (BOOL) MouseTerm_acceptsFirstResponder
{
    return YES;
}

- (BOOL) MouseTerm_windowDidBecomeKey: (id) arg1
{
    NSData* data = [NSData dataWithBytes: "\033[I" length: 3];
    MTShell* shell = [[(TTView*) self controller] shell];
    if ([shell MouseTerm_getFocusMode]) {
        [(TTShell*) shell writeData: data];
    }
    return YES;
}

- (BOOL) MouseTerm_windowDidResignKey: (id) arg1
{
    NSData* data = [NSData dataWithBytes: "\033[O" length: 3];
    MTShell* shell = [[(TTView*) self controller] shell];
    if ([shell MouseTerm_getFocusMode]) {
        [(TTShell*) shell writeData: data];
    }
    return YES;
}

- (BOOL) MouseTerm_becomeFirstResponder
{
    NSData* data = [NSData dataWithBytes: "\033[I" length: 3];
    MTShell* shell = [[(TTView*) self controller] shell];
    if ([shell MouseTerm_getFocusMode]) {
        [(TTShell*) shell writeData: data];
    }
    return YES;
}

- (BOOL) MouseTerm_resignFirstResponder
{
    NSData* data = [NSData dataWithBytes: "\033[O" length: 3];
    MTShell* shell = [[(TTView*) self controller] shell];
    if ([shell MouseTerm_getFocusMode]) {
        [(TTShell*) shell writeData: data];
    }
    return YES;
}

@end

