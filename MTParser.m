
#import <Cocoa/Cocoa.h>
#import "Mouse.h"
#import "MouseTerm.h"
#import "MTParser.h"
#import "MTParserState.h"
#import "MTShell.h"
#import "MTView.h"
#import "MTTabController.h"
#import "Terminal.h"

static NSMutableData *osc52Buffer = nil;

enum parse_state {
    PS_GROUND              =  0,
    PS_ESCAPE              =  1,
    PS_ESCAPE_INTERMEDIATE =  2,
    PS_CSI_ENTRY           =  3,
    PS_CSI_PARAM           =  4,
    PS_CSI_INTERMEDIATE    =  5,
    PS_CSI_IGNORE          =  6,
    PS_DCS_ENTRY           =  7,
    PS_DCS_PARAM           =  8,
    PS_DCS_INTERMEDIATE    =  9,
    PS_DCS_PASSTHROUGH     = 10,
    PS_DCS_IGNORE          = 11,
    PS_OSC_STRING          = 12,
    PS_SOS_PM_APC_STRING   = 13,
};
enum osc_parse_state {
    OPS_COMMAND     = 1,
    OPS_SELECTION   = 2,
    OPS_PASSTHROUGH = 3,
    OPS_IGNORE      = 4,
};

static int current_param = 0;
static enum parse_state ps = PS_GROUND;
static enum osc_parse_state ops = OPS_IGNORE;
static int const param_bufsize = 256;
static int params_index = 0;
static int params[param_bufsize];
static int action = 0;

static void osc_clear()
{
    ops = OPS_IGNORE;
}

static void osc_start()
{
    current_param = 0;
    ops = OPS_COMMAND;
}

static void osc_put(char const c)
{
    switch (ops) {
    case OPS_COMMAND:
        switch (c) {
        case 0x30 ... 0x39:
            if (current_param < 6554)
                current_param = current_param * 10 + c - 0x30;
            break;
        case 0x3b:
            if (current_param == 52) {
                ops = OPS_SELECTION;
            } else {
                ops = OPS_IGNORE;
            }
            break;
        default:
            ops = OPS_IGNORE;
            break;
        }
        break;
    case OPS_SELECTION:
        switch (c) {
        case 0x30 ... 0x37:
        case 0x63:
        case 0x70:
        case 0x73:
            break;
        case 0x3b:
            [osc52Buffer release];
            osc52Buffer = [[NSMutableData alloc] init];
            ops = OPS_PASSTHROUGH;
            break;
        default:
            break;
        }
        break;
    case OPS_PASSTHROUGH:
        [osc52Buffer appendBytes: &c length: 1];
        break;
    case OPS_IGNORE:
    default:
        break;
    }
}

static void osc_end(MTShell *shell)
{
    if (osc52Buffer) {
        NSString *str= [[NSString alloc] initWithData:osc52Buffer 
                                             encoding:NSASCIIStringEncoding];
        if ([str isEqualToString:@"?"]) {
            if ([NSView MouseTerm_getBase64PasteEnabled]) {
                [shell MouseTerm_osc52GetAccess];
            }
        } else {
            [shell MouseTerm_osc52SetAccess:str];
        }
        [osc52Buffer release];
        osc52Buffer = nil;
    }
}

static void terminate_string(MTShell *shell)
{
    osc_end(shell);
}

static void init_param()
{
    params_index = 0;
}

static void push()
{
    if (params_index < param_bufsize)
        params[params_index++] = current_param;
    current_param = 0;
}

static void param(char const c)
{
    if (current_param < 6554)
        current_param = current_param * 10 + c - 0x30;
}

static void init_action()
{
    action = 0;
}

static void collect(char const c)
{
    action = action << 8 | c;
    if (action > 0x40 << 24) {
        action = (-1);
    }
}

static void handle_ris(MTShell *shell)
{
    [shell MouseTerm_setAppCursorMode: NO];
    [shell MouseTerm_setMouseMode: NO_MODE];
    [shell MouseTerm_setFocusMode: NO];
    [shell MouseTerm_setMouseProtocol: NORMAL_PROTOCOL];
    [osc52Buffer release];
    osc52Buffer = nil;
}

