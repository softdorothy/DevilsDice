// =====================================================================================================================
//  InfoViewController.m
// =====================================================================================================================


#import "InfoViewController.h"
#import "InterfaceSounds.h"
#import "SimpleAudioEngine.h"


@implementation InfoViewController
// ================================================================================================== InfoViewController
// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	[super dealloc];
}

// --------------------------------------------------------------------------------------------- didReceiveMemoryWarning

- (void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark ----- Actions
// ----------------------------------------------------------------------------------------------- beginTouchClickAction

- (void) beginTouchClickAction: (id) sender
{
	[[InterfaceSounds sharedInterfaceSounds] buttonPressed];
}

// ---------------------------------------------------------------------------------------------------------- doneAction

- (void) doneAction: (id) sender
{
	// Save to prefs.
	[[NSUserDefaults standardUserDefaults] setFloat: _volume forKey: @"Volume"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[InterfaceSounds sharedInterfaceSounds] buttonReleased];
	[self dismissModalViewControllerAnimated: YES];
}

// -------------------------------------------------------------------------------------------------------- volumeAction

- (void) volumeAction: (id) sender
{
	// Get the volume.
	_volume = [(UISlider *) sender value];
	
	[[SimpleAudioEngine sharedEngine] setEffectsVolume: _volume];
	
	// Play a sample sound.
	[[InterfaceSounds sharedInterfaceSounds] sampleSound];
}

#pragma mark ----- View Lifecycle
// --------------------------------------------------------------------------------------------------------- viewDidLoad

- (void) viewDidLoad
{
	// Super.
	[super viewDidLoad];
	
	// Adjust background image and scroll view for iPhone5 height.
	if (CGRectGetHeight ([UIScreen mainScreen].bounds) == 568)
	{
		_backgroundImageView.image = [UIImage imageNamed: @"InfoBackground-568h"];
		_shortRuleLabel.hidden = YES;
	}
	else
	{
		_tallRuleLabel.hidden = YES;
	}
	
	[_volumeSlider setThumbImage: [UIImage imageNamed: @"SliderThumb"] forState: UIControlStateNormal];
	[_volumeSlider setMinimumTrackImage: [[UIImage imageNamed: @"SliderLeft"] stretchableImageWithLeftCapWidth: 5 topCapHeight: 11] forState: UIControlStateNormal];
	[_volumeSlider setMaximumTrackImage: [[UIImage imageNamed: @"SliderRight"] stretchableImageWithLeftCapWidth: 1 topCapHeight: 11] forState: UIControlStateNormal];
	
	_volumeSlider.value = [[SimpleAudioEngine sharedEngine] effectsVolume];
}

// ------------------------------------------------------------------------------------------------------- viewDidUnload

- (void) viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

// ------------------------------------------------------------------------------ shouldAutorotateToInterfaceOrientation

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) orientation
{
	// Return YES for supported orientations.
	return UIInterfaceOrientationIsPortrait (orientation);
}

@end
