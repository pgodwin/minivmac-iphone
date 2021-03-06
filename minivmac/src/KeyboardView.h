#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "KBKey.h"
#import "SYSDEPNS.h"
#import "MYOSGLUE.h"

#ifdef UI_USER_INTERFACE_IDIOM()
#define IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#else
#define IPAD() (false)
#endif

#define KeyboardViewAnimationDuration   0.3

#define KeyboardViewFrameVisible        (IPAD()==YES ? \
                                            CGRectMake((1024/2)-240, 768-162.0, 480.0, 162.0) : \
                                            CGRectMake(0.0, 320.0-162.0, 480.0, 162.0))

#define KeyboardViewFrameHidden         (IPAD()==YES ? \
                                            CGRectMake((1024/2)-240, 768.0, 480.0, 162.0) : \
                                            CGRectMake(0.0, 320.0, 480.0, 162.0))

@protocol VirtualKeyboard
- (void)vKeyDown:(int)scancode;
- (void)vKeyUp:(int)scancode;
@end

@interface KeyboardView : UIView {
    id <VirtualKeyboard> delegate;
    NSDictionary    *keyImages; // (up => (images...), down => (images...), hold (images...))
    UIView          *keyboard[2]; // view, toggled view
    NSArray         *keyMap[2], *currentKeyMap;
    BOOL            stickyKeyDown[3]; // shift, option, command
    NSString        *layout;
    NSArray         *searchPaths;
    SystemSoundID   keySound;
    BOOL            soundEnabled;
}

@property (nonatomic, assign) id <VirtualKeyboard> delegate;
@property (nonatomic, retain) NSString* layout;
@property (nonatomic, retain) NSArray* searchPaths;

- (void)loadImages;
- (void)hide;
- (void)show;
- (void)removeLayout;
- (void)didChangePreferences:(NSNotification *)aNotification;
- (void)addKeys:(NSDictionary*)keys;
- (NSArray*)makeKeyMap:(NSArray*)arr view:(UIView*)view;
- (void)toggleKeyMap;
- (void)changeKeyTitles;
- (void)keyDown:(KBKey*)key type:(int)type scancode:(int)scancode;
- (void)keyUp:(KBKey*)key type:(int)type scancode:(int)scancode;

@end
