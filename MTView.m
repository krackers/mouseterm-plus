#import <Cocoa/Cocoa.h>
#import <math.h>
#import "MTView.h"
#import "MTShell.h"
#import "Mouse.h"
#import "Terminal.h"

@implementation NSView (MTView)

- (NSData*) MouseTerm_codeForEvent: (NSEvent*) event
                            button: (MouseButton) button
                            motion: (BOOL) motion
{
    Position pos = [self MouseTerm_currentPosition: event];
    unsigned int x = pos.x;
    unsigned int y = pos.y;
    char cb = button + 32;
    char modflag = [event modifierFlags];

    if (modflag & NSShiftKeyMask) cb |= 4;
    if (modflag & NSAlternateKeyMask) cb |= 8;
    if (modflag & NSControlKeyMask) cb |= 16;
    if (motion) cb += 32;

    char buf[MOUSE_RESPONSE_LEN + 1];
    snprintf(buf, sizeof(buf), MOUSE_RESPONSE, cb, 32 + x + 1,
             32 + y + 1);
    return [NSData dataWithBytes: buf length: MOUSE_RESPONSE_LEN];
}

- (BOOL) MouseTerm_shouldIgnore: (NSEvent*) event
{
    // Don't handle if alt/option is pressed
    if ([event modifierFlags] & NSAlternateKeyMask)
        return YES;

    TTLogicalScreen* screen = [(TTView*) self logicalScreen];
    // Don't handle if the scroller isn't at the bottom
    linecount_t scrollback =
        (linecount_t) [screen lineCount] -
        (linecount_t) [(TTView*) self rowCount];
    if (scrollback > 0 &&
        [[[(TTView*) self pane] scroller] floatValue] < 1.0)
    {
        return YES;
    }

    return NO;
}

- (BOOL) MouseTerm_shouldIgnoreDown
{
    TTLogicalScreen* screen = [(TTView*) self logicalScreen];
    // Don't handle if the scroller isn't at the bottom
    linecount_t scrollback =
        (linecount_t) [screen lineCount] -
        (linecount_t) [(TTView*) self rowCount];
    if (scrollback > 0 &&
        [[[(TTView*) self pane] scroller] floatValue] < 1.0)
    {
        return YES;
    }

    MTShell* shell = [[(TTView*) self controller] shell];
    if (![shell MouseTerm_getIsMouseDown])
        return YES;

    return NO;
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
    return pos;
}

- (void) MouseTerm_mouseDown: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnore: event])
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
                                             button: MOUSE_BUTTON1
                                             motion: NO];
        [(TTShell*) shell writeData: data];

        goto handled;
    }
    }

handled:
    [(TTView*) self clearTextSelection];
    return;
ignored:
    [self MouseTerm_mouseDown: event];
}

- (void) MouseTerm_mouseDragged: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnoreDown])
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
                                             button: MOUSE_RELEASE
                                             motion: YES];
        [(TTShell*) shell writeData: data];
        goto handled;
    }
    }
handled:
    [(TTView*) self clearTextSelection];
    return;
ignored:
    [self MouseTerm_mouseDragged: event];
}

- (void) MouseTerm_mouseUp: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnoreDown])
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
                                             button: MOUSE_RELEASE
                                             motion: NO];
        [(TTShell*) shell writeData: data];

        goto handled;
    }
    }
handled:
    [(TTView*) self clearTextSelection];
    return;
ignored:
    [self MouseTerm_mouseUp: event];
}

- (void) MouseTerm_rightMouseDown: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseDown");
    [self MouseTerm_rightMouseDown: event];
}

- (void) MouseTerm_rightMouseDragged: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseDragged");
    [self MouseTerm_rightMouseDragged: event];
}

- (void) MouseTerm_rightMouseUp: (NSEvent*) event
{
    NSLog(@"[MouseTerm] rightMouseUp");
    [self MouseTerm_rightMouseUp: event];
}

- (void) MouseTerm_otherMouseDown: (NSEvent*) event
{
    NSLog(@"[MouseTerm] otherMouseDown");
    [self MouseTerm_otherMouseDown: event];
}

- (void) MouseTerm_otherMouseDragged: (NSEvent*) event
{
    NSLog(@"[MouseTerm] otherMouseDragged");
    [self MouseTerm_otherMouseDragged: event];
}

- (void) MouseTerm_otherMouseUp: (NSEvent*) event
{
    NSLog(@"[MouseTerm] otherMouseUp");
    [self MouseTerm_otherMouseUp: event];
}

// Intercepts all scroll wheel movements (one wheel "tick" at a time)
- (void) MouseTerm_scrollWheel: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnore: event])
        goto ignored;

    TTLogicalScreen* screen = [(TTView*) self logicalScreen];
    MTShell* shell = [[(TTView*) self controller] shell];

    switch ([shell MouseTerm_getMouseMode])
    {
    case NO_MODE:
    {
        if ([screen isAlternateScreenActive] &&
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
                                             motion: NO];

        long i;
        long lines = lround(delta) + 1;
        for (i = 0; i < lines; ++i)
            [(TTShell*) shell writeData: data];

        goto handled;
    }
    }

handled:
    return;
ignored:
    [self MouseTerm_scrollWheel: event];
}

@end

