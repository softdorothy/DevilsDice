// =====================================================================================================================
//  PlayViewController.m
// =====================================================================================================================


#import "InterfaceSounds.h"
#import "PlayViewController.h"
#import "RootViewController.h"


@interface PlayViewController ()
{
	BOOL	_viewLoaded;
	BOOL	_enableAchievements;
}
@end


@implementation PlayViewController
// ================================================================================================== PlayViewController
// --------------------------------------------------------------------------------------------------------- @synthesize

@synthesize delegate = _delegate;

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
// ---------------------------------------------------------------------------------------------------- updateStatistics

- (void) updateStatistics: (id) sender
{
	NSUserDefaults	*defaults;
	NSInteger		played = 0;
	NSInteger		won = 0;
	
	// Skip out if called before views instantiated.
	if (_gamesPlayedLabel0 == nil)
		return;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Update games played.
	if ([defaults objectForKey: @"DevilPlayed"] != nil)
		played = [defaults integerForKey: @"DevilPlayed"];
	_gamesPlayedLabel0.text = [NSString stringWithFormat: @"%d", played];
	_gamesPlayedLabel1.text = [NSString stringWithFormat: @"%d", played];
	
	// Update games won.
	if ([defaults objectForKey: @"DevilWon"] != nil)
		won = [defaults integerForKey: @"DevilWon"];
	if (played != 0)
	{
		_gamesWonLabel0.text = [NSString stringWithFormat: @"%d (%.0f%%)", won, (CGFloat) (won * 100) / played];
		_gamesWonLabel1.text = [NSString stringWithFormat: @"%d (%.0f%%)", won, (CGFloat) (won * 100) / played];
	}
	else
	{
		_gamesWonLabel0.text = @"0";
		_gamesWonLabel1.text = @"0";
	}
}

// -------------------------------------------------------------------------------------------------- enableAchievements

- (void) enableAchievements: (BOOL) enable
{
	// Store.
	_enableAchievements = enable;
	
	// NOP.
	if (_viewLoaded == NO)
		return;
	
	// NOP.
	if (((enable == YES) && (_scrollViewSubview == _achievementView)) ||
			((enable == NO) && (_scrollViewSubview == _sansAchievementView)))
	{
		return;
	}
	
	// Pop off the current scroller content view.
	[_scrollViewSubview removeFromSuperview];
	
	// Make one of our two views the scroll-view content.
	if (enable)
	{
		[_achievementScrollView addSubview: _achievementView];
		_scrollViewSubview = _achievementView;
	}
	else
	{
		[_achievementScrollView addSubview: _sansAchievementView];
		_scrollViewSubview = _sansAchievementView;
	}
	_achievementScrollView.contentSize = _scrollViewSubview.frame.size;
}

// -------------------------------------------------------------------------------------------- displayAchievementEarned

- (void) displayAchievementEarned: (NSUInteger) index
{
	CGRect	bounds;
	
	switch (index)
	{
		case 0:
		bounds = _achievement0ImageView.frame;
		break;
		
		case 1:
		bounds = _achievement1ImageView.frame;
		break;
		
		case 2:
		bounds = _achievement2ImageView.frame;
		break;
		
		case 3:
		bounds = _achievement3ImageView.frame;
		break;
		
		case 4:
		bounds = _achievement4ImageView.frame;
		break;
		
		case 5:
		bounds = _achievement5ImageView.frame;
		break;
		
		default:	// Scroll to top.
		bounds = CGRectMake (0, 0, 16, 16);
		break;
	}
	
	// Scroll to achievement;
	[_achievementScrollView scrollRectToVisible: CGRectInset (bounds, 0, -7) animated: NO];
}

// ------------------------------------------------------------------------------------------ updateAchievementUIAtIndex

