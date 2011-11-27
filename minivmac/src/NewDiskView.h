#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern float NewDiskViewAnimationDuration;
extern CGRect NewDiskViewFrameHidden;
extern CGRect NewDiskViewFrameVisible;

@interface NewDiskView : UIView
{
    UINavigationBar*    navBar;
    UILabel*            labels[2];
    UILabel*            sizeLabel;
    UITextField*        nameField;
    UISlider*           sizeSlider;
    UIImageView*        iconView;
}

- (void)hide;
- (void)show;
- (void)sizeSliderChanged:(UISlider*)slider;
- (int)selectedImageSize;
@end

