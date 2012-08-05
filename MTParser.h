#import <Cocoa/Cocoa.h>

@class MTParserState;

int MTParser_init(void);
int MTParser_execute(char* data, int len, BOOL isEof, id obj,
                     MTParserState* state);
