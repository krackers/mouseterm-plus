#import <Cocoa/Cocoa.h>

@interface MTEscapeParserState : NSObject
{
	int currentState;
	int pendingMouseMode;
	BOOL toggleState;
}
@property (nonatomic, assign) int currentState;
@property (nonatomic, assign) int pendingMouseMode;
@property (nonatomic, assign) BOOL toggleState;
@end