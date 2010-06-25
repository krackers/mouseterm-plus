#import <Cocoa/Cocoa.h>
#import <math.h>

#import "MouseTerm.h"
#import "Mouse.h"

@implementation NSObject (MouseTermTTTabController)

// Intercepts all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    // FIXME: What if the data's split up over method calls?
    NSUInteger length = [data length];
    const char* chars = [data bytes];
    const char* pos;

    // Handle mouse reporting toggle
    if ((pos = strnstr(chars, TOGGLE_MOUSE, length)))
    {
        // Is there enough data in the buffer for the next two characters?
        if (length >= (NSUInteger) (&pos[TOGGLE_MOUSE_LEN] - chars) + 2)
        {
            char mode = pos[TOGGLE_MOUSE_LEN];
            char flag = pos[TOGGLE_MOUSE_LEN + 1];
            MouseMode mouseMode = NO_MODE;

            switch (mode)
            {
            case '0':
                mouseMode = NORMAL_MODE;
                break;
            case '1':
                mouseMode = HILITE_MODE;
                break;
            case '2':
                mouseMode = BUTTON_MODE;
                break;
            case '3':
                mouseMode = ALL_MODE;
                break;
            }

            if (mouseMode != NO_MODE)
            {
                switch (flag)
                {
                case TOGGLE_ON:
                    [[(TTTabController*) self shell]
                        MouseTerm_set: @"mouseMode"
                                value: [NSNumber numberWithInt: mouseMode]];
                    break;
                case TOGGLE_OFF:
                    [[(TTTabController*) self shell]
                        MouseTerm_set: @"mouseMode"
                                value: [NSNumber numberWithInt: NO_MODE]];
                    break;
                }
            }
        }
    }
    // Handle application cursor keys mode toggle
    //
    // Note: This information does exist on the TTVT100Emulator object
    // already, but it's in private member data, and there's no method
    // that returns any data from it. That means we have to look for it
    // ourselves.
    else if ((pos = strnstr(chars, TOGGLE_CURSOR_KEYS, length)))
    {
        // Is there enough data in the buffer for the next character?
        if (length >= (NSUInteger) (&pos[TOGGLE_CURSOR_KEYS_LEN] - chars) + 1)
        {
            char flag = pos[TOGGLE_CURSOR_KEYS_LEN];
            switch (flag)
            {
            case TOGGLE_ON:
                [[(TTTabController*) self shell]
                    MouseTerm_set: @"appCursorMode"
                            value: [NSNumber numberWithBool: YES]];
                break;
            case TOGGLE_OFF:
                [[(TTTabController*) self shell]
                    MouseTerm_set: @"appCursorMode"
                            value: [NSNumber numberWithBool: NO]];
                break;
            }
        }
    }

    [self MouseTerm_shellDidReceiveData: data];
}

@end

@implementation NSView (MouseTermTTView)

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

- (BOOL) MouseTerm_shouldIgnoreDown: (NSEvent*) event
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

    MouseTermTTShell* shell = [[(TTView*) self controller] shell];
    if (![(NSNumber*) [shell MouseTerm_get: @"isMouseDown"] boolValue])
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

    MouseTermTTShell* shell = [[(TTView*) self controller] shell];
    switch ([(NSNumber*) [shell MouseTerm_get: @"mouseMode"] intValue])
    {
    case NO_MODE:
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        [shell MouseTerm_set: @"isMouseDown"
                       value: [NSNumber numberWithBool: YES]];
        Position pos = [self MouseTerm_currentPosition: event];
        NSData* data = mousePress(MOUSE_BUTTON1, [event modifierFlags],
                                  pos.x, pos.y);
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
    if ([self MouseTerm_shouldIgnoreDown: event])
        goto ignored;

    MouseTermTTShell* shell = [[(TTView*) self controller] shell];
    switch ([(NSNumber*) [shell MouseTerm_get: @"mouseMode"] intValue])
    {
    case NO_MODE:
        goto ignored;
    case NORMAL_MODE:
    case HILITE_MODE:
        goto handled;
    case BUTTON_MODE:
    case ALL_MODE:
    {
        Position pos = [self MouseTerm_currentPosition: event];
        NSData* data = mouseMotion(MOUSE_RELEASE, [event modifierFlags],
                                   pos.x, pos.y);
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
    if ([self MouseTerm_shouldIgnoreDown: event])
        goto ignored;

    MouseTermTTShell* shell = [[(TTView*) self controller] shell];
    switch ([(NSNumber*) [shell MouseTerm_get: @"mouseMode"] intValue])
    {
    case NO_MODE:
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        [shell MouseTerm_set: @"isMouseDown"
                       value: [NSNumber numberWithBool: NO]];
        Position pos = [self MouseTerm_currentPosition: event];
        NSData* data = mousePress(MOUSE_RELEASE, [event modifierFlags],
                                  pos.x, pos.y);
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
    MouseTermTTShell* shell = [[(TTView*) self controller] shell];

    switch ([(NSNumber*) [shell MouseTerm_get: @"mouseMode"] intValue])
    {
    case NO_MODE:
    {
        if ([screen isAlternateScreenActive]
            &&
            [(NSNumber*) [shell MouseTerm_get: @"appCursorMode"] boolValue])
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

        Position pos = [self MouseTerm_currentPosition: event];
        NSData* data = mousePress(button, [event modifierFlags], pos.x,
                                  pos.y);

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

@implementation NSObject (MouseTermTTShell)

- (NSValue*) MouseTerm_initVars
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [MouseTerm_ivars setObject: dict forKey: ptr];
        [dict setObject: [NSNumber numberWithInt: NO_MODE]
                 forKey: @"mouseMode"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"appCursorMode"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"isMouseDown"];
    }
    return ptr;
}

- (id) MouseTerm_get: (NSString*) name
{
    NSValue* ptr = [self MouseTerm_initVars];
    return [[MouseTerm_ivars objectForKey: ptr] objectForKey: name];
}

- (void) MouseTerm_set: (NSString*) name value: (id) value
{
    NSValue* ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr] setObject: value forKey: name];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];

    [self MouseTerm_dealloc];
}

@end
