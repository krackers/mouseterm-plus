
#import <Cocoa/Cocoa.h>
#import "MTParser.h"
#import "MTShell.h"
#import "MTView.h"

static int
parse_x_colorspec(MTShell *shell, char const *spec, int *red, int *green, int *blue)
{
    unsigned long long v;
    char const *p;
    int components[3];
    int index = 0;
    int component;
    char *endptr;

    if (strncmp(spec, "rgb:", 4) == 0) {
        p = spec + 4;
        while (p) {
            component = strtoul(p, &endptr, 16);
            if (component == ULONG_MAX)
                break;
            if (endptr - p == 0)
                break;
            if (endptr - p > 4)
                break;
            components[index++] = component << ((4 - (endptr - p)) * 4);
            p = endptr;
            if (index == 3)
                break;
            if (*p == '\0')
                break;
            if (*p != '/')
                break;
            ++p;
        }
        if (*p == '\0' || *p == '/')
            return (-1);
        if (index != 3)
            return (-1);
        *red = components[0];
        *green = components[1];
        *blue = components[2];
    } else if (*spec == '#') {
        p = spec + 1;
        v = strtoull(p, &endptr, 16);
        if (v == ULLONG_MAX)
            return (-1);
        if (*endptr != '\0')
            return (-1);
        if (endptr - p > 12)
            return (-1);
        switch (endptr - p) {
        case 3:
            *red   = (v & 0xf00) << 4;
            *green = (v & 0x0f0) << 8;
            *blue  = (v & 0x00f) << 12;
            break;
        case 6:
            *red   = (v & 0xff0000) >> 8;
            *green = (v & 0x00ff00);
            *blue  = (v & 0x0000ff) << 8;
            break;
        case 9:
            *red   = (v & 0xfff000000) >> 20;
            *green = (v & 0x000fff000) >> 8;
            *blue  = (v & 0x000000fff) << 4;
            break;
        case 12:
            *red   = (v & 0xffff00000000) >> 32;
            *green = (v & 0x0000ffff0000) >> 16;
            *blue  = (v & 0x00000000ffff);
            break;
        default:
            return (-1);
        }
    } else {
        NSMutableDictionary *colorNameMap = [shell MouseTerm_getColorNameMap];
        NSColor *color = [colorNameMap objectForKey: [[NSString stringWithUTF8String: spec] lowercaseString]];
        if (!color)
            return (-1);
        *red = (int)([color redComponent] * 0xffff);
        *green = (int)([color greenComponent] * 0xffff);
        *blue = (int)([color blueComponent] * 0xffff);
    }

    return 0;
}

static void osc4_get(MTShell *shell, int n)
{
    CGFloat components[8];
    int r, g, b;
    TTView *view = (TTView *)[[[shell controller] activePane] view];
    NSColor *color = [view MouseTerm_colorForANSIColor: 1000 + n];

    if (n > 255 || n < 0)
        return;
    if (![color isKindOfClass:[NSColor class]])
        return;
    color = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    [color getComponents: components];
    r = components[0] * 0xffff;
    g = components[1] * 0xffff;
    b = components[2] * 0xffff;
    NSString *spec = [NSString stringWithFormat: @"\033]4;%d;rgb:%04x/%04x/%04x\033\\", n, r, g, b];
    [(TTShell*) shell writeData: [NSData dataWithBytes: [spec UTF8String]
                                                length: spec.length]];
}

