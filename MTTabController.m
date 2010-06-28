#import <Cocoa/Cocoa.h>
#import "MTTabController.h"
#import "MTShell.h"
#import "Mouse.h"
#import "Terminal.h"
#import "MTEscapeParserState.h"

@implementation NSObject (MTTabController)

// Intercepts all shell output to look for mouse reporting control codes
- (void) MouseTerm_shellDidReceiveData: (NSData*) data
{
    // FIXME: What if the data's split up over method calls?
    NSUInteger length = [data length];
    const char* chars = [data bytes];
    const char* pos;

	MTEscapeParserState *state = [[self shell] MouseTerm_getParserState];
	EscapeParser_execute(chars, length, NO, [self shell], state);
	
	// Unset so it's not set the next time
	state.handleSda = NO;
	
    [self MouseTerm_shellDidReceiveData: data];
}

@end
