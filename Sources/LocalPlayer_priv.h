// =====================================================================================================================
//  LocalPlayer_priv.h
// =====================================================================================================================


#import "LocalPlayer.h"


@interface LocalPlayer (LocalPlayer_priv)

- (BOOL) gameCenterAPIAvailable;
- (BOOL) needAchievementDescriptions: (NSArray *) gameCenterAchievements;
- (void) reportAchievementForIdentifier: (NSString *) indentifier percentComplete: (double) percentComplete;
- (void) mergeLocalAchievementsWithGameCenter: (NSArray *) gameCenterAchievements;
- (void) mergeLocalAchievementDescriptionsWithGameCenter: (NSArray *) descriptions;
- (void) completedInitialization;
- (void) unflattenAchievementImages;

- (void) loadAchievementsFromGameCenter;
- (void) storeLocalAchievements;
- (void) loadLocalAchievementDescriptions;
- (void) storeLocalAchievementDescriptions;
- (void) authenticateLocalPlayer;

@end
