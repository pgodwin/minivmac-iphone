#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "vMacApp.h"
#import "NewDiskView.h"

#define InsertDiskViewAnimationDuration     0.3

#define InsertDiskViewFrameHidden           (IPAD()==YES ? \
                                                CGRectMake(1024.0, 0.0, 240.0, 768.0) : \
                                                CGRectMake(480.0, 0.0, 240.0, 320.0))

#define InsertDiskViewFrameVisible          (IPAD()==YES ? \
                                                CGRectMake(1024.0-240.0, 0.0, 240.0, 768.0) : \
                                                CGRectMake(240.0, 0.0, 240.0, 320.0))


@interface InsertDiskView : UIView {
    id <VirtualDiskDrive>   diskDrive;
    NSArray*                diskFiles;
    
    UITableView*            table;
    UINavigationBar*        navBar;
    NewDiskView*            newDisk;
}

@property (nonatomic, assign) id <VirtualDiskDrive> diskDrive;

- (void)hide;
- (void)show;
- (void)findDiskFiles;
- (void)didEjectDisk:(NSNotification *)aNotification;
- (void)didInsertDisk:(NSNotification *)aNotification;
- (UIImage*)iconForDiskImageAtPath:(NSString *)path;
@end