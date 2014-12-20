
#import <Cocoa/Cocoa.h>
#import "MTParser.h"
#import "MTShell.h"
#import "MTView.h"

static void osc_start(struct parse_context *ppc)
{
    ppc->current_param = 0;
    ppc->action = 0x5d;
    ppc->osc_state = OPS_COMMAND;
}

static void osc_put(struct parse_context *ppc)
{
    switch (ppc->osc_state) {
    case OPS_COMMAND:
        switch (*ppc->p) {
        case 0x30 ... 0x39:
            if (ppc->current_param < 6554)
                ppc->current_param = ppc->current_param * 10 + *ppc->p - 0x30;
            break;
        case 0x3b:
            if (ppc->current_param == 52) {
                ppc->osc_state = OPS_SELECTION;
            } else {
                ppc->osc_state = OPS_IGNORE;
            }
            break;
        default:
            ppc->osc_state = OPS_IGNORE;
            break;
        }
        break;
    case OPS_SELECTION:
        switch (*ppc->p) {
        case 0x30 ... 0x37:
        case 0x63:
        case 0x70:
        case 0x73:
            break;
        case 0x3b:
            [ppc->osc52Buffer release];
            ppc->osc52Buffer = [[NSMutableData alloc] init];
            ppc->osc_state = OPS_PASSTHROUGH;
            break;
        default:
            break;
        }
        break;
    case OPS_PASSTHROUGH:
        [ppc->osc52Buffer appendBytes: ppc->p length: 1];
        break;
    case OPS_IGNORE:
    default:
        break;
    }
}

static void osc_end(struct parse_context *ppc, MTShell *shell)
{
    if (ppc->action == 0x5d && ppc->osc_state == OPS_PASSTHROUGH) {
        if (ppc->osc52Buffer) {
            NSString *str= [[NSString alloc] initWithData:ppc->osc52Buffer
                                                 encoding:NSASCIIStringEncoding];
            if ([str isEqualToString:@"?"]) {
                if ([NSView MouseTerm_getBase64PasteEnabled]) {
                    [shell MouseTerm_osc52GetAccess];
                }
            } else {
                [shell MouseTerm_osc52SetAccess:str];
            }
            [ppc->osc52Buffer release];
            ppc->osc52Buffer = nil;
        }
        ppc->action = 0;
    }
}

static void terminate_string(struct parse_context *ppc, MTShell *shell)
{
    osc_end(ppc, shell);
}

static void init_param(struct parse_context *ppc)
{
    ppc->params_index = 0;
}

static void push(struct parse_context *ppc)
{
    if (ppc->params_index < param_bufsize)
        ppc->params[ppc->params_index++] = ppc->current_param;
    ppc->current_param = 0;
}

static void param(struct parse_context *ppc)
{
    if (ppc->current_param < 6554)
        ppc->current_param = ppc->current_param * 10 + *ppc->p - 0x30;
}

static void init_action(struct parse_context *ppc)
{
    ppc->action = 0;
}

static void collect(struct parse_context *ppc)
{
    ppc->action = ppc->action << 8 | *ppc->p;
    if (ppc->action > 0x40 << 24) {
        ppc->action = (-1);
    }
}

static void handle_ris(struct parse_context *ppc, MTShell *shell)
{
    [shell MouseTerm_setAppCursorMode: NO];
    [shell MouseTerm_setMouseMode: NO_MODE];
    [shell MouseTerm_setFocusMode: NO];
    [shell MouseTerm_setMouseProtocol: NORMAL_PROTOCOL];
    [ppc->osc52Buffer release];
    ppc->osc52Buffer = nil;
}

