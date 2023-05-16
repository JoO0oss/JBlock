if false
    # Actually running this extends the startup-time by quite a bit, so this line is just here
    # for code completion.
    using SimpleDirectMediaLayer.LibSDL2
end

# I'm not gonna lie, this is 164 lines of GitHub Copilot (I did KEYS_A myself!).

""" A "key" has the keycode, a human-programmer-friendly name and a flag noting whether it's a modifier key (eg shift, control). """
struct Keys
    code::Int
    name::String
    is_mod::Bool
end

struct KeysUnion
    keys::Vector{Keys}
end

KEYS_A = Keys(5, "a", false)
KEYS_B = Keys(6, "b", false)
KEYS_C = Keys(7, "c", false)
KEYS_D = Keys(8, "d", false)
KEYS_E = Keys(9, "e", false)
KEYS_F = Keys(10, "f", false)
KEYS_G = Keys(11, "g", false)
KEYS_H = Keys(12, "h", false)
KEYS_I = Keys(13, "i", false)
KEYS_J = Keys(14, "j", false)
KEYS_K = Keys(15, "k", false)
KEYS_L = Keys(16, "l", false)
KEYS_M = Keys(17, "m", false)
KEYS_N = Keys(18, "n", false)
KEYS_O = Keys(19, "o", false)
KEYS_P = Keys(20, "p", false)
KEYS_Q = Keys(21, "q", false)
KEYS_R = Keys(22, "r", false)
KEYS_S = Keys(23, "s", false)
KEYS_T = Keys(24, "t", false)
KEYS_U = Keys(25, "u", false)
KEYS_V = Keys(26, "v", false)
KEYS_W = Keys(27, "w", false)
KEYS_X = Keys(28, "x", false)
KEYS_Y = Keys(29, "y", false)
KEYS_Z = Keys(30, "z", false)
KEYS_1 = Keys(31, "1", false)
KEYS_2 = Keys(32, "2", false)
KEYS_3 = Keys(33, "3", false)
KEYS_4 = Keys(34, "4", false)
KEYS_5 = Keys(35, "5", false)
KEYS_6 = Keys(36, "6", false)
KEYS_7 = Keys(37, "7", false)
KEYS_8 = Keys(38, "8", false)
KEYS_9 = Keys(39, "9", false)
KEYS_0 = Keys(40, "0", false)

KEYS_RETURN = Keys(41, "enter", false)
KEYS_ESCAPE = Keys(42, "escape", false)
KEYS_BACKSPACE = Keys(43, "backspace", false)
KEYS_TAB = Keys(44, "tab", false)
KEYS_SPACE = Keys(45, "space", false)
KEYS_MINUS = Keys(46, "-", false)
KEYS_EQUALS = Keys(47, "=", false)
KEYS_LEFTBRACKET = Keys(48, "[", false)
KEYS_RIGHTBRACKET = Keys(49, "]", false)
KEYS_US_BACKSLASH = Keys(50, "\\", false)  # US backslash.
KEYS_HASH = Keys(51, "#", false)  # Might not work on US keyboards?
KEYS_SEMICOLON = Keys(52, ";", false)
KEYS_APOSTROPHE = Keys(53, "'", false)
KEYS_GRAVE = Keys(54, "`", false)
KEYS_COMMA = Keys(55, ",", false)
KEYS_PERIOD = Keys(56, ".", false)
KEYS_SLASH = Keys(57, "/", false)
KEYS_CAPSLOCK_MAIN = Keys(58, "capslock", false)  # This has an equivalent keymods entry.
KEYS_F1 = Keys(59, "f1", false)
KEYS_F2 = Keys(60, "f2", false)
KEYS_F3 = Keys(61, "f3", false)
KEYS_F4 = Keys(62, "f4", false)
KEYS_F5 = Keys(63, "f5", false)
KEYS_F6 = Keys(64, "f6", false)
KEYS_F7 = Keys(65, "f7", false)
KEYS_F8 = Keys(66, "f8", false)
KEYS_F9 = Keys(67, "f9", false)
KEYS_F10 = Keys(68, "f10", false)
KEYS_F11 = Keys(69, "f11", false)
KEYS_F12 = Keys(70, "f12", false)

