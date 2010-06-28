#import <Cocoa/Cocoa.h>

@interface MTEscapeParserState : NSObject
{
	int currentState;
	int pendingMouseMode;
	BOOL toggleState;
	int lastEscapeIndex;
	BOOL handleSda;
	int sdaIndex;
}
@property (nonatomic, assign) int currentState;
@property (nonatomic, assign) int pendingMouseMode;
@property (nonatomic, assign) BOOL toggleState;
@property (nonatomic, assign) int lastEscapeIndex;
@property (nonatomic, assign) BOOL handleSda;
@property (nonatomic, assign) int sdaIndex;
@end