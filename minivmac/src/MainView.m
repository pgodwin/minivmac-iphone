#import "MainView.h"

@implementation MainView

- (id)initWithFrame:(CGRect)rect {
    if (self = [super initWithFrame:rect]) {
        // initialization
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        [self setBackgroundColor:[UIColor blackColor]];
        [self didChangePreferences:nil];
        [self setMultipleTouchEnabled:YES];
        
        // add screen view
        CGRect screenRect;
        if ([defaults boolForKey:@"ScreenSizeToFit"]) screenRect = kScreenRectFullScreen;
        else screenRect = kScreenRectRealSize;
        screenView = [[SurfaceView alloc] initWithFrame:screenRect pixelFormat:kPixelFormat565L surfaceSize:CGSizeMake(vMacScreenWidth, vMacScreenHeight) scalingFilter:kCAFilterLinear];
        [self addSubview:screenView];
        [screenView setUserInteractionEnabled:NO];
        _gScreenView = screenView;
        _updateColorMode = NSSelectorFromString (@"useColorMode:");
        SurfaceScrnBuf = [screenView pixels];
        screenSizeToFit = [defaults boolForKey:@"ScreenSizeToFit"];
        screenPosition = [defaults integerForKey:@"ScreenPosition"];
        [self scrollScreenViewTo:screenPosition];
        
        // other views
        keyboardView = nil;
        insertDiskView = nil;
        settingsView = nil;
        
        // register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}

- (void) dealloc {
    [super dealloc];
}

- (void)didChangePreferences:(NSNotification *)aNotification {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    trackpadMode = [defaults boolForKey:@"TrackpadMode"];
}

- (void)_createKeyboardView {
    if (keyboardView) return;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    keyboardView = [[KeyboardView alloc] initWithFrame:KeyboardViewFrameHidden];
    keyboardView.searchPaths = [[vMacApp sharedInstance] searchPaths];
    keyboardView.layout = [defaults objectForKey:@"KeyboardLayout"];
    [self addSubview:keyboardView];
    keyboardView.delegate = [vMacApp sharedInstance];
}

- (void)_createInsertDiskView {
    // add insert disk view
    insertDiskView = [[InsertDiskView alloc] initWithFrame:InsertDiskViewFrameHidden];
    [self addSubview:insertDiskView];
    insertDiskView.diskDrive = [vMacApp sharedInstance];
}

- (void)_createSettingsView {
    // add settings view
    settingsView = [[SettingsView alloc] initWithFrame:SettingsViewFrameHidden];
    [self addSubview:settingsView];
}

#if 0
#pragma mark -
#pragma mark Touches
#endif

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[event allTouches] count] > 1) {
        // gesture started
        mouseTouch = nil;
        if (inGesture) return;
        inGesture = YES;
        mouseDrag = NO;
        if (trackpadMode) {
            trackpadClick = NO;
        } else {
            [vMacApp cancelPreviousPerformRequestsWithTarget:_vmacAppSharedInstance selector:@selector(setMouseButtonDown) object:nil];
        }
        [_vmacAppSharedInstance setMouseButtonUp];
        
        // start point
        gestureStart = CGPointCenter(
            [[[event.allTouches allObjects] objectAtIndex:0] locationInView:self],
            [[[event.allTouches allObjects] objectAtIndex:1] locationInView:self]);
        return;
    }
    
    // mouse tap
    mouseTouch = [touches anyObject];
    CGPoint tapLoc = [mouseTouch locationInView:self];
    if (!screenSizeToFit) {
        // check to scroll screen
        CGPoint screenLoc = [screenView frame].origin;
        Direction scrollTo = 0;
        if (tapLoc.x < kScreenEdgeSize && screenLoc.x != 0.0) scrollTo |= dirLeft;
        if (tapLoc.y < kScreenEdgeSize && screenLoc.y != 0.0) scrollTo |= dirUp;
#ifdef IPAD
        if (tapLoc.x > (1024-kScreenEdgeSize) && screenLoc.x == 0.0) scrollTo |= dirRight;
        if (tapLoc.y > (768-kScreenEdgeSize) && screenLoc.y == 0.0) scrollTo |= dirDown;
#else
        if (tapLoc.x > (480-kScreenEdgeSize) && screenLoc.x == 0.0) scrollTo |= dirRight;
        if (tapLoc.y > (320-kScreenEdgeSize) && screenLoc.y == 0.0) scrollTo |= dirDown;
#endif
        if (scrollTo) {
            [self scrollScreenViewTo:scrollTo];
            return;
        }
    }
    
    Point loc = [self mouseLocForCGPoint:tapLoc];
    NSTimeInterval mouseTime = event.timestamp;
    NSTimeInterval mouseDiff = mouseTime - lastMouseClick;
    
    if (trackpadMode) {
        trackpadClick = YES;
        if ((mouseDiff <= TRACKPAD_DRAG_DELAY) &&
            (PointDistanceSq(loc, lastMouseLoc) < MOUSE_LOC_THRESHOLD)) {
            mouseDrag = YES;
            [_vmacAppSharedInstance setMouseButtonDown];
        }
    } else {
        // help double clicking: click in the same place if it was fast and near
        if ((mouseDiff < MOUSE_DBLCLICK_TIME) &&
            (PointDistanceSq(loc, lastMouseLoc) < MOUSE_LOC_THRESHOLD)) {
            loc = lastMouseLoc;
        }
        [_vmacAppSharedInstance setMouseLoc:loc];
        [_vmacAppSharedInstance performSelector:@selector(setMouseButtonDown) withObject:nil afterDelay:MOUSE_CLICK_DELAY];
    }
    
    lastMouseLoc = loc;
    lastMouseTime = lastMouseClick = mouseTime;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ((mouseTouch == nil) || (![touches containsObject:mouseTouch])) {
        // end gesture?
        if (!inGesture) return;
        inGesture = NO;
        CGPoint gestureEnd = [touches.anyObject locationInView:self];
        
        // process gesture (relative to landscape orientation)
        Direction swipeDirection = 0;
        CGPoint delta = CGPointMake(gestureStart.x-gestureEnd.x, gestureStart.y-gestureEnd.y);
        if (delta.x > kSwipeThresholdHorizontal)  swipeDirection |= dirLeft;
        if (delta.x < -kSwipeThresholdHorizontal) swipeDirection |= dirRight;
        if (delta.y > kSwipeThresholdVertical)    swipeDirection |= dirUp;
        if (delta.y < -kSwipeThresholdVertical)   swipeDirection |= dirDown;

        if (swipeDirection) [self twoFingerSwipeGesture:swipeDirection];
        else [self twoFingerTapGesture:event];
        
        return;
    }
    
    Point loc = [self mouseLocForCGPoint:[mouseTouch locationInView:self]];
    NSTimeInterval mouseTime = event.timestamp;
    NSTimeInterval mouseDiff = mouseTime - lastMouseClick;
    
    if (trackpadMode) {
        if (trackpadClick && (mouseDiff <= TRACKPAD_CLICK_TIME)) [self scheduleMouseClickAt:[_vmacAppSharedInstance mouseLoc]];
        trackpadClick = NO;
        if (mouseDrag) {
            [_vmacAppSharedInstance setMouseButtonUp];
            mouseDrag = NO;
        }
    } else {
        // mouseUp in the same place if it's near enough
        if (PointDistanceSq(loc, lastMouseLoc) < MOUSE_LOC_THRESHOLD) loc = lastMouseLoc;
        [_vmacAppSharedInstance setMouseLoc:loc];
        [_vmacAppSharedInstance performSelector:@selector(setMouseButtonUp) withObject:nil afterDelay:MOUSE_CLICK_DELAY];
        mouseDrag = NO;
    }
    
    lastMouseLoc = loc;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (inGesture) return;
    if ((mouseTouch == nil) || (![touches containsObject:mouseTouch])) return;
    
    NSTimeInterval mouseTime = event.timestamp;
    Point loc = [self mouseLocForCGPoint:[mouseTouch locationInView:self]];
    
    if (trackpadMode) {
        Point locDiff = loc;
        locDiff.h -= lastMouseLoc.h;
        locDiff.v -= lastMouseLoc.v;
        // acceleration
        NSTimeInterval timeDiff = 100 * (mouseTime - lastMouseTime);
        NSTimeInterval accel = TRACKPAD_ACCEL_N / (TRACKPAD_ACCEL_T + ((timeDiff * timeDiff)/TRACKPAD_ACCEL_D));
        locDiff.h *= accel;
        locDiff.v *= accel;
        trackpadClick = NO;
        [_vmacAppSharedInstance moveMouse:locDiff button:mouseDrag];
    } else {
        if (!mouseDrag) {
            // start dragging, mouseDown at current position NOW
            [vMacApp cancelPreviousPerformRequestsWithTarget:_vmacAppSharedInstance selector:@selector(setMouseButtonDown) object:nil];
            [_vmacAppSharedInstance setMouseButton:YES];
            DoEmulateOneTick();
            DoEmulateOneTick();
            CurEmulatedTime += 2;
            mouseDrag = YES;
        }
        [_vmacAppSharedInstance setMouseLoc:loc];
    }
    
    lastMouseTime = mouseTime;
    lastMouseLoc = loc;
}

