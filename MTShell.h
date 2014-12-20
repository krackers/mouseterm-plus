#import <Cocoa/Cocoa.h>

enum parse_state {
    PS_GROUND              =  0,
    PS_ESCAPE              =  1,
    PS_ESCAPE_INTERMEDIATE =  2,
    PS_CSI_ENTRY           =  3,
    PS_CSI_PARAM           =  4,
    PS_CSI_INTERMEDIATE    =  5,
    PS_CSI_IGNORE          =  6,
    PS_DCS_ENTRY           =  7,
    PS_DCS_PARAM           =  8,
    PS_DCS_INTERMEDIATE    =  9,
    PS_DCS_PASSTHROUGH     = 10,
    PS_DCS_IGNORE          = 11,
    PS_OSC_STRING          = 12,
    PS_SOS_PM_APC_STRING   = 13,
};

enum osc_parse_state {
    OPS_COMMAND     = 1,
    OPS_SELECTION   = 2,
    OPS_PASSTHROUGH = 3,
    OPS_IGNORE      = 4,
};

static int const param_bufsize = 256;

struct parse_context {
    int state;
    int osc_state;
    char *p;
    int action;
    int current_param;
    int params_index;
    int params[param_bufsize];
    NSMutableData *osc52Buffer;
};

@interface NSObject (MTShell)
- (NSValue*) MouseTerm_initVars;
- (void) MouseTerm_writeData: (NSData*) data;
- (void) MouseTerm_dealloc;

- (void) MouseTerm_setFocusMode: (BOOL) focusMode;
- (BOOL) MouseTerm_getFocusMode;

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

- (struct parse_context*) MouseTerm_getParseContext;

@end
