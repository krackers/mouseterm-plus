#import <Cocoa/Cocoa.h>

@class MTShell;
@class MTTabController;

// Classes from Terminal.app being overridden

#ifdef __x86_64__
typedef unsigned long long linecount_t;
#else
typedef unsigned int linecount_t;
#endif

typedef struct
{
    linecount_t y;
    linecount_t x;
} Position;

@interface TTShell: NSObject
- (void) writeData: (NSData*) data;
@end

@interface TTLogicalScreen: NSObject
- (BOOL) isAlternateScreenActive;
- (linecount_t) lineCount;
@end

@interface TTPane: NSObject
- (NSScroller*) scroller;
@end

@interface TTTabController: NSObject
- (MTShell*) shell;
@end

@interface TTView: NSView
- (TTLogicalScreen*) logicalScreen;
- (linecount_t) rowCount;
- (TTPane*) pane;
- (MTTabController*) controller;
- (Position) displayPositionForPoint: (NSPoint) point;
- (void) clearTextSelection;
@end
