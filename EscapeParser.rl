#import <Cocoa/Cocoa.h>
#import <math.h>
#import "EscapeParser.h"
#import "Mouse.h"
#import "MouseTerm.h"
#import "MTShell.h"
#import "MTTabController.h"
#import "Terminal.h"

%%{
    machine EscapeSeqParser;
    action got_toggle {}
    action got_debug {}
    action handle_flag
    {
        stateObj.toggleState = (fc == 'h' ? YES : NO);
    }

    action handle_appkeys
    {
        [mobj MouseTerm_setAppCursorMode: stateObj.toggleState];
    }

    action handle_mouse_digit
    {
        stateObj.pendingMouseMode = (fc - 48);
    }

    action handle_sda
    {
        stateObj.handleSda = YES;
    }

    action handle_mouse
    {
        int mouseMode = stateObj.pendingMouseMode;
        MouseMode newMouseMode = NO_MODE;
        switch (mouseMode)
        {
        case 0:
            newMouseMode = NORMAL_MODE;
            break;
        case 1:
            newMouseMode = HILITE_MODE;
            break;
        case 2:
            newMouseMode = BUTTON_MODE;
            break;
        case 3:
            newMouseMode = ALL_MODE;
            break;
        default:
            newMouseMode = NO_MODE;
        }
        if (newMouseMode != NO_MODE && stateObj.toggleState)
            [mobj MouseTerm_setMouseMode: newMouseMode];
        else
            [mobj MouseTerm_setMouseMode: NO_MODE];
    }

    esc = 0x1b;
    csi = esc . "[";
    flag = ("h" | "l") @handle_flag;
    osc = esc . ']';
    appkeys = "1";
    mouse = "100" . ([0123]) @handle_mouse_digit;
    debug = (csi . "li");
    cs_sda = csi . ">" . [01]? . "c";
    mode_toggle = csi . "?" . (appkeys . flag @handle_flag @handle_appkeys
                               | mouse . flag @handle_flag @handle_mouse );
    bel = 0x07;
    st  = 0x9c;

    main := ((any - csi | any - osc)* . (mode_toggle # @got_toggle
                                         | cs_sda @handle_sda
                                         | debug @got_debug))*;
}%%

%% write data;

int EscapeParser_execute(const char* data, int len, BOOL isEof, id obj,
                         MTEscapeParserState* stateObj)
{
    const char* p = data;
    const char* pe = data + len;
    const char* eof = isEof ? pe : 0;

    int cs = stateObj.currentState;
    MTShell* mobj = (MTShell*) obj;
    NSThread* ct = [NSThread currentThread];

    %%write init nocs;
    %%write exec;

    stateObj.currentState = cs;

    if (cs == EscapeSeqParser_error)
        return -1;
    if (cs >= EscapeSeqParser_first_final)
        return 1;
    return 0;
}
