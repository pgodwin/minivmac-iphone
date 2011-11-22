#import "KBKey.h"
#import "KeyboardView.h"

static UIFont* sharedKeyFont = NULL;

@implementation KBKey

@synthesize keyboard;

+ (UIFont*)sharedKeyFont {
    if (sharedKeyFont == NULL)
        sharedKeyFont = [UIFont boldSystemFontOfSize:22];
    return sharedKeyFont;
}

+ (KBKey*)keyWithDictionary:(NSDictionary*)d images:(NSDictionary*)keyImages {
    return [[[KBKey alloc] initWithDictionary:d images:keyImages] autorelease];
}

+ (KBKey*)keyWithType:(KBKeyType)keyType scancode:(int)keyScancode position:(CGPoint)position images:(NSDictionary*)keyImages {
    return [[[KBKey alloc] initWithType:keyType scancode:keyScancode position:position images:keyImages] autorelease];
}

- (id)initWithDictionary:(NSDictionary*)d images:(NSDictionary*)keyImages {
    // init
    if ((self = [self initWithType: [[d valueForKey:@"Type"] integerValue]
                          scancode: [[d valueForKey:@"Scancode"] integerValue]
                          position: CGPointMake([[d valueForKey:@"PosX"] floatValue], [[d valueForKey:@"PosY"] floatValue])
                            images: keyImages]) == nil) return nil;
    
    // set titles
    id titles = [d valueForKey:@"Title"];
    if (titles) {
        [self setFont:[KBKey sharedKeyFont]];
        [self setTitleColor:[UIColor blackColor] forState: UIControlStateNormal];
        
        // set title
        if ([titles isKindOfClass:[NSDictionary class]]) {
            // titles for different states, only Normal required
            NSString* newTitle;
            title[0] = [[titles valueForKey:@"Normal"] retain];
            newTitle = [titles valueForKey:@"Option"];
            title[1] = [(newTitle?newTitle:title[0]) retain];
            newTitle = [titles valueForKey:@"Shift"];
            title[2] = [(newTitle?newTitle:title[0]) retain];
            newTitle = [titles valueForKey:@"OptionShift"];
            title[3] = [(newTitle?newTitle:title[0]) retain];
        } else {
            // same title for all states
            title[0] = [titles retain];
            title[1] = [titles retain];
            title[2] = [titles retain];
            title[3] = [titles retain];
        }
        [self setTitle:title[0] forState: UIControlStateNormal];
    }
    
    return self;
}

- (id)initWithType:(KBKeyType)keyType scancode:(int)keyScancode position:(CGPoint)position images:(NSDictionary*)keyImages {
    CGRect  myFrame;
    int     i;
    NSArray *keysUp = [keyImages objectForKey:@"up"];
    NSArray *keysDown = [keyImages objectForKey:@"down"];
    NSArray *keysHold = [keyImages objectForKey:@"hold"];
    
    // calculate frame
    myFrame.origin = position;
    myFrame.size = [[[keyImages objectForKey:@"up"] objectAtIndex:keyType] size];
    
    // super init
    if ((self = [super initWithFrame:myFrame]) == nil) return nil;
    
    // set key data
    type = keyType;
    scancode = keyScancode;
    isDown = NO;
    
    // set view images
    [self setBackgroundImage:[keysUp objectAtIndex:keyType] forState:0]; // up
    if (IsStickyKey(keyType)) {
        [self setBackgroundImage:[keysHold objectAtIndex:keyType] forState:1]; // down
        [self setBackgroundImage:[keysDown objectAtIndex:keyType] forState:4]; // selected
        [self setBackgroundImage:[keysHold objectAtIndex:keyType] forState:1|4]; // down+selected
    } else if (keyType == KBKey_Toggle) {
        [self setBackgroundImage:[keysDown objectAtIndex:keyType] forState:4]; // selected
    } else {
        [self setBackgroundImage:[keysDown objectAtIndex:keyType] forState:1]; // down
    }
    
    // set other view stuff
    [self setUserInteractionEnabled: YES];
    [self setAutosizesToFit: NO];
    
    // actions
    [self addTarget:self action:@selector(_keyDown:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDownRepeat];
    [self addTarget:self action:@selector(_keyUp:) forControlEvents:UIControlEventTouchDragExit|UIControlEventTouchUpInside|UIControlEventTouchCancel];
    
    return self;
}

- (void) dealloc {
    int i;
    for(i=0;i<4;i++) if (title[i]) [title[i] release];
    [super dealloc];
}

- (void)setMyTitle:(NSInteger)i {
    if (i < 0 || i > 3) return;
    if (title[i] == nil) i = 0;
    [self setTitle:title[i] forState:UIControlStateNormal];
}

- (void)_keyDown:(id)sender {
    isDown = YES;
    [keyboard keyDown:self type:type scancode:scancode];
}

- (void)_keyUp:(id)sender {
    if (isDown) {
        [keyboard keyUp:self type:type scancode:scancode];
        isDown = NO;
    }
}

@end