- (void) updateAchievementDescription: (GKAchievementDescription *) description atIndex: (NSInteger) index achieved: (BOOL) didIt
{
	UIImageView	*coinBlank;
	UIImageView	*imageView;
	UILabel		*titleLabel;
	UILabel		*descriptionLabel;
	
	switch (index)
	{
		case 0:
		coinBlank = _coinBlank0ImageView;
		imageView = _achievement0ImageView;
		titleLabel = _achievement0TitleLabel;
		descriptionLabel = _achievement0DescriptionLabel;
		break;
		
		case 1:
		coinBlank = _coinBlank1ImageView;
		imageView = _achievement1ImageView;
		titleLabel = _achievement1TitleLabel;
		descriptionLabel = _achievement1DescriptionLabel;
		break;
		
		case 2:
		coinBlank = _coinBlank2ImageView;
		imageView = _achievement2ImageView;
		titleLabel = _achievement2TitleLabel;
		descriptionLabel = _achievement2DescriptionLabel;
		break;
		
		case 3:
		coinBlank = _coinBlank3ImageView;
		imageView = _achievement3ImageView;
		titleLabel = _achievement3TitleLabel;
		descriptionLabel = _achievement3DescriptionLabel;
		break;
		
		case 4:
		coinBlank = _coinBlank4ImageView;
		imageView = _achievement4ImageView;
		titleLabel = _achievement4TitleLabel;
		descriptionLabel = _achievement4DescriptionLabel;
		break;
		
		default:	// 5
		coinBlank = _coinBlank5ImageView;
		imageView = _achievement5ImageView;
		titleLabel = _achievement5TitleLabel;
		descriptionLabel = _achievement5DescriptionLabel;
		break;
	}
	
	// Fetch images for the achievements (they may be hidden below if the achievement was not achieved).
	[description loadImageWithCompletionHandler: ^(UIImage *image, NSError *error)
	{
		if (image != nil)
			imageView.image = image;
	}];
	
	// Set title.
	titleLabel.text = description.title;
	if (didIt)
	{
		// Handle images.
		coinBlank.hidden = NO;
		imageView.hidden = NO;
		
		// Fill in description.
		descriptionLabel.text = description.achievedDescription;
		titleLabel.alpha = 1.0;
		descriptionLabel.alpha = 1.0;
	}
	else
	{
		// Handle images.
		coinBlank.hidden = YES;
		imageView.hidden = YES;
		
		// Fill in description.
		descriptionLabel.text = description.unachievedDescription;
		titleLabel.alpha = 0.5;
		descriptionLabel.alpha = 0.5;
	}
}

// ------------------------------------------------------------------------------------------- updateAchievement:atIndex

- (void) updateAchievement: (NSDictionary *) achievementDictionary atIndex: (NSInteger) index
{
	UIImageView	*coinBlank;
	UIImageView	*imageView;
	UILabel		*titleLabel;
	UILabel		*descriptionLabel;
	NSNumber	*numberValue;
	
	// NOP.
	if (_viewLoaded == NO)
		return;
	
	switch (index)
	{
		case 0:
		coinBlank = _coinBlank0ImageView;
		imageView = _achievement0ImageView;
		titleLabel = _achievement0TitleLabel;
		descriptionLabel = _achievement0DescriptionLabel;
		break;
		
		case 1:
		coinBlank = _coinBlank1ImageView;
		imageView = _achievement1ImageView;
		titleLabel = _achievement1TitleLabel;
		descriptionLabel = _achievement1DescriptionLabel;
		break;
		
		case 2:
		coinBlank = _coinBlank2ImageView;
		imageView = _achievement2ImageView;
		titleLabel = _achievement2TitleLabel;
		descriptionLabel = _achievement2DescriptionLabel;
		break;
		
		case 3:
		coinBlank = _coinBlank3ImageView;
		imageView = _achievement3ImageView;
		titleLabel = _achievement3TitleLabel;
		descriptionLabel = _achievement3DescriptionLabel;
		break;
		
		case 4:
		coinBlank = _coinBlank4ImageView;
		imageView = _achievement4ImageView;
		titleLabel = _achievement4TitleLabel;
		descriptionLabel = _achievement4DescriptionLabel;
		break;
		
		default:	// 5
		coinBlank = _coinBlank5ImageView;
		imageView = _achievement5ImageView;
		titleLabel = _achievement5TitleLabel;
		descriptionLabel = _achievement5DescriptionLabel;
		break;
	}
	
	titleLabel.text = [achievementDictionary objectForKey: @"title"];
	
	numberValue = [achievementDictionary objectForKey: @"percentComplete"];
	if ((numberValue) && ([numberValue doubleValue] > 0))
	{
		coinBlank.hidden = NO;
		imageView.hidden = NO;
		descriptionLabel.text = [achievementDictionary objectForKey: @"achievedDescription"];
	}
	else
	{
		coinBlank.hidden = YES;
		imageView.hidden = YES;
		descriptionLabel.text = [achievementDictionary objectForKey: @"unachievedDescription"];
	}
	
	imageView.image = [achievementDictionary objectForKey: @"image"];
}

