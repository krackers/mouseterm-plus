#import <Cocoa/Cocoa.h>
#import <apr-1/apr.h>
#import <apr-1/apr_base64.h>
#import "terminal.h"
#import "Mouse.h"
#import "MouseTerm.h"
#import "MTShell.h"

NSString *convertToHexString(NSString *src)
{
    char const *raw = [src UTF8String];
    NSMutableString *ms = [[NSMutableString alloc] init];
    int i;
    for (i = 0; i < src.length; ++i) {
        [ms appendString:[NSString stringWithFormat:@"%02x", raw[i]]];
    }
    return ms;
}

NSDictionary * generateTcapMap()
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    NSDictionary *tcapRawMap = [NSDictionary dictionaryWithObjectsAndKeys:
        @"MouseTerm-Plus", @"TN",
        // max_colors: maximum number of colors on screen
        @"256", @"Co",
        @"256", @"colors",
        // enter_blink_mode: turn on blinking
        @"\033[5m", @"blink",
        @"\033[5m", @"mb",
        // enter_bold_mode: turn on bold (extra bright) mode
        @"\033[1m", @"bold",
        @"\033[1m", @"md",
        // enter_underline_mode: begin underline mode
        @"\033[4m", @"us",
        @"\033[4m", @"smul",
        // exit_underline_mode: exit underline mode
        @"\033[24m", @"ue",
        @"\033[24m", @"rmul",
        // key_backspace: backspace key
        @"\177", @"kbs",
        @"\177", @"kb",
        // key_up: up-arrow key
        @"\033OA", @"kcuu1",
        @"\033OA", @"ku",
        // key_down: down-arrow key
        @"\033OB", @"kcud1",
        @"\033OB", @"kd",
        // key_right: right-arrow key
        @"\033OC", @"kcuf1",
        @"\033OC", @"kr",
        // key_left: left-arrow key
        @"\033OD", @"kcub1",
        @"\033OD", @"kl",
        // key_sright: shifted right-arrow key
        @"\033[1;2C", @"kRIT",
        @"\033[1;2C", @"%i",
        // key_sleft: shifted left-arrow key
        @"\033[1;2D", @"kLFT",
        @"\033[1;2D", @"#4",
        // key_f1: F1 function key
        @"\033OP", @"kf1",
        @"\033OP", @"k1",
        // key_f2: F2 function key
        @"\033OQ", @"kf2",
        @"\033OQ", @"k2",
        // key_f3: F3 function key
        @"\033OR", @"kf3",
        @"\033OR", @"k3",
        // key_f4: F4 function key
        @"\033OS", @"kf4",
        @"\033OS", @"k4",
        // key_f5: F5 function key
        @"\033[15~", @"kf5",
        @"\033[15~", @"k5",
        // key_f6: F6 function key
        @"\033[17~", @"kf6",
        @"\033[17~", @"k6",
        // key_f7: F7 function key
        @"\033[18~", @"kf7",
        @"\033[18~", @"k7",
        // key_f8: F8 function key
        @"\033[19~", @"kf8",
        @"\033[19~", @"k8",
        // key_f9: F9 function key
        @"\033[20~", @"kf9",
        @"\033[20~", @"k9",
        // key_f10: F10 function key
        @"\033[21~", @"kf10",
        @"\033[21~", @"k;",
        // key_f11: F11 function key
        @"\033[23~", @"kf11",
        @"\033[23~", @"F1",
        // key_f12: F12 function key
        @"\033[24~", @"kf12",
        @"\033[24~", @"F2",
        // key_mouse: Mouse event has occurred
        @"\033[<", @"kmous",
        @"\033[<", @"Km",
        nil];
    NSArray *keyArray =  [tcapRawMap allKeys];
    int count = [keyArray count];
    for (int i = 0; i < count; i++) {
        NSString *key = [keyArray objectAtIndex:i];
        NSString *hexkey = convertToHexString(key);
        NSString *hexvalue = convertToHexString([tcapRawMap objectForKey:key]);
        [result setObject: hexvalue forKey: hexkey];
        [result setObject: hexvalue forKey: [hexkey uppercaseString]];
    }
    return result;
}


@implementation NSObject (MTShell)

- (NSValue*) MouseTerm_initVars
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        struct parse_context *ppc = malloc(sizeof(struct parse_context));
        ppc->state = PS_GROUND;
        ppc->osc_state = OPS_IGNORE;
        ppc->action = 0;
        ppc->current_param = 0;
        ppc->params_index = 0;
        ppc->buffer = nil;

        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [MouseTerm_ivars setObject: dict forKey: ptr];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"focusMode"];
        [dict setObject: [NSNumber numberWithInt: NO_MODE]
                 forKey: @"mouseMode"];
        [dict setObject: [NSNumber numberWithInt: NORMAL_PROTOCOL]
                 forKey: @"mouseProtocol"];
        [dict setObject: [NSNumber numberWithInt: NO]
                 forKey: @"emojiFix"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"appCursorMode"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"isMouseDown"];
        [dict setObject: [NSValue valueWithPointer:ppc]
                 forKey: @"parseContext"];
        [dict setObject: generateTcapMap()
                 forKey: @"tcapMap"];
        [dict setObject: [[[NSMutableArray alloc] init] autorelease]
                 forKey: @"windowTitleStack"];
        [dict setObject: [[[NSMutableArray alloc] init] autorelease]
                 forKey: @"tabTitleStack"];
    }
    return ptr;
}

- (void) MouseTerm_setFocusMode: (BOOL) focusMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithBool:focusMode] forKey: @"focusMode"];
}

- (BOOL) MouseTerm_getFocusMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"focusMode"] boolValue];
}

