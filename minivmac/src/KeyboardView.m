#import "KeyboardView.h"

@implementation KeyboardView

@synthesize delegate;
@synthesize searchPaths;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        if (AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:@"/System/Library/Frameworks/UIKit.framework/Tock.aiff"] ,&keySound) != noErr) keySound = 0;
        soundEnabled = [defaults boolForKey:@"KeyboardSound"];
        
        for (int i = 0; i < 2; i++) {
            keyboard[i] = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"KBBackground.png"]] retain];
            [keyboard[i] setUserInteractionEnabled: YES];
        }
        
        [self setUserInteractionEnabled: YES];
        [self loadImages];
        [self setAlpha:[defaults floatForKey:@"KeyboardAlpha"]];
        [self setSearchPaths:[NSArray arrayWithObject:[[NSBundle mainBundle] resourcePath]]];
        
        // notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [keyboard[0] release];
    [keyboard[1] release];
    [keyMap[0] release];
    [keyMap[1] release];
    [keyImages release];
    AudioServicesDisposeSystemSoundID(keySound);
    [super dealloc];
}

- (void)loadImages {
    int i;
    NSMutableArray* imagesUp = [NSMutableArray arrayWithCapacity:12];
    NSMutableArray* imagesDown = [NSMutableArray arrayWithCapacity:12];
    NSMutableArray* imagesHold = [NSMutableArray arrayWithCapacity:3];
    char *keyNames[] = {"Command",  "Option",   "Shift",    "Toggle",
                        "Key",      "Key0",     "Key2",     "Backspace",
                        "Escape",   "Tab",      "Return",   "Space"};
    for (i=0; i < 12; i++) {
        [imagesUp addObject:[UIImage imageNamed:[NSString stringWithFormat:@"KB%s-Up.png", keyNames[i]]]];
        [imagesDown addObject:[UIImage imageNamed:[NSString stringWithFormat:@"KB%s-Down.png", keyNames[i]]]];
        if (i < 3) [imagesHold addObject:[UIImage imageNamed:[NSString stringWithFormat:@"KB%s-Hold.png", keyNames[i]]]];
    }
    keyImages = [[NSDictionary dictionaryWithObjectsAndKeys:
                                imagesUp,       @"up",
                                imagesDown,     @"down",
                                imagesHold,     @"hold",
                                nil] retain];
}

- (void)hide {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:KeyboardViewAnimationDuration];
    self.frame = KeyboardViewFrameHidden;
    [UIView endAnimations];
}

- (void)show {  
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:KeyboardViewAnimationDuration];
    self.frame = KeyboardViewFrameVisible;
    [UIView endAnimations];
}

- (NSString*)layout {
    return layout;
}

- (void)setLayout:(NSString*)newLayout {
    if ([newLayout isEqualToString:layout]) return;
    if (layout) [self removeLayout];
    layout = [newLayout retain];
    
    // find file
    NSString* layoutFileName = [newLayout stringByAppendingPathExtension:@"kbdlayout"];
    NSString* layoutPath = nil;
    NSFileManager* fm = [NSFileManager defaultManager];
    for(NSString* basePath in searchPaths) {
        if ([fm fileExistsAtPath:[basePath stringByAppendingPathComponent:layoutFileName]])
            layoutPath = [basePath stringByAppendingPathComponent:layoutFileName];
    }
    
    // set layout
    NSDictionary* kbFile = [NSDictionary dictionaryWithContentsOfFile:layoutPath];
    if (kbFile == nil) {
        // we enter an infinite loop if there is no US.kbdlayout file
        // this would be easy to fix, but US.kbdlayout is a requirement
        [self setLayout:@"US"];
        return;
    }
    [self addKeys:kbFile];
}

- (void)removeLayout {
    // remove current layout
    if (layout) [layout release];
    layout = nil;
    
    for(int i=0; i<2; i++) {
        [keyboard[i] removeFromSuperview];
        // remove all key from superview
        for(KBKey *k in keyMap[i]) [k removeFromSuperview];
        // release key array
        [keyMap[i] release];
        keyMap[i] = nil;
    }
    currentKeyMap = nil;
}

- (void)didChangePreferences:(NSNotification *)aNotification {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    self.layout = [defaults objectForKey:@"KeyboardLayout"];
    [self setAlpha: [defaults floatForKey:@"KeyboardAlpha"]];
    soundEnabled = [defaults boolForKey:@"KeyboardSound"];
}

- (void)addKeys:(NSDictionary*)keys {
    keyMap[0] = [[self makeKeyMap:[keys objectForKey:@"Map1"] view:keyboard[0]] retain];
    keyMap[1] = [[self makeKeyMap:[keys objectForKey:@"Map2"] view:keyboard[1]] retain];
    [self addSubview:keyboard[0]];
    currentKeyMap = keyMap[0];
}

