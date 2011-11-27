#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIEvent.h>
#import "vMacApp.h"
#import "SurfaceView.h"
#import "InsertDiskView.h"
#import "SettingsView.h"

#define kSwipeThresholdHorizontal   100.0
#define kSwipeThresholdVertical     70.0

@interface MainView : UIView
{
    SurfaceView     *screenView;
    KeyboardView    *keyboardView;
    InsertDiskView  *insertDiskView;
    SettingsView    *settingsView;
    
    // screen
    BOOL            screenSizeToFit;
    Direction       screenPosition;
    
    // mouse
    UITouch         *mouseTouch;
    BOOL            trackpadMode, trackpadClick;
    BOOL            clickScheduled, mouseDrag;
    Point           clickLoc;
    NSTimeInterval  lastMouseTime, lastMouseClick;
    Point           lastMouseLoc;
    Point           mouseOffset;
    // gesture
    BOOL            inGesture;
    CGPoint         gestureStart;
}

- (void)didChangePreferences:(NSNotification *)aNotification;
- (void)_createKeyboardView;
- (void)_createInsertDiskView;
- (void)_createSettingsView;

- (Point)mouseLocForCGPoint:(CGPoint)point;
- (void)scheduleMouseClickAt:(Point)mouseLoc;
- (void)cancelMouseClick;
- (void)mouseClick;

- (void)toggleScreenSize;
- (void)scrollScreenViewTo:(Direction)scroll;

- (void)twoFingerSwipeGesture:(Direction)direction;
- (void)twoFingerTapGesture:(UIEvent *)event;

@end