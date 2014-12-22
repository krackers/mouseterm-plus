#import <Cocoa/Cocoa.h>
#import "Mouse.h"
#import "MTParser.h"
#import "MTShell.h"
#import "MTView.h"
#import "MTTabController.h"
#import "Terminal.h"

@implementation NSObject (MTTabController)

// Intercepts all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    NSUInteger length = [data length];
    char* chars = (char*)[data bytes];

    MTParser_execute(chars, length, [(TTTabController*) self shell]);

    [self MouseTerm_shellDidReceiveData: data];
}

- (BOOL) MouseTerm_acceptsFirstResponder
{
    return YES;
}

- (BOOL) MouseTerm_becomeFirstResponder
{
    NSData* data = [NSData dataWithBytes: "\033[I" length: 3];
    MTShell* shell = [(TTTabController*) self shell];
    [(TTShell*) shell writeData: data];
    return YES;
}

- (BOOL) MouseTerm_resignFirstResponder
{
    NSData* data = [NSData dataWithBytes: "\033[O" length: 3];
    MTShell* shell = [(TTTabController*) self shell];
    [(TTShell*) shell writeData: data];
    return YES;
}

@end
