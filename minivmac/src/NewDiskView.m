#import "NewDiskView.h"
#import "vMacApp.h"

float NewDiskViewAnimationDuration = 0.3;
CGRect NewDiskViewFrameHidden = {{0.0, -158.0}, {480.0, 158.0}};
CGRect NewDiskViewFrameVisible = {{0.0, 0.0}, {480.0, 158.0}};

@implementation NewDiskView
- (id)initWithFrame:(CGRect)rect {
    if ((self = [super initWithFrame: rect]) != nil) {
        self.backgroundColor = [UIColor whiteColor];
        
        // create nav bar
        navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 0.0, rect.size.width, 48.0)];
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"NewDiskImageTitle", nil)];
        UIBarButtonItem *button;
        // cancel
        button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",nil) style:1 target:self action:@selector(hide)]; // XXX: UIBarButtonItemStyleBordered
        [navItem setLeftBarButtonItem:button animated:NO];
        [button release];
        // create
        button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CreateDiskImage",nil) style:2 target:self action:@selector(createDiskImage)]; // XXX: UIBarButtonItemStyleDone
        [navItem setRightBarButtonItem:button animated:NO];
        [button release];
        // nav bar
        [navBar pushNavigationItem:navItem animated:NO];
        [navItem autorelease];
        [self addSubview: navBar];
        
        // create labels
        labels[0] = [[UILabel alloc] initWithFrame:CGRectMake(20, 63, 80, 21)];
        labels[0].text = NSLocalizedString(@"Name:", nil);
        [self addSubview:labels[0]];
        labels[1] = [[UILabel alloc] initWithFrame:CGRectMake(20, 104, 80, 21)];
        labels[1].text = NSLocalizedString(@"Size:", nil);
        [self addSubview:labels[1]];
        sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(380, 104, 80, 21)];
        [self addSubview:sizeLabel];
        
        // icon view
        iconView = [[UIImageView alloc] initWithFrame:CGRectMake(380, 57, 32, 32)];
        [self addSubview:iconView];
        
        // name field
        nameField = [[UITextField alloc] initWithFrame:CGRectMake(108, 60, 264, 31)];
        [nameField setBorderStyle:3]; // XXX: UITextBorderStyleRoundedRect
        [self addSubview:nameField];
        
        // size slider
        sizeSlider = [[UISlider alloc] initWithFrame:CGRectMake(106, 104, 268, 23)];
        [sizeSlider addTarget:self action:@selector(sizeSliderChanged:) forControlEvents:UIControlEventValueChanged];
        sizeSlider.minimumValue = 0.0;
        sizeSlider.maximumValue = 50.0;
        sizeSlider.value = 3.0;
        [sizeSlider setContinuous:YES];
        [self addSubview: sizeSlider];

    }
    return self;
}

- (void)dealloc {
    [navBar release];
    for(int i=0; i < (sizeof labels/sizeof labels[0]); i++)
        [labels[i] release];
    [sizeLabel release];
    [nameField release];
    [sizeSlider release];
    [iconView release];
    [super dealloc];
}

- (void)hide {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:NewDiskViewAnimationDuration];
    self.frame = NewDiskViewFrameHidden;
    [nameField resignFirstResponder];
    [UIView endAnimations];
}

- (void)show {
    //[[UIKeyboard activeKeyboard] prepareForGeometryChange];
    [self sizeSliderChanged:sizeSlider];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:NewDiskViewAnimationDuration];
    self.frame = NewDiskViewFrameVisible;
    [nameField becomeFirstResponder];
    [UIView endAnimations];
}

- (void)createDiskImage {
    nameField.text = [nameField.text stringByReplacingOccurrencesOfString:@"/" withString:@":"];
    [[vMacApp sharedInstance] createDiskImage:nameField.text size:[self selectedImageSize]];
}

#if 0
#pragma mark -
#pragma mark Slider Delegate
#endif

- (void)sizeSliderChanged:(UISlider*)slider {
    // round value to allowed values
    int value = round(slider.value);
    if (value < 3) value = 0; // 400K
    else if (value < 8) value = 4; // 800K
    else if (value < 11) value = 10; // 1440K
    slider.value = value;
    
    // set text
    int imageSize = [self selectedImageSize];
    NSString * sizeString;
    if (imageSize < 2048) sizeString = [NSString stringWithFormat:@"%d KiB", imageSize];
    else sizeString = [NSString stringWithFormat:@"%d MiB", imageSize/1024];
    sizeLabel.text = sizeString;
    
    // set icon
    if (imageSize <= 1440) iconView.image = [UIImage imageNamed:@"DiskListFloppy.png"];
    else iconView.image = [UIImage imageNamed:@"DiskListHD.png"];
}

- (int)selectedImageSize {
    int value = [sizeSlider value];
    
    // calculate image size
    int imageSize; // KiB
    if (value <= 9)
        imageSize = (400 + value*100);
    else if (value == 10)
        imageSize = 1440;
    else if (value <= 29)
        imageSize = (value - 9) * 1024;
    else
        imageSize = (25 + 5*(value-30)) * 1024;
    
    return imageSize;
}

@end