static void enable_extended_mode(MTShell *shell)
{
    int i;

    for (i = 0; i < params_index; ++i) {
        switch (params[i]) {
        case 1:
            [shell MouseTerm_setAppCursorMode: YES];
            break;
        case 1000:
            [shell MouseTerm_setMouseMode: NORMAL_MODE];
            break;
        case 1001:
            [shell MouseTerm_setMouseMode: HILITE_MODE];
            break;
        case 1002:
            [shell MouseTerm_setMouseMode: BUTTON_MODE];
            break;
        case 1003:
            [shell MouseTerm_setMouseMode: ALL_MODE];
            break;
        case 1004:
            [shell MouseTerm_setFocusMode: YES];
            break;
        case 1006:
            [shell MouseTerm_setMouseProtocol: SGR_PROTOCOL];
            break;
        case 1015:
            [shell MouseTerm_setMouseProtocol: URXVT_PROTOCOL];
            break;
        default:
            break;
        }
    }
}

static void disable_extended_mode(MTShell *shell)
{
    int i;

    for (i = 0; i < params_index; ++i) {
        switch (params[i]) {
        case 1:
            [shell MouseTerm_setAppCursorMode: NO];
            break;
        case 1000:
        case 1001:
        case 1002:
        case 1003:
            [shell MouseTerm_setMouseMode: NO_MODE];
            break;
        case 1004:
            [shell MouseTerm_setFocusMode: NO];
            break;
        case 1006:
        case 1015:
            [shell MouseTerm_setMouseProtocol: NORMAL_PROTOCOL];
            break;
        default:
            break;
        }
    }
}

static void push_title(MTShell *shell, int param)
{
    switch (param) {
    case 0:
        [shell MouseTerm_pushWindowTitle];
        [shell MouseTerm_pushTabTitle];
        break;
    case 1:
        [shell MouseTerm_pushTabTitle];
        break;
    case 2:
        [shell MouseTerm_pushWindowTitle];
        break;
    default:
        break;
    }
}

static void pop_title(MTShell *shell, int param)
{
    switch (param) {
    case 0:
        [shell MouseTerm_popWindowTitle];
        [shell MouseTerm_popTabTitle];
        break;
    case 1:
        [shell MouseTerm_popTabTitle];
        break;
    case 2:
        [shell MouseTerm_popWindowTitle];
        break;
    default:
        break;
    }
}

static void esc_dispatch(MTShell *shell)
{
    switch (action) {
    case 'c':
        handle_ris(shell);
        break;
    default:
        break;
    }
}

static void csi_dispatch(MTShell *shell, MTParserState *state)
{
    switch (action) {
    case ('>' << 8) | 'c':
        state.handleSda = YES;
        break;
    case ('?' << 8) | 'h':
        enable_extended_mode(shell);
        break;
    case ('?' << 8) | 'l':
        disable_extended_mode(shell);
        break;
    case 't':
        if (params_index > 0) {
            switch (params[0]) {
            case 22:
                if (params_index == 1)
                    push_title(shell, 0);
                else
                    push_title(shell, params[1]);
                break;
            case 23:
                if (params_index == 1)
                    pop_title(shell, 0);
                else
                    pop_title(shell, params[1]);
                break;
            default:
                break;
            }
        }
        break;
    default:
        break;
    }
}

