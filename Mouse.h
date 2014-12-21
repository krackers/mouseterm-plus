// Possible mouse modes
typedef enum
{
    NO_MODE = 0,
    NORMAL_MODE,
    HILITE_MODE,
    BUTTON_MODE,
    ALL_MODE
} MouseMode;

typedef enum
{
    NORMAL_PROTOCOL = 0,
    URXVT_PROTOCOL,
    SGR_PROTOCOL
} MouseProtocol;

// Control codes

#define SDA_RESPONSE "\033[>32;277;2c"
#define SDA_RESPONSE_LEN (sizeof(SDA_RESPONSE) - 1)

// Normal control codes
#define UP_ARROW "\033[A"
#define DOWN_ARROW "\033[B"
// Control codes for application keypad mode
#define UP_ARROW_APP "\033OA"
#define DOWN_ARROW_APP "\033OB"
#define ARROW_LEN (sizeof(UP_ARROW) - 1)

// X11 mouse button values
typedef enum
{
    MOUSE_BUTTON1 = 0,
    MOUSE_BUTTON3 = 1,
    MOUSE_BUTTON2 = 2,
    MOUSE_RELEASE = 3,
    MOUSE_WHEEL_UP = 64,
    MOUSE_WHEEL_DOWN = 65
} MouseButton;

// X11 mouse reporting responses
#define MOUSE_RESPONSE "\033[M%c%c%c"
#define MOUSE_RESPONSE_LEN 6
