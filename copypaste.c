#include "copypaste.h"
#include "keymap.h"
#include <X11/Xlib.h>
#include <X11/extensions/XInput2.h>
#include <X11/XKBlib.h>  // For XkbKeycodeToKeysym
#include <X11/keysym.h>

int get_virtual_key(int platform_keycode) {
    switch(platform_keycode) {
        case 99: return KEY_C;
        case 118: return KEY_V;
        case 49: return KEY_1;
        case 50: return KEY_2;
        case 51: return KEY_3;
        case 52: return KEY_4;
        case 53: return KEY_5;
        case 54: return KEY_6;
        case 55: return KEY_7;
        case 56: return KEY_8;
        case 57: return KEY_9;
        default: return -1;
    }
}

int main(int argc, const char* argv[]) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "Failed to open display\n");
        return 1;
    }

    int xi_major = 2, xi_minor = 0;
    if (XIQueryVersion(dpy, &xi_major, &xi_minor) != Success) {
        fprintf(stderr, "XInput2 not available\n");
        return 1;
    }

    // Get XInput extension opcode
    int xi_opcode, event, error;
    if (!XQueryExtension(dpy, "XInputExtension", &xi_opcode, &event, &error)) {
        fprintf(stderr, "X Input extension not available.\n");
        return 1;
    }

    Window root = DefaultRootWindow(dpy);

    XIEventMask eventmask;
    unsigned char mask[(XI_LASTEVENT + 7)/8] = {0};

    eventmask.deviceid = XIAllMasterDevices;
    eventmask.mask_len = sizeof(mask);
    eventmask.mask = mask;

    XISetMask(mask, XI_RawKeyPress);

    if (XISelectEvents(dpy, root, &eventmask, 1) != Success) {
        fprintf(stderr, "Failed to select XI2 events\n");
        return 1;
    }

    XSync(dpy, False);

    printf("Listening for Shift+Control + [c,v,1-9] using XInput2 raw events...\n");

    while (1) {
        XEvent ev;
        XGenericEventCookie *cookie = &ev.xcookie;

        XNextEvent(dpy, &ev);

        if (XGetEventData(dpy, cookie)) {
            if (cookie->type == GenericEvent &&
                cookie->extension == xi_opcode &&
                cookie->evtype == XI_RawKeyPress) {
                XIRawEvent *raw_ev = (XIRawEvent*)cookie->data;

                // X11 hardware keycode is offset by 8 for Xkb
                KeySym keysym = XkbKeycodeToKeysym(dpy, raw_ev->detail, 0, 0);

                // The modifier masks are in raw_ev->mods.effective_mask
                // But XIRawEvent *does not* have mods. Instead, use XIQueryPointer or track via XGetKeyboardState.

                // As a workaround: use XQueryKeymap to get modifier state:

                char keys_return[32];
                XQueryKeymap(dpy, keys_return);

                // Check ControlMask
                // Control keycodes may vary, but common:
                // Left Control is usually keycode 37, Right Control 105
                // Shift is usually 50 and 62

                // Let's just check if keycode for Control and Shift keys are pressed:

                // keycodes
                int ctrl1 = XKeysymToKeycode(dpy, XK_Control_L);
                int ctrl2 = XKeysymToKeycode(dpy, XK_Control_R);
                int shift1 = XKeysymToKeycode(dpy, XK_Shift_L);
                int shift2 = XKeysymToKeycode(dpy, XK_Shift_R);

                bool control_pressed = (keys_return[ctrl1/8] & (1 << (ctrl1 % 8))) != 0 ||
                                       (keys_return[ctrl2/8] & (1 << (ctrl2 % 8))) != 0;
                bool shift_pressed = (keys_return[shift1/8] & (1 << (shift1 % 8))) != 0 ||
                                     (keys_return[shift2/8] & (1 << (shift2 % 8))) != 0;

                int vk = get_virtual_key(keysym);
                handle_key_event(control_pressed, shift_pressed, vk);
            }
            XFreeEventData(dpy, cookie);
        }
    }

    XCloseDisplay(dpy);
    return 0;
}
