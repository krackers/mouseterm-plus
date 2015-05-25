#import <Cocoa/Cocoa.h>
#import "Terminal.h"

@interface NSWindowController (MTWindowController)
- (id) MouseTerm_makeTabWithProfile:(TTProfile *)profile customFont:(id)arg2 \
        command:(id)arg3 runAsShell:(BOOL)arg4 restorable:(BOOL)arg5 \
        workingDirectory:(id)arg6 sessionClass:(id)arg7 restoreSession:(id)arg8;
@end