# My keyboard doesn't work with/have most of these, so I can't test them.
KEYS_PRINTSCREEN = Keys(71, "printscreen", false)  # Might need a windows machine to test this one.
KEYS_SCROLLLOCK_MAIN = Keys(72, "scrolllock", false)  # This has an equivalent keymods entry.
KEYS_PAUSE = Keys(73, "pause", false)
KEYS_INSERT = Keys(74, "insert", false)  # ✓
KEYS_HOME = Keys(75, "home", false)  # ✓
KEYS_PAGEUP = Keys(76, "pageup", false)  # ✓
KEYS_DELETE = Keys(77, "delete", false)  # ✓
KEYS_END = Keys(78, "end", false)  # ✓
KEYS_PAGEDOWN = Keys(79, "pagedown", false)  # ✓
KEYS_RIGHT = Keys(80, "right", false)  # ✓
KEYS_LEFT = Keys(81, "left", false)  # ✓
KEYS_DOWN = Keys(82, "down", false)  # ✓
KEYS_UP = Keys(83, "up", false)  # ✓
KEYS_NUM_LOCK = Keys(84, "numlock", false)
KEYS_KP_DIVIDE = Keys(85, "kp_divide", false)
KEYS_KP_MULTIPLY = Keys(86, "kp_multiply", false)
KEYS_KP_MINUS = Keys(87, "kp_minus", false)
KEYS_KP_PLUS = Keys(88, "kp_plus", false)
KEYS_KP_ENTER = Keys(89, "kp_enter", false)
KEYS_KP_1 = Keys(90, "kp_1", false)
KEYS_KP_2 = Keys(91, "kp_2", false)
KEYS_KP_3 = Keys(92, "kp_3", false)
KEYS_KP_4 = Keys(93, "kp_4", false)
KEYS_KP_5 = Keys(94, "kp_5", false)
KEYS_KP_6 = Keys(95, "kp_6", false)
KEYS_KP_7 = Keys(96, "kp_7", false)
KEYS_KP_8 = Keys(97, "kp_8", false)
KEYS_KP_9 = Keys(98, "kp_9", false)
KEYS_KP_0 = Keys(99, "kp_0", false)
KEYS_KP_PERIOD = Keys(100, "kp_period", false)
KEYS_NON_US_BACKSLASH = Keys(101, "\\", false)  # ✓ Also might not work on US keyboards.
KEYS_APPLICATION = Keys(102, "application", false)
KEYS_POWER = Keys(103, "power", false)
KEYS_KP_EQUALS = Keys(104, "kp_equals", false)
KEYS_F13 = Keys(105, "f13", false)
KEYS_F14 = Keys(106, "f14", false)
KEYS_F15 = Keys(107, "f15", false)
KEYS_F16 = Keys(108, "f16", false)
KEYS_F17 = Keys(109, "f17", false)
KEYS_F18 = Keys(110, "f18", false)
KEYS_F19 = Keys(111, "f19", false)
KEYS_F20 = Keys(112, "f20", false)
KEYS_F21 = Keys(113, "f21", false)
KEYS_F22 = Keys(114, "f22", false)
KEYS_F23 = Keys(115, "f23", false)
KEYS_F24 = Keys(116, "f24", false)
KEYS_EXECUTE = Keys(117, "execute", false)
KEYS_HELP = Keys(118, "help", false)
KEYS_MENU = Keys(119, "menu", false)
KEYS_SELECT = Keys(120, "select", false)
KEYS_STOP = Keys(121, "stop", false)
KEYS_AGAIN = Keys(122, "again", false)
KEYS_UNDO = Keys(123, "undo", false)
KEYS_CUT = Keys(124, "cut", false)
KEYS_COPY = Keys(125, "copy", false)
KEYS_PASTE = Keys(126, "paste", false)
KEYS_FIND = Keys(127, "find", false)
KEYS_MUTE = Keys(128, "mute", false)  # ✓
KEYS_VOLUMEUP = Keys(129, "volumeup", false)  # ✓
KEYS_VOLUMEDOWN = Keys(130, "volumedown", false)  # ✓

KEYS_LSHIFT = Keys(KMOD_LSHIFT, "lshift", true)
KEYS_RSHIFT = Keys(KMOD_RSHIFT, "rshift", true)
KEYS_LCTRL = Keys(KMOD_LCTRL, "lctrl", true)
KEYS_RCTRL = Keys(KMOD_RCTRL, "rctrl", true)
KEYS_LALT = Keys(KMOD_LALT, "lalt", true)
KEYS_RALT = Keys(KMOD_RALT, "ralt", true)
KEYS_LWINDOWS = Keys(KMOD_LGUI, "lwindows", true)  # Sorry Linux users, I know this is really the super key.
KEYS_RWINDOWS = Keys(KMOD_RGUI, "rwindows", true)
KEYS_NUMLOCK = Keys(KMOD_NUM, "numlock", true)
KEYS_CAPSLOCK_MOD = Keys(KMOD_CAPS, "capslock", true)  # This has an equivalent main entry.
KEYS_ALTGR = Keys(KMOD_MODE, "altgr", true)
KEYS_SCROLLLOCK_MOD = Keys(KMOD_MODE, "scrolllock", true)  # This has an equivalent main entry.

# Key unions:
KEYS_BACKSLASH = KeysUnion([KEYS_NON_US_BACKSLASH, KEYS_US_BACKSLASH])

KEYS_SHIFT = Keys(KMOD_SHIFT, "shift", true)
KEYS_CTRL = Keys(KMOD_CTRL, "ctrl", true)
KEYS_ALT = Keys(KMOD_ALT, "alt", true)
KEYS_WINDOWS = Keys(KMOD_GUI, "windows", true)

KEYS_SCROLLLOCK = KeysUnion([KEYS_SCROLLLOCK_MAIN, KEYS_SCROLLLOCK_MOD])
KEYS_CAPSLOCK = KeysUnion([KEYS_CAPSLOCK_MAIN, KEYS_CAPSLOCK_MOD])

# Note: ✓ means that the key has been tested.