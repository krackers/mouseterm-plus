#import <Cocoa/Cocoa.h>
#import "MTTabController.h"
#import "MTShell.h"
#import "Mouse.h"
#import "Terminal.h"
#import "MTEscapeParserState.h"

#define SDA_RESPONSE "\033[>0;95;c"
#define SDA_RESPONSE_LEN 9

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
		
    [self MouseTerm_shellDidReceiveData: data];

	if (state.handleSda)
	{
		[[self shell] writeData: [NSData dataWithBytes: SDA_RESPONSE length: SDA_RESPONSE_LEN]];
		// Unset so it's not set the next time
		state.handleSda = NO;
	}
}

@end
