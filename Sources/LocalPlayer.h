// =====================================================================================================================
//  LocalPlayer.h
// =====================================================================================================================


#import <Foundation/Foundation.h>


@protocol LocalPlayerDelegate;


@interface LocalPlayer : NSObject
{
	NSString			*_playerID;
	NSString			*_alias;
	BOOL				_authenticationCompleted;
	BOOL				_usingGameCenter;
	id					_delegate;
	NSMutableDictionary	*_descriptions;
	BOOL				_descriptionsDirty;
	NSMutableDictionary	*_achievements;
	BOOL				_achievementsDirty;
}

@property(nonatomic,readonly)	NSString		*playerID;				// Only valid if using Game Center and authenticated.
@property(nonatomic,readonly)	NSString		*alias;					// Only valid if using Game Center and authenticated.
@property(nonatomic,readonly)	BOOL			authenticationCompleted;
@property(nonatomic,readonly)	BOOL			usingGameCenter;		// Returns YES if LocalPlayer is from Game Center.
@property(nonatomic,assign)		id <LocalPlayerDelegate>	delegate;	// Delegate called for asynchronous completions.
@property(nonatomic,readonly)	NSDictionary	*achievements;

- (id) init;
- (void) achievementAttained: (NSString *) indentifier percentComplete: (double) percentComplete;
- (double) percentCompletedForAchievement: (NSString *) identifier;
- (void) resetAchievements;

@end


@protocol LocalPlayerDelegate<NSObject>

@optional

- (void) localPlayerInitializationComplete: (LocalPlayer *) player;
- (void) localPlayer: (LocalPlayer *) player loadedImage: (UIImage *) image forAchievement: (NSString *) identifier;
- (void) localPlayer: (LocalPlayer *) player gameCenterFailure: (NSString *) gameCenterAPI error: (NSError *) error;

@end
