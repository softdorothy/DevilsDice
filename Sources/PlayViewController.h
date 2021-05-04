// =====================================================================================================================
//  PlayViewController.h
// =====================================================================================================================


#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>


@protocol PlayViewDelegate;


@interface PlayViewController : UIViewController
{
	id						_delegate;
	UIView					*_scrollViewSubview;	// Assigned, do not release.
	
	IBOutlet UIImageView	*_backgroundImageView;
	IBOutlet UIView			*_achievementView;
	IBOutlet UIView			*_sansAchievementView;
	IBOutlet UIScrollView	*_achievementScrollView;
	IBOutlet UILabel		*_gamesPlayedLabel0;
	IBOutlet UILabel		*_gamesWonLabel0;
	IBOutlet UILabel		*_gamesPlayedLabel1;
	IBOutlet UILabel		*_gamesWonLabel1;
	IBOutlet UIImageView	*_coinBlank0ImageView;
	IBOutlet UIImageView	*_achievement0ImageView;
	IBOutlet UILabel		*_achievement0TitleLabel;
	IBOutlet UILabel		*_achievement0DescriptionLabel;
	IBOutlet UIImageView	*_coinBlank1ImageView;
	IBOutlet UIImageView	*_achievement1ImageView;
	IBOutlet UILabel		*_achievement1TitleLabel;
	IBOutlet UILabel		*_achievement1DescriptionLabel;
	IBOutlet UIImageView	*_coinBlank2ImageView;
	IBOutlet UIImageView	*_achievement2ImageView;
	IBOutlet UILabel		*_achievement2TitleLabel;
	IBOutlet UILabel		*_achievement2DescriptionLabel;
	IBOutlet UIImageView	*_coinBlank3ImageView;
	IBOutlet UIImageView	*_achievement3ImageView;
	IBOutlet UILabel		*_achievement3TitleLabel;
	IBOutlet UILabel		*_achievement3DescriptionLabel;
	IBOutlet UIImageView	*_coinBlank4ImageView;
	IBOutlet UIImageView	*_achievement4ImageView;
	IBOutlet UILabel		*_achievement4TitleLabel;
	IBOutlet UILabel		*_achievement4DescriptionLabel;
	IBOutlet UIImageView	*_coinBlank5ImageView;
	IBOutlet UIImageView	*_achievement5ImageView;
	IBOutlet UILabel		*_achievement5TitleLabel;
	IBOutlet UILabel		*_achievement5DescriptionLabel;
}

@property (nonatomic,assign)	id <PlayViewDelegate>	delegate;

- (void) updateStatistics: (id) sender;
- (void) enableAchievements: (BOOL) enable;
- (void) displayAchievementEarned: (NSUInteger) index;
- (void) updateAchievementDescription: (GKAchievementDescription *) description atIndex: (NSInteger) index achieved: (BOOL) didIt;
- (void) updateAchievement: (NSDictionary *) achievementDictionary atIndex: (NSInteger) index;
- (IBAction) openGliderInAppStore: (id) sender;
- (IBAction) beginTouchClickAction: (id) sender;
- (IBAction) playerVsPlayerAction: (id) sender;
- (IBAction) playerVsDevilAction: (id) sender;

@end

@protocol PlayViewDelegate<NSObject>

enum
{
	kGamePlayerVsPlayer = 0, 
	kGamePlayerVsDevil = 1
};

- (void) setGameMode: (int) mode;

@end

