#import <Cocoa/Cocoa.h>

@interface MTEscapeParserState : NSObject
{
	int currentState;
	int pendingMouseMode;
	BOOL toggleState;
	int lastEscapeIndex;
}
@property (nonatomic, assign) int currentState;
@property (nonatomic, assign) int pendingMouseMode;
@property (nonatomic, assign) BOOL toggleState;
@property (nonatomic, assign) int lastEscapeIndex;
@end