- (void) MouseTerm_setMouseMode: (int) mouseMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt:mouseMode] forKey: @"mouseMode"];
}

- (int) MouseTerm_getMouseMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"mouseMode"] intValue];
}

- (void) MouseTerm_setMouseProtocol: (int) mouseProtocol
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt:mouseProtocol]
           forKey: @"mouseProtocol"];
}

- (int) MouseTerm_getMouseProtocol
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"mouseProtocol"] intValue];
}

- (void) MouseTerm_setAppCursorMode: (BOOL) appCursorMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithBool: appCursorMode]
           forKey: @"appCursorMode"];
}

- (BOOL) MouseTerm_getAppCursorMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"appCursorMode"] boolValue];
}

- (void) MouseTerm_pushWindowTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"windowTitleStack"];
    TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
    NSString *title = [screen windowTitle];
    if (title == nil)
        title = @"";
    [stack addObject: title];
}

- (void) MouseTerm_popWindowTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"windowTitleStack"];
    NSUInteger count = [stack count];
    if (count > 0) {
        TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
        if (screen != nil) {
            NSString *title = [stack objectAtIndex: count - 1];
            if (title != nil)
                [screen setWindowTitle:title];
            [stack removeObjectAtIndex: count - 1];
        }
    }
}

- (void) MouseTerm_pushTabTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"tabTitleStack"];
    TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
    NSString *title = [screen tabTitle];
    if (title == nil)
        title = @"";
    [stack addObject: title];
}

- (void) MouseTerm_popTabTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"tabTitleStack"];
    NSUInteger count = [stack count];
    if (count > 0) {
        TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
        if (screen != nil) {
            NSString *title = [stack objectAtIndex: count - 1];
            if (title != nil)
                [screen setTabTitle:title];
            [stack removeObjectAtIndex: count - 1];
        }
    }
}

- (void) MouseTerm_setIsMouseDown: (BOOL) isMouseDown
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithBool:isMouseDown]
           forKey: @"isMouseDown"];
}

- (BOOL) MouseTerm_getIsMouseDown
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"isMouseDown"] boolValue];
}

- (BOOL) MouseTerm_writeToPasteBoard: (NSString*) stringToWrite
{
    return [[NSPasteboard generalPasteboard] setString:stringToWrite
                                               forType:NSStringPboardType];
}

- (NSString*) MouseTerm_readFromPasteBoard
{
    return [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
}

- (void) MouseTerm_osc52SetAccess: (NSString*) stringToWrite
{
    char *encodedBuffer = (char*)[stringToWrite cStringUsingEncoding:NSASCIIStringEncoding];
    int destLength = apr_base64_decode_len(encodedBuffer);
    char *decodedBuffer = malloc(destLength);
    apr_base64_decode(decodedBuffer, encodedBuffer);
    NSString *resultString = [NSString stringWithUTF8String:decodedBuffer];
    if (!resultString) {
        TTTabController *controller = [(TTShell *)self controller];
        TTOutputDecoder *decoder = [controller encodingConverter];
        NSData *data = [decoder decodeData:[NSData dataWithBytes:decodedBuffer
                                                          length:destLength]];
        resultString = [[[NSString alloc] initWithData: data
                                              encoding: NSUTF8StringEncoding] autorelease];
    }
    free(decodedBuffer);

    [[[[(TTShell*)self controller] activePane] view] copy: nil];
    [self MouseTerm_writeToPasteBoard: resultString];
}

- (void) MouseTerm_osc52GetAccess
{
    // ref: http://blog.livedoor.jp/jgoamakf/archives/51160286.html
    NSString *str = [self MouseTerm_readFromPasteBoard];
    char *sourceCString = (char*)[str UTF8String];
    const char prefix[] = "\033]52;c;"; // OSC52 from Clipboard
    const char postfix[] = "\033\\"; // ST
    size_t prefix_len = sizeof(prefix) - 1;
    size_t postfix_len = sizeof(postfix) - 1;

    int sourceLength = strlen(sourceCString);
    int resultLength = apr_base64_encode_len(sourceLength);
    int allLength = prefix_len + resultLength + postfix_len;
    char *encodedBuffer = (char*)malloc(allLength);
    char *it = encodedBuffer;

    memcpy(it, prefix, prefix_len);
    it += prefix_len;
    apr_base64_encode(it, sourceCString, sourceLength);
    it += resultLength;
    memcpy(it, postfix, postfix_len);

    [(TTShell*)self writeData: [NSData dataWithBytes: encodedBuffer
                                              length: allLength]];
}

- (void) MouseTerm_tcapQuery: (NSString*) query
{
    NSString *answer;
    NSValue *ptr = [self MouseTerm_initVars];
    NSString *cap = [[[MouseTerm_ivars objectForKey: ptr] objectForKey:@"tcapMap"] objectForKey:query];

    if (cap) {
        answer = [NSString stringWithFormat:@"\033P1+r%@=%@\033\\", query, cap];
    } else {
        answer = @"\033P0+r\033\\";
    }
    [(TTShell*)self writeData: [answer dataUsingEncoding:NSASCIIStringEncoding]];
}

- (struct parse_context*) MouseTerm_getParseContext
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [[[MouseTerm_ivars objectForKey: ptr] objectForKey:@"parseContext"] pointerValue];
}

- (void) MouseTerm_writeData: (NSData*) data
{
    [self MouseTerm_writeData: data];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    struct parse_context *ppc = [[[MouseTerm_ivars objectForKey: ptr] objectForKey: @"parseContext"] pointerValue];
    free(ppc);
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];
    [self MouseTerm_dealloc];
}

@end
