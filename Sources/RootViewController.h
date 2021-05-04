// =====================================================================================================================
//  RootViewController.h
// =====================================================================================================================


#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "Clock.h"
#import "LocalPlayer.h"
#import "PlayViewController.h"


@class InfoViewController;


@interface RootViewController : UIViewController <ADBannerViewDelegate, ClockDelegate, LocalPlayerDelegate, PlayViewDelegate>
{
	int							_gameMode;
	int							_gameState;
	int							_playerSafeScore;
	int							_playerJeopardizedScore;
	int							_opponentSafeScore;
	int							_opponentJeopardizedScore;
	BOOL						_playersTurn;
	
	int							_trackingControl;
	CGPoint						_trackingOffset;
	CGFloat						_wasValue;
	BOOL						_hitSliderLimit;
	
	CGFloat						_turnLeverVelocity;
	CGFloat						_turnLeverDestination;
	int							_turnLeverMoveDelayCounter;
	
	UIImageView					*_dieWheel;
	int							_wheelState;
	int							_wheelCounter;
	CGFloat						_wheelPosition;
	CGFloat						_wheelVelocity;
	
	NSUInteger					_indicatorCounter;
	
	int							_devilState;
	NSUInteger					_devilWaitCounter;
	CGFloat						_rollLeverVelocity;
	
	int							_gameOverState;
	int							_gameOverCounter;
	
	LocalPlayer					*_localPlayer;
	NSMutableDictionary			*_playerAchievements;
	NSUInteger					_achievementEarned;
	
	BOOL						_beginGameWhenViewAppears;
	
	ADBannerView				*_bannerView;

	IBOutlet PlayViewController	*_playController;
	IBOutlet InfoViewController	*_infoController;
	
	IBOutlet UIImageView		*_backgroundImageView;
	IBOutlet UIImageView		*_baseWinnerView;
	IBOutlet UIImageView		*_smallHandle;
	IBOutlet UIImageView		*_largeHandle;
	IBOutlet UIImageView		*_handleShaft;
	IBOutlet UIImageView		*_shaftMaskView;
	IBOutlet UIImageView		*_handleShadow;
	IBOutlet UIImageView		*_dieWheel0;
	IBOutlet UIImageView		*_dieWheel16;
	IBOutlet UIImageView		*_primaryIndicatorLeft;
	IBOutlet UIImageView		*_primaryIndicatorRight;
	IBOutlet UIImageView		*_secondaryIndicatorLeft;
	IBOutlet UIImageView		*_secondaryIndicatorRight;
	IBOutlet UIImageView		*_achievementUnlockedView;
}

- (void) updatePlayerViewAchievementUI;
- (BOOL) hasSavedGame;
- (void) restoreSavedGame;
- (IBAction) beginTouchClickAction: (id) sender;
- (IBAction) infoAction: (id) sender;
- (void) playAction: (id) sender;
- (void) setup: (BOOL) displayAds;

- (void) setGameMode: (int) mode;

- (void) beginGameWhenViewAppears;

@end
