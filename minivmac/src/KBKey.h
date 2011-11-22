#import <UIKit/UIKit.h>

@class KeyboardView;

#define IsStickyKey(t) (t <= KBKey_Shift)

typedef enum KBKeyType {
    KBKey_Command,
    KBKey_Option,
    KBKey_Shift,
    KBKey_Toggle,
    KBKey_Normal,
    KBKey_Small,
    KBKey_Big,
    KBKey_Backspace,
    KBKey_Escape,
    KBKey_Tab,
    KBKey_Return,
    KBKey_Space
} KBKeyType;

typedef enum KBKeyTitleState {
    KBKeyTitle_Normal,
    KBKeyTitle_Option,
    KBKeyTitle_Shift,
    KBKeyTitle_ShiftOption
} KBKeyTitleState;

@interface KBKey : UIButton {
    KBKeyType       type;
    KeyboardView*   keyboard;
    int             scancode;
    NSString*       title[4]; // normal, option, shift, shift+option
    BOOL            isDown;
}

+ (UIFont*)sharedKeyFont;
+ (KBKey*)keyWithDictionary:(NSDictionary*)d images:(NSDictionary*)keyImages;
+ (KBKey*)keyWithType:(KBKeyType)keyType scancode:(int)keyScancode position:(CGPoint)position images:(NSDictionary*)keyImages;

@property (nonatomic, assign) KeyboardView* keyboard;

- (id)initWithDictionary:(NSDictionary*)d images:(NSDictionary*)keyImages;
- (id)initWithType:(KBKeyType)keyType scancode:(int)keyScancode position:(CGPoint)position images:(NSDictionary*)keyImages;
- (void)setMyTitle:(NSInteger)i;

@end