#import <Cocoa/Cocoa.h>

extern NSMutableDictionary* MouseTerm_ivars;

@interface MouseTerm: NSWindowController
+ (void) load;
+ (void) updateProfileOfAlreadyRunningTabs;
+ (void) toggleMouse: (NSMenuItem*) sender;
+ (void) toggleBase64Copy: (NSMenuItem*) sender;
+ (void) insertMenuItem;
+ (MouseTerm*) sharedInstance;
- (void) orderFrontMouseConfiguration: (id) sender;
- (void) orderOutConfiguration: (id) sender;
- (id) profilesController;
- (BOOL) unload;
@end
