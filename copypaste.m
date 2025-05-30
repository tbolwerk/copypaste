#include "copypaste.h"
#import <Cocoa/Cocoa.h>
#include "keymap_mac.c"
#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
CGEventRef CGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
int eventTap();
  
int main(int argc, const char * argv[]) 
{
    @autoreleasepool {
       eventTap();
    }
    return 0;
}

CGEventRef CGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    CGEventRef returnEvent = isInFront ? NULL : event; // Prevent input in background when App is foreground.

    if (type != kCGEventKeyDown && type != kCGEventFlagsChanged) {
        return returnEvent;
    }

    CGEventFlags flags = CGEventGetFlags(event);
    // Retrieve the incoming keycode.
    CGKeyCode keyCode = (CGKeyCode) CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    bool shift = flags & kCGEventFlagMaskShift;
    bool caps = flags & kCGEventFlagMaskAlphaShift;
    bool cmd = flags & kCGEventFlagMaskCommand;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        handle_key_event(cmd, shift, get_virtual_key(keyCode));
    });
    return returnEvent;
}

int eventTap()
{
	CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged);
	CFMachPortRef eventTap = CGEventTapCreate(0, 1, 0, eventMask, CGEventCallback, NULL);
	if(!eventTap)
	{
		printf("ERROR: Unable to create event tap.\n");
		return 1;
	}
	// Create a run loop source and add enable the event tap.
	CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
	CGEventTapEnable(eventTap, true);
	CFRunLoopRun();
	return 0;
}

