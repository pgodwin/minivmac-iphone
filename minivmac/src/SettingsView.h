#import <UIKit/UIKit.h>
#import <UIKit/UISwitch.h>

#define SettingsViewAnimationDuration     0.3

#define SettingsViewFrameHidden           (IPAD()==YES ? CGRectMake(-240.0, 0.0, 240.0, 768.0) : CGRectMake(-240.0, 0.0, 240.0, 320.0))

#define SettingsViewFrameVisible          (IPAD()==YES ? CGRectMake(0.0, 0.0, 240.0, 768.0) : CGRectMake(0.0, 0.0, 240.0, 320.0))

        
typedef enum {
    settingsGroupMouse,
    settingsGroupSound,
    settingsGroupDisk,
    settingsGroupKeyboard,
    
    settingsGroupCount
} SettingsTableGroup;

@interface SettingsView : UIView {
    UINavigationBar     *navBar;
    UITableView         *table;
    UIToolbar           *toolbar;
    NSUserDefaults      *defaults;
    
    NSDictionary        *layouts;
    NSArray             *layoutIDs;
    
    NSMutableArray      *switchPrefKeys;
}

- (void)hide;
- (void)show;
- (UITableViewCell*)cellWithIdentifier:(NSString*)cellIdentifier forTableView:(UITableView*)tableView;
- (UITableViewCell*)switchCellWithTitle:(NSString*)title forPrefsKey:(NSString*)key;
- (void)switchChanged:(UISwitch*)sender;
@end