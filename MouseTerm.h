#import <Cocoa/Cocoa.h>

extern NSMutableDictionary* MouseTerm_ivars;

@interface MouseTerm: NSObject
+ (void) load;
+ (IBAction) toggle: (NSMenuItem*) sender;
+ (void) insertMenuItem;
- (BOOL) unload;
@end