#if 0
#pragma mark -
#pragma mark Mouse
#endif

- (Point)mouseLocForCGPoint:(CGPoint)point {
    Point pt;
    if (trackpadMode) {
        // same location
        pt.h = point.x;
        pt.v = point.y;
    } else if (screenSizeToFit) {
        // scale
#ifdef IPAD
        pt.h = point.x * (vMacScreenWidth / 1024.0);
        pt.v = point.y * (vMacScreenHeight / 768.0);
#else
        pt.h = point.x * (vMacScreenWidth / 480.0);
        pt.v = point.y * (vMacScreenHeight / 320.0); 
#endif
    } else {
        // translate
        pt.h = point.x - mouseOffset.h;
        pt.v = point.y - mouseOffset.v;
    }
    return pt;
}

- (void)scheduleMouseClickAt:(Point)loc {
    if (clickScheduled) {
        [MainView cancelPreviousPerformRequestsWithTarget:self selector:@selector(mouseClick) object:nil];
        [self mouseClick];
    }
    clickScheduled = YES;
    clickLoc = loc;
    [self performSelector:@selector(mouseClick) withObject:nil afterDelay:TRACKPAD_CLICK_DELAY];
}

- (void)cancelMouseClick {
    clickScheduled = NO;
    [MainView cancelPreviousPerformRequestsWithTarget:self selector:@selector(mouseClick) object:nil];
}

