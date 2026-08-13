#import <Cocoa/Cocoa.h>

static const CGFloat PetCellWidth = 192.0;
static const CGFloat PetCellHeight = 208.0;
static const NSInteger PetAtlasColumns = 8;
static const NSInteger PetAtlasRows = 11;
static const NSTimeInterval PetWalkDuration = 1.06;

@interface PetView : NSView
@property(nonatomic, strong) NSImage *atlas;
@property(nonatomic, copy) NSArray<NSNumber *> *animationRows;
@property(nonatomic, copy) NSArray<NSNumber *> *animationColumns;
@property(nonatomic, copy) NSArray<NSNumber *> *frameDurations;
@property(nonatomic) NSInteger animationIndex;
@property(nonatomic) BOOL loopAnimation;
@property(nonatomic, strong) NSTimer *animationTimer;
@property(nonatomic) NSPoint mouseDownLocation;
@property(nonatomic) NSPoint windowOriginAtMouseDown;
@property(nonatomic) BOOL dragging;
@property(nonatomic, copy) void (^toggleAutomaticActivityHandler)(void);
@property(nonatomic, copy) BOOL (^automaticActivityEnabledProvider)(void);
@property(nonatomic, copy) void (^actionHandler)(NSInteger row);
@property(nonatomic, copy) void (^interactionStartedHandler)(void);
@property(nonatomic, copy) void (^dragEndedHandler)(void);
- (instancetype)initWithAtlas:(NSImage *)atlas;
- (void)showIdle;
- (void)playStandardRow:(NSInteger)row loop:(BOOL)loop;
- (void)playLookAround;
- (BOOL)isIdle;
- (BOOL)isShowingRow:(NSInteger)row;
@end

@implementation PetView

- (instancetype)initWithAtlas:(NSImage *)atlas {
    self = [super initWithFrame:NSMakeRect(0, 0, PetCellWidth, PetCellHeight)];
    if (self) {
        _atlas = atlas;
        [self showIdle];
    }
    return self;
}

- (BOOL)isFlipped {
    return NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    (void)event;
    return YES;
}

- (NSArray<NSNumber *> *)columnsForFrameCount:(NSInteger)frameCount {
    NSMutableArray<NSNumber *> *columns = [NSMutableArray arrayWithCapacity:(NSUInteger)frameCount];
    for (NSInteger column = 0; column < frameCount; column += 1) {
        [columns addObject:@(column)];
    }
    return columns;
}

- (NSArray<NSNumber *> *)rowsForRow:(NSInteger)row frameCount:(NSInteger)frameCount {
    NSMutableArray<NSNumber *> *rows = [NSMutableArray arrayWithCapacity:(NSUInteger)frameCount];
    for (NSInteger index = 0; index < frameCount; index += 1) {
        [rows addObject:@(row)];
    }
    return rows;
}

- (void)playRows:(NSArray<NSNumber *> *)rows
         columns:(NSArray<NSNumber *> *)columns
       durations:(NSArray<NSNumber *> *)durations
            loop:(BOOL)loop {
    if (rows.count == 0 || rows.count != columns.count || rows.count != durations.count) {
        return;
    }

    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.animationRows = rows;
    self.animationColumns = columns;
    self.frameDurations = durations;
    self.animationIndex = 0;
    self.loopAnimation = loop;
    [self setNeedsDisplay:YES];
    [self scheduleNextFrame];
}

- (void)scheduleNextFrame {
    if (self.animationIndex < 0 || self.animationIndex >= (NSInteger)self.frameDurations.count) {
        return;
    }
    NSTimeInterval duration = self.frameDurations[(NSUInteger)self.animationIndex].doubleValue;
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                          target:self
                                                        selector:@selector(advanceFrame:)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)advanceFrame:(NSTimer *)timer {
    (void)timer;
    NSInteger nextIndex = self.animationIndex + 1;
    if (nextIndex >= (NSInteger)self.animationRows.count) {
        if (self.loopAnimation) {
            nextIndex = 0;
        } else {
            [self showIdle];
            return;
        }
    }

    self.animationIndex = nextIndex;
    [self setNeedsDisplay:YES];
    [self scheduleNextFrame];
}

