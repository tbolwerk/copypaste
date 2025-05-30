#ifndef KEYMAP_H
#define KEYMAP_H

enum {
    KEY_UNKNOWN = -1,
    KEY_C = 'C',
    KEY_V = 'V',
    KEY_1 = '1',
    KEY_2 = '2',
    KEY_3 = '3',
    KEY_4 = '4',
    KEY_5 = '5',
    KEY_6 = '6',
    KEY_7 = '7',
    KEY_8 = '8',
    KEY_9 = '9',
};

int get_virtual_key(int platform_keycode);

#endif