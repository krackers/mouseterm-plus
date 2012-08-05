#import <Cocoa/Cocoa.h>
#import <math.h>
#import "Mouse.h"
#import "MouseTerm.h"
#import "MTParser.h"
#import "MTParserState.h"
#import "MTShell.h"
#import "MTView.h"
#import "MTTabController.h"
#import "Terminal.h"

%%{
    machine EscapeSeqParser;
    action got_toggle {}
    action got_debug {}
    action handle_flag
    {
        state.toggleState = (fc == 'h');
    }

    action handle_appkeys
    {
        [mobj MouseTerm_setAppCursorMode: state.toggleState];
    }

    action handle_mouse_digit
    {
        state.pendingMouseMode = (fc - 48);
    }

    action handle_sda
    {
        state.handleSda = YES;
    }

    action handle_mouse_mode
    {
        int mouseMode = state.pendingMouseMode;
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
        if (newMouseMode != NO_MODE && state.toggleState)
            [mobj MouseTerm_setMouseMode: newMouseMode];
        else
            [mobj MouseTerm_setMouseMode: NO_MODE];
    }

    action handle_urxvt_protocol
    {
        if (state.toggleState)
            [mobj MouseTerm_setMouseProtocol: URXVT_PROTOCOL];
        else
            [mobj MouseTerm_setMouseProtocol: NORMAL_PROTOCOL];
    }

    action handle_sgr_protocol
    {
        if (state.toggleState)
            [mobj MouseTerm_setMouseProtocol: SGR_PROTOCOL];
        else
            [mobj MouseTerm_setMouseProtocol: NORMAL_PROTOCOL];
    }

    action handle_osc52_set_start
    {
        if ([NSView MouseTerm_getBase64CopyEnabled]) {
            if (osc52Buffer)
                [osc52Buffer release];
            osc52Buffer = [[NSMutableData alloc] init];
        }
    }

    action handle_osc52_get
    {
        if (osc52Buffer) {
            [osc52Buffer release];
            osc52Buffer = nil;
        }
        if ([NSView MouseTerm_getBase64PasteEnabled]) {
            [mobj MouseTerm_osc52GetAccess];
        }
    }

    action handle_osc52
    {
        if (osc52Buffer)
            [osc52Buffer appendBytes: &fc length: 1];
    }

    action handle_osc_end
    {
        if (osc52Buffer) {
            NSString *str= [[NSString alloc] initWithData:osc52Buffer 
                                                 encoding:NSASCIIStringEncoding];
            [mobj MouseTerm_osc52SetAccess:str];
            [osc52Buffer release];
            osc52Buffer = nil;
        }
    }

    esc = 0x1b;
    csi = esc . "[";
    flag = ("h" | "l") @handle_flag;
    osc = esc . ']';
    dcs = esc . 'P';
    appkeys = "1";
    mouse = "100" . ([0123]) @handle_mouse_digit;
    debug = (csi . "li");
    cs_sda = csi . ">" . [01]? . "c";
    mode_toggle = csi . "?" . (appkeys . flag @handle_flag @handle_appkeys
                               | mouse . flag @handle_flag @handle_mouse_mode
                               | "1015" . flag @handle_flag @handle_urxvt_protocol
                               | "1006" . flag @handle_flag @handle_sgr_protocol);
    bel = 0x07;
    st  = esc . "\\" | 0x9c;
    base64 = ([a-zA-Z0-9\+/]+[=]*);
    osc52 = osc . "52;" . [psc0-9]* . (";" @handle_osc52_set_start)
                                    . ("?" @handle_osc52_get)?;

    main := ((base64 @handle_osc52
              | (bel | st) @handle_osc_end
              | any - csi
              | any - osc)* . (mode_toggle # @got_toggle
                               | osc52
                               | cs_sda @handle_sda
                               | debug @got_debug))*;
}%%

%% write data;

static NSMutableData *osc52Buffer = nil;

int MTParser_execute(const char* data, int len, BOOL isEof, id obj,
                     MTParserState* state)
{
    const char* p = data;
    const char* pe = data + len;
    const char* eof __attribute__((unused)) = isEof ? pe : 0;

    int cs = state.currentState;
    MTShell* mobj = (MTShell*) obj;
    [NSThread currentThread];

    %%write init nocs;
    %%write exec;

    state.currentState = cs;

    if (cs == EscapeSeqParser_error)
        return -1;
    if (cs >= EscapeSeqParser_first_final)
        return 1;
    return 0;
}