- (void)showIdle {
    [self playRows:[self rowsForRow:0 frameCount:6]
           columns:[self columnsForFrameCount:6]
         durations:@[@0.280, @0.110, @0.110, @0.140, @0.140, @0.320]
              loop:YES];
}

- (void)playStandardRow:(NSInteger)row loop:(BOOL)loop {
    NSArray<NSNumber *> *durations = nil;
    switch (row) {
        case 0:
            [self showIdle];
            return;
        case 1:
        case 2:
            durations = @[@0.120, @0.120, @0.120, @0.120, @0.120, @0.120, @0.120, @0.220];
            break;
        case 3:
            durations = @[@0.140, @0.140, @0.140, @0.280];
            break;
        case 4:
            durations = @[@0.140, @0.140, @0.140, @0.140, @0.280];
            break;
        case 5:
            durations = @[@0.140, @0.140, @0.140, @0.140, @0.140, @0.140, @0.140, @0.240];
            break;
        case 6:
            durations = @[@0.150, @0.150, @0.150, @0.150, @0.150, @0.260];
            break;
        case 7:
            durations = @[@0.120, @0.120, @0.120, @0.120, @0.120, @0.220];
            break;
        case 8:
            durations = @[@0.150, @0.150, @0.150, @0.150, @0.150, @0.280];
            break;
        default:
            return;
    }

    [self playRows:[self rowsForRow:row frameCount:(NSInteger)durations.count]
           columns:[self columnsForFrameCount:(NSInteger)durations.count]
         durations:durations
              loop:loop];
}

- (void)playLookAround {
    NSMutableArray<NSNumber *> *rows = [NSMutableArray arrayWithCapacity:16];
    NSMutableArray<NSNumber *> *columns = [NSMutableArray arrayWithCapacity:16];
    NSMutableArray<NSNumber *> *durations = [NSMutableArray arrayWithCapacity:16];
    for (NSInteger row = 9; row <= 10; row += 1) {
        for (NSInteger column = 0; column < 8; column += 1) {
            [rows addObject:@(row)];
            [columns addObject:@(column)];
            [durations addObject:@0.120];
        }
    }
    [self playRows:rows columns:columns durations:durations loop:NO];
}

- (BOOL)isIdle {
    return [self isShowingRow:0];
}

- (BOOL)isShowingRow:(NSInteger)row {
    if (self.animationRows.count == 0) {
        return NO;
    }
    for (NSNumber *animationRow in self.animationRows) {
        if (animationRow.integerValue != row) {
            return NO;
        }
    }
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (self.animationIndex < 0 || self.animationIndex >= (NSInteger)self.animationRows.count) {
        return;
    }

    NSInteger row = self.animationRows[(NSUInteger)self.animationIndex].integerValue;
    NSInteger column = self.animationColumns[(NSUInteger)self.animationIndex].integerValue;
    CGFloat atlasHeight = self.atlas.size.height;
    NSRect source = NSMakeRect(
        column * PetCellWidth,
        atlasHeight - ((row + 1) * PetCellHeight),
        PetCellWidth,
        PetCellHeight
    );
    [self.atlas drawInRect:self.bounds
                 fromRect:source
                operation:NSCompositingOperationSourceOver
                 fraction:1.0
           respectFlipped:YES
                    hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
}

- (void)mouseDown:(NSEvent *)event {
    (void)event;
    if (self.interactionStartedHandler) {
        self.interactionStartedHandler();
    }
    self.mouseDownLocation = NSEvent.mouseLocation;
    self.windowOriginAtMouseDown = self.window.frame.origin;
    self.dragging = NO;
}

- (void)mouseDragged:(NSEvent *)event {
    (void)event;
    NSPoint current = NSEvent.mouseLocation;
    CGFloat deltaX = current.x - self.mouseDownLocation.x;
    CGFloat deltaY = current.y - self.mouseDownLocation.y;
    if (!self.dragging && hypot(deltaX, deltaY) < 3.0) {
        return;
    }

    self.dragging = YES;
    NSPoint origin = NSMakePoint(self.windowOriginAtMouseDown.x + deltaX,
                                 self.windowOriginAtMouseDown.y + deltaY);
    [self.window setFrameOrigin:origin];
}

- (void)mouseUp:(NSEvent *)event {
    (void)event;
    if (self.dragging) {
        if (self.dragEndedHandler) {
            self.dragEndedHandler();
        }
    } else if (self.actionHandler) {
        self.actionHandler(3);
    } else {
        [self playStandardRow:3 loop:NO];
    }
}

- (NSMenuItem *)actionItemWithTitle:(NSString *)title row:(NSInteger)row {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                 action:@selector(playMenuAction:)
                                          keyEquivalent:@""];
    item.target = self;
    item.tag = row;
    return item;
}

