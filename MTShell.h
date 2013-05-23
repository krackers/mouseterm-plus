#import <Cocoa/Cocoa.h>

@class MTParserState;

@interface NSObject (MTShell)
- (NSValue*) MouseTerm_initVars;
- (void) MouseTerm_writeData: (NSData*) data;
- (void) MouseTerm_dealloc;

- (void) MouseTerm_setFocusMode: (BOOL) focusMode;
- (BOOL) MouseTerm_getFocuseMode;

- (void) MouseTerm_setMouseMode: (int) mouseMode;
- (int) MouseTerm_getMouseMode;

- (void) MouseTerm_setMouseProtocol: (int) mouseProtocol;
- (int) MouseTerm_getMouseProtocol;

- (void) MouseTerm_setAppCursorMode: (BOOL) appCursorMode;
- (BOOL) MouseTerm_getAppCursorMode;

- (void) MouseTerm_pushWindowTitle;
- (void) MouseTerm_popWindowTitle;

- (void) MouseTerm_pushTabTitle;
- (void) MouseTerm_popTabTitle;

- (void) MouseTerm_setIsMouseDown: (BOOL) isMouseDown;
- (BOOL) MouseTerm_getIsMouseDown;

- (BOOL) MouseTerm_writeToPasteBoard: (NSString*) stringToWrite;
- (NSString*) MouseTerm_readFromPasteBoard;

- (void) MouseTerm_osc52SetAccess: (NSString*) stringToWrite;
- (void) MouseTerm_osc52GetAccess;

- (void) MouseTerm_setParserState: (MTParserState*) parserState;
- (MTParserState*) MouseTerm_getParserState;

@end
