#import <Cocoa/Cocoa.h>
#import "Terminal.h"

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
    OPS_IGNORE      = 0,
    OPS_COMMAND     = 1,
    OPS_SELECTION   = 2,
    OPS_PASSTHROUGH = 3,
};

static int const param_bufsize = 256;

struct parse_context {
    int state;
    int osc_state;
    int action;
    int current_param;
    int params_index;
    int params[param_bufsize];
    NSMutableData *buffer;
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

- (void) MouseTerm_setCoordinateType: (int) coordinateType;
- (int) MouseTerm_getCoordinateType;

- (void) MouseTerm_setEventFilter: (int) eventFilter;
- (int) MouseTerm_getEventFilter;

- (void) MouseTerm_setFilterRectangle: (NSValue *) filterRectangle;
- (NSValue *) MouseTerm_getFilterRectangle;

- (void) MouseTerm_setAppCursorMode: (BOOL) appCursorMode;
- (BOOL) MouseTerm_getAppCursorMode;

- (void) MouseTerm_pushWindowTitle;
- (void) MouseTerm_popWindowTitle;

- (void) MouseTerm_pushTabTitle;
- (void) MouseTerm_popTabTitle;

- (void) MouseTerm_setMouseState: (int) state;
- (int) MouseTerm_getMouseState;

- (BOOL) MouseTerm_writeToPasteBoard: (NSString*) stringToWrite;
- (NSString*) MouseTerm_readFromPasteBoard;

- (void) MouseTerm_osc52SetAccess: (NSString*) stringToWrite;
- (void) MouseTerm_osc52GetAccess;

- (void) MouseTerm_tcapQuery: (NSString*) query;
- (NSMutableDictionary*) MouseTerm_getPalette;
- (NSMutableDictionary*) MouseTerm_getColorNameMap;
- (struct parse_context*) MouseTerm_getParseContext;

- (void) MouseTerm_cachePosition: (Position*) pos;
- (BOOL) MouseTerm_positionIsChanged: (Position*) pos;

@end