- (void)rightMouseDown:(NSEvent *)event {
    if (self.interactionStartedHandler) {
        self.interactionStartedHandler();
    }
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"小满"];
    BOOL automaticActivityEnabled = self.automaticActivityEnabledProvider
        ? self.automaticActivityEnabledProvider()
        : YES;
    NSString *automaticTitle = automaticActivityEnabled ? @"暂停自动活动" : @"开启自动活动";
    NSMenuItem *automaticItem = [[NSMenuItem alloc] initWithTitle:automaticTitle
                                                           action:@selector(toggleAutomaticActivity:)
                                                    keyEquivalent:@""];
    automaticItem.target = self;
    [menu addItem:automaticItem];

    NSMenu *actionsMenu = [[NSMenu alloc] initWithTitle:@"播放动作"];
    [actionsMenu addItem:[self actionItemWithTitle:@"回到待机" row:0]];
    [actionsMenu addItem:[self actionItemWithTitle:@"向右跑" row:1]];
    [actionsMenu addItem:[self actionItemWithTitle:@"向左跑" row:2]];
    [actionsMenu addItem:NSMenuItem.separatorItem];
    [actionsMenu addItem:[self actionItemWithTitle:@"挥手" row:3]];
    [actionsMenu addItem:[self actionItemWithTitle:@"跳一下" row:4]];
    [actionsMenu addItem:[self actionItemWithTitle:@"难过" row:5]];
    [actionsMenu addItem:[self actionItemWithTitle:@"等待" row:6]];
    [actionsMenu addItem:[self actionItemWithTitle:@"忙碌" row:7]];
    [actionsMenu addItem:[self actionItemWithTitle:@"认真检查" row:8]];
    [actionsMenu addItem:[self actionItemWithTitle:@"环视四周" row:9]];

    NSMenuItem *actionsItem = [[NSMenuItem alloc] initWithTitle:@"播放动作"
                                                        action:nil
                                                 keyEquivalent:@""];
    actionsItem.submenu = actionsMenu;
    [menu addItem:actionsItem];
    [menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出桌宠"
                                                      action:@selector(quit:)
                                               keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    [NSMenu popUpContextMenu:menu withEvent:event forView:self];
}

- (void)playMenuAction:(NSMenuItem *)sender {
    if (self.actionHandler) {
        self.actionHandler(sender.tag);
    }
}

- (void)toggleAutomaticActivity:(id)sender {
    (void)sender;
    if (self.toggleAutomaticActivityHandler) {
        self.toggleAutomaticActivityHandler();
    }
}

- (void)quit:(id)sender {
    (void)sender;
    [NSApp terminate:nil];
}

- (void)dealloc {
    [_animationTimer invalidate];
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) PetView *petView;
@property(nonatomic, strong) NSTimer *activityTimer;
@property(nonatomic) BOOL automaticActivityEnabled;
@property(nonatomic) BOOL moving;
@end

@implementation AppDelegate

- (void)showLaunchError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"无法启动小满桌宠";
    alert.informativeText = message;
    [alert runModal];
    [NSApp terminate:nil];
}

