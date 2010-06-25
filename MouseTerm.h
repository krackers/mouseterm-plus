#import <Cocoa/Cocoa.h>

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
- (BOOL) MouseTerm_shouldIgnore: (NSEvent*) event;
- (BOOL) MouseTerm_shouldIgnoreDown: (NSEvent*) event;
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
