#import <Cocoa/Cocoa.h>
#import <apr-1/apr.h>
#import <apr-1/apr_base64.h>
#import "Terminal.h"
#import "Mouse.h"
#import "MouseTerm.h"
#import "MTShell.h"

NSString* convertToHexString(NSString *src)
{
    char const *raw = [src UTF8String];
    NSMutableString *ms = [[[NSMutableString alloc] init] autorelease];
    int i;
    for (i = 0; i < src.length; ++i) {
        [ms appendString:[NSString stringWithFormat:@"%02x", raw[i]]];
    }
    return ms;
}

NSDictionary* generateTcapMap()
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    NSDictionary *tcapRawMap = [NSDictionary dictionaryWithObjectsAndKeys:
        @"MouseTerm-Plus", @"TN",
        // max_colors: maximum number of colors on screen
        @"256", @"Co",
        @"256", @"colors",
        // enter_blink_mode: turn on blinking
        @"\033[5m", @"blink",
        @"\033[5m", @"mb",
        // enter_bold_mode: turn on bold (extra bright) mode
        @"\033[1m", @"bold",
        @"\033[1m", @"md",
        // enter_underline_mode: begin underline mode
        @"\033[4m", @"us",
        @"\033[4m", @"smul",
        // exit_underline_mode: exit underline mode
        @"\033[24m", @"ue",
        @"\033[24m", @"rmul",
        // key_backspace: backspace key
        @"\177", @"kbs",
        @"\177", @"kb",
        // key_up: up-arrow key
        @"\033OA", @"kcuu1",
        @"\033OA", @"ku",
        // key_down: down-arrow key
        @"\033OB", @"kcud1",
        @"\033OB", @"kd",
        // key_right: right-arrow key
        @"\033OC", @"kcuf1",
        @"\033OC", @"kr",
        // key_left: left-arrow key
        @"\033OD", @"kcub1",
        @"\033OD", @"kl",
        // key_sright: shifted right-arrow key
        @"\033[1;2C", @"kRIT",
        @"\033[1;2C", @"%i",
        // key_sleft: shifted left-arrow key
        @"\033[1;2D", @"kLFT",
        @"\033[1;2D", @"#4",
        // key_f1: F1 function key
        @"\033OP", @"kf1",
        @"\033OP", @"k1",
        // key_f2: F2 function key
        @"\033OQ", @"kf2",
        @"\033OQ", @"k2",
        // key_f3: F3 function key
        @"\033OR", @"kf3",
        @"\033OR", @"k3",
        // key_f4: F4 function key
        @"\033OS", @"kf4",
        @"\033OS", @"k4",
        // key_f5: F5 function key
        @"\033[15~", @"kf5",
        @"\033[15~", @"k5",
        // key_f6: F6 function key
        @"\033[17~", @"kf6",
        @"\033[17~", @"k6",
        // key_f7: F7 function key
        @"\033[18~", @"kf7",
        @"\033[18~", @"k7",
        // key_f8: F8 function key
        @"\033[19~", @"kf8",
        @"\033[19~", @"k8",
        // key_f9: F9 function key
        @"\033[20~", @"kf9",
        @"\033[20~", @"k9",
        // key_f10: F10 function key
        @"\033[21~", @"kf10",
        @"\033[21~", @"k;",
        // key_f11: F11 function key
        @"\033[23~", @"kf11",
        @"\033[23~", @"F1",
        // key_f12: F12 function key
        @"\033[24~", @"kf12",
        @"\033[24~", @"F2",
        // key_mouse: Mouse event has occurred
        @"\033[<", @"kmous",
        @"\033[<", @"Km",
        nil];
    NSArray *keyArray =  [tcapRawMap allKeys];
    int count = [keyArray count];
    for (int i = 0; i < count; i++) {
        NSString *key = [keyArray objectAtIndex:i];
        NSString *hexkey = convertToHexString(key);
        NSString *hexvalue = convertToHexString([tcapRawMap objectForKey:key]);
        [result setObject: hexvalue forKey: hexkey];
        [result setObject: hexvalue forKey: [hexkey uppercaseString]];
    }
    return result;
}


