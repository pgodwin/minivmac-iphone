#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define SBCustomIconAvailable (class_respondsToSelector(objc_getClass("UIApplication"), @selector(hasCustomIcon)))

@interface UIApplication (SBCustomIcon)
- (BOOL)hasCustomIcon;
- (NSString*)pathForCustomIcon;
- (BOOL)setCustomIcon:(UIImage*)customIcon;
- (BOOL)setCustomIconFile:(NSString*)customIconPath;
- (void)removeCustomIcon;
@end