static void enable_extended_mode(struct parse_context *ppc, MTShell *shell)
{
    int i;

    for (i = 0; i < ppc->params_index; ++i) {
        switch (ppc->params[i]) {
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

static void disable_extended_mode(struct parse_context *ppc, MTShell *shell)
{
    int i;

    for (i = 0; i < ppc->params_index; ++i) {
        switch (ppc->params[i]) {
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

static void esc_dispatch(struct parse_context *ppc, MTShell *shell)
{
    switch (ppc->action) {
    case 'c':
        handle_ris(ppc, shell);
        break;
    default:
        break;
    }
}

static void csi_dispatch(struct parse_context *ppc, MTShell *shell)
{
    switch (ppc->action) {
    case ('>' << 8) | 'c':
        [(TTShell*) shell writeData: [NSData dataWithBytes: SDA_RESPONSE
                                                    length: SDA_RESPONSE_LEN]];
        *ppc->p = 0x7f;
        break;
    case ('?' << 8) | 'h':
        enable_extended_mode(ppc, shell);
        break;
    case ('?' << 8) | 'l':
        disable_extended_mode(ppc, shell);
        break;
    case 't':
        if (ppc->params_index > 0) {
            switch (ppc->params[0]) {
            case 22:
                if (ppc->params_index == 1)
                    push_title(shell, 0);
                else
                    push_title(shell, ppc->params[1]);
                break;
            case 23:
                if (ppc->params_index == 1)
                    pop_title(shell, 0);
                else
                    pop_title(shell, ppc->params[1]);
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

int MTParser_execute(char* data, int len, id obj)
{

    MTShell *shell = (MTShell *)obj;
    struct parse_context *ppc = [shell MouseTerm_getParseContext];
    if (!ppc) {
        return 0;
    }

    for (ppc->p = data; ppc->p != data + len; ++ppc->p) {
        switch (ppc->state) {
        case PS_GROUND:
            switch (*ppc->p) {
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            default:
                break;
            }
            break;
        case PS_ESCAPE:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                init_action(ppc);
                ppc->state = PS_ESCAPE_INTERMEDIATE;
                break;
            case 0x30 ... 0x4f:
                init_action(ppc);
                ppc->state = PS_GROUND;
                break;
            case 0x50:
                init_action(ppc);
                ppc->state = PS_DCS_ENTRY;
                break;
            case 0x51 ... 0x57:
                init_action(ppc);
                ppc->state = PS_GROUND;
                break;
            case 0x58:
                init_action(ppc);
                ppc->state = PS_SOS_PM_APC_STRING;
                break;
            case 0x59 ... 0x5a:
                init_action(ppc);
                ppc->state = PS_GROUND;
                break;
            case 0x5b:
                init_action(ppc);
                ppc->state = PS_CSI_ENTRY;
                break;
            case 0x5c:
                terminate_string(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
                break;
            case 0x5d:
                osc_start(ppc);
                ppc->state = PS_OSC_STRING;
                break;
            case 0x5e ... 0x5f:
                init_action(ppc);
                ppc->state = PS_SOS_PM_APC_STRING;
                break;
            case 0x60 ... 0x7e:
                init_action(ppc);
                collect(ppc);
                esc_dispatch(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_ESCAPE_INTERMEDIATE:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                collect(ppc);
                break;
            case 0x30 ... 0x7e:
                collect(ppc);
                esc_dispatch(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_ENTRY:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                ppc->state = PS_CSI_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                init_param(ppc);
                param(ppc);
                ppc->state = PS_CSI_PARAM;
                break;
            case 0x3a:
                ppc->state = PS_CSI_IGNORE;
                break;
            case 0x3b:
                init_param(ppc);
                push(ppc);
                ppc->state = PS_CSI_PARAM;
                break;
            case 0x3c ... 0x3f:
                collect(ppc);
                ppc->state = PS_CSI_PARAM;
                break;
            case 0x40 ... 0x7e:
                init_param(ppc);
                collect(ppc);
                csi_dispatch(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_PARAM:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                collect(ppc);
                ppc->state = PS_CSI_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                param(ppc);
                break;
            case 0x3a:
                ppc->state = PS_CSI_IGNORE;
                break;
            case 0x3b:
                push(ppc);
                break;
            case 0x3c ... 0x3f:
                ppc->state = PS_CSI_IGNORE;
                break;
            case 0x40 ... 0x7e:
                push(ppc);
                collect(ppc);
                csi_dispatch(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_INTERMEDIATE:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                collect(ppc);
                break;
            case 0x30 ... 0x3f:
                ppc->state = PS_CSI_IGNORE;
                break;
            case 0x40 ... 0x7e:
                collect(ppc);
                csi_dispatch(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_CSI_IGNORE:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x3f:
                break;
            case 0x40 ... 0x7e:
                ppc->state = PS_GROUND;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_ENTRY:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                *ppc->p = '\0';
                ppc->state = PS_DCS_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3a:
                *ppc->p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x3b:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3c ... 0x3f:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x40 ... 0x7e:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PASSTHROUGH;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_PARAM:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                *ppc->p = '\0';
                ppc->state = PS_DCS_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3a:
                *ppc->p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x3b:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3c ... 0x3f:
                *ppc->p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x40 ... 0x7e:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PASSTHROUGH;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_INTERMEDIATE:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x1c ... 0x1f:
                break;
            case 0x20 ... 0x2f:
                *ppc->p = '\0';
                break;
            case 0x30 ... 0x3f:
                *ppc->p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x40 ... 0x7e:
                *ppc->p = '\0';
                ppc->state = PS_DCS_PASSTHROUGH;
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_PASSTHROUGH:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x20 ... 0x7e:
                *ppc->p = '\0';
                break;
            case 0x7f:
                break;
            default:
                break;
            }
            break;
        case PS_DCS_IGNORE:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x20 ... 0x7f:
                *ppc->p = '\0';
                break;
            default:
                *ppc->p = '\0';
                break;
            }
            break;
        case PS_OSC_STRING:
            switch (*ppc->p) {
            case 0x00 ... 0x06:
                break;
            case 0x07:
                osc_end(ppc, (MTShell *)obj);
                break;
            case 0x08 ... 0x17:
                break;
            case 0x18:
                init_action(ppc);
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                init_action(ppc);
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            case 0x20 ... 0x7f:
                osc_put(ppc);
                break;
            default:
                break;
            }
            break;
        case PS_SOS_PM_APC_STRING:
            switch (*ppc->p) {
            case 0x00 ... 0x17:
                break;
            case 0x18:
                ppc->state = PS_GROUND;
                break;
            case 0x19:
                break;
            case 0x1a:
                ppc->state = PS_GROUND;
                break;
            case 0x1b:
                ppc->state = PS_ESCAPE;
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