NSDictionary* generateX11ColorNameMap()
{
    NSDictionary *colorNameMap = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"snow",
        [NSColor colorWithRed: 248 / 255.0f green: 248 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"ghost white",
        [NSColor colorWithRed: 248 / 255.0f green: 248 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"ghostwhite",
        [NSColor colorWithRed: 245 / 255.0f green: 245 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"white smoke",
        [NSColor colorWithRed: 245 / 255.0f green: 245 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"whitesmoke",
        [NSColor colorWithRed: 220 / 255.0f green: 220 / 255.0f blue: 220 / 255.0f alpha: 1.0f], @"gainsboro",
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"floral white",
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"floralwhite",
        [NSColor colorWithRed: 253 / 255.0f green: 245 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"old lace",
        [NSColor colorWithRed: 253 / 255.0f green: 245 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"oldlace",
        [NSColor colorWithRed: 250 / 255.0f green: 240 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"linen",
        [NSColor colorWithRed: 250 / 255.0f green: 235 / 255.0f blue: 215 / 255.0f alpha: 1.0f], @"antique white",
        [NSColor colorWithRed: 250 / 255.0f green: 235 / 255.0f blue: 215 / 255.0f alpha: 1.0f], @"antiquewhite",
        [NSColor colorWithRed: 255 / 255.0f green: 239 / 255.0f blue: 213 / 255.0f alpha: 1.0f], @"papaya whip",
        [NSColor colorWithRed: 255 / 255.0f green: 239 / 255.0f blue: 213 / 255.0f alpha: 1.0f], @"papayawhip",
        [NSColor colorWithRed: 255 / 255.0f green: 235 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"blanched almond",
        [NSColor colorWithRed: 255 / 255.0f green: 235 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"blanchedalmond",
        [NSColor colorWithRed: 255 / 255.0f green: 228 / 255.0f blue: 196 / 255.0f alpha: 1.0f], @"bisque",
        [NSColor colorWithRed: 255 / 255.0f green: 218 / 255.0f blue: 185 / 255.0f alpha: 1.0f], @"peach puff",
        [NSColor colorWithRed: 255 / 255.0f green: 218 / 255.0f blue: 185 / 255.0f alpha: 1.0f], @"peachpuff",
        [NSColor colorWithRed: 255 / 255.0f green: 222 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"navajo white",
        [NSColor colorWithRed: 255 / 255.0f green: 222 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"navajowhite",
        [NSColor colorWithRed: 255 / 255.0f green: 228 / 255.0f blue: 181 / 255.0f alpha: 1.0f], @"moccasin",
        [NSColor colorWithRed: 255 / 255.0f green: 248 / 255.0f blue: 220 / 255.0f alpha: 1.0f], @"cornsilk",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"ivory",
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lemon chiffon",
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lemonchiffon",
        [NSColor colorWithRed: 255 / 255.0f green: 245 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"seashell",
        [NSColor colorWithRed: 240 / 255.0f green: 255 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"honeydew",
        [NSColor colorWithRed: 245 / 255.0f green: 255 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"mint cream",
        [NSColor colorWithRed: 245 / 255.0f green: 255 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"mintcream",
        [NSColor colorWithRed: 240 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"azure",
        [NSColor colorWithRed: 240 / 255.0f green: 248 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"alice blue",
        [NSColor colorWithRed: 240 / 255.0f green: 248 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"aliceblue",
        [NSColor colorWithRed: 230 / 255.0f green: 230 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"lavender",
        [NSColor colorWithRed: 255 / 255.0f green: 240 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"lavender blush",
        [NSColor colorWithRed: 255 / 255.0f green: 240 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"lavenderblush",
        [NSColor colorWithRed: 255 / 255.0f green: 228 / 255.0f blue: 225 / 255.0f alpha: 1.0f], @"misty rose",
        [NSColor colorWithRed: 255 / 255.0f green: 228 / 255.0f blue: 225 / 255.0f alpha: 1.0f], @"mistyrose",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"white",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"black",
        [NSColor colorWithRed:  47 / 255.0f green:  79 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"dark slate gray",
        [NSColor colorWithRed:  47 / 255.0f green:  79 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"darkslategray",
        [NSColor colorWithRed:  47 / 255.0f green:  79 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"dark slate grey",
        [NSColor colorWithRed:  47 / 255.0f green:  79 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"darkslategrey",
        [NSColor colorWithRed: 105 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"dim gray",
        [NSColor colorWithRed: 105 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"dimgray",
        [NSColor colorWithRed: 105 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"dim grey",
        [NSColor colorWithRed: 105 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"dimgrey",
        [NSColor colorWithRed: 112 / 255.0f green: 128 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"slate gray",
        [NSColor colorWithRed: 112 / 255.0f green: 128 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"slategray",
        [NSColor colorWithRed: 112 / 255.0f green: 128 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"slate grey",
        [NSColor colorWithRed: 112 / 255.0f green: 128 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"slategrey",
        [NSColor colorWithRed: 119 / 255.0f green: 136 / 255.0f blue: 153 / 255.0f alpha: 1.0f], @"light slate gray",
        [NSColor colorWithRed: 119 / 255.0f green: 136 / 255.0f blue: 153 / 255.0f alpha: 1.0f], @"lightslategray",
        [NSColor colorWithRed: 119 / 255.0f green: 136 / 255.0f blue: 153 / 255.0f alpha: 1.0f], @"light slate grey",
        [NSColor colorWithRed: 119 / 255.0f green: 136 / 255.0f blue: 153 / 255.0f alpha: 1.0f], @"lightslategrey",
        [NSColor colorWithRed: 190 / 255.0f green: 190 / 255.0f blue: 190 / 255.0f alpha: 1.0f], @"gray",
        [NSColor colorWithRed: 190 / 255.0f green: 190 / 255.0f blue: 190 / 255.0f alpha: 1.0f], @"grey",
        [NSColor colorWithRed: 211 / 255.0f green: 211 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"light grey",
        [NSColor colorWithRed: 211 / 255.0f green: 211 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"lightgrey",
        [NSColor colorWithRed: 211 / 255.0f green: 211 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"light gray",
        [NSColor colorWithRed: 211 / 255.0f green: 211 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"lightgray",
        [NSColor colorWithRed:  25 / 255.0f green:  25 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"midnight blue",
        [NSColor colorWithRed:  25 / 255.0f green:  25 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"midnightblue",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 128 / 255.0f alpha: 1.0f], @"navy",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 128 / 255.0f alpha: 1.0f], @"navy blue",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 128 / 255.0f alpha: 1.0f], @"navyblue",
        [NSColor colorWithRed: 100 / 255.0f green: 149 / 255.0f blue: 237 / 255.0f alpha: 1.0f], @"cornflower blue",
        [NSColor colorWithRed: 100 / 255.0f green: 149 / 255.0f blue: 237 / 255.0f alpha: 1.0f], @"cornflowerblue",
        [NSColor colorWithRed:  72 / 255.0f green:  61 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"dark slate blue",
        [NSColor colorWithRed:  72 / 255.0f green:  61 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"darkslateblue",
        [NSColor colorWithRed: 106 / 255.0f green:  90 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"slate blue",
        [NSColor colorWithRed: 106 / 255.0f green:  90 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"slateblue",
        [NSColor colorWithRed: 123 / 255.0f green: 104 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"medium slate blue",
        [NSColor colorWithRed: 123 / 255.0f green: 104 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"mediumslateblue",
        [NSColor colorWithRed: 132 / 255.0f green: 112 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"light slate blue",
        [NSColor colorWithRed: 132 / 255.0f green: 112 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"lightslateblue",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"medium blue",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"mediumblue",
        [NSColor colorWithRed:  65 / 255.0f green: 105 / 255.0f blue: 225 / 255.0f alpha: 1.0f], @"royal blue",
        [NSColor colorWithRed:  65 / 255.0f green: 105 / 255.0f blue: 225 / 255.0f alpha: 1.0f], @"royalblue",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"blue",
        [NSColor colorWithRed:  30 / 255.0f green: 144 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"dodger blue",
        [NSColor colorWithRed:  30 / 255.0f green: 144 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"dodgerblue",
        [NSColor colorWithRed:   0 / 255.0f green: 191 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"deep sky blue",
        [NSColor colorWithRed:   0 / 255.0f green: 191 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"deepskyblue",
        [NSColor colorWithRed: 135 / 255.0f green: 206 / 255.0f blue: 235 / 255.0f alpha: 1.0f], @"sky blue",
        [NSColor colorWithRed: 135 / 255.0f green: 206 / 255.0f blue: 235 / 255.0f alpha: 1.0f], @"skyblue",
        [NSColor colorWithRed: 135 / 255.0f green: 206 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"light sky blue",
        [NSColor colorWithRed: 135 / 255.0f green: 206 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"lightskyblue",
        [NSColor colorWithRed:  70 / 255.0f green: 130 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"steel blue",
        [NSColor colorWithRed:  70 / 255.0f green: 130 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"steelblue",
        [NSColor colorWithRed: 176 / 255.0f green: 196 / 255.0f blue: 222 / 255.0f alpha: 1.0f], @"light steel blue",
        [NSColor colorWithRed: 176 / 255.0f green: 196 / 255.0f blue: 222 / 255.0f alpha: 1.0f], @"lightsteelblue",
        [NSColor colorWithRed: 173 / 255.0f green: 216 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"light blue",
        [NSColor colorWithRed: 173 / 255.0f green: 216 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"lightblue",
        [NSColor colorWithRed: 176 / 255.0f green: 224 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"powder blue",
        [NSColor colorWithRed: 176 / 255.0f green: 224 / 255.0f blue: 230 / 255.0f alpha: 1.0f], @"powderblue",
        [NSColor colorWithRed: 175 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"pale turquoise",
        [NSColor colorWithRed: 175 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"paleturquoise",
        [NSColor colorWithRed:   0 / 255.0f green: 206 / 255.0f blue: 209 / 255.0f alpha: 1.0f], @"dark turquoise",
        [NSColor colorWithRed:   0 / 255.0f green: 206 / 255.0f blue: 209 / 255.0f alpha: 1.0f], @"darkturquoise",
        [NSColor colorWithRed:  72 / 255.0f green: 209 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"medium turquoise",
        [NSColor colorWithRed:  72 / 255.0f green: 209 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"mediumturquoise",
        [NSColor colorWithRed:  64 / 255.0f green: 224 / 255.0f blue: 208 / 255.0f alpha: 1.0f], @"turquoise",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"cyan",
        [NSColor colorWithRed: 224 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"light cyan",
        [NSColor colorWithRed: 224 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"lightcyan",
        [NSColor colorWithRed:  95 / 255.0f green: 158 / 255.0f blue: 160 / 255.0f alpha: 1.0f], @"cadet blue",
        [NSColor colorWithRed:  95 / 255.0f green: 158 / 255.0f blue: 160 / 255.0f alpha: 1.0f], @"cadetblue",
        [NSColor colorWithRed: 102 / 255.0f green: 205 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"medium aquamarine",
        [NSColor colorWithRed: 102 / 255.0f green: 205 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"mediumaquamarine",
        [NSColor colorWithRed: 127 / 255.0f green: 255 / 255.0f blue: 212 / 255.0f alpha: 1.0f], @"aquamarine",
        [NSColor colorWithRed:   0 / 255.0f green: 100 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"dark green",
        [NSColor colorWithRed:   0 / 255.0f green: 100 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkgreen",
        [NSColor colorWithRed:  85 / 255.0f green: 107 / 255.0f blue:  47 / 255.0f alpha: 1.0f], @"dark olive green",
        [NSColor colorWithRed:  85 / 255.0f green: 107 / 255.0f blue:  47 / 255.0f alpha: 1.0f], @"darkolivegreen",
        [NSColor colorWithRed: 143 / 255.0f green: 188 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"dark sea green",
        [NSColor colorWithRed: 143 / 255.0f green: 188 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"darkseagreen",
        [NSColor colorWithRed:  46 / 255.0f green: 139 / 255.0f blue:  87 / 255.0f alpha: 1.0f], @"sea green",
        [NSColor colorWithRed:  46 / 255.0f green: 139 / 255.0f blue:  87 / 255.0f alpha: 1.0f], @"seagreen",
        [NSColor colorWithRed:  60 / 255.0f green: 179 / 255.0f blue: 113 / 255.0f alpha: 1.0f], @"medium sea green",
        [NSColor colorWithRed:  60 / 255.0f green: 179 / 255.0f blue: 113 / 255.0f alpha: 1.0f], @"mediumseagreen",
        [NSColor colorWithRed:  32 / 255.0f green: 178 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"light sea green",
        [NSColor colorWithRed:  32 / 255.0f green: 178 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"lightseagreen",
        [NSColor colorWithRed: 152 / 255.0f green: 251 / 255.0f blue: 152 / 255.0f alpha: 1.0f], @"pale green",
        [NSColor colorWithRed: 152 / 255.0f green: 251 / 255.0f blue: 152 / 255.0f alpha: 1.0f], @"palegreen",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue: 127 / 255.0f alpha: 1.0f], @"spring green",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue: 127 / 255.0f alpha: 1.0f], @"springgreen",
        [NSColor colorWithRed: 124 / 255.0f green: 252 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"lawn green",
        [NSColor colorWithRed: 124 / 255.0f green: 252 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"lawngreen",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"green",
        [NSColor colorWithRed: 127 / 255.0f green: 255 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"chartreuse",
        [NSColor colorWithRed:   0 / 255.0f green: 250 / 255.0f blue: 154 / 255.0f alpha: 1.0f], @"medium spring green",
        [NSColor colorWithRed:   0 / 255.0f green: 250 / 255.0f blue: 154 / 255.0f alpha: 1.0f], @"mediumspringgreen",
        [NSColor colorWithRed: 173 / 255.0f green: 255 / 255.0f blue:  47 / 255.0f alpha: 1.0f], @"green yellow",
        [NSColor colorWithRed: 173 / 255.0f green: 255 / 255.0f blue:  47 / 255.0f alpha: 1.0f], @"greenyellow",
        [NSColor colorWithRed:  50 / 255.0f green: 205 / 255.0f blue:  50 / 255.0f alpha: 1.0f], @"lime green",
        [NSColor colorWithRed:  50 / 255.0f green: 205 / 255.0f blue:  50 / 255.0f alpha: 1.0f], @"limegreen",
        [NSColor colorWithRed: 154 / 255.0f green: 205 / 255.0f blue:  50 / 255.0f alpha: 1.0f], @"yellow green",
        [NSColor colorWithRed: 154 / 255.0f green: 205 / 255.0f blue:  50 / 255.0f alpha: 1.0f], @"yellowgreen",
        [NSColor colorWithRed:  34 / 255.0f green: 139 / 255.0f blue:  34 / 255.0f alpha: 1.0f], @"forest green",
        [NSColor colorWithRed:  34 / 255.0f green: 139 / 255.0f blue:  34 / 255.0f alpha: 1.0f], @"forestgreen",
        [NSColor colorWithRed: 107 / 255.0f green: 142 / 255.0f blue:  35 / 255.0f alpha: 1.0f], @"olive drab",
        [NSColor colorWithRed: 107 / 255.0f green: 142 / 255.0f blue:  35 / 255.0f alpha: 1.0f], @"olivedrab",
        [NSColor colorWithRed: 189 / 255.0f green: 183 / 255.0f blue: 107 / 255.0f alpha: 1.0f], @"dark khaki",
        [NSColor colorWithRed: 189 / 255.0f green: 183 / 255.0f blue: 107 / 255.0f alpha: 1.0f], @"darkkhaki",
        [NSColor colorWithRed: 240 / 255.0f green: 230 / 255.0f blue: 140 / 255.0f alpha: 1.0f], @"khaki",
        [NSColor colorWithRed: 238 / 255.0f green: 232 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"pale goldenrod",
        [NSColor colorWithRed: 238 / 255.0f green: 232 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"palegoldenrod",
        [NSColor colorWithRed: 250 / 255.0f green: 250 / 255.0f blue: 210 / 255.0f alpha: 1.0f], @"light goldenrod yellow",
        [NSColor colorWithRed: 250 / 255.0f green: 250 / 255.0f blue: 210 / 255.0f alpha: 1.0f], @"lightgoldenrodyellow",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"light yellow",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"lightyellow",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"yellow",
        [NSColor colorWithRed: 255 / 255.0f green: 215 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @" gold",
        [NSColor colorWithRed: 238 / 255.0f green: 221 / 255.0f blue: 130 / 255.0f alpha: 1.0f], @"light goldenrod",
        [NSColor colorWithRed: 238 / 255.0f green: 221 / 255.0f blue: 130 / 255.0f alpha: 1.0f], @"lightgoldenrod",
        [NSColor colorWithRed: 218 / 255.0f green: 165 / 255.0f blue:  32 / 255.0f alpha: 1.0f], @"goldenrod",
        [NSColor colorWithRed: 184 / 255.0f green: 134 / 255.0f blue:  11 / 255.0f alpha: 1.0f], @"dark goldenrod",
        [NSColor colorWithRed: 184 / 255.0f green: 134 / 255.0f blue:  11 / 255.0f alpha: 1.0f], @"darkgoldenrod",
        [NSColor colorWithRed: 188 / 255.0f green: 143 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"rosy brown",
        [NSColor colorWithRed: 188 / 255.0f green: 143 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"rosybrown",
        [NSColor colorWithRed: 205 / 255.0f green:  92 / 255.0f blue:  92 / 255.0f alpha: 1.0f], @"indian red",
        [NSColor colorWithRed: 205 / 255.0f green:  92 / 255.0f blue:  92 / 255.0f alpha: 1.0f], @"indianred",
        [NSColor colorWithRed: 139 / 255.0f green:  69 / 255.0f blue:  19 / 255.0f alpha: 1.0f], @"saddle brown",
        [NSColor colorWithRed: 139 / 255.0f green:  69 / 255.0f blue:  19 / 255.0f alpha: 1.0f], @"saddlebrown",
        [NSColor colorWithRed: 160 / 255.0f green:  82 / 255.0f blue:  45 / 255.0f alpha: 1.0f], @"sienna",
        [NSColor colorWithRed: 205 / 255.0f green: 133 / 255.0f blue:  63 / 255.0f alpha: 1.0f], @"peru",
        [NSColor colorWithRed: 222 / 255.0f green: 184 / 255.0f blue: 135 / 255.0f alpha: 1.0f], @"burlywood",
        [NSColor colorWithRed: 245 / 255.0f green: 245 / 255.0f blue: 220 / 255.0f alpha: 1.0f], @"beige",
        [NSColor colorWithRed: 245 / 255.0f green: 222 / 255.0f blue: 179 / 255.0f alpha: 1.0f], @"wheat",
        [NSColor colorWithRed: 244 / 255.0f green: 164 / 255.0f blue:  96 / 255.0f alpha: 1.0f], @"sandy brown",
        [NSColor colorWithRed: 244 / 255.0f green: 164 / 255.0f blue:  96 / 255.0f alpha: 1.0f], @"sandybrown",
        [NSColor colorWithRed: 210 / 255.0f green: 180 / 255.0f blue: 140 / 255.0f alpha: 1.0f], @"tan",
        [NSColor colorWithRed: 210 / 255.0f green: 105 / 255.0f blue:  30 / 255.0f alpha: 1.0f], @"chocolate",
        [NSColor colorWithRed: 178 / 255.0f green:  34 / 255.0f blue:  34 / 255.0f alpha: 1.0f], @"firebrick",
        [NSColor colorWithRed: 165 / 255.0f green:  42 / 255.0f blue:  42 / 255.0f alpha: 1.0f], @"brown",
        [NSColor colorWithRed: 233 / 255.0f green: 150 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"dark salmon",
        [NSColor colorWithRed: 233 / 255.0f green: 150 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"darksalmon",
        [NSColor colorWithRed: 250 / 255.0f green: 128 / 255.0f blue: 114 / 255.0f alpha: 1.0f], @"salmon",
        [NSColor colorWithRed: 255 / 255.0f green: 160 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"light salmon",
        [NSColor colorWithRed: 255 / 255.0f green: 160 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"lightsalmon",
        [NSColor colorWithRed: 255 / 255.0f green: 165 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orange",
        [NSColor colorWithRed: 255 / 255.0f green: 140 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"dark orange",
        [NSColor colorWithRed: 255 / 255.0f green: 140 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkorange",
        [NSColor colorWithRed: 255 / 255.0f green: 127 / 255.0f blue:  80 / 255.0f alpha: 1.0f], @"coral",
        [NSColor colorWithRed: 240 / 255.0f green: 128 / 255.0f blue: 128 / 255.0f alpha: 1.0f], @"light coral",
        [NSColor colorWithRed: 240 / 255.0f green: 128 / 255.0f blue: 128 / 255.0f alpha: 1.0f], @"lightcoral",
        [NSColor colorWithRed: 255 / 255.0f green:  99 / 255.0f blue:  71 / 255.0f alpha: 1.0f], @"tomato",
        [NSColor colorWithRed: 255 / 255.0f green:  69 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orange red",
        [NSColor colorWithRed: 255 / 255.0f green:  69 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orangered",
        [NSColor colorWithRed: 255 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"red",
        [NSColor colorWithRed: 255 / 255.0f green: 105 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"hot pink",
        [NSColor colorWithRed: 255 / 255.0f green: 105 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"hotpink",
        [NSColor colorWithRed: 255 / 255.0f green:  20 / 255.0f blue: 147 / 255.0f alpha: 1.0f], @"deep pink",
        [NSColor colorWithRed: 255 / 255.0f green:  20 / 255.0f blue: 147 / 255.0f alpha: 1.0f], @"deeppink",
        [NSColor colorWithRed: 255 / 255.0f green: 192 / 255.0f blue: 203 / 255.0f alpha: 1.0f], @"pink",
        [NSColor colorWithRed: 255 / 255.0f green: 182 / 255.0f blue: 193 / 255.0f alpha: 1.0f], @"light pink",
        [NSColor colorWithRed: 255 / 255.0f green: 182 / 255.0f blue: 193 / 255.0f alpha: 1.0f], @"lightpink",
        [NSColor colorWithRed: 219 / 255.0f green: 112 / 255.0f blue: 147 / 255.0f alpha: 1.0f], @"pale violet red",
        [NSColor colorWithRed: 219 / 255.0f green: 112 / 255.0f blue: 147 / 255.0f alpha: 1.0f], @"palevioletred",
        [NSColor colorWithRed: 176 / 255.0f green:  48 / 255.0f blue:  96 / 255.0f alpha: 1.0f], @"maroon",
        [NSColor colorWithRed: 199 / 255.0f green:  21 / 255.0f blue: 133 / 255.0f alpha: 1.0f], @"medium violet red",
        [NSColor colorWithRed: 199 / 255.0f green:  21 / 255.0f blue: 133 / 255.0f alpha: 1.0f], @"mediumvioletred",
        [NSColor colorWithRed: 208 / 255.0f green:  32 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"violet red",
        [NSColor colorWithRed: 208 / 255.0f green:  32 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"violetred",
        [NSColor colorWithRed: 255 / 255.0f green:   0 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"magenta",
        [NSColor colorWithRed: 238 / 255.0f green: 130 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"violet",
        [NSColor colorWithRed: 221 / 255.0f green: 160 / 255.0f blue: 221 / 255.0f alpha: 1.0f], @"plum",
        [NSColor colorWithRed: 218 / 255.0f green: 112 / 255.0f blue: 214 / 255.0f alpha: 1.0f], @"orchid",
        [NSColor colorWithRed: 186 / 255.0f green:  85 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"medium orchid",
        [NSColor colorWithRed: 186 / 255.0f green:  85 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"mediumorchid",
        [NSColor colorWithRed: 153 / 255.0f green:  50 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"dark orchid",
        [NSColor colorWithRed: 153 / 255.0f green:  50 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"darkorchid",
        [NSColor colorWithRed: 148 / 255.0f green:   0 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"dark violet",
        [NSColor colorWithRed: 148 / 255.0f green:   0 / 255.0f blue: 211 / 255.0f alpha: 1.0f], @"darkviolet",
        [NSColor colorWithRed: 138 / 255.0f green:  43 / 255.0f blue: 226 / 255.0f alpha: 1.0f], @"blue violet",
        [NSColor colorWithRed: 138 / 255.0f green:  43 / 255.0f blue: 226 / 255.0f alpha: 1.0f], @"blueviolet",
        [NSColor colorWithRed: 160 / 255.0f green:  32 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"purple",
        [NSColor colorWithRed: 147 / 255.0f green: 112 / 255.0f blue: 219 / 255.0f alpha: 1.0f], @"medium purple",
        [NSColor colorWithRed: 147 / 255.0f green: 112 / 255.0f blue: 219 / 255.0f alpha: 1.0f], @"mediumpurple",
        [NSColor colorWithRed: 216 / 255.0f green: 191 / 255.0f blue: 216 / 255.0f alpha: 1.0f], @"thistle",
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"snow1",
        [NSColor colorWithRed: 238 / 255.0f green: 233 / 255.0f blue: 233 / 255.0f alpha: 1.0f], @"snow2",
        [NSColor colorWithRed: 205 / 255.0f green: 201 / 255.0f blue: 201 / 255.0f alpha: 1.0f], @"snow3",
        [NSColor colorWithRed: 139 / 255.0f green: 137 / 255.0f blue: 137 / 255.0f alpha: 1.0f], @"snow4",
        [NSColor colorWithRed: 255 / 255.0f green: 245 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"seashell1",
        [NSColor colorWithRed: 238 / 255.0f green: 229 / 255.0f blue: 222 / 255.0f alpha: 1.0f], @"seashell2",
        [NSColor colorWithRed: 205 / 255.0f green: 197 / 255.0f blue: 191 / 255.0f alpha: 1.0f], @"seashell3",
        [NSColor colorWithRed: 139 / 255.0f green: 134 / 255.0f blue: 130 / 255.0f alpha: 1.0f], @"seashell4",
        [NSColor colorWithRed: 255 / 255.0f green: 239 / 255.0f blue: 219 / 255.0f alpha: 1.0f], @"antiquewhite1",
        [NSColor colorWithRed: 238 / 255.0f green: 223 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"antiquewhite2",
        [NSColor colorWithRed: 205 / 255.0f green: 192 / 255.0f blue: 176 / 255.0f alpha: 1.0f], @"antiquewhite3",
        [NSColor colorWithRed: 139 / 255.0f green: 131 / 255.0f blue: 120 / 255.0f alpha: 1.0f], @"antiquewhite4",
        [NSColor colorWithRed: 255 / 255.0f green: 228 / 255.0f blue: 196 / 255.0f alpha: 1.0f], @"bisque1",
        [NSColor colorWithRed: 238 / 255.0f green: 213 / 255.0f blue: 183 / 255.0f alpha: 1.0f], @"bisque2",
        [NSColor colorWithRed: 205 / 255.0f green: 183 / 255.0f blue: 158 / 255.0f alpha: 1.0f], @"bisque3",
        [NSColor colorWithRed: 139 / 255.0f green: 125 / 255.0f blue: 107 / 255.0f alpha: 1.0f], @"bisque4",
        [NSColor colorWithRed: 255 / 255.0f green: 218 / 255.0f blue: 185 / 255.0f alpha: 1.0f], @"peachpuff1",
        [NSColor colorWithRed: 238 / 255.0f green: 203 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"peachpuff2",
        [NSColor colorWithRed: 205 / 255.0f green: 175 / 255.0f blue: 149 / 255.0f alpha: 1.0f], @"peachpuff3",
        [NSColor colorWithRed: 139 / 255.0f green: 119 / 255.0f blue: 101 / 255.0f alpha: 1.0f], @"peachpuff4",
        [NSColor colorWithRed: 255 / 255.0f green: 222 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"navajowhite1",
        [NSColor colorWithRed: 238 / 255.0f green: 207 / 255.0f blue: 161 / 255.0f alpha: 1.0f], @"navajowhite2",
        [NSColor colorWithRed: 205 / 255.0f green: 179 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"navajowhite3",
        [NSColor colorWithRed: 139 / 255.0f green: 121 / 255.0f blue:  94 / 255.0f alpha: 1.0f], @"navajowhite4",
        [NSColor colorWithRed: 255 / 255.0f green: 250 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lemonchiffon1",
        [NSColor colorWithRed: 238 / 255.0f green: 233 / 255.0f blue: 191 / 255.0f alpha: 1.0f], @"lemonchiffon2",
        [NSColor colorWithRed: 205 / 255.0f green: 201 / 255.0f blue: 165 / 255.0f alpha: 1.0f], @"lemonchiffon3",
        [NSColor colorWithRed: 139 / 255.0f green: 137 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"lemonchiffon4",
        [NSColor colorWithRed: 255 / 255.0f green: 248 / 255.0f blue: 220 / 255.0f alpha: 1.0f], @"cornsilk1",
        [NSColor colorWithRed: 238 / 255.0f green: 232 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"cornsilk2",
        [NSColor colorWithRed: 205 / 255.0f green: 200 / 255.0f blue: 177 / 255.0f alpha: 1.0f], @"cornsilk3",
        [NSColor colorWithRed: 139 / 255.0f green: 136 / 255.0f blue: 120 / 255.0f alpha: 1.0f], @"cornsilk4",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"ivory1",
        [NSColor colorWithRed: 238 / 255.0f green: 238 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"ivory2",
        [NSColor colorWithRed: 205 / 255.0f green: 205 / 255.0f blue: 193 / 255.0f alpha: 1.0f], @"ivory3",
        [NSColor colorWithRed: 139 / 255.0f green: 139 / 255.0f blue: 131 / 255.0f alpha: 1.0f], @"ivory4",
        [NSColor colorWithRed: 240 / 255.0f green: 255 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"honeydew1",
        [NSColor colorWithRed: 224 / 255.0f green: 238 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"honeydew2",
        [NSColor colorWithRed: 193 / 255.0f green: 205 / 255.0f blue: 193 / 255.0f alpha: 1.0f], @"honeydew3",
        [NSColor colorWithRed: 131 / 255.0f green: 139 / 255.0f blue: 131 / 255.0f alpha: 1.0f], @"honeydew4",
        [NSColor colorWithRed: 255 / 255.0f green: 240 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"lavenderblush1",
        [NSColor colorWithRed: 238 / 255.0f green: 224 / 255.0f blue: 229 / 255.0f alpha: 1.0f], @"lavenderblush2",
        [NSColor colorWithRed: 205 / 255.0f green: 193 / 255.0f blue: 197 / 255.0f alpha: 1.0f], @"lavenderblush3",
        [NSColor colorWithRed: 139 / 255.0f green: 131 / 255.0f blue: 134 / 255.0f alpha: 1.0f], @"lavenderblush4",
        [NSColor colorWithRed: 255 / 255.0f green: 228 / 255.0f blue: 225 / 255.0f alpha: 1.0f], @"mistyrose1",
        [NSColor colorWithRed: 238 / 255.0f green: 213 / 255.0f blue: 210 / 255.0f alpha: 1.0f], @"mistyrose2",
        [NSColor colorWithRed: 205 / 255.0f green: 183 / 255.0f blue: 181 / 255.0f alpha: 1.0f], @"mistyrose3",
        [NSColor colorWithRed: 139 / 255.0f green: 125 / 255.0f blue: 123 / 255.0f alpha: 1.0f], @"mistyrose4",
        [NSColor colorWithRed: 240 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"azure1",
        [NSColor colorWithRed: 224 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"azure2",
        [NSColor colorWithRed: 193 / 255.0f green: 205 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"azure3",
        [NSColor colorWithRed: 131 / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"azure4",
        [NSColor colorWithRed: 131 / 255.0f green: 111 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"slateblue1",
        [NSColor colorWithRed: 122 / 255.0f green: 103 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"slateblue2",
        [NSColor colorWithRed: 105 / 255.0f green:  89 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"slateblue3",
        [NSColor colorWithRed:  71 / 255.0f green:  60 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"slateblue4",
        [NSColor colorWithRed:  72 / 255.0f green: 118 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"royalblue1",
        [NSColor colorWithRed:  67 / 255.0f green: 110 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"royalblue2",
        [NSColor colorWithRed:  58 / 255.0f green:  95 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"royalblue3",
        [NSColor colorWithRed:  39 / 255.0f green:  64 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"royalblue4",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"blue1",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"blue2",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"blue3",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"blue4",
        [NSColor colorWithRed:  30 / 255.0f green: 144 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"dodgerblue1",
        [NSColor colorWithRed:  28 / 255.0f green: 134 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"dodgerblue2",
        [NSColor colorWithRed:  24 / 255.0f green: 116 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"dodgerblue3",
        [NSColor colorWithRed:  16 / 255.0f green:  78 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"dodgerblue4",
        [NSColor colorWithRed:  99 / 255.0f green: 184 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"steelblue1",
        [NSColor colorWithRed:  92 / 255.0f green: 172 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"steelblue2",
        [NSColor colorWithRed:  79 / 255.0f green: 148 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"steelblue3",
        [NSColor colorWithRed:  54 / 255.0f green: 100 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"steelblue4",
        [NSColor colorWithRed:   0 / 255.0f green: 191 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"deepskyblue1",
        [NSColor colorWithRed:   0 / 255.0f green: 178 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"deepskyblue2",
        [NSColor colorWithRed:   0 / 255.0f green: 154 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"deepskyblue3",
        [NSColor colorWithRed:   0 / 255.0f green: 104 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"deepskyblue4",
        [NSColor colorWithRed: 135 / 255.0f green: 206 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"skyblue1",
        [NSColor colorWithRed: 126 / 255.0f green: 192 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"skyblue2",
        [NSColor colorWithRed: 108 / 255.0f green: 166 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"skyblue3",
        [NSColor colorWithRed:  74 / 255.0f green: 112 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"skyblue4",
        [NSColor colorWithRed: 176 / 255.0f green: 226 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"lightskyblue1",
        [NSColor colorWithRed: 164 / 255.0f green: 211 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"lightskyblue2",
        [NSColor colorWithRed: 141 / 255.0f green: 182 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lightskyblue3",
        [NSColor colorWithRed:  96 / 255.0f green: 123 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"lightskyblue4",
        [NSColor colorWithRed: 198 / 255.0f green: 226 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"slategray1",
        [NSColor colorWithRed: 185 / 255.0f green: 211 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"slategray2",
        [NSColor colorWithRed: 159 / 255.0f green: 182 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"slategray3",
        [NSColor colorWithRed: 108 / 255.0f green: 123 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"slategray4",
        [NSColor colorWithRed: 202 / 255.0f green: 225 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"lightsteelblue1",
        [NSColor colorWithRed: 188 / 255.0f green: 210 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"lightsteelblue2",
        [NSColor colorWithRed: 162 / 255.0f green: 181 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lightsteelblue3",
        [NSColor colorWithRed: 110 / 255.0f green: 123 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"lightsteelblue4",
        [NSColor colorWithRed: 191 / 255.0f green: 239 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"lightblue1",
        [NSColor colorWithRed: 178 / 255.0f green: 223 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"lightblue2",
        [NSColor colorWithRed: 154 / 255.0f green: 192 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lightblue3",
        [NSColor colorWithRed: 104 / 255.0f green: 131 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"lightblue4",
        [NSColor colorWithRed: 224 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"lightcyan1",
        [NSColor colorWithRed: 209 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"lightcyan2",
        [NSColor colorWithRed: 180 / 255.0f green: 205 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"lightcyan3",
        [NSColor colorWithRed: 122 / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"lightcyan4",
        [NSColor colorWithRed: 187 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"paleturquoise1",
        [NSColor colorWithRed: 174 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"paleturquoise2",
        [NSColor colorWithRed: 150 / 255.0f green: 205 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"paleturquoise3",
        [NSColor colorWithRed: 102 / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"paleturquoise4",
        [NSColor colorWithRed: 152 / 255.0f green: 245 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"cadetblue1",
        [NSColor colorWithRed: 142 / 255.0f green: 229 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"cadetblue2",
        [NSColor colorWithRed: 122 / 255.0f green: 197 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"cadetblue3",
        [NSColor colorWithRed:  83 / 255.0f green: 134 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"cadetblue4",
        [NSColor colorWithRed:   0 / 255.0f green: 245 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"turquoise1",
        [NSColor colorWithRed:   0 / 255.0f green: 229 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"turquoise2",
        [NSColor colorWithRed:   0 / 255.0f green: 197 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"turquoise3",
        [NSColor colorWithRed:   0 / 255.0f green: 134 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"turquoise4",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"cyan1",
        [NSColor colorWithRed:   0 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"cyan2",
        [NSColor colorWithRed:   0 / 255.0f green: 205 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"cyan3",
        [NSColor colorWithRed:   0 / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"cyan4",
        [NSColor colorWithRed: 151 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"darkslategray1",
        [NSColor colorWithRed: 141 / 255.0f green: 238 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"darkslategray2",
        [NSColor colorWithRed: 121 / 255.0f green: 205 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"darkslategray3",
        [NSColor colorWithRed:  82 / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"darkslategray4",
        [NSColor colorWithRed: 127 / 255.0f green: 255 / 255.0f blue: 212 / 255.0f alpha: 1.0f], @"aquamarine1",
        [NSColor colorWithRed: 118 / 255.0f green: 238 / 255.0f blue: 198 / 255.0f alpha: 1.0f], @"aquamarine2",
        [NSColor colorWithRed: 102 / 255.0f green: 205 / 255.0f blue: 170 / 255.0f alpha: 1.0f], @"aquamarine3",
        [NSColor colorWithRed:  69 / 255.0f green: 139 / 255.0f blue: 116 / 255.0f alpha: 1.0f], @"aquamarine4",
        [NSColor colorWithRed: 193 / 255.0f green: 255 / 255.0f blue: 193 / 255.0f alpha: 1.0f], @"darkseagreen1",
        [NSColor colorWithRed: 180 / 255.0f green: 238 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"darkseagreen2",
        [NSColor colorWithRed: 155 / 255.0f green: 205 / 255.0f blue: 155 / 255.0f alpha: 1.0f], @"darkseagreen3",
        [NSColor colorWithRed: 105 / 255.0f green: 139 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"darkseagreen4",
        [NSColor colorWithRed:  84 / 255.0f green: 255 / 255.0f blue: 159 / 255.0f alpha: 1.0f], @"seagreen1",
        [NSColor colorWithRed:  78 / 255.0f green: 238 / 255.0f blue: 148 / 255.0f alpha: 1.0f], @"seagreen2",
        [NSColor colorWithRed:  67 / 255.0f green: 205 / 255.0f blue: 128 / 255.0f alpha: 1.0f], @"seagreen3",
        [NSColor colorWithRed:  46 / 255.0f green: 139 / 255.0f blue:  87 / 255.0f alpha: 1.0f], @"seagreen4",
        [NSColor colorWithRed: 154 / 255.0f green: 255 / 255.0f blue: 154 / 255.0f alpha: 1.0f], @"palegreen1",
        [NSColor colorWithRed: 144 / 255.0f green: 238 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"palegreen2",
        [NSColor colorWithRed: 124 / 255.0f green: 205 / 255.0f blue: 124 / 255.0f alpha: 1.0f], @"palegreen3",
        [NSColor colorWithRed:  84 / 255.0f green: 139 / 255.0f blue:  84 / 255.0f alpha: 1.0f], @"palegreen4",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue: 127 / 255.0f alpha: 1.0f], @"springgreen1",
        [NSColor colorWithRed:   0 / 255.0f green: 238 / 255.0f blue: 118 / 255.0f alpha: 1.0f], @"springgreen2",
        [NSColor colorWithRed:   0 / 255.0f green: 205 / 255.0f blue: 102 / 255.0f alpha: 1.0f], @"springgreen3",
        [NSColor colorWithRed:   0 / 255.0f green: 139 / 255.0f blue:  69 / 255.0f alpha: 1.0f], @"springgreen4",
        [NSColor colorWithRed:   0 / 255.0f green: 255 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"green1",
        [NSColor colorWithRed:   0 / 255.0f green: 238 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"green2",
        [NSColor colorWithRed:   0 / 255.0f green: 205 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"green3",
        [NSColor colorWithRed:   0 / 255.0f green: 139 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"green4",
        [NSColor colorWithRed: 127 / 255.0f green: 255 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"chartreuse1",
        [NSColor colorWithRed: 118 / 255.0f green: 238 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"chartreuse2",
        [NSColor colorWithRed: 102 / 255.0f green: 205 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"chartreuse3",
        [NSColor colorWithRed:  69 / 255.0f green: 139 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"chartreuse4",
        [NSColor colorWithRed: 192 / 255.0f green: 255 / 255.0f blue:  62 / 255.0f alpha: 1.0f], @"olivedrab1",
        [NSColor colorWithRed: 179 / 255.0f green: 238 / 255.0f blue:  58 / 255.0f alpha: 1.0f], @"olivedrab2",
        [NSColor colorWithRed: 154 / 255.0f green: 205 / 255.0f blue:  50 / 255.0f alpha: 1.0f], @"olivedrab3",
        [NSColor colorWithRed: 105 / 255.0f green: 139 / 255.0f blue:  34 / 255.0f alpha: 1.0f], @"olivedrab4",
        [NSColor colorWithRed: 202 / 255.0f green: 255 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"darkolivegreen1",
        [NSColor colorWithRed: 188 / 255.0f green: 238 / 255.0f blue: 104 / 255.0f alpha: 1.0f], @"darkolivegreen2",
        [NSColor colorWithRed: 162 / 255.0f green: 205 / 255.0f blue:  90 / 255.0f alpha: 1.0f], @"darkolivegreen3",
        [NSColor colorWithRed: 110 / 255.0f green: 139 / 255.0f blue:  61 / 255.0f alpha: 1.0f], @"darkolivegreen4",
        [NSColor colorWithRed: 255 / 255.0f green: 246 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"khaki1",
        [NSColor colorWithRed: 238 / 255.0f green: 230 / 255.0f blue: 133 / 255.0f alpha: 1.0f], @"khaki2",
        [NSColor colorWithRed: 205 / 255.0f green: 198 / 255.0f blue: 115 / 255.0f alpha: 1.0f], @"khaki3",
        [NSColor colorWithRed: 139 / 255.0f green: 134 / 255.0f blue:  78 / 255.0f alpha: 1.0f], @"khaki4",
        [NSColor colorWithRed: 255 / 255.0f green: 236 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"lightgoldenrod1",
        [NSColor colorWithRed: 238 / 255.0f green: 220 / 255.0f blue: 130 / 255.0f alpha: 1.0f], @"lightgoldenrod2",
        [NSColor colorWithRed: 205 / 255.0f green: 190 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"lightgoldenrod3",
        [NSColor colorWithRed: 139 / 255.0f green: 129 / 255.0f blue:  76 / 255.0f alpha: 1.0f], @"lightgoldenrod4",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"lightyellow1",
        [NSColor colorWithRed: 238 / 255.0f green: 238 / 255.0f blue: 209 / 255.0f alpha: 1.0f], @"lightyellow2",
        [NSColor colorWithRed: 205 / 255.0f green: 205 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"lightyellow3",
        [NSColor colorWithRed: 139 / 255.0f green: 139 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"lightyellow4",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"yellow1",
        [NSColor colorWithRed: 238 / 255.0f green: 238 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"yellow2",
        [NSColor colorWithRed: 205 / 255.0f green: 205 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"yellow3",
        [NSColor colorWithRed: 139 / 255.0f green: 139 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"yellow4",
        [NSColor colorWithRed: 255 / 255.0f green: 215 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"gold1",
        [NSColor colorWithRed: 238 / 255.0f green: 201 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"gold2",
        [NSColor colorWithRed: 205 / 255.0f green: 173 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"gold3",
        [NSColor colorWithRed: 139 / 255.0f green: 117 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"gold4",
        [NSColor colorWithRed: 255 / 255.0f green: 193 / 255.0f blue:  37 / 255.0f alpha: 1.0f], @"goldenrod1",
        [NSColor colorWithRed: 238 / 255.0f green: 180 / 255.0f blue:  34 / 255.0f alpha: 1.0f], @"goldenrod2",
        [NSColor colorWithRed: 205 / 255.0f green: 155 / 255.0f blue:  29 / 255.0f alpha: 1.0f], @"goldenrod3",
        [NSColor colorWithRed: 139 / 255.0f green: 105 / 255.0f blue:  20 / 255.0f alpha: 1.0f], @"goldenrod4",
        [NSColor colorWithRed: 255 / 255.0f green: 185 / 255.0f blue:  15 / 255.0f alpha: 1.0f], @"darkgoldenrod1",
        [NSColor colorWithRed: 238 / 255.0f green: 173 / 255.0f blue:  14 / 255.0f alpha: 1.0f], @"darkgoldenrod2",
        [NSColor colorWithRed: 205 / 255.0f green: 149 / 255.0f blue:  12 / 255.0f alpha: 1.0f], @"darkgoldenrod3",
        [NSColor colorWithRed: 139 / 255.0f green: 101 / 255.0f blue:   8 / 255.0f alpha: 1.0f], @"darkgoldenrod4",
        [NSColor colorWithRed: 255 / 255.0f green: 193 / 255.0f blue: 193 / 255.0f alpha: 1.0f], @"rosybrown1",
        [NSColor colorWithRed: 238 / 255.0f green: 180 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"rosybrown2",
        [NSColor colorWithRed: 205 / 255.0f green: 155 / 255.0f blue: 155 / 255.0f alpha: 1.0f], @"rosybrown3",
        [NSColor colorWithRed: 139 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"rosybrown4",
        [NSColor colorWithRed: 255 / 255.0f green: 106 / 255.0f blue: 106 / 255.0f alpha: 1.0f], @"indianred1",
        [NSColor colorWithRed: 238 / 255.0f green:  99 / 255.0f blue:  99 / 255.0f alpha: 1.0f], @"indianred2",
        [NSColor colorWithRed: 205 / 255.0f green:  85 / 255.0f blue:  85 / 255.0f alpha: 1.0f], @"indianred3",
        [NSColor colorWithRed: 139 / 255.0f green:  58 / 255.0f blue:  58 / 255.0f alpha: 1.0f], @"indianred4",
        [NSColor colorWithRed: 255 / 255.0f green: 130 / 255.0f blue:  71 / 255.0f alpha: 1.0f], @"sienna1",
        [NSColor colorWithRed: 238 / 255.0f green: 121 / 255.0f blue:  66 / 255.0f alpha: 1.0f], @"sienna2",
        [NSColor colorWithRed: 205 / 255.0f green: 104 / 255.0f blue:  57 / 255.0f alpha: 1.0f], @"sienna3",
        [NSColor colorWithRed: 139 / 255.0f green:  71 / 255.0f blue:  38 / 255.0f alpha: 1.0f], @"sienna4",
        [NSColor colorWithRed: 255 / 255.0f green: 211 / 255.0f blue: 155 / 255.0f alpha: 1.0f], @"burlywood1",
        [NSColor colorWithRed: 238 / 255.0f green: 197 / 255.0f blue: 145 / 255.0f alpha: 1.0f], @"burlywood2",
        [NSColor colorWithRed: 205 / 255.0f green: 170 / 255.0f blue: 125 / 255.0f alpha: 1.0f], @"burlywood3",
        [NSColor colorWithRed: 139 / 255.0f green: 115 / 255.0f blue:  85 / 255.0f alpha: 1.0f], @"burlywood4",
        [NSColor colorWithRed: 255 / 255.0f green: 231 / 255.0f blue: 186 / 255.0f alpha: 1.0f], @"wheat1",
        [NSColor colorWithRed: 238 / 255.0f green: 216 / 255.0f blue: 174 / 255.0f alpha: 1.0f], @"wheat2",
        [NSColor colorWithRed: 205 / 255.0f green: 186 / 255.0f blue: 150 / 255.0f alpha: 1.0f], @"wheat3",
        [NSColor colorWithRed: 139 / 255.0f green: 126 / 255.0f blue: 102 / 255.0f alpha: 1.0f], @"wheat4",
        [NSColor colorWithRed: 255 / 255.0f green: 165 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"tan1",
        [NSColor colorWithRed: 238 / 255.0f green: 154 / 255.0f blue:  73 / 255.0f alpha: 1.0f], @"tan2",
        [NSColor colorWithRed: 205 / 255.0f green: 133 / 255.0f blue:  63 / 255.0f alpha: 1.0f], @"tan3",
        [NSColor colorWithRed: 139 / 255.0f green:  90 / 255.0f blue:  43 / 255.0f alpha: 1.0f], @"tan4",
        [NSColor colorWithRed: 255 / 255.0f green: 127 / 255.0f blue:  36 / 255.0f alpha: 1.0f], @"chocolate1",
        [NSColor colorWithRed: 238 / 255.0f green: 118 / 255.0f blue:  33 / 255.0f alpha: 1.0f], @"chocolate2",
        [NSColor colorWithRed: 205 / 255.0f green: 102 / 255.0f blue:  29 / 255.0f alpha: 1.0f], @"chocolate3",
        [NSColor colorWithRed: 139 / 255.0f green:  69 / 255.0f blue:  19 / 255.0f alpha: 1.0f], @"chocolate4",
        [NSColor colorWithRed: 255 / 255.0f green:  48 / 255.0f blue:  48 / 255.0f alpha: 1.0f], @"firebrick1",
        [NSColor colorWithRed: 238 / 255.0f green:  44 / 255.0f blue:  44 / 255.0f alpha: 1.0f], @"firebrick2",
        [NSColor colorWithRed: 205 / 255.0f green:  38 / 255.0f blue:  38 / 255.0f alpha: 1.0f], @"firebrick3",
        [NSColor colorWithRed: 139 / 255.0f green:  26 / 255.0f blue:  26 / 255.0f alpha: 1.0f], @"firebrick4",
        [NSColor colorWithRed: 255 / 255.0f green:  64 / 255.0f blue:  64 / 255.0f alpha: 1.0f], @"brown1",
        [NSColor colorWithRed: 238 / 255.0f green:  59 / 255.0f blue:  59 / 255.0f alpha: 1.0f], @"brown2",
        [NSColor colorWithRed: 205 / 255.0f green:  51 / 255.0f blue:  51 / 255.0f alpha: 1.0f], @"brown3",
        [NSColor colorWithRed: 139 / 255.0f green:  35 / 255.0f blue:  35 / 255.0f alpha: 1.0f], @"brown4",
        [NSColor colorWithRed: 255 / 255.0f green: 140 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"salmon1",
        [NSColor colorWithRed: 238 / 255.0f green: 130 / 255.0f blue:  98 / 255.0f alpha: 1.0f], @"salmon2",
        [NSColor colorWithRed: 205 / 255.0f green: 112 / 255.0f blue:  84 / 255.0f alpha: 1.0f], @"salmon3",
        [NSColor colorWithRed: 139 / 255.0f green:  76 / 255.0f blue:  57 / 255.0f alpha: 1.0f], @"salmon4",
        [NSColor colorWithRed: 255 / 255.0f green: 160 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"lightsalmon1",
        [NSColor colorWithRed: 238 / 255.0f green: 149 / 255.0f blue: 114 / 255.0f alpha: 1.0f], @"lightsalmon2",
        [NSColor colorWithRed: 205 / 255.0f green: 129 / 255.0f blue:  98 / 255.0f alpha: 1.0f], @"lightsalmon3",
        [NSColor colorWithRed: 139 / 255.0f green:  87 / 255.0f blue:  66 / 255.0f alpha: 1.0f], @"lightsalmon4",
        [NSColor colorWithRed: 255 / 255.0f green: 165 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orange1",
        [NSColor colorWithRed: 238 / 255.0f green: 154 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orange2",
        [NSColor colorWithRed: 205 / 255.0f green: 133 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orange3",
        [NSColor colorWithRed: 139 / 255.0f green:  90 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orange4",
        [NSColor colorWithRed: 255 / 255.0f green: 127 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkorange1",
        [NSColor colorWithRed: 238 / 255.0f green: 118 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkorange2",
        [NSColor colorWithRed: 205 / 255.0f green: 102 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkorange3",
        [NSColor colorWithRed: 139 / 255.0f green:  69 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkorange4",
        [NSColor colorWithRed: 255 / 255.0f green: 114 / 255.0f blue:  86 / 255.0f alpha: 1.0f], @"coral1",
        [NSColor colorWithRed: 238 / 255.0f green: 106 / 255.0f blue:  80 / 255.0f alpha: 1.0f], @"coral2",
        [NSColor colorWithRed: 205 / 255.0f green:  91 / 255.0f blue:  69 / 255.0f alpha: 1.0f], @"coral3",
        [NSColor colorWithRed: 139 / 255.0f green:  62 / 255.0f blue:  47 / 255.0f alpha: 1.0f], @"coral4",
        [NSColor colorWithRed: 255 / 255.0f green:  99 / 255.0f blue:  71 / 255.0f alpha: 1.0f], @"tomato1",
        [NSColor colorWithRed: 238 / 255.0f green:  92 / 255.0f blue:  66 / 255.0f alpha: 1.0f], @"tomato2",
        [NSColor colorWithRed: 205 / 255.0f green:  79 / 255.0f blue:  57 / 255.0f alpha: 1.0f], @"tomato3",
        [NSColor colorWithRed: 139 / 255.0f green:  54 / 255.0f blue:  38 / 255.0f alpha: 1.0f], @"tomato4",
        [NSColor colorWithRed: 255 / 255.0f green:  69 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orangered1",
        [NSColor colorWithRed: 238 / 255.0f green:  64 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orangered2",
        [NSColor colorWithRed: 205 / 255.0f green:  55 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orangered3",
        [NSColor colorWithRed: 139 / 255.0f green:  37 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"orangered4",
        [NSColor colorWithRed: 255 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"red1",
        [NSColor colorWithRed: 238 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"red2",
        [NSColor colorWithRed: 205 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"red3",
        [NSColor colorWithRed: 139 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"red4",
        [NSColor colorWithRed: 255 / 255.0f green:  20 / 255.0f blue: 147 / 255.0f alpha: 1.0f], @"deeppink1",
        [NSColor colorWithRed: 238 / 255.0f green:  18 / 255.0f blue: 137 / 255.0f alpha: 1.0f], @"deeppink2",
        [NSColor colorWithRed: 205 / 255.0f green:  16 / 255.0f blue: 118 / 255.0f alpha: 1.0f], @"deeppink3",
        [NSColor colorWithRed: 139 / 255.0f green:  10 / 255.0f blue:  80 / 255.0f alpha: 1.0f], @"deeppink4",
        [NSColor colorWithRed: 255 / 255.0f green: 110 / 255.0f blue: 180 / 255.0f alpha: 1.0f], @"hotpink1",
        [NSColor colorWithRed: 238 / 255.0f green: 106 / 255.0f blue: 167 / 255.0f alpha: 1.0f], @"hotpink2",
        [NSColor colorWithRed: 205 / 255.0f green:  96 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"hotpink3",
        [NSColor colorWithRed: 139 / 255.0f green:  58 / 255.0f blue:  98 / 255.0f alpha: 1.0f], @"hotpink4",
        [NSColor colorWithRed: 255 / 255.0f green: 181 / 255.0f blue: 197 / 255.0f alpha: 1.0f], @"pink1",
        [NSColor colorWithRed: 238 / 255.0f green: 169 / 255.0f blue: 184 / 255.0f alpha: 1.0f], @"pink2",
        [NSColor colorWithRed: 205 / 255.0f green: 145 / 255.0f blue: 158 / 255.0f alpha: 1.0f], @"pink3",
        [NSColor colorWithRed: 139 / 255.0f green:  99 / 255.0f blue: 108 / 255.0f alpha: 1.0f], @"pink4",
        [NSColor colorWithRed: 255 / 255.0f green: 174 / 255.0f blue: 185 / 255.0f alpha: 1.0f], @"lightpink1",
        [NSColor colorWithRed: 238 / 255.0f green: 162 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"lightpink2",
        [NSColor colorWithRed: 205 / 255.0f green: 140 / 255.0f blue: 149 / 255.0f alpha: 1.0f], @"lightpink3",
        [NSColor colorWithRed: 139 / 255.0f green:  95 / 255.0f blue: 101 / 255.0f alpha: 1.0f], @"lightpink4",
        [NSColor colorWithRed: 255 / 255.0f green: 130 / 255.0f blue: 171 / 255.0f alpha: 1.0f], @"palevioletred1",
        [NSColor colorWithRed: 238 / 255.0f green: 121 / 255.0f blue: 159 / 255.0f alpha: 1.0f], @"palevioletred2",
        [NSColor colorWithRed: 205 / 255.0f green: 104 / 255.0f blue: 137 / 255.0f alpha: 1.0f], @"palevioletred3",
        [NSColor colorWithRed: 139 / 255.0f green:  71 / 255.0f blue:  93 / 255.0f alpha: 1.0f], @"palevioletred4",
        [NSColor colorWithRed: 255 / 255.0f green:  52 / 255.0f blue: 179 / 255.0f alpha: 1.0f], @"maroon1",
        [NSColor colorWithRed: 238 / 255.0f green:  48 / 255.0f blue: 167 / 255.0f alpha: 1.0f], @"maroon2",
        [NSColor colorWithRed: 205 / 255.0f green:  41 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"maroon3",
        [NSColor colorWithRed: 139 / 255.0f green:  28 / 255.0f blue:  98 / 255.0f alpha: 1.0f], @"maroon4",
        [NSColor colorWithRed: 255 / 255.0f green:  62 / 255.0f blue: 150 / 255.0f alpha: 1.0f], @"violetred1",
        [NSColor colorWithRed: 238 / 255.0f green:  58 / 255.0f blue: 140 / 255.0f alpha: 1.0f], @"violetred2",
        [NSColor colorWithRed: 205 / 255.0f green:  50 / 255.0f blue: 120 / 255.0f alpha: 1.0f], @"violetred3",
        [NSColor colorWithRed: 139 / 255.0f green:  34 / 255.0f blue:  82 / 255.0f alpha: 1.0f], @"violetred4",
        [NSColor colorWithRed: 255 / 255.0f green:   0 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"magenta1",
        [NSColor colorWithRed: 238 / 255.0f green:   0 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"magenta2",
        [NSColor colorWithRed: 205 / 255.0f green:   0 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"magenta3",
        [NSColor colorWithRed: 139 / 255.0f green:   0 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"magenta4",
        [NSColor colorWithRed: 255 / 255.0f green: 131 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"orchid1",
        [NSColor colorWithRed: 238 / 255.0f green: 122 / 255.0f blue: 233 / 255.0f alpha: 1.0f], @"orchid2",
        [NSColor colorWithRed: 205 / 255.0f green: 105 / 255.0f blue: 201 / 255.0f alpha: 1.0f], @"orchid3",
        [NSColor colorWithRed: 139 / 255.0f green:  71 / 255.0f blue: 137 / 255.0f alpha: 1.0f], @"orchid4",
        [NSColor colorWithRed: 255 / 255.0f green: 187 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"plum1",
        [NSColor colorWithRed: 238 / 255.0f green: 174 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"plum2",
        [NSColor colorWithRed: 205 / 255.0f green: 150 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"plum3",
        [NSColor colorWithRed: 139 / 255.0f green: 102 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"plum4",
        [NSColor colorWithRed: 224 / 255.0f green: 102 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"mediumorchid1",
        [NSColor colorWithRed: 209 / 255.0f green:  95 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"mediumorchid2",
        [NSColor colorWithRed: 180 / 255.0f green:  82 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"mediumorchid3",
        [NSColor colorWithRed: 122 / 255.0f green:  55 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"mediumorchid4",
        [NSColor colorWithRed: 191 / 255.0f green:  62 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"darkorchid1",
        [NSColor colorWithRed: 178 / 255.0f green:  58 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"darkorchid2",
        [NSColor colorWithRed: 154 / 255.0f green:  50 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"darkorchid3",
        [NSColor colorWithRed: 104 / 255.0f green:  34 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"darkorchid4",
        [NSColor colorWithRed: 155 / 255.0f green:  48 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"purple1",
        [NSColor colorWithRed: 145 / 255.0f green:  44 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"purple2",
        [NSColor colorWithRed: 125 / 255.0f green:  38 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"purple3",
        [NSColor colorWithRed:  85 / 255.0f green:  26 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"purple4",
        [NSColor colorWithRed: 171 / 255.0f green: 130 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"mediumpurple1",
        [NSColor colorWithRed: 159 / 255.0f green: 121 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"mediumpurple2",
        [NSColor colorWithRed: 137 / 255.0f green: 104 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"mediumpurple3",
        [NSColor colorWithRed:  93 / 255.0f green:  71 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"mediumpurple4",
        [NSColor colorWithRed: 255 / 255.0f green: 225 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"thistle1",
        [NSColor colorWithRed: 238 / 255.0f green: 210 / 255.0f blue: 238 / 255.0f alpha: 1.0f], @"thistle2",
        [NSColor colorWithRed: 205 / 255.0f green: 181 / 255.0f blue: 205 / 255.0f alpha: 1.0f], @"thistle3",
        [NSColor colorWithRed: 139 / 255.0f green: 123 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"thistle4",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"gray0",
        [NSColor colorWithRed:   0 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"grey0",
        [NSColor colorWithRed:   3 / 255.0f green:   3 / 255.0f blue:   3 / 255.0f alpha: 1.0f], @"gray1",
        [NSColor colorWithRed:   3 / 255.0f green:   3 / 255.0f blue:   3 / 255.0f alpha: 1.0f], @"grey1",
        [NSColor colorWithRed:   5 / 255.0f green:   5 / 255.0f blue:   5 / 255.0f alpha: 1.0f], @"gray2",
        [NSColor colorWithRed:   5 / 255.0f green:   5 / 255.0f blue:   5 / 255.0f alpha: 1.0f], @"grey2",
        [NSColor colorWithRed:   8 / 255.0f green:   8 / 255.0f blue:   8 / 255.0f alpha: 1.0f], @"gray3",
        [NSColor colorWithRed:   8 / 255.0f green:   8 / 255.0f blue:   8 / 255.0f alpha: 1.0f], @"grey3",
        [NSColor colorWithRed:  10 / 255.0f green:  10 / 255.0f blue:  10 / 255.0f alpha: 1.0f], @"gray4",
        [NSColor colorWithRed:  10 / 255.0f green:  10 / 255.0f blue:  10 / 255.0f alpha: 1.0f], @"grey4",
        [NSColor colorWithRed:  13 / 255.0f green:  13 / 255.0f blue:  13 / 255.0f alpha: 1.0f], @"gray5",
        [NSColor colorWithRed:  13 / 255.0f green:  13 / 255.0f blue:  13 / 255.0f alpha: 1.0f], @"grey5",
        [NSColor colorWithRed:  15 / 255.0f green:  15 / 255.0f blue:  15 / 255.0f alpha: 1.0f], @"gray6",
        [NSColor colorWithRed:  15 / 255.0f green:  15 / 255.0f blue:  15 / 255.0f alpha: 1.0f], @"grey6",
        [NSColor colorWithRed:  18 / 255.0f green:  18 / 255.0f blue:  18 / 255.0f alpha: 1.0f], @"gray7",
        [NSColor colorWithRed:  18 / 255.0f green:  18 / 255.0f blue:  18 / 255.0f alpha: 1.0f], @"grey7",
        [NSColor colorWithRed:  20 / 255.0f green:  20 / 255.0f blue:  20 / 255.0f alpha: 1.0f], @"gray8",
        [NSColor colorWithRed:  20 / 255.0f green:  20 / 255.0f blue:  20 / 255.0f alpha: 1.0f], @"grey8",
        [NSColor colorWithRed:  23 / 255.0f green:  23 / 255.0f blue:  23 / 255.0f alpha: 1.0f], @"gray9",
        [NSColor colorWithRed:  23 / 255.0f green:  23 / 255.0f blue:  23 / 255.0f alpha: 1.0f], @"grey9",
        [NSColor colorWithRed:  26 / 255.0f green:  26 / 255.0f blue:  26 / 255.0f alpha: 1.0f], @"gray10",
        [NSColor colorWithRed:  26 / 255.0f green:  26 / 255.0f blue:  26 / 255.0f alpha: 1.0f], @"grey10",
        [NSColor colorWithRed:  28 / 255.0f green:  28 / 255.0f blue:  28 / 255.0f alpha: 1.0f], @"gray11",
        [NSColor colorWithRed:  28 / 255.0f green:  28 / 255.0f blue:  28 / 255.0f alpha: 1.0f], @"grey11",
        [NSColor colorWithRed:  31 / 255.0f green:  31 / 255.0f blue:  31 / 255.0f alpha: 1.0f], @"gray12",
        [NSColor colorWithRed:  31 / 255.0f green:  31 / 255.0f blue:  31 / 255.0f alpha: 1.0f], @"grey12",
        [NSColor colorWithRed:  33 / 255.0f green:  33 / 255.0f blue:  33 / 255.0f alpha: 1.0f], @"gray13",
        [NSColor colorWithRed:  33 / 255.0f green:  33 / 255.0f blue:  33 / 255.0f alpha: 1.0f], @"grey13",
        [NSColor colorWithRed:  36 / 255.0f green:  36 / 255.0f blue:  36 / 255.0f alpha: 1.0f], @"gray14",
        [NSColor colorWithRed:  36 / 255.0f green:  36 / 255.0f blue:  36 / 255.0f alpha: 1.0f], @"grey14",
        [NSColor colorWithRed:  38 / 255.0f green:  38 / 255.0f blue:  38 / 255.0f alpha: 1.0f], @"gray15",
        [NSColor colorWithRed:  38 / 255.0f green:  38 / 255.0f blue:  38 / 255.0f alpha: 1.0f], @"grey15",
        [NSColor colorWithRed:  41 / 255.0f green:  41 / 255.0f blue:  41 / 255.0f alpha: 1.0f], @"gray16",
        [NSColor colorWithRed:  41 / 255.0f green:  41 / 255.0f blue:  41 / 255.0f alpha: 1.0f], @"grey16",
        [NSColor colorWithRed:  43 / 255.0f green:  43 / 255.0f blue:  43 / 255.0f alpha: 1.0f], @"gray17",
        [NSColor colorWithRed:  43 / 255.0f green:  43 / 255.0f blue:  43 / 255.0f alpha: 1.0f], @"grey17",
        [NSColor colorWithRed:  46 / 255.0f green:  46 / 255.0f blue:  46 / 255.0f alpha: 1.0f], @"gray18",
        [NSColor colorWithRed:  46 / 255.0f green:  46 / 255.0f blue:  46 / 255.0f alpha: 1.0f], @"grey18",
        [NSColor colorWithRed:  48 / 255.0f green:  48 / 255.0f blue:  48 / 255.0f alpha: 1.0f], @"gray19",
        [NSColor colorWithRed:  48 / 255.0f green:  48 / 255.0f blue:  48 / 255.0f alpha: 1.0f], @"grey19",
        [NSColor colorWithRed:  51 / 255.0f green:  51 / 255.0f blue:  51 / 255.0f alpha: 1.0f], @"gray20",
        [NSColor colorWithRed:  51 / 255.0f green:  51 / 255.0f blue:  51 / 255.0f alpha: 1.0f], @"grey20",
        [NSColor colorWithRed:  54 / 255.0f green:  54 / 255.0f blue:  54 / 255.0f alpha: 1.0f], @"gray21",
        [NSColor colorWithRed:  54 / 255.0f green:  54 / 255.0f blue:  54 / 255.0f alpha: 1.0f], @"grey21",
        [NSColor colorWithRed:  56 / 255.0f green:  56 / 255.0f blue:  56 / 255.0f alpha: 1.0f], @"gray22",
        [NSColor colorWithRed:  56 / 255.0f green:  56 / 255.0f blue:  56 / 255.0f alpha: 1.0f], @"grey22",
        [NSColor colorWithRed:  59 / 255.0f green:  59 / 255.0f blue:  59 / 255.0f alpha: 1.0f], @"gray23",
        [NSColor colorWithRed:  59 / 255.0f green:  59 / 255.0f blue:  59 / 255.0f alpha: 1.0f], @"grey23",
        [NSColor colorWithRed:  61 / 255.0f green:  61 / 255.0f blue:  61 / 255.0f alpha: 1.0f], @"gray24",
        [NSColor colorWithRed:  61 / 255.0f green:  61 / 255.0f blue:  61 / 255.0f alpha: 1.0f], @"grey24",
        [NSColor colorWithRed:  64 / 255.0f green:  64 / 255.0f blue:  64 / 255.0f alpha: 1.0f], @"gray25",
        [NSColor colorWithRed:  64 / 255.0f green:  64 / 255.0f blue:  64 / 255.0f alpha: 1.0f], @"grey25",
        [NSColor colorWithRed:  66 / 255.0f green:  66 / 255.0f blue:  66 / 255.0f alpha: 1.0f], @"gray26",
        [NSColor colorWithRed:  66 / 255.0f green:  66 / 255.0f blue:  66 / 255.0f alpha: 1.0f], @"grey26",
        [NSColor colorWithRed:  69 / 255.0f green:  69 / 255.0f blue:  69 / 255.0f alpha: 1.0f], @"gray27",
        [NSColor colorWithRed:  69 / 255.0f green:  69 / 255.0f blue:  69 / 255.0f alpha: 1.0f], @"grey27",
        [NSColor colorWithRed:  71 / 255.0f green:  71 / 255.0f blue:  71 / 255.0f alpha: 1.0f], @"gray28",
        [NSColor colorWithRed:  71 / 255.0f green:  71 / 255.0f blue:  71 / 255.0f alpha: 1.0f], @"grey28",
        [NSColor colorWithRed:  74 / 255.0f green:  74 / 255.0f blue:  74 / 255.0f alpha: 1.0f], @"gray29",
        [NSColor colorWithRed:  74 / 255.0f green:  74 / 255.0f blue:  74 / 255.0f alpha: 1.0f], @"grey29",
        [NSColor colorWithRed:  77 / 255.0f green:  77 / 255.0f blue:  77 / 255.0f alpha: 1.0f], @"gray30",
        [NSColor colorWithRed:  77 / 255.0f green:  77 / 255.0f blue:  77 / 255.0f alpha: 1.0f], @"grey30",
        [NSColor colorWithRed:  79 / 255.0f green:  79 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"gray31",
        [NSColor colorWithRed:  79 / 255.0f green:  79 / 255.0f blue:  79 / 255.0f alpha: 1.0f], @"grey31",
        [NSColor colorWithRed:  82 / 255.0f green:  82 / 255.0f blue:  82 / 255.0f alpha: 1.0f], @"gray32",
        [NSColor colorWithRed:  82 / 255.0f green:  82 / 255.0f blue:  82 / 255.0f alpha: 1.0f], @"grey32",
        [NSColor colorWithRed:  84 / 255.0f green:  84 / 255.0f blue:  84 / 255.0f alpha: 1.0f], @"gray33",
        [NSColor colorWithRed:  84 / 255.0f green:  84 / 255.0f blue:  84 / 255.0f alpha: 1.0f], @"grey33",
        [NSColor colorWithRed:  87 / 255.0f green:  87 / 255.0f blue:  87 / 255.0f alpha: 1.0f], @"gray34",
        [NSColor colorWithRed:  87 / 255.0f green:  87 / 255.0f blue:  87 / 255.0f alpha: 1.0f], @"grey34",
        [NSColor colorWithRed:  89 / 255.0f green:  89 / 255.0f blue:  89 / 255.0f alpha: 1.0f], @"gray35",
        [NSColor colorWithRed:  89 / 255.0f green:  89 / 255.0f blue:  89 / 255.0f alpha: 1.0f], @"grey35",
        [NSColor colorWithRed:  92 / 255.0f green:  92 / 255.0f blue:  92 / 255.0f alpha: 1.0f], @"gray36",
        [NSColor colorWithRed:  92 / 255.0f green:  92 / 255.0f blue:  92 / 255.0f alpha: 1.0f], @"grey36",
        [NSColor colorWithRed:  94 / 255.0f green:  94 / 255.0f blue:  94 / 255.0f alpha: 1.0f], @"gray37",
        [NSColor colorWithRed:  94 / 255.0f green:  94 / 255.0f blue:  94 / 255.0f alpha: 1.0f], @"grey37",
        [NSColor colorWithRed:  97 / 255.0f green:  97 / 255.0f blue:  97 / 255.0f alpha: 1.0f], @"gray38",
        [NSColor colorWithRed:  97 / 255.0f green:  97 / 255.0f blue:  97 / 255.0f alpha: 1.0f], @"grey38",
        [NSColor colorWithRed:  99 / 255.0f green:  99 / 255.0f blue:  99 / 255.0f alpha: 1.0f], @"gray39",
        [NSColor colorWithRed:  99 / 255.0f green:  99 / 255.0f blue:  99 / 255.0f alpha: 1.0f], @"grey39",
        [NSColor colorWithRed: 102 / 255.0f green: 102 / 255.0f blue: 102 / 255.0f alpha: 1.0f], @"gray40",
        [NSColor colorWithRed: 102 / 255.0f green: 102 / 255.0f blue: 102 / 255.0f alpha: 1.0f], @"grey40",
        [NSColor colorWithRed: 105 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"gray41",
        [NSColor colorWithRed: 105 / 255.0f green: 105 / 255.0f blue: 105 / 255.0f alpha: 1.0f], @"grey41",
        [NSColor colorWithRed: 107 / 255.0f green: 107 / 255.0f blue: 107 / 255.0f alpha: 1.0f], @"gray42",
        [NSColor colorWithRed: 107 / 255.0f green: 107 / 255.0f blue: 107 / 255.0f alpha: 1.0f], @"grey42",
        [NSColor colorWithRed: 110 / 255.0f green: 110 / 255.0f blue: 110 / 255.0f alpha: 1.0f], @"gray43",
        [NSColor colorWithRed: 110 / 255.0f green: 110 / 255.0f blue: 110 / 255.0f alpha: 1.0f], @"grey43",
        [NSColor colorWithRed: 112 / 255.0f green: 112 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"gray44",
        [NSColor colorWithRed: 112 / 255.0f green: 112 / 255.0f blue: 112 / 255.0f alpha: 1.0f], @"grey44",
        [NSColor colorWithRed: 115 / 255.0f green: 115 / 255.0f blue: 115 / 255.0f alpha: 1.0f], @"gray45",
        [NSColor colorWithRed: 115 / 255.0f green: 115 / 255.0f blue: 115 / 255.0f alpha: 1.0f], @"grey45",
        [NSColor colorWithRed: 117 / 255.0f green: 117 / 255.0f blue: 117 / 255.0f alpha: 1.0f], @"gray46",
        [NSColor colorWithRed: 117 / 255.0f green: 117 / 255.0f blue: 117 / 255.0f alpha: 1.0f], @"grey46",
        [NSColor colorWithRed: 120 / 255.0f green: 120 / 255.0f blue: 120 / 255.0f alpha: 1.0f], @"gray47",
        [NSColor colorWithRed: 120 / 255.0f green: 120 / 255.0f blue: 120 / 255.0f alpha: 1.0f], @"grey47",
        [NSColor colorWithRed: 122 / 255.0f green: 122 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"gray48",
        [NSColor colorWithRed: 122 / 255.0f green: 122 / 255.0f blue: 122 / 255.0f alpha: 1.0f], @"grey48",
        [NSColor colorWithRed: 125 / 255.0f green: 125 / 255.0f blue: 125 / 255.0f alpha: 1.0f], @"gray49",
        [NSColor colorWithRed: 125 / 255.0f green: 125 / 255.0f blue: 125 / 255.0f alpha: 1.0f], @"grey49",
        [NSColor colorWithRed: 127 / 255.0f green: 127 / 255.0f blue: 127 / 255.0f alpha: 1.0f], @"gray50",
        [NSColor colorWithRed: 127 / 255.0f green: 127 / 255.0f blue: 127 / 255.0f alpha: 1.0f], @"grey50",
        [NSColor colorWithRed: 130 / 255.0f green: 130 / 255.0f blue: 130 / 255.0f alpha: 1.0f], @"gray51",
        [NSColor colorWithRed: 130 / 255.0f green: 130 / 255.0f blue: 130 / 255.0f alpha: 1.0f], @"grey51",
        [NSColor colorWithRed: 133 / 255.0f green: 133 / 255.0f blue: 133 / 255.0f alpha: 1.0f], @"gray52",
        [NSColor colorWithRed: 133 / 255.0f green: 133 / 255.0f blue: 133 / 255.0f alpha: 1.0f], @"grey52",
        [NSColor colorWithRed: 135 / 255.0f green: 135 / 255.0f blue: 135 / 255.0f alpha: 1.0f], @"gray53",
        [NSColor colorWithRed: 135 / 255.0f green: 135 / 255.0f blue: 135 / 255.0f alpha: 1.0f], @"grey53",
        [NSColor colorWithRed: 138 / 255.0f green: 138 / 255.0f blue: 138 / 255.0f alpha: 1.0f], @"gray54",
        [NSColor colorWithRed: 138 / 255.0f green: 138 / 255.0f blue: 138 / 255.0f alpha: 1.0f], @"grey54",
        [NSColor colorWithRed: 140 / 255.0f green: 140 / 255.0f blue: 140 / 255.0f alpha: 1.0f], @"gray55",
        [NSColor colorWithRed: 140 / 255.0f green: 140 / 255.0f blue: 140 / 255.0f alpha: 1.0f], @"grey55",
        [NSColor colorWithRed: 143 / 255.0f green: 143 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"gray56",
        [NSColor colorWithRed: 143 / 255.0f green: 143 / 255.0f blue: 143 / 255.0f alpha: 1.0f], @"grey56",
        [NSColor colorWithRed: 145 / 255.0f green: 145 / 255.0f blue: 145 / 255.0f alpha: 1.0f], @"gray57",
        [NSColor colorWithRed: 145 / 255.0f green: 145 / 255.0f blue: 145 / 255.0f alpha: 1.0f], @"grey57",
        [NSColor colorWithRed: 148 / 255.0f green: 148 / 255.0f blue: 148 / 255.0f alpha: 1.0f], @"gray58",
        [NSColor colorWithRed: 148 / 255.0f green: 148 / 255.0f blue: 148 / 255.0f alpha: 1.0f], @"grey58",
        [NSColor colorWithRed: 150 / 255.0f green: 150 / 255.0f blue: 150 / 255.0f alpha: 1.0f], @"gray59",
        [NSColor colorWithRed: 150 / 255.0f green: 150 / 255.0f blue: 150 / 255.0f alpha: 1.0f], @"grey59",
        [NSColor colorWithRed: 153 / 255.0f green: 153 / 255.0f blue: 153 / 255.0f alpha: 1.0f], @"gray60",
        [NSColor colorWithRed: 153 / 255.0f green: 153 / 255.0f blue: 153 / 255.0f alpha: 1.0f], @"grey60",
        [NSColor colorWithRed: 156 / 255.0f green: 156 / 255.0f blue: 156 / 255.0f alpha: 1.0f], @"gray61",
        [NSColor colorWithRed: 156 / 255.0f green: 156 / 255.0f blue: 156 / 255.0f alpha: 1.0f], @"grey61",
        [NSColor colorWithRed: 158 / 255.0f green: 158 / 255.0f blue: 158 / 255.0f alpha: 1.0f], @"gray62",
        [NSColor colorWithRed: 158 / 255.0f green: 158 / 255.0f blue: 158 / 255.0f alpha: 1.0f], @"grey62",
        [NSColor colorWithRed: 161 / 255.0f green: 161 / 255.0f blue: 161 / 255.0f alpha: 1.0f], @"gray63",
        [NSColor colorWithRed: 161 / 255.0f green: 161 / 255.0f blue: 161 / 255.0f alpha: 1.0f], @"grey63",
        [NSColor colorWithRed: 163 / 255.0f green: 163 / 255.0f blue: 163 / 255.0f alpha: 1.0f], @"gray64",
        [NSColor colorWithRed: 163 / 255.0f green: 163 / 255.0f blue: 163 / 255.0f alpha: 1.0f], @"grey64",
        [NSColor colorWithRed: 166 / 255.0f green: 166 / 255.0f blue: 166 / 255.0f alpha: 1.0f], @"gray65",
        [NSColor colorWithRed: 166 / 255.0f green: 166 / 255.0f blue: 166 / 255.0f alpha: 1.0f], @"grey65",
        [NSColor colorWithRed: 168 / 255.0f green: 168 / 255.0f blue: 168 / 255.0f alpha: 1.0f], @"gray66",
        [NSColor colorWithRed: 168 / 255.0f green: 168 / 255.0f blue: 168 / 255.0f alpha: 1.0f], @"grey66",
        [NSColor colorWithRed: 171 / 255.0f green: 171 / 255.0f blue: 171 / 255.0f alpha: 1.0f], @"gray67",
        [NSColor colorWithRed: 171 / 255.0f green: 171 / 255.0f blue: 171 / 255.0f alpha: 1.0f], @"grey67",
        [NSColor colorWithRed: 173 / 255.0f green: 173 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"gray68",
        [NSColor colorWithRed: 173 / 255.0f green: 173 / 255.0f blue: 173 / 255.0f alpha: 1.0f], @"grey68",
        [NSColor colorWithRed: 176 / 255.0f green: 176 / 255.0f blue: 176 / 255.0f alpha: 1.0f], @"gray69",
        [NSColor colorWithRed: 176 / 255.0f green: 176 / 255.0f blue: 176 / 255.0f alpha: 1.0f], @"grey69",
        [NSColor colorWithRed: 179 / 255.0f green: 179 / 255.0f blue: 179 / 255.0f alpha: 1.0f], @"gray70",
        [NSColor colorWithRed: 179 / 255.0f green: 179 / 255.0f blue: 179 / 255.0f alpha: 1.0f], @"grey70",
        [NSColor colorWithRed: 181 / 255.0f green: 181 / 255.0f blue: 181 / 255.0f alpha: 1.0f], @"gray71",
        [NSColor colorWithRed: 181 / 255.0f green: 181 / 255.0f blue: 181 / 255.0f alpha: 1.0f], @"grey71",
        [NSColor colorWithRed: 184 / 255.0f green: 184 / 255.0f blue: 184 / 255.0f alpha: 1.0f], @"gray72",
        [NSColor colorWithRed: 184 / 255.0f green: 184 / 255.0f blue: 184 / 255.0f alpha: 1.0f], @"grey72",
        [NSColor colorWithRed: 186 / 255.0f green: 186 / 255.0f blue: 186 / 255.0f alpha: 1.0f], @"gray73",
        [NSColor colorWithRed: 186 / 255.0f green: 186 / 255.0f blue: 186 / 255.0f alpha: 1.0f], @"grey73",
        [NSColor colorWithRed: 189 / 255.0f green: 189 / 255.0f blue: 189 / 255.0f alpha: 1.0f], @"gray74",
        [NSColor colorWithRed: 189 / 255.0f green: 189 / 255.0f blue: 189 / 255.0f alpha: 1.0f], @"grey74",
        [NSColor colorWithRed: 191 / 255.0f green: 191 / 255.0f blue: 191 / 255.0f alpha: 1.0f], @"gray75",
        [NSColor colorWithRed: 191 / 255.0f green: 191 / 255.0f blue: 191 / 255.0f alpha: 1.0f], @"grey75",
        [NSColor colorWithRed: 194 / 255.0f green: 194 / 255.0f blue: 194 / 255.0f alpha: 1.0f], @"gray76",
        [NSColor colorWithRed: 194 / 255.0f green: 194 / 255.0f blue: 194 / 255.0f alpha: 1.0f], @"grey76",
        [NSColor colorWithRed: 196 / 255.0f green: 196 / 255.0f blue: 196 / 255.0f alpha: 1.0f], @"gray77",
        [NSColor colorWithRed: 196 / 255.0f green: 196 / 255.0f blue: 196 / 255.0f alpha: 1.0f], @"grey77",
        [NSColor colorWithRed: 199 / 255.0f green: 199 / 255.0f blue: 199 / 255.0f alpha: 1.0f], @"gray78",
        [NSColor colorWithRed: 199 / 255.0f green: 199 / 255.0f blue: 199 / 255.0f alpha: 1.0f], @"grey78",
        [NSColor colorWithRed: 201 / 255.0f green: 201 / 255.0f blue: 201 / 255.0f alpha: 1.0f], @"gray79",
        [NSColor colorWithRed: 201 / 255.0f green: 201 / 255.0f blue: 201 / 255.0f alpha: 1.0f], @"grey79",
        [NSColor colorWithRed: 204 / 255.0f green: 204 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"gray80",
        [NSColor colorWithRed: 204 / 255.0f green: 204 / 255.0f blue: 204 / 255.0f alpha: 1.0f], @"grey80",
        [NSColor colorWithRed: 207 / 255.0f green: 207 / 255.0f blue: 207 / 255.0f alpha: 1.0f], @"gray81",
        [NSColor colorWithRed: 207 / 255.0f green: 207 / 255.0f blue: 207 / 255.0f alpha: 1.0f], @"grey81",
        [NSColor colorWithRed: 209 / 255.0f green: 209 / 255.0f blue: 209 / 255.0f alpha: 1.0f], @"gray82",
        [NSColor colorWithRed: 209 / 255.0f green: 209 / 255.0f blue: 209 / 255.0f alpha: 1.0f], @"grey82",
        [NSColor colorWithRed: 212 / 255.0f green: 212 / 255.0f blue: 212 / 255.0f alpha: 1.0f], @"gray83",
        [NSColor colorWithRed: 212 / 255.0f green: 212 / 255.0f blue: 212 / 255.0f alpha: 1.0f], @"grey83",
        [NSColor colorWithRed: 214 / 255.0f green: 214 / 255.0f blue: 214 / 255.0f alpha: 1.0f], @"gray84",
        [NSColor colorWithRed: 214 / 255.0f green: 214 / 255.0f blue: 214 / 255.0f alpha: 1.0f], @"grey84",
        [NSColor colorWithRed: 217 / 255.0f green: 217 / 255.0f blue: 217 / 255.0f alpha: 1.0f], @"gray85",
        [NSColor colorWithRed: 217 / 255.0f green: 217 / 255.0f blue: 217 / 255.0f alpha: 1.0f], @"grey85",
        [NSColor colorWithRed: 219 / 255.0f green: 219 / 255.0f blue: 219 / 255.0f alpha: 1.0f], @"gray86",
        [NSColor colorWithRed: 219 / 255.0f green: 219 / 255.0f blue: 219 / 255.0f alpha: 1.0f], @"grey86",
        [NSColor colorWithRed: 222 / 255.0f green: 222 / 255.0f blue: 222 / 255.0f alpha: 1.0f], @"gray87",
        [NSColor colorWithRed: 222 / 255.0f green: 222 / 255.0f blue: 222 / 255.0f alpha: 1.0f], @"grey87",
        [NSColor colorWithRed: 224 / 255.0f green: 224 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"gray88",
        [NSColor colorWithRed: 224 / 255.0f green: 224 / 255.0f blue: 224 / 255.0f alpha: 1.0f], @"grey88",
        [NSColor colorWithRed: 227 / 255.0f green: 227 / 255.0f blue: 227 / 255.0f alpha: 1.0f], @"gray89",
        [NSColor colorWithRed: 227 / 255.0f green: 227 / 255.0f blue: 227 / 255.0f alpha: 1.0f], @"grey89",
        [NSColor colorWithRed: 229 / 255.0f green: 229 / 255.0f blue: 229 / 255.0f alpha: 1.0f], @"gray90",
        [NSColor colorWithRed: 229 / 255.0f green: 229 / 255.0f blue: 229 / 255.0f alpha: 1.0f], @"grey90",
        [NSColor colorWithRed: 232 / 255.0f green: 232 / 255.0f blue: 232 / 255.0f alpha: 1.0f], @"gray91",
        [NSColor colorWithRed: 232 / 255.0f green: 232 / 255.0f blue: 232 / 255.0f alpha: 1.0f], @"grey91",
        [NSColor colorWithRed: 235 / 255.0f green: 235 / 255.0f blue: 235 / 255.0f alpha: 1.0f], @"gray92",
        [NSColor colorWithRed: 235 / 255.0f green: 235 / 255.0f blue: 235 / 255.0f alpha: 1.0f], @"grey92",
        [NSColor colorWithRed: 237 / 255.0f green: 237 / 255.0f blue: 237 / 255.0f alpha: 1.0f], @"gray93",
        [NSColor colorWithRed: 237 / 255.0f green: 237 / 255.0f blue: 237 / 255.0f alpha: 1.0f], @"grey93",
        [NSColor colorWithRed: 240 / 255.0f green: 240 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"gray94",
        [NSColor colorWithRed: 240 / 255.0f green: 240 / 255.0f blue: 240 / 255.0f alpha: 1.0f], @"grey94",
        [NSColor colorWithRed: 242 / 255.0f green: 242 / 255.0f blue: 242 / 255.0f alpha: 1.0f], @"gray95",
        [NSColor colorWithRed: 242 / 255.0f green: 242 / 255.0f blue: 242 / 255.0f alpha: 1.0f], @"grey95",
        [NSColor colorWithRed: 245 / 255.0f green: 245 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"gray96",
        [NSColor colorWithRed: 245 / 255.0f green: 245 / 255.0f blue: 245 / 255.0f alpha: 1.0f], @"grey96",
        [NSColor colorWithRed: 247 / 255.0f green: 247 / 255.0f blue: 247 / 255.0f alpha: 1.0f], @"gray97",
        [NSColor colorWithRed: 247 / 255.0f green: 247 / 255.0f blue: 247 / 255.0f alpha: 1.0f], @"grey97",
        [NSColor colorWithRed: 250 / 255.0f green: 250 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"gray98",
        [NSColor colorWithRed: 250 / 255.0f green: 250 / 255.0f blue: 250 / 255.0f alpha: 1.0f], @"grey98",
        [NSColor colorWithRed: 252 / 255.0f green: 252 / 255.0f blue: 252 / 255.0f alpha: 1.0f], @"gray99",
        [NSColor colorWithRed: 252 / 255.0f green: 252 / 255.0f blue: 252 / 255.0f alpha: 1.0f], @"grey99",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"gray100",
        [NSColor colorWithRed: 255 / 255.0f green: 255 / 255.0f blue: 255 / 255.0f alpha: 1.0f], @"grey100",
        [NSColor colorWithRed: 169 / 255.0f green: 169 / 255.0f blue: 169 / 255.0f alpha: 1.0f], @"dark grey",
        [NSColor colorWithRed: 169 / 255.0f green: 169 / 255.0f blue: 169 / 255.0f alpha: 1.0f], @"darkgrey",
        [NSColor colorWithRed: 169 / 255.0f green: 169 / 255.0f blue: 169 / 255.0f alpha: 1.0f], @"dark gray",
        [NSColor colorWithRed: 169 / 255.0f green: 169 / 255.0f blue: 169 / 255.0f alpha: 1.0f], @"darkgray",
        [NSColor colorWithRed: 0   / 255.0f green:   0 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"dark blue",
        [NSColor colorWithRed: 0   / 255.0f green:   0 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"darkblue",
        [NSColor colorWithRed: 0   / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"dark cyan",
        [NSColor colorWithRed: 0   / 255.0f green: 139 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"darkcyan",
        [NSColor colorWithRed: 139 / 255.0f green:   0 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"dark magenta",
        [NSColor colorWithRed: 139 / 255.0f green:   0 / 255.0f blue: 139 / 255.0f alpha: 1.0f], @"darkmagenta",
        [NSColor colorWithRed: 139 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"dark red",
        [NSColor colorWithRed: 139 / 255.0f green:   0 / 255.0f blue:   0 / 255.0f alpha: 1.0f], @"darkred",
        [NSColor colorWithRed: 144 / 255.0f green: 238 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"light green",
        [NSColor colorWithRed: 144 / 255.0f green: 238 / 255.0f blue: 144 / 255.0f alpha: 1.0f], @"lightgreen",
        nil];
    return colorNameMap;
}


@implementation NSObject (MTShell)

- (NSValue*) MouseTerm_initVars
{
    NSValue* ptr = [NSValue valueWithPointer: self];
    if ([MouseTerm_ivars objectForKey: ptr] == nil)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [MouseTerm_ivars setObject: dict forKey: ptr];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"focusMode"];
        [dict setObject: [NSNumber numberWithInt: NO_MODE]
                 forKey: @"mouseMode"];
        [dict setObject: [NSNumber numberWithInt: NORMAL_PROTOCOL]
                 forKey: @"mouseProtocol"];
        [dict setObject: [NSNumber numberWithInt: NO]
                 forKey: @"emojiFix"];
        [dict setObject: [NSNumber numberWithBool: NO]
                 forKey: @"appCursorMode"];
        [dict setObject: [NSNumber numberWithInt: 0]
                 forKey: @"mouseState"];
        [dict setObject: [NSMutableDictionary dictionary]
                 forKey: @"colorPalette"];
        [dict setObject: [[[NSMutableData alloc] initWithLength:sizeof(struct parse_context)] autorelease]
                 forKey: @"parseContext"];
        [dict setObject: generateX11ColorNameMap()
                 forKey: @"colorNameMap"];
        [dict setObject: generateTcapMap()
                 forKey: @"tcapMap"];
        [dict setObject: [[[NSMutableArray alloc] init] autorelease]
                 forKey: @"windowTitleStack"];
        [dict setObject: [[[NSMutableArray alloc] init] autorelease]
                 forKey: @"tabTitleStack"];
    }
    return ptr;
}

- (void) MouseTerm_setFocusMode: (BOOL) focusMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithBool: focusMode] forKey: @"focusMode"];
}

- (BOOL) MouseTerm_getFocusMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"focusMode"] boolValue];
}

- (void) MouseTerm_setMouseMode: (int) mouseMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt: mouseMode] forKey: @"mouseMode"];
    [self MouseTerm_cachePosition: nil];
}

- (int) MouseTerm_getMouseMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"mouseMode"] intValue];
}

- (void) MouseTerm_setMouseProtocol: (int) mouseProtocol
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt: mouseProtocol]
           forKey: @"mouseProtocol"];
    [self MouseTerm_cachePosition: nil];
}

- (int) MouseTerm_getMouseProtocol
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"mouseProtocol"] intValue];
}

- (void) MouseTerm_setCoordinateType: (int) coordinateType
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt: coordinateType] forKey: @"coordinateType"];
}

- (int) MouseTerm_getCoordinateType
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"coordinateType"] intValue];
}

- (void) MouseTerm_setEventFilter: (int) eventFilter
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt: eventFilter] forKey: @"eventFilter"];
}

- (int) MouseTerm_getEventFilter
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"eventFilter"] intValue];
}

- (void) MouseTerm_setAppCursorMode: (BOOL) appCursorMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithBool: appCursorMode]
           forKey: @"appCursorMode"];
}

- (BOOL) MouseTerm_getAppCursorMode
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"appCursorMode"] boolValue];
}

- (void) MouseTerm_pushWindowTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"windowTitleStack"];
    TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
    NSString *title = [screen windowTitle];
    if (title == nil)
        title = @"";
    [stack addObject: title];
}

- (void) MouseTerm_popWindowTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"windowTitleStack"];
    NSUInteger count = [stack count];
    if (count > 0) {
        TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
        if (screen != nil) {
            NSString *title = [stack objectAtIndex: count - 1];
            if (title != nil)
                [screen setWindowTitle:title];
            [stack removeObjectAtIndex: count - 1];
        }
    }
}

- (void) MouseTerm_pushTabTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"tabTitleStack"];
    TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
    NSString *title = [screen tabTitle];
    if (title == nil)
        title = @"";
    [stack addObject: title];
}

- (void) MouseTerm_popTabTitle
{
    NSValue *ptr = [self MouseTerm_initVars];
    NSMutableArray *stack = (NSMutableArray *)[[MouseTerm_ivars objectForKey: ptr]
                                                                objectForKey: @"tabTitleStack"];
    NSUInteger count = [stack count];
    if (count > 0) {
        TTLogicalScreen *screen = [[(TTShell *)self controller] logicalScreen];
        if (screen != nil) {
            NSString *title = [stack objectAtIndex: count - 1];
            if (title != nil)
                [screen setTabTitle:title];
            [stack removeObjectAtIndex: count - 1];
        }
    }
}

- (void) MouseTerm_setMouseState: (int) state
{
    NSValue *ptr = [self MouseTerm_initVars];
    [[MouseTerm_ivars objectForKey: ptr]
        setObject: [NSNumber numberWithInt:state]
           forKey: @"mouseState"];
}

- (int) MouseTerm_getMouseState
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [(NSNumber*) [[MouseTerm_ivars objectForKey: ptr]
                            objectForKey: @"mouseState"] intValue];
}

- (BOOL) MouseTerm_writeToPasteBoard: (NSString*) stringToWrite
{
    return [[NSPasteboard generalPasteboard] setString:stringToWrite
                                               forType:NSStringPboardType];
}

- (NSString*) MouseTerm_readFromPasteBoard
{
    return [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
}

- (void) MouseTerm_osc52SetAccess: (NSString*) stringToWrite
{
    char *encodedBuffer = (char*)[stringToWrite cStringUsingEncoding:NSASCIIStringEncoding];
    int destLength = apr_base64_decode_len(encodedBuffer);
    char *decodedBuffer = malloc(destLength);
    apr_base64_decode(decodedBuffer, encodedBuffer);
    NSString *resultString = [NSString stringWithUTF8String:decodedBuffer];
    if (!resultString) {
        TTTabController *controller = [(TTShell *)self controller];
        TTOutputDecoder *decoder = [controller encodingConverter];
        NSData *data = [decoder decodeData:[NSData dataWithBytes:decodedBuffer
                                                          length:destLength]];
        resultString = [[[NSString alloc] initWithData: data
                                              encoding: NSUTF8StringEncoding] autorelease];
    }
    free(decodedBuffer);

    [[[[(TTShell*)self controller] activePane] view] copy: nil];
    [self MouseTerm_writeToPasteBoard: resultString];
}

- (void) MouseTerm_osc52GetAccess
{
    // ref: http://blog.livedoor.jp/jgoamakf/archives/51160286.html
    NSString *str = [self MouseTerm_readFromPasteBoard];
    char *sourceCString = (char*)[str UTF8String];
    const char prefix[] = "\033]52;c;"; // OSC52 from Clipboard
    const char postfix[] = "\033\\"; // ST
    size_t prefix_len = sizeof(prefix) - 1;
    size_t postfix_len = sizeof(postfix) - 1;

    int sourceLength = strlen(sourceCString);
    int resultLength = apr_base64_encode_len(sourceLength);
    int allLength = prefix_len + resultLength + postfix_len;
    char *encodedBuffer = (char*)malloc(allLength);
    char *it = encodedBuffer;

    memcpy(it, prefix, prefix_len);
    it += prefix_len;
    apr_base64_encode(it, sourceCString, sourceLength);
    it += resultLength;
    memcpy(it, postfix, postfix_len);

    [(TTShell*)self writeData: [NSData dataWithBytes: encodedBuffer
                                              length: allLength]];
}

- (void) MouseTerm_tcapQuery: (NSString*) query
{
    NSString *answer;
    NSValue *ptr = [self MouseTerm_initVars];
    NSString *cap = [[[MouseTerm_ivars objectForKey: ptr] objectForKey:@"tcapMap"] objectForKey:query];

    if (cap) {
        answer = [NSString stringWithFormat:@"\033P1+r%@=%@\033\\", query, cap];
    } else {
        answer = @"\033P0+r\033\\";
    }
    [(TTShell*)self writeData: [answer dataUsingEncoding:NSASCIIStringEncoding]];
}

- (NSMutableDictionary*) MouseTerm_getPalette
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [[MouseTerm_ivars objectForKey: ptr] objectForKey:@"colorPalette"];
}

- (NSMutableDictionary*) MouseTerm_getColorNameMap
{
    NSValue *ptr = [self MouseTerm_initVars];
    return [[MouseTerm_ivars objectForKey: ptr] objectForKey:@"colorNameMap"];
}

- (struct parse_context*) MouseTerm_getParseContext
{
    NSValue *ptr = [self MouseTerm_initVars];
    return (struct parse_context*)[[[MouseTerm_ivars objectForKey: ptr] objectForKey:@"parseContext"] bytes];
}

- (void) MouseTerm_writeData: (NSData*) data
{
    [self MouseTerm_writeData: data];
}

- (void) MouseTerm_cachePosition: (Position*) pos
{
    NSValue *ptr = [self MouseTerm_initVars];
    if (pos) {
        [[MouseTerm_ivars objectForKey: ptr]
            setObject: [NSValue valueWithBytes: pos objCType: @encode(Position)]
               forKey: @"positionCache"];
    } else {
        [[MouseTerm_ivars objectForKey: ptr] removeObjectForKey: @"positionCache"];
    }
}

- (BOOL) MouseTerm_positionIsChanged: (Position*) pos;
{
    Position cache;
    NSValue *ptr = [self MouseTerm_initVars];
    NSValue *value = [[MouseTerm_ivars objectForKey: ptr] objectForKey: @"positionCache"];
    if (!value)
        return YES;
    [value getValue: &cache];
    return cache.x != pos->x || cache.y != pos->y;
}

// Deletes instance variables
- (void) MouseTerm_dealloc
{
    struct parse_context *context = [self MouseTerm_getParseContext];
    [context->buffer release];
    [MouseTerm_ivars removeObjectForKey: [NSValue valueWithPointer: self]];
    [self MouseTerm_dealloc];
}

@end
