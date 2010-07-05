#import <Cocoa/Cocoa.h>
#import "Mouse.h"
#import "Terminal.h"

@interface NSView (MTView)
- (NSData*) MouseTerm_codeForEvent: (NSEvent*) event
                            button: (MouseButton) button
                            motion: (BOOL) motion;
- (BOOL) MouseTerm_shouldIgnore: (NSEvent*) event;
- (BOOL) MouseTerm_shouldIgnoreDown: (NSEvent*) event;
- (Position) MouseTerm_currentPosition: (NSEvent*) event;
- (BOOL) MouseTerm_buttonDown: (NSEvent*) event button: (MouseButton) button;
- (BOOL) MouseTerm_buttonDragged: (NSEvent*) event;
- (BOOL) MouseTerm_buttonUp: (NSEvent*) event;
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
