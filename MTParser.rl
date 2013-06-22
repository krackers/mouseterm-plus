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

    action handle_digit
    {
        state.pendingDigit = (fc - '0');
    }

    action handle_dcs
    {
        const char *it = p;
        const char *end = data + len;
        if (++it != end) {
            if (*it != '\x1b' || *it != '\x90') {
                if (++it != end) {
                    if (*it != '\x1b' || *it != '\x90') {
                        if (++it != end) {
                            if (*it != '\x1b' || *it != '\x90') {
                                *(char*)p = ']';
                                *(char*)(p + 1) = '4';
                                *(char*)(p + 2) = ';';
                            }
                        }
                    }
                }
            } 
        }
    }

    action handle_sda
    {
        state.handleSda = YES;
    }

    action handle_mouse_mode
    {
        int mouseMode = state.pendingDigit;
        switch (mouseMode)
        {
        case 0:
            if (state.toggleState)
                [mobj MouseTerm_setMouseMode: NORMAL_MODE];
            else
                [mobj MouseTerm_setMouseMode: NO_MODE];
            break;
        case 1:
            if (state.toggleState)
                [mobj MouseTerm_setMouseMode: HILITE_MODE];
            else
                [mobj MouseTerm_setMouseMode: NO_MODE];
            break;
        case 2:
            if (state.toggleState)
                [mobj MouseTerm_setMouseMode: BUTTON_MODE];
            else
                [mobj MouseTerm_setMouseMode: NO_MODE];
            break;
        case 3:
            if (state.toggleState)
                [mobj MouseTerm_setMouseMode: ALL_MODE];
            else
                [mobj MouseTerm_setMouseMode: NO_MODE];
            break;
        case 4:
            if (state.toggleState)
                [mobj MouseTerm_setFocusMode: YES];
            else
                [mobj MouseTerm_setFocusMode: NO];
            break;
        default:
            break;
        }
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

    action handle_titlepush
    {
        switch (state.pendingDigit)
        {
        case 0:
            [mobj MouseTerm_pushWindowTitle];
            [mobj MouseTerm_pushTabTitle];
            break;
        case 1:
            [mobj MouseTerm_pushTabTitle];
            break;
        case 2:
            [mobj MouseTerm_pushWindowTitle];
            break;
        default:
            break;
        }
    }

    action handle_titlepop
    {
        switch (state.pendingDigit)
        {
        case 0:
            [mobj MouseTerm_popWindowTitle];
            [mobj MouseTerm_popTabTitle];
            break;
        case 1:
            [mobj MouseTerm_popTabTitle];
            break;
        case 2:
            [mobj MouseTerm_popWindowTitle];
            break;
        default:
            break;
        }
    }

    esc = 0x1b;
    csi = esc . "[";
    flag = ("h" | "l") @handle_flag;
    osc = esc . ']';
    dcs = esc . 'P';
    appkeys = "1";
    mouse = "100" . ([01234]) @handle_digit;
    debug = (csi . "li");
    cs_sda = csi . ">" . [01]? . "c";
    cs_titlepush = csi . "22;" . ([012]?) @handle_digit . "t";
    cs_titlepop = csi . "23;" . ([012]?) @handle_digit . "t";
    mode_toggle = csi . "?" . (mouse . flag @handle_mouse_mode
                               | "1015" . flag @handle_urxvt_protocol
                               | "1006" . flag @handle_sgr_protocol
                               | appkeys . flag @handle_appkeys);
    bel = 0x07;
    st  = esc . "\\" | 0x9c;
    base64 = ([a-zA-Z0-9\+/]+[=]*);
    osc52 = osc . "52;" . [psc0-9]* . (";" @handle_osc52_set_start)
                                    . ("?" @handle_osc52_get)?;

    main := ((base64 @handle_osc52
              | (bel | st) @handle_osc_end
              | dcs @handle_dcs
              | any - csi
              | any - osc)* . (mode_toggle # @got_toggle
                               | osc52
                               | cs_sda @handle_sda
                               | cs_titlepush @handle_titlepush
                               | cs_titlepop @handle_titlepop
                               | debug @got_debug))*;
}%%

%% write data;

static NSMutableData *osc52Buffer = nil;

int MTParser_execute(char* data, int len, BOOL isEof, id obj,
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
