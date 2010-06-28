#import <Cocoa/Cocoa.h>
#import "MTTabController.h"
#import "MTShell.h"
#import "Mouse.h"
#import "Terminal.h"

@implementation NSObject (MTTabController)

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
					[[(TTTabController*) self shell] MouseTerm_setMouseMode: mouseMode];
                    break;
                case TOGGLE_OFF:
					[[(TTTabController*) self shell] MouseTerm_setMouseMode: NO_MODE];
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
