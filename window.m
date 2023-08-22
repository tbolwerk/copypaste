#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSTextField *textField;
@end

@implementation AppDelegate

- (void)setTextFieldContent:(const char *)content {
    NSString *nsContent = [NSString stringWithUTF8String:content];
    [self.textField setStringValue:nsContent];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    NSUInteger styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                               styleMask:styleMask
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
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        [NSApp setDelegate:appDelegate];
        [NSApp run];
        if (argc > 1) {
            [appDelegate setTextFieldContent:argv[1]];
        }
    }
    return EXIT_SUCCESS;
}