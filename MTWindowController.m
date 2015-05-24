#import <Cocoa/Cocoa.h>
#import "MTWindowController.h"

@implementation NSWindowController(MTWindowController)

- (id)MouseTerm_makeTabWithProfile:(TTProfile *)profile customFont:(id)arg2 \
                           command:(id)arg3 runAsShell:(BOOL)arg4 \
                        restorable:(BOOL)arg5 workingDirectory:(id)arg6 \
                      sessionClass:(id)arg7 restoreSession:(id)arg8
{
    Class sharedProfileControllerMetaclass = objc_getClass("TTProfileManager");
    TTProfileManager *sharedProfileManager \
        = (TTProfileManager*) objc_msgSend(sharedProfileControllerMetaclass, \
                @selector(sharedProfileManager));

    TTProfile *newProfile = [[sharedProfileManager profileWithName:[profile name]] copy];

    return [self MouseTerm_makeTabWithProfile:newProfile customFont:arg2
                                      command:arg3 runAsShell:arg4
                                   restorable:arg5 workingDirectory:arg6
                                 sessionClass:arg7 restoreSession:arg8];
}

@end
