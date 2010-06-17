#import <Cocoa/Cocoa.h>
#import <math.h>

#import "MouseTerm.h"
#import "Mouse.h"

inline NSValue* init_ivars(id obj)
{
    NSValue* value = [NSValue valueWithPointer: obj];
    if ([MouseTerm_ivars objectForKey: value] == nil)
    {
        [MouseTerm_ivars setObject: [NSMutableDictionary dictionary]
                            forKey: value];
    }
    return value;
}

inline id get_ivar(id obj, NSString* name)
{
    NSValue* ptr = init_ivars(obj);
    return [[MouseTerm_ivars objectForKey: ptr] objectForKey: name];
}

inline void set_ivar(id obj, NSString* name, id value)
{
    NSValue* ptr = init_ivars(obj);
    [[MouseTerm_ivars objectForKey: ptr] setObject: value forKey: name];
}

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
                    set_ivar([self shell], @"mouseMode",
                             [NSNumber numberWithInt: mouseMode]);
                    break;
                case TOGGLE_OFF:
                    set_ivar([self shell], @"mouseMode",
                             [NSNumber numberWithInt: NO_MODE]);
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
                set_ivar([self shell], @"appCursorMode",
                         [NSNumber numberWithBool: YES]);
                break;
            case TOGGLE_OFF:
                set_ivar([self shell], @"appCursorMode",
                         [NSNumber numberWithBool: NO]);
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

    TTLogicalScreen* screen = [self logicalScreen];
    // Don't handle if the scroller isn't at the bottom
    linecount_t scrollback =
        (linecount_t) [screen lineCount] -
        (linecount_t) [self rowCount];
    if (scrollback > 0 &&
        [[[self pane] scroller] floatValue] < 1.0)
    {
        return YES;
    }

    return NO;
}

- (BOOL) MouseTerm_shouldIgnoreDown: (NSEvent*) event
{
    TTLogicalScreen* screen = [self logicalScreen];
    // Don't handle if the scroller isn't at the bottom
    linecount_t scrollback =
        (linecount_t) [screen lineCount] -
        (linecount_t) [self rowCount];
    if (scrollback > 0 &&
        [[[self pane] scroller] floatValue] < 1.0)
    {
        return YES;
    }

    TTShell* shell = [[self controller] shell];
    if (![(NSNumber*) get_ivar(shell, @"isMouseDown") boolValue])
        return YES;

    return NO;
}

- (Position) MouseTerm_currentPosition: (NSEvent*) event
{
    linecount_t scrollback =
        (linecount_t) [[self logicalScreen] lineCount] -
        (linecount_t) [self rowCount];
    NSPoint viewloc = [self convertPoint: [event locationInWindow]
                                fromView: nil];
    Position pos = [self displayPositionForPoint: viewloc];
    // The above method returns the position *including* scrollback,
    // so we have to compensate for that.
    pos.y -= scrollback;
    return pos;
}

- (void) MouseTerm_mouseDown: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnore: event])
        goto ignored;

    TTShell* shell = [[self controller] shell];
    switch ([(NSNumber*) get_ivar(shell, @"mouseMode") intValue])
    {
    case NO_MODE:
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        set_ivar(shell, @"isMouseDown", [NSNumber numberWithBool: YES]);
        Position pos = [self MouseTerm_currentPosition: event];
        NSData* data = mousePress(MOUSE_BUTTON1, [event modifierFlags],
                                  pos.x, pos.y);
        [shell writeData: data];

        goto handled;
    }
    }

handled:
    [self clearTextSelection];
    return;
ignored:
    [self MouseTerm_mouseDown: event];
}

- (void) MouseTerm_mouseDragged: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnoreDown: event])
        goto ignored;

    TTShell* shell = [[self controller] shell];
    switch ([(NSNumber*) get_ivar(shell, @"mouseMode") intValue])
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
        [shell writeData: data];

        goto handled;
    }
    }
handled:
    [self clearTextSelection];
    return;
ignored:
    [self MouseTerm_mouseDragged: event];
}

- (void) MouseTerm_mouseUp: (NSEvent*) event
{
    if ([self MouseTerm_shouldIgnoreDown: event])
        goto ignored;

    TTShell* shell = [[self controller] shell];
    switch ([(NSNumber*) get_ivar(shell, @"mouseMode") intValue])
    {
    case NO_MODE:
    case HILITE_MODE:
        goto ignored;
    case NORMAL_MODE:
    case BUTTON_MODE:
    case ALL_MODE:
    {
        set_ivar(shell, @"isMouseDown", [NSNumber numberWithBool: NO]);
        Position pos = [self MouseTerm_currentPosition: event];
        NSData* data = mousePress(MOUSE_RELEASE, [event modifierFlags],
                                  pos.x, pos.y);
        [shell writeData: data];

        goto handled;
    }
    }
handled:
    [self clearTextSelection];
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

    TTLogicalScreen* screen = [self logicalScreen];
    TTShell* shell = [[self controller] shell];

    switch ([(NSNumber*) get_ivar(shell, @"mouseMode") intValue])
    {
    case NO_MODE:
    {
        if ([screen isAlternateScreenActive]
            &&
            [(NSNumber*) get_ivar(shell, @"appCursorMode") boolValue])
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
                [shell writeData: data];

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
            [shell writeData: data];

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

// Initializes instance variables
- (TTShell*) MouseTerm_initWithAction: (SEL) arg1 target: (id) arg2
             profile: (id) arg3 controller: (id) arg4 customShell: (id) arg5
             commandAsShell: (BOOL) arg6
{
    [MouseTerm_ivars setObject: [NSMutableDictionary dictionary]
                        forKey: [NSValue valueWithPointer: self]];
    set_ivar(self, @"mouseMode", [NSNumber numberWithInt: NO_MODE]);
    set_ivar(self, @"appCursorMode", [NSNumber numberWithBool: NO]);
    set_ivar(self, @"isMouseDown", [NSNumber numberWithBool: NO]);
    return [self MouseTerm_initWithAction: arg1 target: arg2 profile: arg3
                               controller: arg4 customShell: arg5
                           commandAsShell: arg6];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];

    [self MouseTerm_dealloc];
}

@end