- (NSImage *)loadAtlas {
    NSURL *atlasURL = [NSBundle.mainBundle URLForResource:@"spritesheet" withExtension:@"png"];
    if (!atlasURL) {
        [self showLaunchError:@"缺少动画图集 spritesheet.png。"];
        return nil;
    }

    NSData *atlasData = [NSData dataWithContentsOfURL:atlasURL];
    NSBitmapImageRep *representation = [[NSBitmapImageRep alloc] initWithData:atlasData];
    NSInteger expectedWidth = (NSInteger)PetCellWidth * PetAtlasColumns;
    NSInteger expectedHeight = (NSInteger)PetCellHeight * PetAtlasRows;
    if (!representation || representation.pixelsWide != expectedWidth || representation.pixelsHigh != expectedHeight) {
        NSString *message = [NSString stringWithFormat:@"动画图集尺寸不正确，应为 %ld×%ld 像素。",
                                                      (long)expectedWidth,
                                                      (long)expectedHeight];
        [self showLaunchError:message];
        return nil;
    }

    NSImage *atlas = [[NSImage alloc] initWithData:atlasData];
    if (!atlas) {
        [self showLaunchError:@"动画图集无法读取。"];
    }
    return atlas;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSImage *atlas = [self loadAtlas];
    if (!atlas) {
        return;
    }

    NSSize windowSize = NSMakeSize(230, 249);
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, windowSize.width, windowSize.height)
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.opaque = NO;
    self.window.backgroundColor = NSColor.clearColor;
    self.window.hasShadow = NO;
    self.window.level = NSFloatingWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorFullScreenAuxiliary;
    self.window.releasedWhenClosed = NO;

    self.petView = [[PetView alloc] initWithAtlas:atlas];
    __weak typeof(self) weakSelf = self;
    self.petView.toggleAutomaticActivityHandler = ^{
        [weakSelf toggleAutomaticActivity];
    };
    self.petView.automaticActivityEnabledProvider = ^BOOL{
        return weakSelf.automaticActivityEnabled;
    };
    self.petView.actionHandler = ^(NSInteger row) {
        [weakSelf performActionRow:row];
    };
    self.petView.interactionStartedHandler = ^{
        [weakSelf cancelMovementForInteraction];
    };
    self.petView.dragEndedHandler = ^{
        [weakSelf keepWindowVisible];
    };
    self.window.contentView = self.petView;

    NSScreen *screen = NSScreen.mainScreen;
    NSRect visible = screen.visibleFrame;
    [self.window setFrameOrigin:NSMakePoint(NSMaxX(visible) - windowSize.width - 28,
                                            NSMinY(visible) + 18)];
    [self.window orderFrontRegardless];

    self.automaticActivityEnabled = YES;
    [self startAutomaticActivity];
}

- (NSScreen *)screenContainingPoint:(NSPoint)point {
    for (NSScreen *screen in NSScreen.screens) {
        if (NSPointInRect(point, screen.frame)) {
            return screen;
        }
    }
    return nil;
}

- (NSScreen *)bestScreenForWindow {
    if (self.window.screen) {
        return self.window.screen;
    }

    NSScreen *bestScreen = NSScreen.mainScreen;
    CGFloat largestArea = 0.0;
    for (NSScreen *screen in NSScreen.screens) {
        NSRect intersection = NSIntersectionRect(self.window.frame, screen.visibleFrame);
        CGFloat area = NSWidth(intersection) * NSHeight(intersection);
        if (area > largestArea) {
            largestArea = area;
            bestScreen = screen;
        }
    }
    return bestScreen;
}

- (NSRect)clampedFrame:(NSRect)frame toVisibleFrame:(NSRect)visible {
    CGFloat maximumX = MAX(NSMinX(visible), NSMaxX(visible) - NSWidth(frame));
    CGFloat maximumY = MAX(NSMinY(visible), NSMaxY(visible) - NSHeight(frame));
    frame.origin.x = MIN(MAX(frame.origin.x, NSMinX(visible)), maximumX);
    frame.origin.y = MIN(MAX(frame.origin.y, NSMinY(visible)), maximumY);
    return frame;
}

