#import <Cocoa/Cocoa.h>

@interface NSObject (MTTabController)
- (void) MouseTerm_shellDidReceiveData: (NSData*) data;
- (BOOL) MouseTerm_acceptsFirstResponder;
- (BOOL) MouseTerm_becomeFirstResponder;
- (BOOL) MouseTerm_resignFirstResponder;
@end