- (void)mouseClick {
    clickScheduled = NO;
    if (mouseDrag) return;
    [_vmacAppSharedInstance setMouseLoc:clickLoc button:YES];
    DoEmulateOneTick();
    DoEmulateOneTick();
    [_vmacAppSharedInstance setMouseButtonUp];
    CurEmulatedTime += 2;
}

#if 0
#pragma mark -
#pragma mark Screen
#endif

- (void)toggleScreenSize {
    [UIView beginAnimations:nil context:nil];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    screenSizeToFit =! screenSizeToFit;
    if (screenSizeToFit) [screenView setFrame: kScreenRectFullScreen];
    else {
        [screenView setFrame: kScreenRectRealSize];
        [self scrollScreenViewTo: screenPosition];
    }
    [UIView endAnimations];
    [defaults setBool:screenSizeToFit forKey:@"ScreenSizeToFit"];
    [defaults synchronize];
}

- (void)scrollScreenViewTo:(Direction)scroll {
    if (screenSizeToFit) return;
    // calculate new position
    CGRect screenFrame = screenView.frame;
#ifdef IPAD
    if (scroll & dirDown) screenFrame.origin.y = 768.0-vMacScreenHeight;
#else
    if (scroll & dirDown) screenFrame.origin.y = ([[vMacApp sharedInstance] isRetinaDisplay]?320.5:320.0)-vMacScreenHeight;
#endif
    else if (scroll & dirUp) screenFrame.origin.y = 0.0;
    if (scroll & dirLeft) screenFrame.origin.x = 0.0;
#ifdef IPAD    
    else if (scroll & dirRight) screenFrame.origin.x = 1024.0-vMacScreenWidth;
#else
    else if (scroll & dirRight) screenFrame.origin.x = 480.0-vMacScreenWidth;
#endif
    if (scroll != screenPosition) {
        screenPosition = scroll;
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:screenPosition forKey:@"ScreenPosition"];
        [defaults synchronize];
    }
    
    // set mouse offset
    mouseOffset.h = screenFrame.origin.x;
    mouseOffset.v = screenFrame.origin.y;
    
    // apply
    screenView.frame = screenFrame;
}

#if 0
#pragma mark -
#pragma mark Gestures
#endif

- (void)twoFingerSwipeGesture:(Direction)direction {
    switch(direction) {
    case dirDown:
        if (keyboardView) [keyboardView hide];
        break;
    case dirUp:
        if (keyboardView == nil) [self _createKeyboardView];
        [keyboardView show];
        [self bringSubviewToFront:keyboardView];
        break;
    case dirLeft:
        if (insertDiskView == nil) [self _createInsertDiskView];
        [insertDiskView show];
        [self bringSubviewToFront:insertDiskView];
        break;
    case dirRight:
        if (settingsView == nil) [self _createSettingsView];
        [settingsView show];
        [self bringSubviewToFront:settingsView];
        break;
    }
}

- (void)twoFingerTapGesture:(UIEvent *)event {
    [self toggleScreenSize];
}

@end