- (NSArray*)makeKeyMap:(NSArray*)arr view:(UIView*)view {
    NSMutableArray *newKeyMap = [NSMutableArray arrayWithCapacity:8 + [arr count]];
    int     i;
    KBKey   *key;
    
    // special keys
    struct {int type, scancode; CGPoint pos;} specialKeys[] = {
        {KBKey_Command,     MKC_Command,    {92,123}},
        {KBKey_Option,      MKC_Option,     {52,123}},
        {KBKey_Shift,       MKC_Shift,      {4,83}},
        {KBKey_Toggle,      -1,             {4,123}},
        {KBKey_Backspace,   MKC_BackSpace,  {414,83}},
        {KBKey_Escape,      MKC_Escape,     {330,123}},
        {KBKey_Tab,         MKC_Tab,        {369,123}},
        {KBKey_Return,      MKC_Return,     {420,123}},
    };
    for(i=0; i < 8; i++) {
        key = [KBKey keyWithType: specialKeys[i].type 
                        scancode: specialKeys[i].scancode
                        position: CGPointMake(specialKeys[i].pos.x, specialKeys[i].pos.y)
                          images: keyImages];
        key.keyboard = self;
        [view addSubview:key];
        [newKeyMap addObject:key];
    }
    
    // keys from array
    for(NSDictionary* d in arr) {
        key = [KBKey keyWithDictionary: d images: keyImages];
        key.keyboard = self;
        [view addSubview:key];
        [newKeyMap addObject:key];
    }
    
    return [NSArray arrayWithArray:newKeyMap];
}

- (void)toggleKeyMap {
    // swap keymap
    if (currentKeyMap == keyMap[0]) {
        [keyboard[0] removeFromSuperview];
        currentKeyMap = keyMap[1];
        [self addSubview: keyboard[1]];
    } else {
        [keyboard[1] removeFromSuperview];
        currentKeyMap = keyMap[0];
        [self addSubview: keyboard[0]];
    }
    
    // set key states
    [[currentKeyMap objectAtIndex:KBKey_Command] setSelected:stickyKeyDown[KBKey_Command]];
    [[currentKeyMap objectAtIndex:KBKey_Option] setSelected:stickyKeyDown[KBKey_Option]];
    [[currentKeyMap objectAtIndex:KBKey_Shift] setSelected:stickyKeyDown[KBKey_Shift]];
    [[currentKeyMap objectAtIndex:KBKey_Toggle] setSelected:(currentKeyMap == keyMap[1])];
    
    // and titles
    [self changeKeyTitles];
}

- (void)changeKeyTitles {
    int state = 0;
    
    // calculate key state
    if (stickyKeyDown[KBKey_Option])  state += 1;
    if (stickyKeyDown[KBKey_Shift])   state += 2;
    if (stickyKeyDown[KBKey_Command]) state = 0;
    
    // keys will set themselves
    for(KBKey* k in currentKeyMap)
        [k setMyTitle:state];
}

#if 0
#pragma mark -
#pragma mark Key Delegate
#endif

- (void)keyDown:(KBKey*)key type:(int)type scancode:(int)scancode {
    if (soundEnabled && keySound) AudioServicesPlaySystemSound(keySound);
    if (type == KBKey_Toggle) {
        [self toggleKeyMap];
    } else if (IsStickyKey(type) && ![key isSelected]) {
        // sticky key down, change other keys' titles
        stickyKeyDown[type] = YES;
        [self changeKeyTitles];
        [delegate vKeyDown:scancode];
    } else if (!IsStickyKey(type)) {
        // non-sticky key down
        [delegate vKeyDown:scancode];
    }
}

- (void)keyUp:(KBKey*)key type:(int)type scancode:(int)scancode {
    if (type == KBKey_Toggle) {
        [self toggleKeyMap];
    } else if (IsStickyKey(type) && [key isSelected]) {
        // unselect
        [key setSelected:NO];
        stickyKeyDown[type] = NO;
        [self changeKeyTitles];
        [delegate vKeyUp:scancode];
    } else if (IsStickyKey(type)) {
        [key setSelected:YES];
    } else {
        [delegate vKeyUp:scancode];
        // up special keys
        if (stickyKeyDown[KBKey_Command]) [self keyUp:[currentKeyMap objectAtIndex:KBKey_Command] type:KBKey_Command scancode:MKC_Command];
        if (stickyKeyDown[KBKey_Option]) [self keyUp:[currentKeyMap objectAtIndex:KBKey_Option] type:KBKey_Option scancode:MKC_Option];
        if (stickyKeyDown[KBKey_Shift]) [self keyUp:[currentKeyMap objectAtIndex:KBKey_Shift] type:KBKey_Shift scancode:MKC_Shift];
    }
}

@end