int MTParser_execute(char* data, int len, BOOL isEof, id obj,
                     MTParserState* state)
{
    char* p;

    for (p = data; p != data + len; ++p) {
        switch (ps) {
        case PS_GROUND:
            switch (*p) {
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            default:
                break;
            }
            break;
        case PS_ESCAPE:
            init_action();
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                ps = PS_ESCAPE_INTERMEDIATE;
                break;
            case 0x30 ... 0x4f:
                ps = PS_GROUND;
                break;
            case 0x50:
                ps = PS_DCS_ENTRY;
                break;
            case 0x51 ... 0x57:
                ps = PS_GROUND;
                break;
            case 0x58:
                ps = PS_SOS_PM_APC_STRING;
                break;
            case 0x59 ... 0x5a:
                ps = PS_GROUND;
                break;
            case 0x5b:
                ps = PS_CSI_ENTRY;
                break;
            case 0x5c:
                terminate_string((MTShell *)obj);
                ps = PS_GROUND;
                break;
            case 0x5d:
                osc_start();
                ps = PS_OSC_STRING;
                break;
            case 0x5e ... 0x5f:
                ps = PS_SOS_PM_APC_STRING;
                break;
            case 0x60 ... 0x7e:
                collect(*p);
                esc_dispatch((MTShell *)obj);
                ps = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_ESCAPE_INTERMEDIATE:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                collect(*p);
                break;
            case 0x30 ... 0x7e:
                collect(*p);
                esc_dispatch((MTShell *)obj);
                ps = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_ENTRY:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                ps = PS_CSI_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                init_param();
                param(*p);
                ps = PS_CSI_PARAM;
                break;
            case 0x3a:
                ps = PS_CSI_IGNORE;
                break;
            case 0x3b:
                init_param();
                push();
                ps = PS_CSI_PARAM;
                break;
            case 0x3c ... 0x3f:
                collect(*p);
                ps = PS_CSI_PARAM;
                break;
            case 0x40 ... 0x7e:
                init_param();
                collect(*p);
                csi_dispatch((MTShell *)obj, state);
                ps = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_PARAM:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                collect(*p);
                ps = PS_CSI_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                param(*p);
                break;
            case 0x3a:
                ps = PS_CSI_IGNORE;
                break;
            case 0x3b:
                push();
                break;
            case 0x3c ... 0x3f:
                ps = PS_CSI_IGNORE;
                break;
            case 0x40 ... 0x7e:
                push();
                collect(*p);
                csi_dispatch((MTShell *)obj, state);
                ps = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_INTERMEDIATE:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                collect(*p);
                break;
            case 0x30 ... 0x3f:
                ps = PS_CSI_IGNORE;
                break;
            case 0x40 ... 0x7e:
                collect(*p);
                csi_dispatch((MTShell *)obj, state);
                ps = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_IGNORE:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x3f:
                break;
            case 0x40 ... 0x7e:
                ps = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_ENTRY:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                *p = '\0';
                ps = PS_DCS_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                *p = '\0';
                ps = PS_DCS_PARAM;
                break;
            case 0x3a:
                *p = '\0';
                ps = PS_DCS_IGNORE;
                break;
            case 0x3b:
                *p = '\0';
                ps = PS_DCS_PARAM;
                break;
            case 0x3c ... 0x3f:
                *p = '\0';
                ps = PS_DCS_PARAM;
                break;
            case 0x40 ... 0x7e:
                *p = '\0';
                ps = PS_DCS_PASSTHROUGH;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_PARAM:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                *p = '\0';
                ps = PS_DCS_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                *p = '\0';
                ps = PS_DCS_PARAM;
                break;
            case 0x3a:
                *p = '\0';
                ps = PS_DCS_IGNORE;
                break;
            case 0x3b:
                *p = '\0';
                ps = PS_DCS_PARAM;
                break;
            case 0x3c ... 0x3f:
                *p = '\0';
                ps = PS_DCS_IGNORE;
                break;
            case 0x40 ... 0x7e:
                *p = '\0';
                ps = PS_DCS_PASSTHROUGH;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_INTERMEDIATE:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                *p = '\0';
                break;
            case 0x30 ... 0x3f:
                *p = '\0';
                ps = PS_DCS_IGNORE;
                break;
            case 0x40 ... 0x7e:
                *p = '\0';
                ps = PS_DCS_PASSTHROUGH;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_PASSTHROUGH:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x20 ... 0x7e:
                *p = '\0';
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_IGNORE:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x20 ... 0x7f:
                *p = '\0';
                break;
            default:
                *p = '\0';
                break;
            }
            break;
        case PS_OSC_STRING:
            switch (*p) {
            case 0x00 ... 0x06:
                break;
            case 0x07:
                osc_end((MTShell *)obj);
                break;
            case 0x08 ... 0x17:
                break;
            case 0x18:
                osc_clear();
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                osc_clear();
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x20 ... 0x7f:
                osc_put(*p);
                break;
            default:
                break;
            }
            break;
        case PS_SOS_PM_APC_STRING:
            switch (*p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ps = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ps = PS_GROUND;
                break;
            case 0x1b:
                ps = PS_ESCAPE;
                break;
            case 0x20 ... 0x7f:
                break;
            default:
                break;
            }
            break;
        }
    }
    return 0;
}

/* EOF */
