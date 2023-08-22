#include "copypaste.h"
#define STACK_IMPL
#include "stack.h"
#define DYNAMIC_STRING_IMPL
#include "dynamic_string.h"

#import <Cocoa/Cocoa.h>

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
    printf("%s\n", content);
    NSString *string = [NSString stringWithUTF8String:content];
    [self.textField setStringValue:string];
}

@end

void UpdateTextFromC(const char *newText) {
    dispatch_async(dispatch_get_main_queue(), ^{
    [globalDelegate setTextFieldContent:newText];
});
}

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

    return 0;
}










int prev = -1;
CGEventFlags lastFlags = 0;

void get_clipboard_entry_filename(dynamic_string* ds, int timestamp){
    create_dynamic_string(ds, "copy_");
    int length = snprintf( NULL, 0, "%d", timestamp);
    char* str = malloc( length + 1 );
    snprintf( str, length + 1, "%d", timestamp);
    concat(str, ds);
    free(str);
    concat(".txt", ds);
}

void remove_clipboard_entry(int timestamp){
    dynamic_string ds = {};
    get_clipboard_entry_filename(&ds, timestamp);
    print_dynamic_string(&ds);
    remove(ds.s);
    free_dynamic_string(&ds);
}

int extract_timestamp_from_filename(char* filename){
    dynamic_string ds = {};
    create_dynamic_string(&ds, filename);
    drop(ds, &ds, 5);
    take(ds, &ds, ds.length - 4);
    int result;
    sscanf(ds.s,"%d", &result);
    free_dynamic_string(&ds);
    return result;
}

void add_clipboard_entry(Stack* stack, int timestamp){
    if(isFull(stack)){
        remove_clipboard_entry(stack->data[STACK_SIZE-1]);
    }
    push(stack, timestamp);
}

void update_clipboard_entries(Stack* stack)
{
    DIR *d;
    struct dirent *dir;
    d = opendir(".");

    if (d) {
        while ((dir = readdir(d)) != NULL) {
            if (strncmp(dir->d_name, "copy_", 5) == 0 && strstr(dir->d_name, ".txt")) {
                int timestamp = extract_timestamp_from_filename(dir->d_name);
                add_clipboard_entry(stack, timestamp);
            }
        }
        closedir(d);
    } else {
        perror("Error opening directory");
    }
    // display(stack);
}

// int main(void)
// {
// 	return eventTap();
// }

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

int get_index(int keyCode){
    switch(keyCode){
        case 18:  return 1;
        case 19:  return 2;
        case 20:  return 3;
        case 21:  return 4;
        case 23:  return 5;
        case 22:  return 6;
        case 26:  return 7;
        case 28:  return 8;
        case 25:  return 9;
        case 29:  return 0;
    }
    return -1;
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
        // case 56: // [left-shift]
        // case 60: // [right-shift]
        //     down = (flags & kCGEventFlagMaskShift) && !(lastFlags & kCGEventFlagMaskShift);
        //     break;
        // case 58: // [left-option]
        // case 61: // [right-option]
        //     down = (flags & kCGEventFlagMaskAlternate) && !(lastFlags & kCGEventFlagMaskAlternate);
        //     break;
        // case 59: // [left-ctrl]
        // case 62: // [right-ctrl]
        //     down = (flags & kCGEventFlagMaskControl) && !(lastFlags & kCGEventFlagMaskControl);
        //     break;
        // case 57: // [caps]
        //     down = (flags & kCGEventFlagMaskAlphaShift) && !(lastFlags & kCGEventFlagMaskAlphaShift);
        //     break;
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
        if(fork() == 0){
            update();
        }
    }

    Stack stack;
    initialize(&stack);
    update_clipboard_entries(&stack);

    if(cmd && shift && keyCode == kVK_ANSI_V){ // CMD + shift + V
 	    printf("open menu for selecting copied content");
    }
    if(cmd || down){
        int index = get_index(keyCode) - 1;
        printf("index = %d\n", index);
        if(index >= 0 && index <= stack.top){
            int timestamp = stack.data[index];
            printf("selected: %d\n", timestamp);
            dynamic_string ds = {};
            get_clipboard_entry_filename(&ds, timestamp);
            char* content = readFile(ds.s);
            if(content != NULL){
               copyToClipboard(content);
               UpdateTextFromC(content);
               free(content);
            }
        }
    }
    prev = keyCode;
    return event;
}

void copyToClipboard(const char *text) {
    FILE *pipe = popen("pbcopy", "w");
    if (pipe == NULL) {
        perror("popen");
        return;
    }

    fprintf(pipe, "%s", text);
    pclose(pipe);
}

char* readFile(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        perror("fopen");
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *buffer = malloc(length + 1);
    if (buffer == NULL) {
        perror("malloc");
        fclose(file);
        return NULL;
    }

    fread(buffer, 1, length, file);
    buffer[length] = '\0';

    fclose(file);
    return buffer;
}

int update()
{
    FILE *pb = popen("pbpaste", "r");

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

        //strftime(filename, sizeof(filename), "copy_%Y-%m-%d_%H:%M:%S.txt", timenow);
        strftime(filename, sizeof(filename), "copy_%s.txt", timenow);
        FILE *history = fopen(filename, "a+");
        fputs(paste, history);
        printf("%s\n", paste);
        fputs("\n", history);
        fclose(history);
    }
    pclose(pb);

	return 0;
}
