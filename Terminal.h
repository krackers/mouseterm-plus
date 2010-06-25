#import <Cocoa/Cocoa.h>

// Possible mouse modes
typedef enum
{
    NO_MODE = 0,
    NORMAL_MODE,
    HILITE_MODE,
    BUTTON_MODE,
    ALL_MODE
} MouseMode;

// Control codes

// Normal control codes
#define UP_ARROW "\033[A"
#define DOWN_ARROW "\033[B"
// Control codes for application keypad mode
#define UP_ARROW_APP "\033OA"
#define DOWN_ARROW_APP "\033OB"
#define ARROW_LEN (sizeof(UP_ARROW) - 1)

// Mode control codes

#define TOGGLE_ON 'h'
#define TOGGLE_OFF 'l'

// Excludes mode and toggle flag
#define TOGGLE_MOUSE "\033[?100"
#define TOGGLE_MOUSE_LEN (sizeof(TOGGLE_MOUSE) - 1)

// Excludes toggle flag
#define TOGGLE_CURSOR_KEYS "\033[?1"
#define TOGGLE_CURSOR_KEYS_LEN (sizeof(TOGGLE_CURSOR_KEYS) - 1)

// X11 mouse button values
typedef enum
{
    MOUSE_BUTTON1 = 0,
    MOUSE_BUTTON2 = 1,
    MOUSE_BUTTON3 = 2,
    MOUSE_RELEASE = 3,
    MOUSE_WHEEL_UP = 64,
    MOUSE_WHEEL_DOWN = 65
} MouseButton;

// X11 mouse reporting responses
#define MOUSE_RESPONSE "\033[M%c%c%c"
#define MOUSE_RESPONSE_LEN 6

// Classes from Terminal.app being overridden

#ifdef __x86_64__
typedef unsigned long long linecount_t;
#else
typedef unsigned int linecount_t;
#endif

typedef struct
{
    linecount_t y;
    linecount_t x;
} Position;

@class MouseTermTTShell;
@class MouseTermTTTabController;
@class MouseTermTTView;

@interface TTShell
- (void) writeData: (NSData*) data;
@end

@interface NSObject (MouseTermTTShell)
- (NSValue*) MouseTerm_initVars;
- (id) MouseTerm_get: (NSString*) name;
- (void) MouseTerm_set: (NSString*) name value: (id) value;
- (void) MouseTerm_dealloc;
@end

@interface TTLogicalScreen
- (BOOL) isAlternateScreenActive;
- (linecount_t) lineCount;
@end

@interface TTPane
- (NSScroller*) scroller;
@end

@interface TTTabController
- (MouseTermTTShell*) shell;
@end

@interface NSObject (MouseTermTTTabController)
- (void) MouseTerm_shellDidReceiveData: (NSData*) data;
@end

@interface TTView: NSView
- (TTLogicalScreen*) logicalScreen;
- (linecount_t) rowCount;
- (TTPane*) pane;
- (MouseTermTTTabController*) controller;
- (Position) displayPositionForPoint: (NSPoint) point;
- (void) clearTextSelection;
@end

@interface NSView (MouseTermTTView)
- (NSData*) MouseTerm_codeForEvent: (NSEvent*) event
                            button: (MouseButton) button
                            motion: (BOOL) motion;
- (BOOL) MouseTerm_shouldIgnore: (NSEvent*) event;
- (BOOL) MouseTerm_shouldIgnoreDown;
- (Position) MouseTerm_currentPosition: (NSEvent*) event;
- (void) MouseTerm_mouseDown: (NSEvent*) event;
- (void) MouseTerm_mouseDragged: (NSEvent*) event;
- (void) MouseTerm_mouseUp: (NSEvent*) event;
- (void) MouseTerm_rightMouseDown: (NSEvent*) event;
- (void) MouseTerm_rightMouseDragged: (NSEvent*) event;
- (void) MouseTerm_rightMouseUp: (NSEvent*) event;
- (void) MouseTerm_otherMouseDown: (NSEvent*) event;
- (void) MouseTerm_otherMouseDragged: (NSEvent*) event;
- (void) MouseTerm_otherMouseUp: (NSEvent*) event;
- (void) MouseTerm_scrollWheel: (NSEvent*) event;
@end

// Custom instance variables
extern NSMutableDictionary* MouseTerm_ivars;
