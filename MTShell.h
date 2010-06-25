#import <Cocoa/Cocoa.h>

@interface NSObject (MouseTermTTShell)
- (NSValue*) MouseTerm_initVars;
- (id) MouseTerm_get: (NSString*) name;
- (void) MouseTerm_set: (NSString*) name value: (id) value;
- (void) MouseTerm_dealloc;
@end
