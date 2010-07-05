#import <Cocoa/Cocoa.h>
#import "MTEscapeParserState.h"

int EscapeParser_init(void);
int EscapeParser_execute(const char* data, int len, BOOL isEof, id obj,
                         MTEscapeParserState* state);
