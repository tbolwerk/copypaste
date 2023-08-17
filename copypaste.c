#include "copypaste.h"

int main(void)
{
	return eventTap();
}

int eventTap(void)
{
	CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged);
	CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, CGEventCallback, NULL);
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
	return update();
}

CGEventRef CGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type != kCGEventKeyDown && type != kCGEventFlagsChanged) {
        return event;
    }

    CGEventFlags flags = CGEventGetFlags(event);

    // Retrieve the incoming keycode.
    CGKeyCode keyCode = (CGKeyCode) CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
	

    // Calculate key up/down.
    bool down = false;
    if (type == kCGEventFlagsChanged) {
        switch (keyCode) {
        case 54: // [right-cmd]
        case 55: // [left-cmd]
            down = (flags & kCGEventFlagMaskCommand) && !(lastFlags & kCGEventFlagMaskCommand);
            break;
        case 56: // [left-shift]
        case 60: // [right-shift]
            down = (flags & kCGEventFlagMaskShift) && !(lastFlags & kCGEventFlagMaskShift);
            break;
        case 58: // [left-option]
        case 61: // [right-option]
            down = (flags & kCGEventFlagMaskAlternate) && !(lastFlags & kCGEventFlagMaskAlternate);
            break;
        case 59: // [left-ctrl]
        case 62: // [right-ctrl]
            down = (flags & kCGEventFlagMaskControl) && !(lastFlags & kCGEventFlagMaskControl);
            break;
        case 57: // [caps]
            down = (flags & kCGEventFlagMaskAlphaShift) && !(lastFlags & kCGEventFlagMaskAlphaShift);
            break;
        default:
            break;
        }
    } else if (type == kCGEventKeyDown) {
        down = true;
    }
    lastFlags = flags;
	
    // Only log key down events.
    if (!down) {
        return event;
    }

    bool shift = flags & kCGEventFlagMaskShift;
    bool caps = flags & kCGEventFlagMaskAlphaShift;
	bool cmd = (prev == 55 || prev == 54);
	if(cmd && keyCode == kVK_ANSI_C){ // CMD + C
		printf("Copy to clipboard\n");
		update();
	}
	if(cmd && shift && keyCode == kVK_ANSI_V){ // CMD + shift + V
		printf("open menu for selecting copied content");
	}
	prev = keyCode;
	
    return event;
}

int update(void)
{
	FILE *pb = popen("/usr/bin/pbpaste", "r");

	char paste[MAX_SIZE] = {};
	if(pb == NULL){
		printf("Failed to run pbpaste");
		exit(1);
	}

	while(fgets(paste, sizeof(paste), pb) != NULL) {
		char filename[40] = {};
		struct tm *timenow = {0};

		time_t now = time(NULL);
		timenow = gmtime(&now);

		strftime(filename, sizeof(filename), "copy_%Y-%m-%d_%H:%M:%S.txt", timenow);

		FILE *history = fopen(filename, "a+");
		fputs(paste, history);
		fputs("\n", history);
		fclose(history);
	}

	pclose(pb);
	return 0;
}
