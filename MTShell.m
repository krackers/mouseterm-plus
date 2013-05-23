#import <Cocoa/Cocoa.h>
#import <apr-1/apr.h>
#import <apr-1/apr_base64.h>
#import "terminal.h"
#import "Mouse.h"
#import "MouseTerm.h"
#import "MTParserState.h"
#import "MTShell.h"

@implementation NSObject (MTShell)

- (NSValue*) MouseTerm_initVars
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [MouseTerm_ivars setObject: dict forKey: ptr];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"focusMode"];
        [dict setObject: [NSNumber numberWithInt: NO_MODE]
                 forKey: @"mouseMode"];
        [dict setObject: [NSNumber numberWithInt: NORMAL_PROTOCOL]
                 forKey: @"mouseProtocol"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"appCursorMode"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"isMouseDown"];
        [dict setObject: [[[MTParserState alloc] init] autorelease]
                 forKey: @"parserState"];
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
        NSData *data = (NSData*)[[[(TTShell *)self controller] encodingConverter] decodedData];
        resultString = [[[NSString alloc] initWithData: data
                                              encoding: NSUTF8StringEncoding] autoRelease];
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
    const char prefix[] = "\x1b]52;c;"; // OSC52 from Clipboard
    const char postfix[] = "\x1b\\"; // ST

    int sourceLength = strlen(sourceCString);
    int resultLength = apr_base64_encode_len(sourceLength);
    int allLength = sizeof(prefix) + resultLength + sizeof(postfix);
    char *encodedBuffer = (char*)malloc(allLength);
    char *it = encodedBuffer;
    memcpy(it, prefix, sizeof(prefix));
    it += sizeof(prefix);
    apr_base64_encode(it, sourceCString, sourceLength);
    it += resultLength;
    memcpy(it, postfix, sizeof(postfix));

    [(TTShell*)self writeData: [NSData dataWithBytes: encodedBuffer
                                              length: allLength]];
}

- (void) MouseTerm_setParserState: (MTParserState*) parserState
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr] setObject: parserState
                                            forKey: @"parserState"];
}

- (MTParserState*) MouseTerm_getParserState
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [[MouseTerm_ivars objectForKey: ptr] objectForKey: @"parserState"];
}

- (void) MouseTerm_writeData: (NSData*) data
{
    if ([self MouseTerm_getParserState].handleSda &&
        !strncmp([data bytes], PDA_RESPONSE, PDA_RESPONSE_LEN))
        return;

    [self MouseTerm_writeData: data];
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];
    [self MouseTerm_dealloc];
}

@end
