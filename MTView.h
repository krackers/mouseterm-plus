#import <Cocoa/Cocoa.h>
#import "Mouse.h"
#import "Terminal.h"

@interface NSObject (TTLogicalScreen)

- (NSValue*) MouseTerm_initVars2;
- (void) MouseTerm_setNaturalEmojiWidth: (BOOL) emojiFix;
- (BOOL) MouseTerm_getNaturalEmojiWidth;
- (unsigned long long)MouseTerm_logicalWidthForCharacter:(int)arg1;
- (unsigned long long)MouseTerm_displayWidthForCharacter:(int)arg1;

@end

@interface NSView (MTView)
- (id) MouseTerm_colorForANSIColor:(unsigned int)index;
- (id) MouseTerm_colorForANSIColor:(unsigned int)index adjustedRelativeToColor:(id)bgColor;
- (id) MouseTerm_colorForExtendedANSIColor:(unsigned long long)index adjustedRelativeToColor:(id)bgColor withProfile:(id)profile;
- (NSData*) MouseTerm_codeForX: (unsigned int) x
                             Y: (unsigned int) y
                      modifier: (char) modflag
                        button: (MouseButton) button
                        motion: (BOOL) motion
                       release: (BOOL) release;
+ (void) MouseTerm_setMouseEnabled: (BOOL) value;
+ (BOOL) MouseTerm_getMouseEnabled;
+ (void) MouseTerm_setBase64CopyEnabled: (BOOL) value;
+ (BOOL) MouseTerm_getBase64CopyEnabled;
+ (void) MouseTerm_setBase64PasteEnabled: (BOOL) value;
+ (BOOL) MouseTerm_getBase64PasteEnabled;
- (NSScroller*) MouseTerm_scroller;
- (BOOL) MouseTerm_shouldIgnore: (NSEvent*) event button: (MouseButton) button;
- (BOOL) MouseTerm_shouldIgnoreDown: (NSEvent*) event
                             button: (MouseButton) button;
- (BOOL) MouseTerm_shouldIgnoreMoved: (NSEvent*) event;
- (Position) MouseTerm_currentPosition: (NSEvent*) event;
- (BOOL) MouseTerm_buttonDown: (NSEvent*) event button: (MouseButton) button;
- (BOOL) MouseTerm_buttonDragged: (NSEvent*) event
                          button: (MouseButton) button;
- (BOOL) MouseTerm_buttonUp: (NSEvent*) event
                     button: (MouseButton) button;
- (void) MouseTerm_mouseDown: (NSEvent*) event;
- (void) MouseTerm_mouseMoved: (NSEvent*) event;
- (void) MouseTerm_mouseDragged: (NSEvent*) event;
- (void) MouseTerm_mouseUp: (NSEvent*) event;
- (void) MouseTerm_rightMouseDown: (NSEvent*) event;
- (void) MouseTerm_rightMouseDragged: (NSEvent*) event;
- (void) MouseTerm_rightMouseUp: (NSEvent*) event;
- (void) MouseTerm_otherMouseDown: (NSEvent*) event;
- (void) MouseTerm_otherMouseDragged: (NSEvent*) event;
- (void) MouseTerm_otherMouseUp: (NSEvent*) event;
- (void) MouseTerm_scrollWheel: (NSEvent*) event;
- (BOOL) MouseTerm_windowDidBecomeKey: (id) arg1;
- (BOOL) MouseTerm_windowDidResignKey: (id) arg1;
- (BOOL) MouseTerm_acceptsFirstResponder;
- (BOOL) MouseTerm_becomeFirstResponder;
- (BOOL) MouseTerm_resignFirstResponder;
@end
