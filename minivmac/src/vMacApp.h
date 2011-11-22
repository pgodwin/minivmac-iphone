#import <Foundation/Foundation.h>
//#import <Foundation/NSTask.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIAlertView.h>
#import <AudioToolbox/AudioToolbox.h>
#import "KeyboardView.h"

#import "SYSDEPNS.h"
#import "MYOSGLUE.h"
#import "PROGMAIN.h"
#import "DATE2SEC.h"
#import "CNFGGLOB.h"

#define kMacEpoch 2082844800
#define MyTickDuration (1/60.14742)

#define PointDistanceSq(a, b) ((((int)a.h-(int)b.h)*((int)a.h-(int)b.h)) + (((int)a.v-(int)b.v)*((int)a.v-(int)b.v)))
#define CGPointCenter(a, b) CGPointMake((a.x+b.x)/2, (a.y+b.y)/2)
#define MOUSE_DBLCLICK_TIME     0.55    // seconds, NSTimeInterval
#define MOUSE_CLICK_DELAY       0.05    // seconds, NSTimeInterval
#define TRACKPAD_CLICK_DELAY    0.30    // seconds, NSTimeInterval
#define TRACKPAD_CLICK_TIME     0.30    // if finger is held down for longer, it's not a click
#define TRACKPAD_DRAG_DELAY     0.50    // two fast taps to engage in draggnig
#define TRACKPAD_ACCEL_N        1
#define TRACKPAD_ACCEL_T        0.2
#define TRACKPAD_ACCEL_D        20
#define MOUSE_LOC_THRESHOLD     500     // pixel distance in mac screen, squared, integer
#define kScreenEdgeSize         20      // edge size for scrolling
#define kScreenRectFullScreen   CGRectMake(0.f, 0.f, 480.f, 320.f)
#define kScreenRectRealSize     CGRectMake(0.f, 0.f, vMacScreenWidth, vMacScreenHeight)

#undef ABS
#define ABS(x) (((x)>0)? (x) : -(x))

#undef CLAMP
#define CLAMP(x, lo, hi) (((x) > (hi))? (hi) : (((x) < (lo))? (lo) : (x)))

typedef enum Direction {
    dirUp =     1 << 0,
    dirDown =   1 << 1,
    dirLeft =   1 << 2,
    dirRight =  1 << 3
} Direction;

@protocol VirtualDiskDrive
- (BOOL)diskIsInserted:(NSString*)path;
- (BOOL)insertDisk:(NSString*)path;
- (short)readFromDrive:(short)drive start:(unsigned long)start count:(unsigned long*)count buffer:(void*)buffer;
- (short)writeToDrive:(short)drive start:(unsigned long)start count:(unsigned long*)count buffer:(void*)buffer;
- (short)sizeOfDrive:(short)drive count:(unsigned long*)count;
- (BOOL)ejectDrive:(short)drive;
- (BOOL)createDiskImage:(NSString*)name size:(int)size;
#ifdef IncludeSonyGetName
- (NSString*)nameOfDrive:(short)drive;
#endif
#ifdef IncludeSonyNew
- (BOOL)ejectAndDeleteDrive:(short)drive;
#endif
@property (nonatomic, readonly) NSInteger insertedDisks;
@property (nonatomic, readonly) BOOL canCreateDiskImages;
@property (nonatomic, readonly) NSString * pathToDiskImages;
@end

@protocol VirtualMouse
- (void)setMouseButton:(BOOL)pressed;
- (void)setMouseButtonDown;
- (void)setMouseButtonUp;
- (void)setMouseLoc:(Point)mouseLoc button:(BOOL)pressed;
- (void)setMouseLoc:(Point)mouseLoc;
- (void)moveMouse:(Point)mouseMotion;
- (void)moveMouse:(Point)mouseMotion button:(BOOL)pressed;
- (Point)mouseLoc;
- (BOOL)mouseButton;
@end

@class MainView;
@interface vMacApp : UIApplication <VirtualKeyboard, VirtualMouse, VirtualDiskDrive>
{
    UIWindow*   window;
    MainView*   mainView;
    BOOL        initOk, isRetinaDisplay;
    
    NSUserDefaults* defaults;
    NSMutableSet*   openAlerts;
    NSFileHandle*   drives[NumDrives];
    NSString*       drivePath[NumDrives];
    NSData*         romData;
    NSArray*        searchPaths;
    SystemSoundID   ejectSound;
    
    CFRunLoopTimerRef   tickTimer;
    CFAbsoluteTime      aTimeBase;
    ui5b                timeSecBase;
    
    // disk image creation
    FILE * newImageFile;
    int newImageSize;
    //UIModalView * newImageProgress;
    
    // graphics stuff
    CGColorSpaceRef rgbColorSpace;
    
    // icon generator
    //NSTask      *iconTask;
}

+ (vMacApp*)sharedInstance;
- (BOOL)isRetinaDisplay;

- (NSArray*)searchPaths;
- (NSString*)defaultSearchPath;
- (void)initPreferences;
- (void)didChangePreferences:(NSNotification *)aNotification;
- (void)warnMessage:(NSString *)message title:(NSString *)title;
- (void)warnMessage:(NSString *)message;
- (BOOL)initDrives;
- (BOOL)loadROM;
- (NSDictionary*)availableKeyboardLayouts;
- (void)startEmulation:(id)sender;
- (BOOL)initEmulation;
- (void)suspendEmulation;
- (void)resumeEmulation;
- (NSArray*)availableDiskImages;
- (void)createDiskIcons:(NSNumber*)force;
- (void)stopCreatingDiskIcons;
- (BOOL)diskImageHasIcon:(NSString*)path;
- (void)writeDiskImageThread;
- (UIImage*)screenImage;
- (BOOL)setSuspendedIcon;
@end


#ifndef RomFileName
#if CurEmu <= kEmu512K
#define RomFileName "Mac128K.ROM"
#elif CurEmu <= kEmuPlus
#define RomFileName "vMac.ROM"
#elif CurEmu <= kEmuSE
#define RomFileName "MacSE.ROM"
#elif CurEmu <= kEmuClassic
#define RomFileName "Classic.ROM"
#else
#error "RomFileName not defined"
#endif
#endif

extern vMacApp* _vmacAppSharedInstance;
extern NSInteger numInsertedDisks;
extern blnr SpeedStopped;
extern short* SurfaceScrnBuf;
extern short* pixelConversionTable;
extern id _gScreenView;
extern ui5b MacDateDiff;
extern ui5b CurEmulatedTime;

bool MySound_Init (void);
GLOBALPROC MySound_Start (void);
GLOBALPROC MySound_Stop (void);
void runTick (CFRunLoopTimerRef timer, void* info);
void StartUpTimeAdjust (void);
