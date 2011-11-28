#import "SettingsView.h"
#import "vMacApp.h"

#define kToolbarHeight 32
#define kNavBarHeight 32

@implementation SettingsView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        layouts = [[[vMacApp sharedInstance] availableKeyboardLayouts] retain];
        layoutIDs = [[[layouts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
        defaults = [NSUserDefaults standardUserDefaults];
        switchPrefKeys = [[NSMutableArray arrayWithCapacity:5] retain];
        
        // create nav bar
        navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0, 0.0, frame.size.width, kNavBarHeight)];
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)];
        UIBarButtonItem *button;
        [navBar pushNavigationItem:navItem animated:NO];
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:14 target:self action:@selector(hide)]; // XXX: UIBarButtonSystemItemStop
        [navItem setLeftBarButtonItem:button animated:NO];
        [button release];
        [navItem release];
        [self addSubview: navBar];
        
        // create table
        CGRect tableRect = CGRectMake(0.0, kNavBarHeight, frame.size.width, frame.size.height-kNavBarHeight-kToolbarHeight);
        table = [[UITableView alloc] initWithFrame: tableRect style: 1]; // XXX: UITableViewStyleGrouped
        [table setDelegate: self];
        [table setDataSource: self];
        [self addSubview: table];
        
        CGRect toolbarRect;
        // create toolbar
        if (IPAD() == true)
            toolbarRect = CGRectMake(0.0, 720.0-kToolbarHeight, frame.size.width, kToolbarHeight);
        else
            toolbarRect = CGRectMake(0.0, 320.0-kToolbarHeight, frame.size.width, kToolbarHeight);
        UIBarButtonItem *interruptButton, *resetButton;
        interruptButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PSInterrupt.png"]
                            style:0 target:self action:@selector(macInterrupt)];
        resetButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PSReset.png"]
                            style:0 target:self action:@selector(macReset)];
        toolbar = [[UIToolbar alloc] initWithFrame:toolbarRect];
        toolbar.barStyle = 2; // XXX: UIBarStyleBlackTranslucent
        [toolbar setItems:[NSArray arrayWithObjects:interruptButton, resetButton, nil] animated:NO];
        [interruptButton release];
        [resetButton release];
        [self addSubview:toolbar];
    }
    return self;
}

- (void)dealloc {
    [navBar release];
    [layouts release];
    [layoutIDs release];
    [switchPrefKeys release];
    [super dealloc];
}

- (void)hide {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:SettingsViewAnimationDuration];
    self.frame = SettingsViewFrameHidden;
    [UIView endAnimations];
}

- (void)show {
    NSIndexPath *selectedRow = [table indexPathForSelectedRow];
    if (selectedRow) [table deselectRowAtIndexPath:selectedRow animated:NO];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:SettingsViewAnimationDuration];
    self.frame = SettingsViewFrameVisible;
    [UIView endAnimations];
    [table reloadData];
}

- (void)macInterrupt {
    WantMacInterrupt = YES;
}

- (void)macReset {
    WantMacReset = YES;
}

#if 0
#pragma mark -
#pragma mark Table Delegate
#endif

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return settingsGroupCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
    case settingsGroupKeyboard:
        return [layouts count] + 1;
    case settingsGroupMouse:
        return 1;
    case settingsGroupSound:
        return 3;
    case settingsGroupDisk:
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case settingsGroupKeyboard:
            return NSLocalizedString(@"SettingsKeyboard", nil);
        case settingsGroupMouse:
            return NSLocalizedString(@"SettingsMouse", nil);
        case settingsGroupSound:
            return NSLocalizedString(@"SettingsSound", nil);
        case settingsGroupDisk:
            return NSLocalizedString(@"SettingsDisk", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section+1 < settingsGroupCount) return nil;
    NSString* bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString* bundleLongName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleLongName"];
    return [NSString stringWithFormat:@"%@ %@\n©2008-2011 namedfork.net", bundleLongName, bundleVersion];
}

- (UITableViewCell*)cellWithIdentifier:(NSString*)cellIdentifier forTableView:(UITableView*)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier];
        [cell autorelease];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    UISlider *slider = nil;
    NSInteger group = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (group == settingsGroupKeyboard) {
        if ((row - [layoutIDs count]) == 0) {
            // keyboard alpha
            cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil];
            slider = [[UISlider alloc] initWithFrame: CGRectMake(96.0f, 4.0f, 120.0f, 40.0f)];
            [slider addTarget:self action:@selector(keyboardAlphaChanged:) forControlEvents:UIControlEventValueChanged];
            slider.minimumValue = 0.2;
            slider.maximumValue = 1.0;
            slider.value = [defaults floatForKey:@"KeyboardAlpha"];
            [slider setContinuous:YES];
            cell.text = NSLocalizedString(@"SettingsKeyboardOpacity", nil);
            [cell.contentView addSubview:slider];
            [slider release];
            [cell autorelease];
        } else {
            // keyboard layout
            cell = [self cellWithIdentifier:@"keyboardLayout" forTableView:tableView];
            cell.accessoryType = [[layoutIDs objectAtIndex:row] isEqualToString:[defaults objectForKey:@"KeyboardLayout"]]?3:0; // XXX: UITableViewCellAccessoryCheckmark:None
            cell.text = [layouts objectForKey:[layoutIDs objectAtIndex:row]];
        }
    } else if (group == settingsGroupMouse) {
        cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsMouseTrackpadMode", nil) forPrefsKey:@"TrackpadMode"];
    } else if (group == settingsGroupSound) {
        switch(row) {
        case 0: // mac sound
            cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsSoundEnable", nil) forPrefsKey:@"SoundEnabled"];
            break;
        case 1: // disk eject sound
            cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsSoundDiskEject", nil) forPrefsKey:@"DiskEjectSound"];
            break;
        case 2: // keyboard sound
            cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsKeyboardSound", nil) forPrefsKey:@"KeyboardSound"];
            break;
        }
    } else if (group == settingsGroupDisk) {
        // disk image deletion
        switch(row) {
        case 0:
            cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsDiskDelete", nil) forPrefsKey:@"CanDeleteDiskImages"];
            break;
        case 1:
            cell = [self switchCellWithTitle:NSLocalizedString(@"SettingsDiskIcons", nil) forPrefsKey:@"AutoGenerateDiskIcons"];
            break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == settingsGroupKeyboard && (indexPath.row < [layoutIDs count])) {
        [defaults setObject:[layoutIDs objectAtIndex:indexPath.row] forKey:@"KeyboardLayout"];
        [defaults synchronize];
        [table reloadData];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == settingsGroupKeyboard && (indexPath.row < [layoutIDs count])) return indexPath;
    return nil;
}

- (void)keyboardAlphaChanged:(UISlider*)slider {
    [defaults setFloat:[slider value] forKey:@"KeyboardAlpha"];
    [defaults synchronize];
}

- (UITableViewCell*)switchCellWithTitle:(NSString*)title forPrefsKey:(NSString*)key {
    UITableViewCell * cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(117, 8, 0, 0)];
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];   
    cell.text = title;
    [cell.contentView addSubview:sw];
    [sw setOn:[defaults boolForKey:key] animated:NO];
    if (![switchPrefKeys containsObject:key]) [switchPrefKeys addObject:key];
    sw.tag = [switchPrefKeys indexOfObject:key];
    [sw release];
    return [cell autorelease];
}

- (void)switchChanged:(UISwitch*)sender {
    [defaults setBool:[sender isOn] forKey:[switchPrefKeys objectAtIndex:sender.tag]];
    [defaults synchronize];
}

@end
