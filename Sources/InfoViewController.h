// =====================================================================================================================
//  InfoViewController.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@interface InfoViewController : UIViewController <UITextFieldDelegate>
{
	CGFloat					_volume;
	
	IBOutlet UIImageView	*_backgroundImageView;
	IBOutlet UILabel		*_shortRuleLabel;
	IBOutlet UILabel		*_tallRuleLabel;
	IBOutlet UISlider		*_volumeSlider;
}

- (IBAction) beginTouchClickAction: (id) sender;
- (IBAction) doneAction: (id) sender;
- (IBAction) volumeAction: (id) sender;

@end
