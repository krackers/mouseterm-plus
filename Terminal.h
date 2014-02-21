#import <Cocoa/Cocoa.h>

@class MTShell;
@class MTTabController;
@class MTProfile;
@class TTPane;
@class TTView;

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
- (id)controller;
@end

@interface TTLogicalScreen: NSObject
- (BOOL) isAlternateScreenActive;
- (linecount_t) lineCount;
@property(retain) NSString *tabTitle; // @synthesize tabTitle=_tabTitle;
@property(retain) NSString *windowTitle; // @synthesize windowTitle=_windowTitle;
@end

// TTPane is new in OS X 10.6
@interface TTPane: NSObject
- (NSScroller*) scroller;
@property(readonly) TTView *view; // @synthesize view;
@end

@interface TTOutputDecoder
- (NSData*)decodeData:(id)arg1;
@end

@interface TTTabController: NSObject
- (NSScroller*) scroller; // This method exists only in OS X 10.5 or older
- (MTShell*) shell;
- (MTProfile*) profile;
- (TTOutputDecoder*) encodingConverter;
@property(readonly) TTPane *activePane; // @synthesize activePane;
@end

@interface TTView: NSView
- (TTLogicalScreen*) logicalScreen;
- (linecount_t) rowCount;
- (TTPane*) pane;
- (MTTabController*) controller;
- (Position) displayPositionForPoint: (NSPoint) point;
- (void) clearTextSelection;
- (struct CGSize)cellSize;
- (void)copy:(id)arg1;
@end

@interface TTProfileArrayController:
    NSArrayController <NSOpenSavePanelDelegate>
@end

@interface TTAppPrefsController: NSWindowController <NSWindowDelegate>
+ (TTAppPrefsController*) sharedPreferencesController;
- (TTProfileArrayController*) profilesController;
@end