- (void)keepWindowVisible {
    NSScreen *screen = [self screenContainingPoint:NSEvent.mouseLocation] ?: [self bestScreenForWindow];
    if (!screen) {
        return;
    }
    NSRect clamped = [self clampedFrame:self.window.frame toVisibleFrame:screen.visibleFrame];
    if (!NSEqualRects(clamped, self.window.frame)) {
        [self.window setFrame:clamped display:YES animate:YES];
    }
}

- (void)toggleAutomaticActivity {
    self.automaticActivityEnabled = !self.automaticActivityEnabled;
    self.automaticActivityEnabled ? [self startAutomaticActivity] : [self stopAutomaticActivity];
}

- (void)startAutomaticActivity {
    [self stopAutomaticActivity];
    self.automaticActivityEnabled = YES;
    self.activityTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                         target:self
                                                       selector:@selector(performAutomaticActivity:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopAutomaticActivity {
    [self.activityTimer invalidate];
    self.activityTimer = nil;
}

- (void)performAutomaticActivity:(NSTimer *)timer {
    (void)timer;
    if (!self.automaticActivityEnabled || self.moving || !self.petView.isIdle) {
        return;
    }

    if (arc4random_uniform(100) < 65) {
        CGFloat magnitude = 80.0 + arc4random_uniform(101);
        CGFloat offset = arc4random_uniform(2) == 0 ? -magnitude : magnitude;
        [self movePetByOffset:offset];
        return;
    }

    NSInteger automaticRows[] = {4, 5, 6, 7, 8, 9};
    NSInteger row = automaticRows[arc4random_uniform(6)];
    [self performActionRow:row];
}

- (void)performActionRow:(NSInteger)row {
    if (row == 1) {
        [self movePetByOffset:140.0];
    } else if (row == 2) {
        [self movePetByOffset:-140.0];
    } else if (row == 9) {
        [self.petView playLookAround];
    } else {
        [self.petView playStandardRow:row loop:NO];
    }
}

- (void)cancelMovementForInteraction {
    if (!self.moving) {
        return;
    }
    NSRect currentFrame = self.window.frame;
    self.moving = NO;
    [self.window setFrame:currentFrame display:YES];
    if ([self.petView isShowingRow:1] || [self.petView isShowingRow:2]) {
        [self.petView showIdle];
    }
}

- (void)movePetByOffset:(CGFloat)offset {
    if (self.moving || fabs(offset) < 1.0) {
        return;
    }

    NSScreen *screen = [self bestScreenForWindow];
    if (!screen) {
        return;
    }
    NSRect currentFrame = [self clampedFrame:self.window.frame toVisibleFrame:screen.visibleFrame];
    NSRect targetFrame = currentFrame;
    targetFrame.origin.x += offset;
    targetFrame = [self clampedFrame:targetFrame toVisibleFrame:screen.visibleFrame];
    if (fabs(targetFrame.origin.x - currentFrame.origin.x) < 1.0) {
        targetFrame.origin.x -= offset;
        targetFrame = [self clampedFrame:targetFrame toVisibleFrame:screen.visibleFrame];
    }
    if (fabs(targetFrame.origin.x - currentFrame.origin.x) < 1.0) {
        return;
    }

    [self.window setFrame:currentFrame display:YES];
    NSInteger runningRow = targetFrame.origin.x > currentFrame.origin.x ? 1 : 2;
    self.moving = YES;
    [self.petView playStandardRow:runningRow loop:YES];

    __weak typeof(self) weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = PetWalkDuration;
        context.allowsImplicitAnimation = YES;
        [weakSelf.window.animator setFrame:targetFrame display:YES];
    } completionHandler:^{
        typeof(self) strongSelf = weakSelf;
        strongSelf.moving = NO;
        if ([strongSelf.petView isShowingRow:runningRow]) {
            [strongSelf.petView showIdle];
        }
    }];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self stopAutomaticActivity];
    [self.petView.animationTimer invalidate];
}

@end

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