// ------------------------------------------------------------------------------------------------ openGliderInAppStore

- (void) openGliderInAppStore: (id) sender
{
	[[UIApplication sharedApplication] openURL: 
			[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/glider-classic/id463484447?mt=8"]];
}

// ----------------------------------------------------------------------------------------------- beginTouchClickAction

- (void) beginTouchClickAction: (id) sender
{
	[[InterfaceSounds sharedInterfaceSounds] buttonPressed];
}

// ------------------------------------------------------------------------------------------------ playerVsPlayerAction

- (void) playerVsPlayerAction: (id) sender
{
	[[InterfaceSounds sharedInterfaceSounds] buttonReleased];
	
	// Indicate player choice.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (setGameMode:)]))
		[_delegate setGameMode: kGamePlayerVsPlayer];
	
	// Dismiss view.
	[self dismissModalViewControllerAnimated: YES];
}

// ------------------------------------------------------------------------------------------------- playerVsDevilAction

- (void) playerVsDevilAction: (id) sender
{
	[[InterfaceSounds sharedInterfaceSounds] buttonReleased];
	
	// Indicate player choice.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (setGameMode:)]))
		[_delegate setGameMode: kGamePlayerVsDevil];
	
	// Dismiss view.
	[self dismissModalViewControllerAnimated: YES];
}

#pragma mark ----- View Lifecycle
// --------------------------------------------------------------------------------------------------------- viewDidLoad

- (void) viewDidLoad
{
	// Super.
	[super viewDidLoad];
	
	_viewLoaded = YES;
	
	// Adjust background image and scroll view for iPhone5 height.
	if (CGRectGetHeight ([UIScreen mainScreen].bounds) == 568)
	{
		_backgroundImageView.image = [UIImage imageNamed: @"PlayBackground-568h"];
		
		CGRect frame = _achievementScrollView.frame;
		frame.size.height += 88.0;
		_achievementScrollView.frame = frame;
	}
	
	// Update stats.
	[self updateStatistics: self];
	
	// Set UIScrollView properties.
	[_achievementScrollView addSubview: _sansAchievementView];
	_scrollViewSubview = _sansAchievementView;
	_achievementScrollView.contentSize = _scrollViewSubview.frame.size;
	_achievementScrollView.bounces = NO;
}

// ------------------------------------------------------------------------------------------------------ viewWillAppear

- (void) viewWillAppear: (BOOL) animated
{
	[self enableAchievements: _enableAchievements];
	
	// Populate achievement descriptions.
	if ([self respondsToSelector: @selector(presentingViewController)])
		[(RootViewController *)[self presentingViewController] updatePlayerViewAchievementUI];
	else
		[(RootViewController *)[self parentViewController] updatePlayerViewAchievementUI];
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
