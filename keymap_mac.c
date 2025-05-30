#include "keymap.h"
#include <Carbon/Carbon.h>

int get_virtual_key(int platform_keycode) {
    switch(platform_keycode) {
        case kVK_ANSI_C: return KEY_C;
        case kVK_ANSI_V: return KEY_V;
        case kVK_ANSI_1: return KEY_1;
        case kVK_ANSI_2: return KEY_2;
        case kVK_ANSI_3: return KEY_3;
        case kVK_ANSI_4: return KEY_4;
        case kVK_ANSI_5: return KEY_5;
        case kVK_ANSI_6: return KEY_6;
        case kVK_ANSI_7: return KEY_7;
        case kVK_ANSI_8: return KEY_8;
        case kVK_ANSI_9: return KEY_9;
        default: return KEY_UNKNOWN;
    }
}