static void osc4_set(MTShell *shell, int n, char const *p)
{
    int r, g, b;
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    TTView *view = (TTView *)[[[shell controller] activePane] view];

    if (n > 255 || n < 0)
        return;
    if (parse_x_colorspec(shell, p, &r, &g, &b) != 0)
        return;
    if (palette) {
        NSColor *original_color = [view MouseTerm_colorForANSIColor: 1000 + n];
        original_color = [original_color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
        NSColor *color = [NSColor colorWithRed: (float)r / (1 << 16)
                                         green: (float)g / (1 << 16)
                                          blue: (float)b / (1 << 16)
                                         alpha: [original_color alphaComponent]];
        [palette setObject:color forKey: [NSNumber numberWithInt: n]];
        [view setNeedsDisplay: YES];
    }
}

static void osc4_reset(MTShell *shell, int n)
{
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    TTView *view = (TTView *)[[[shell controller] activePane] view];

    if (n > 255 || n < 0)
        return;
    [palette removeObjectForKey: [NSNumber numberWithInt: n]];
    [view setNeedsDisplay: YES];
}

static void osc4_resetall(MTShell *shell)
{
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    TTView *view = (TTView *)[[[shell controller] activePane] view];
    int n;

    for (n = 0; n < 256; ++n)
        [palette removeObjectForKey: [NSNumber numberWithInt: n]];
    [view setNeedsDisplay: YES];
}

static void osc10_get(MTShell *shell)
{
    CGFloat components[8];
    int r, g, b;
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    NSColor *color = [palette objectForKey: [NSNumber numberWithInt: -1]];
    if (!color)
        color = [[shell controller] scriptNormalTextColor];

    if (![color isKindOfClass:[NSColor class]])
        return;
    [color getComponents: components];
    r = components[0] * 0xffff;
    g = components[1] * 0xffff;
    b = components[2] * 0xffff;
    NSString *spec = [NSString stringWithFormat: @"\033]10;rgb:%04x/%04x/%04x\033\\", r, g, b];
    [(TTShell*) shell writeData: [NSData dataWithBytes: [spec UTF8String]
                                                length: spec.length]];
}

static void osc10_set(MTShell *shell, char const *p)
{
    int r, g, b;
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    NSColor *original_color = [[shell controller] scriptNormalTextColor];
    TTView *view = (TTView *)[[[shell controller] activePane] view];

    if (parse_x_colorspec(shell, p, &r, &g, &b) != 0)
        return;
    if (palette) {
        NSColor *color = [NSColor colorWithRed: (float)r / (1 << 16)
                                         green: (float)g / (1 << 16)
                                          blue: (float)b / (1 << 16)
                                         alpha: [original_color alphaComponent]];
        [palette setObject: color forKey: [NSNumber numberWithInt: -1]];
        [view setNeedsDisplay: YES];
    }
}

static void osc10_reset(MTShell *shell)
{
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    TTView *view = (TTView *)[[[shell controller] activePane] view];
    [palette removeObjectForKey: [NSNumber numberWithInt: -1]];
    [view setNeedsDisplay: YES];
}

static void osc11_get(MTShell *shell)
{
    CGFloat components[8];
    int r, g, b;
    NSColor *color = [[shell controller] scriptBackgroundColor];

    if (![color isKindOfClass: [NSColor class]])
        return;
    [color getComponents: components];
    r = components[0] * 0xffff;
    g = components[1] * 0xffff;
    b = components[2] * 0xffff;
    NSString *spec = [NSString stringWithFormat: @"\033]10;rgb:%04x/%04x/%04x\033\\", r, g, b];
    [(TTShell*) shell writeData: [NSData dataWithBytes: [spec UTF8String]
                                                length: spec.length]];
}

static void osc11_set(MTShell *shell, char const *p)
{
    int r, g, b;
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    NSColor *original_color = [[shell controller] scriptBackgroundColor];
    TTView *view = (TTView *)[[[shell controller] activePane] view];

    if (parse_x_colorspec(shell, p, &r, &g, &b) != 0)
        return;
    if (palette) {
        if (![palette objectForKey: @"background"])
            [palette setObject: original_color
                        forKey: @"background"];
        NSColor *color = [NSColor colorWithRed: (float)r / (1 << 16)
                                         green: (float)g / (1 << 16)
                                          blue: (float)b / (1 << 16)
                                         alpha: [original_color alphaComponent]];
        [[shell controller] setScriptBackgroundColor:color];
        [view setNeedsDisplay: YES];
    }
}

static void osc11_reset(MTShell *shell)
{
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    NSColor *color = [palette objectForKey: @"background"];
    TTView *view = (TTView *)[[[shell controller] activePane] view];

    if (color) {
        [palette removeObjectForKey: @"background"];
        [[shell controller] setScriptBackgroundColor:color];
        [view setNeedsDisplay: YES];
    }
}


static void osc12_get(MTShell *shell)
{
    CGFloat components[8];
    int r, g, b;
    NSColor *color = [[shell controller] scriptCursorColor];

    if (![color isKindOfClass: [NSColor class]])
        return;
    [color getComponents: components];
    r = components[0] * 0xffff;
    g = components[1] * 0xffff;
    b = components[2] * 0xffff;
    NSString *spec = [NSString stringWithFormat: @"\033]10;rgb:%04x/%04x/%04x\033\\", r, g, b];
    [(TTShell*) shell writeData: [NSData dataWithBytes: [spec UTF8String]
                                                length: spec.length]];
}

static void osc12_set(MTShell *shell, char const *p)
{
    int r, g, b;
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    NSColor *original_color = [[shell controller] scriptCursorColor];
    TTView *view = (TTView *)[[[shell controller] activePane] view];

    if (parse_x_colorspec(shell, p, &r, &g, &b) != 0)
        return;
    if (palette) {
        if (![palette objectForKey: @"cursor"])
            [palette setObject: original_color
                        forKey: @"cursor"];
        NSColor *color = [NSColor colorWithRed: (float)r / (1 << 16)
                                         green: (float)g / (1 << 16)
                                          blue: (float)b / (1 << 16)
                                         alpha: [original_color alphaComponent]];
        [[shell controller] setScriptCursorColor:color];
        [view setNeedsDisplay: YES];
    }
}

static void osc12_reset(MTShell *shell)
{
    NSMutableDictionary *palette = [shell MouseTerm_getPalette];
    NSColor *color = [palette objectForKey: @"cursor"];
    TTView *view = (TTView *)[[[shell controller] activePane] view];
    if (color) {
        [palette removeObjectForKey: @"cursor"];
        [[shell controller] setScriptCursorColor:color];
        [view setNeedsDisplay: YES];
    }
}

static void dcs_start(struct parse_context *ppc)
{
    ppc->current_param = 0;
    ppc->action = 0;
    [ppc->buffer release];
    ppc->buffer = [[NSMutableData alloc] init];
}

static void dcs_put(struct parse_context *ppc, char const *p)
{
    [ppc->buffer appendBytes: p length: 1];
}

static void dcs_end(struct parse_context *ppc, MTShell *shell)
{
    switch (ppc->action) {
    case '+' << 8 | 'q':
        [shell MouseTerm_tcapQuery:[[[NSString alloc] initWithData: ppc->buffer
                                                          encoding: NSASCIIStringEncoding] autorelease]];
        break;
    default:
        break;
    }
}

static void osc_start(struct parse_context *ppc, char const *p)
{
    ppc->current_param = 0;
    ppc->action = *p;
    ppc->osc_state = OPS_COMMAND;
}

static void osc_put(struct parse_context *ppc, char const *p)
{
    switch (ppc->osc_state) {
    case OPS_COMMAND:
        switch (*p) {
        case 0x30 ... 0x39:
            if (ppc->current_param < 6554)
                ppc->current_param = ppc->current_param * 10 + *p - 0x30;
            break;
        case 0x3b:
            switch (ppc->current_param) {
            case 4:
            case 10:
            case 11:
            case 12:
            case 104:
            case 110:
            case 111:
            case 112:
                [ppc->buffer release];
                ppc->buffer = [[NSMutableData alloc] init];
                ppc->osc_state = OPS_PASSTHROUGH;
                break;
            case 52:
                ppc->osc_state = OPS_SELECTION;
                break;
            default:
                ppc->osc_state = OPS_IGNORE;
                break;
            }
            break;
        default:
            ppc->osc_state = OPS_IGNORE;
            break;
        }
        break;
    case OPS_SELECTION:
        switch (*p) {
        case 0x30 ... 0x37:
        case 0x63:
        case 0x70:
        case 0x73:
            break;
        case 0x3b:
            [ppc->buffer release];
            ppc->buffer = [[NSMutableData alloc] init];
            ppc->osc_state = OPS_PASSTHROUGH;
            break;
        default:
            break;
        }
        break;
    case OPS_PASSTHROUGH:
        [ppc->buffer appendBytes: p length: 1];
        break;
    case OPS_IGNORE:
    default:
        break;
    }
}

static void osc_end(struct parse_context *ppc, MTShell *shell)
{
    NSString *str = nil;
    char *p;
    int n;

    switch (ppc->osc_state) {
    case OPS_COMMAND:
    case OPS_PASSTHROUGH:
        str= [[[NSString alloc] initWithData: ppc->buffer
                                    encoding: NSASCIIStringEncoding] autorelease];
        switch (ppc->current_param) {
        case 4:
            p = (char *)[str UTF8String];
            while (sscanf(p, "%d;", &n) == 1)
            {
                while (*p)
                    if (*p++ == 0x3b)
                        break;
                if (*p == '?')
                    osc4_get(shell, n);
                else
                    osc4_set(shell, n, p);
                while (*p)
                    if (*p++ == 0x3b)
                        break;
            }
            break;
        case 10:
            p = (char *)[str UTF8String];
            if (*p == '?')
                osc10_get(shell);
            else
                osc10_set(shell, p);
            break;
        case 11:
            p = (char *)[str UTF8String];
            if (*p == '?')
                osc11_get(shell);
            else
                osc11_set(shell, p);
            break;
        case 12:
            p = (char *)[str UTF8String];
            if (*p == '?')
                osc12_get(shell);
            else
                osc12_set(shell, p);
            break;
        case 104:
            p = (char *)[str UTF8String];
            if (*p == '\0' || (*p == ';' && *p == '\0')) {
                osc4_resetall(shell);
            } else {
                while (sscanf(p, "%d;", &n) == 1) {
                    osc4_reset(shell, n);
                    while (*p)
                        if (*p++ == 0x3b)
                            break;
                }
            }
            break;
        case 110:
            osc10_reset(shell);
            break;
        case 111:
            osc11_reset(shell);
            break;
        case 112:
            osc12_reset(shell);
            break;
        case 52:
            if ([str isEqualToString:@"?"]) {
                if ([NSView MouseTerm_getBase64PasteEnabled]) {
                    [shell MouseTerm_osc52GetAccess];
                }
            } else {
                [shell MouseTerm_osc52SetAccess: str];
            }
            break;
        default:
            break;
        }
        [ppc->buffer release];
        ppc->buffer = nil;
        ppc->action = 0;
        break;
    default:
        break;
    }
}

static void terminate_string(struct parse_context *ppc, MTShell *shell)
{
    switch (ppc->action) {
    case 0x5d:
        osc_end(ppc, shell);
        break;
    case 0x00:
        break;
    default:
        dcs_end(ppc, shell);
        break;
    }
}

static void init_param(struct parse_context *ppc)
{
    ppc->params_index = 0;
    ppc->current_param = 0;
}

static void push(struct parse_context *ppc)
{
    if (ppc->params_index < param_bufsize)
        ppc->params[ppc->params_index++] = ppc->current_param;
    ppc->current_param = 0;
}

static void param(struct parse_context *ppc, char const *p)
{
    if (ppc->current_param < 6554)
        ppc->current_param = ppc->current_param * 10 + *p - 0x30;
}

static void init_action(struct parse_context *ppc)
{
    ppc->action = 0;
}

static void collect(struct parse_context *ppc, char const *p)
{
    ppc->action = ppc->action << 8 | *p;
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
    [shell MouseTerm_setCoordinateType: CELL_COORDINATE];
    [shell MouseTerm_setEventFilter: REQUEST_EVENT];
    [shell MouseTerm_setFilterRectangle: nil];
    [ppc->buffer release];
    ppc->buffer = nil;
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
        case 8810:
            [[[shell controller] logicalScreen] MouseTerm_setNaturalEmojiWidth: YES];
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
        case 8810:
            [[[shell controller] logicalScreen] MouseTerm_setNaturalEmojiWidth: NO];
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

static void esc_dispatch(struct parse_context *ppc, char *p, MTShell *shell)
{
    switch (ppc->action) {
    case 'Z':
        [(TTShell*) shell writeData: [NSData dataWithBytes: PDA_RESPONSE
                                                    length: PDA_RESPONSE_LEN]];
        *p = 0x7f;
        break;
    case 'c':
        handle_ris(ppc, shell);
        break;
    default:
        break;
    }
}

static void get_current_position(MTShell *shell, int *x, int *y)
{
    TTView *view = (TTView *)[[[shell controller] activePane] view];
    NSWindow *window = [view window];
    NSPoint location = [view convertPoint: [window mouseLocationOutsideOfEventStream] toView: nil];
    NSRect frame = [view frame];
    *x = (int)location.x;
    *y = (int)(frame.size.height - location.y);
    if (*x < 0) *x = 0;
    if (*y < 0) *y = 0;
    if (*x >= frame.size.width) *x = frame.size.width - 1;
    if (*y >= frame.size.height) *y = frame.size.height - 1;
    if ([shell MouseTerm_getCoordinateType] == CELL_COORDINATE) {
        CGSize size = [view cellSize];
        *x = (int)round(*x / (double)size.width + 1.0);
        *y = (int)round(*y / (double)size.height + 0.5);
    }
}

static void csi_dispatch(struct parse_context *ppc, char *p, MTShell *shell)
{
    int i;

    switch (ppc->action) {
    case 'c':
        [(TTShell*) shell writeData: [NSData dataWithBytes: PDA_RESPONSE
                                                    length: PDA_RESPONSE_LEN]];
        *p = 0x7f;
        break;
    case ('>' << 8) | 'c':
        [(TTShell*) shell writeData: [NSData dataWithBytes: SDA_RESPONSE
                                                    length: SDA_RESPONSE_LEN]];
        *p = 0x7f;
        break;
    case ('?' << 8) | 'h':
        enable_extended_mode(ppc, shell);
        break;
    case ('?' << 8) | 'l':
        disable_extended_mode(ppc, shell);
        break;
    case ('\'' << 8) | 'w':  /* DECEFR */
        {
            int x = 0;
            int y = 0;
            get_current_position(shell, &x, &y);
            if (ppc->params_index < 1 || ppc->params[0] == 0)
               ppc->params[0] = y;
            if (ppc->params_index < 2 || ppc->params[1] == 0)
               ppc->params[1] = x;
            if (ppc->params_index < 3 || ppc->params[2] == 0)
               ppc->params[2] = y;
            if (ppc->params_index < 4 || ppc->params[3] == 0)
               ppc->params[3] = x;
            [shell MouseTerm_setFilterRectangle: [NSValue value:ppc->params
                                                   withObjCType:@encode(int[4])]];
        }
        break;
    case ('\'' << 8) | 'z':  /* DECELR */
        if (ppc->params_index < 1)
            ppc->params[0] = 0;
        if (ppc->params_index < 2)
            ppc->params[1] = 0;
        switch (ppc->params[0]) {
        case 1:
            [shell MouseTerm_setMouseMode: DEC_LOCATOR_MODE];
            break;
        case 2:
            [shell MouseTerm_setMouseMode: DEC_LOCATOR_ONESHOT_MODE];
            break;
        case 0:
        default:
            [shell MouseTerm_setMouseMode: NO_MODE];
            break;
        }
        switch (ppc->params[1]) {
        case 1:
            [shell MouseTerm_setCoordinateType: PIXEL_COORDINATE];
            break;
        case 2:
        case 0:
        default:
            [shell MouseTerm_setCoordinateType: CELL_COORDINATE];
            break;
        }
        [shell MouseTerm_setFilterRectangle: nil];
        break;
    case ('\'' << 8) | '{':  /* DECSLE */
        for (i = 0; i < ppc->params_index; ++i) {
            switch (ppc->params[i]) {
            case 1:
                [shell MouseTerm_setEventFilter: [shell MouseTerm_getEventFilter] | BUTTONDOWN_EVENT];
                break;
            case 2:
                [shell MouseTerm_setEventFilter: [shell MouseTerm_getEventFilter] & ~BUTTONDOWN_EVENT];
                break;
            case 3:
                [shell MouseTerm_setEventFilter: [shell MouseTerm_getEventFilter] | BUTTONUP_EVENT];
                break;
            case 4:
                [shell MouseTerm_setEventFilter: [shell MouseTerm_getEventFilter] & ~BUTTONUP_EVENT];
                break;
            case 0:
            default:
                [shell MouseTerm_setEventFilter: REQUEST_EVENT];
                break;
            }
        }
        break;
    case ('\'' << 8) | '|':  /* DECRQLP */
        {
            TTView *view = (TTView *)[[[shell controller] activePane] view];
            NSWindow *window = [view window];
            NSPoint location = [view convertPoint: [window mouseLocationOutsideOfEventStream] toView: nil];
            //Position pos = [view displayPositionForPoint: viewloc];
            NSString *response = @"\033[0&w";
            switch ([shell MouseTerm_getMouseMode]) {
            case DEC_LOCATOR_ONESHOT_MODE:
               [shell MouseTerm_setMouseMode: NO_MODE];
               // pass through
            case DEC_LOCATOR_MODE:
                if (CGRectContainsPoint([view frame], location)) {
                    int pixelx = (int)location.x;
                    int pixely = (int)([view frame].size.height - location.y);
                    int cellx;
                    int celly;
                    CGSize size;
                    int button = 0;
                    if ([shell MouseTerm_getMouseState] & 1 << MOUSE_BUTTON1)
                        button |= 4;
                    if ([shell MouseTerm_getMouseState] & 1 << MOUSE_BUTTON3)
                        button |= 2;
                    if ([shell MouseTerm_getMouseState] & 1 << MOUSE_BUTTON2)
                        button |= 1;
                    switch ([shell MouseTerm_getCoordinateType]) {
                    case PIXEL_COORDINATE:
                        response = [NSString stringWithFormat: @"\033[1;%d;%d;%d;%d&w", button, pixely, pixelx, 0];
                        break;
                    case CELL_COORDINATE:
                        size = [view cellSize];
                        cellx = (int)round(pixelx / (double)size.width + 1.0);
                        celly = (int)round(pixely / (double)size.height + 0.5);
                        response = [NSString stringWithFormat: @"\033[1;%d;%d;%d;%d&w", button, celly, cellx, 0];
                        break;
                    default:
                        break;
                    }
                }
                break;
            default:
                break;
            }
            [(TTShell*) shell writeData: [NSData dataWithBytes: [response UTF8String]
                                                        length: response.length]];
        }
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
    char *p = data;
    MTShell *shell = (MTShell *)obj;
    struct parse_context *ppc = [shell MouseTerm_getParseContext];
    if (!ppc) {
        return 0;
    }

    for (p = data; p != data + len; ++p) {
        switch (ppc->state) {
        case PS_GROUND:
            switch (*p) {
            case 0x1b:
                ppc->state = PS_ESCAPE;
                break;
            default:
                break;
            }
            break;
        case PS_ESCAPE:
            switch (*p) {
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
                dcs_start(ppc);
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
                osc_start(ppc, p);
                ppc->state = PS_OSC_STRING;
                break;
            case 0x5e ... 0x5f:
                init_action(ppc);
                ppc->state = PS_SOS_PM_APC_STRING;
                break;
            case 0x60 ... 0x7e:
                init_action(ppc);
                collect(ppc, p);
                esc_dispatch(ppc, p, shell);
                ppc->state = PS_GROUND;
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
                collect(ppc, p);
                break;
            case 0x30 ... 0x7e:
                collect(ppc, p);
                esc_dispatch(ppc, p, shell);
                ppc->state = PS_GROUND;
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
                init_param(ppc);
                collect(ppc, p);
                ppc->state = PS_CSI_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                init_param(ppc);
                param(ppc, p);
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
                init_param(ppc);
                collect(ppc, p);
                ppc->state = PS_CSI_PARAM;
                break;
            case 0x40 ... 0x7e:
                init_param(ppc);
                collect(ppc, p);
                csi_dispatch(ppc, p, shell);
                ppc->state = PS_GROUND;
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
                push(ppc);
                collect(ppc, p);
                ppc->state = PS_CSI_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                param(ppc, p);
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
                collect(ppc, p);
                csi_dispatch(ppc, p, shell);
                ppc->state = PS_GROUND;
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
                collect(ppc, p);
                break;
            case 0x30 ... 0x3f:
                ppc->state = PS_CSI_IGNORE;
                break;
            case 0x40 ... 0x7e:
                collect(ppc, p);
                csi_dispatch(ppc, p, shell);
                ppc->state = PS_GROUND;
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
            switch (*p) {
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
                init_param(ppc);
                collect(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                init_param(ppc);
                param(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3a:
                *p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x3b:
                init_param(ppc);
                push(ppc);
                *p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3c ... 0x3f:
                init_param(ppc);
                collect(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x40 ... 0x7e:
                init_param(ppc);
                collect(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_PASSTHROUGH;
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
                collect(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_INTERMEDIATE;
                break;
            case 0x30 ... 0x39:
                param(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3a:
                *p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x3b:
                push(ppc);
                *p = '\0';
                ppc->state = PS_DCS_PARAM;
                break;
            case 0x3c ... 0x3f:
                *p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x40 ... 0x7e:
                collect(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_PASSTHROUGH;
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
                collect(ppc, p);
                *p = '\0';
                break;
            case 0x30 ... 0x3f:
                *p = '\0';
                ppc->state = PS_DCS_IGNORE;
                break;
            case 0x40 ... 0x7e:
                collect(ppc, p);
                *p = '\0';
                ppc->state = PS_DCS_PASSTHROUGH;
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
                dcs_put(ppc, p);
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
                osc_end(ppc, (MTShell *)obj);
                ppc->state = PS_GROUND;
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
                osc_put(ppc, p);
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
                *p = '\0';
                break;
            default:
                *p = '\0';
                break;
            }
            break;
        }
    }
    return 0;
}

/* EOF */
