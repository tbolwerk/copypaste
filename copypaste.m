#include "copypaste.h"
#define STACK_IMPL
#include "stack.h"
#define DYNAMIC_STRING_IMPL
#include "dynamic_string.h"
#import <Cocoa/Cocoa.h>
#define CORE_IMPL
#include "core.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSTextField *textField;
@end

AppDelegate *globalDelegate = nil;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                               styleMask:(NSWindowStyleMaskTitled |
                                                          NSWindowStyleMaskClosable |
                                                          NSWindowStyleMaskResizable)
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    [self.window setTitle:@"Text Display"];
    [self.window makeKeyAndOrderFront:nil];

    self.textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, 760, 560)];
    [self.textField setBezeled:NO];
    [self.textField setDrawsBackground:NO];
    [self.textField setEditable:NO];
    [self.textField setSelectable:YES];
    [[self.window contentView] addSubview:self.textField];
    globalDelegate = self;
}

- (void)setTextFieldContent:(const char *)content {
    NSString *string = [NSString stringWithUTF8String:content];
    [self.textField setStringValue:string];
}
bool isInFront = false;
@end
void BringToFrontFromC() {
 dispatch_async(dispatch_get_main_queue(), ^{
        if ([globalDelegate.window level] == NSFloatingWindowLevel) {
        // If the window is currently the key window, minimize it
            isInFront = false;
            [globalDelegate.window setLevel:NSNormalWindowLevel];
        } else {
            // If the window is not the key window, bring it to the front
            isInFront = true;
            [globalDelegate.window makeKeyAndOrderFront:nil];
            [globalDelegate.window setLevel:NSFloatingWindowLevel];
        }
    });
}
void UpdateTextFromC(const char *newText) {
    dispatch_async(dispatch_get_main_queue(), ^{
    [globalDelegate setTextFieldContent:newText];
});
}
char* content ;
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            eventTap();
        });
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app run];
    }
    free(content);
    return 0;
}

int prev = -1;
CGEventFlags lastFlags = 0;

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

CGEventRef CGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    CGEventRef returnEvent = isInFront ? NULL : event; // Prevent input in background when App is foreground.

    if (type != kCGEventKeyDown && type != kCGEventFlagsChanged) {
        return returnEvent;
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
        default:
            break;
        }
    } else if (type == kCGEventKeyDown) {
        down = true;
    }
    lastFlags = flags;
	
    // Only log key down events.
    if (!down) {
        return returnEvent;
    }

    bool shift = flags & kCGEventFlagMaskShift;
    bool caps = flags & kCGEventFlagMaskAlphaShift;
    bool cmd = (prev == 55 || prev == 54);
    if(cmd && keyCode == kVK_ANSI_C){ // CMD + Cif (cmd && keyCode == kVK_ANSI_C) {
        printf("Copy to clipboard\n");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            copyToDisk();
        });
    }
    

    Stack stack;
    initialize(&stack);
    update_clipboard_entries(&stack);

    if(cmd && shift && keyCode == kVK_ANSI_V){ // CMD + shift + V
 	    printf("open menu for selecting copied content");
        BringToFrontFromC();
    }
    if(cmd && down && isInFront){
        int index = get_index(keyCode) - 1;
        if(index >= 0 && index <= stack.top) {
            int timestamp = stack.data[stack.top - index];
            dynamic_string ds = {};
            get_clipboard_entry_filename(&ds, timestamp);
            content = readFile(ds.s);
            if(content != NULL){
               copyToClipboard(content);
               UpdateTextFromC(content);
            }
        }
    }
    prev = keyCode;
    return returnEvent;
}
