// =====================================================================================================================
//  LocalPlayer.m
// =====================================================================================================================


#define DEBUG_LOCAL_PLAYER		0


#import <AssertMacros.h>
#import <GameKit/GameKit.h>
#import "LocalPlayer_priv.h"


@implementation LocalPlayer
// ========================================================================================================= LocalPlayer
// --------------------------------------------------------------------------------------------------------- @synthesize

@synthesize playerID = _playerID;
@synthesize alias = _alias;
@synthesize authenticationCompleted = _authenticationCompleted;
@synthesize usingGameCenter = _usingGameCenter;
@synthesize delegate = _delegate;

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	id		myself = nil;
	
	if ((self = [super init]))
	{
		// Create instance variables.
		_playerID = nil;
		_alias = nil;
		_authenticationCompleted = NO;
		_usingGameCenter = NO;
		_delegate = nil;
		_descriptions = [[NSMutableDictionary alloc] initWithCapacity: 3];
		_descriptionsDirty = NO;
		_achievements = [[NSMutableDictionary alloc] initWithCapacity: 3];
		_achievementsDirty = NO;
		
		// Try to authenticate local player with Game Center (if avail).
		[self authenticateLocalPlayer];
		
		// Success.
		myself = self;
	}
	
	return myself;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Write out achievements and descriptions if modified.
	[self storeLocalAchievements];
	[self storeLocalAchievementDescriptions];
	
	// Release instance vars.
	[_playerID release];
	[_alias release];
	[_descriptions release];
	[_achievements release];
	
	// Super.
	[super dealloc];
}

// --------------------------------------------------------------------------------------------- achievementDescriptions

- (NSDictionary *) achievements
{
	NSMutableDictionary	*clientAchievements;
	NSArray				*descriptionKeys;
	
	// Write out achievements and descriptions if modified.
	[self storeLocalAchievements];
	[self storeLocalAchievementDescriptions];
	
	// Start by making a copy of our descriptions dictionary.
	clientAchievements = [NSMutableDictionary dictionaryWithDictionary: _descriptions];
	
	// Unflatten images.
	descriptionKeys = [clientAchievements allKeys];
	for (NSString *identifier in descriptionKeys)
	{
		NSDictionary	*localDescription;
		NSData			*imageData;
		
		// Get our local achievement dictionary.
		localDescription = [clientAchievements objectForKey: identifier];
		if (localDescription == nil)
			continue;
		
		imageData = [localDescription objectForKey: @"imageData"];
		if (imageData)
		{
			NSMutableDictionary	*newDescription;
			
			// Create new dictionary.
			newDescription = [NSMutableDictionary dictionaryWithDictionary: localDescription];
			
			// Unflatten the image.
			[newDescription setObject: [UIImage imageWithData: imageData] forKey: @"image"];
			[newDescription removeObjectForKey: @"imageData"];
			
			// Assign back to our client achievements.
			[clientAchievements setObject: newDescription forKey: identifier];
		}
	}
	
	// Merge acheivements.
	for (NSString *identifier in descriptionKeys)
	{
		NSDictionary		*localDescription;
		NSDictionary		*achievement;
		id					percentComplete = nil;
		NSMutableDictionary	*newDescription;
		
		// Get the client achievement dictionary.
		localDescription = [clientAchievements objectForKey: identifier];
		if (localDescription == nil)
			continue;
		
		// Create new dictionary.
		newDescription = [NSMutableDictionary dictionaryWithDictionary: localDescription];
		
		achievement = [_achievements objectForKey: identifier];
		if (achievement)
			percentComplete = [achievement objectForKey: @"percentComplete"];
		
		if (percentComplete)
			[newDescription setObject: percentComplete forKey: @"percentComplete"];
		else
			[newDescription setObject: [NSNumber numberWithDouble: 0] forKey: @"percentComplete"];
		
		// Assign back to our client achievements.
		[clientAchievements setObject: newDescription forKey: identifier];
	}
	
	return clientAchievements;
}

// --------------------------------------------------------------------------------- achievementAttained:percentComplete

- (void) achievementAttained: (NSString *) indentifier percentComplete: (double) percentComplete
{
	NSDictionary		*localAchievement;
	NSMutableDictionary	*newAchievement;
	
	// We have to have been authenticated already.
	if (_authenticationCompleted == NO)
		goto bail;
	
	// Store locally.
	localAchievement = [_achievements objectForKey: indentifier];
	if (localAchievement)
		newAchievement = [NSMutableDictionary dictionaryWithDictionary: localAchievement];
	else
		newAchievement = [NSMutableDictionary dictionaryWithCapacity: 1];
	[newAchievement setObject: [NSNumber numberWithDouble: percentComplete] forKey: @"percentComplete"];
	[_achievements setObject: newAchievement forKey: indentifier];
	_achievementsDirty = YES;
	
	// Report to Game Center.
	if (_usingGameCenter)
		[self reportAchievementForIdentifier: indentifier percentComplete: percentComplete];
	
bail:
	
	return;
}

// -------------------------------------------------------------------------------------- percentCompletedForAchievement

- (double) percentCompletedForAchievement: (NSString *) identifier;
{
	NSDictionary	*localAchievement;
	double			percent = 0;
	
	// We have to have been authenticated already.
	if (_authenticationCompleted == NO)
		goto bail;
	
	// Get our local achievement.
	localAchievement = [_achievements objectForKey: identifier];
	if (localAchievement)
	{
		NSNumber	*percentValue;
		
		// Find the 'percentComplete' property.
		percentValue = [localAchievement objectForKey: @"percentComplete"];
		if (percentValue)
			percent = [percentValue doubleValue];
	}
	
bail:
	
	return percent;
}

// --------------------------------------------------------------------------------------------------- resetAchievements

- (void) resetAchievements
{
	// We have to have been authenticated already.
	if (_authenticationCompleted == NO)
		goto bail;
	
	// Clear achievements dictionary.
	[_achievements removeAllObjects];
	_achievementsDirty = YES;
	[self storeLocalAchievements];
	
	// Go to Game Center and clear our achievements.
	if (_usingGameCenter)
	{
		[GKAchievement resetAchievementsWithCompletionHandler: ^(NSError *error)
		{
			if (error != nil)
			{
				if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:gameCenterFailure:error:)]))
					[_delegate localPlayer: self gameCenterFailure: @"resetAchievementsWithCompletionHandler" error: error];
			}
		}];
	}
	
bail:
	
	return;
}

@end


@implementation LocalPlayer (LocalPlayer_priv)
// ====================================================================================== LocalPlayer (LocalPlayer_priv)
// ---------------------------------------------------------------------------------------------- gameCenterAPIAvailable

- (BOOL) gameCenterAPIAvailable
{
	BOOL		localPlayerClassAvailable;
	NSString	*requiredSystemVersion = @"4.1";
	NSString	*currentSystemVersion;
	BOOL		osVersionSupported;
	
	localPlayerClassAvailable = (NSClassFromString (@"GKLocalPlayer") != nil);
	currentSystemVersion = [[UIDevice currentDevice] systemVersion];
	osVersionSupported = ([currentSystemVersion compare: requiredSystemVersion options: NSNumericSearch] != NSOrderedAscending);
	
	return (localPlayerClassAvailable && osVersionSupported);
}

// ----------------------------------------------------------------------------------------- needAchievementDescriptions

- (BOOL) needAchievementDescriptions: (NSArray *) gameCenterAchievements
{
	BOOL	needDescription = NO;
	
	for (GKAchievement *oneAchievement in gameCenterAchievements)
	{
		NSDictionary	*localDescription;
		
		// See if we need a 
		localDescription = [_descriptions objectForKey: oneAchievement.identifier];
		if (localDescription)
		{
			// Determine if any fields are missing.
			if (([localDescription objectForKey: @"title"] == nil) || 
					([localDescription objectForKey: @"achievedDescription"] == nil) || 
					([localDescription objectForKey: @"unachievedDescription"] == nil) || 
					([localDescription objectForKey: @"maximumPoints"] == nil) || 
					([localDescription objectForKey: @"imageData"] == nil))
			{
				needDescription = YES;
			}
		}
		else
		{
			// We'll need a complete description.
			needDescription = YES;
		}
	}
	
#if DEBUG_LOCAL_PLAYER
	if (needDescription)
		printf ("needAchievementDescriptions: YES\n");
#endif	// DEBUG_LOCAL_PLAYER
	
	return needDescription;
}

// ---------------------------------------------------------------------- reportAchievementForIdentifier:percentComplete

- (void) reportAchievementForIdentifier: (NSString *) indentifier percentComplete: (double) percentComplete
{
	GKAchievement	*achievement;
	
	// Sanity check.
	if ((_authenticationCompleted == NO) || (_usingGameCenter == NO))
		goto bail;
	
	// Create object to report score. Assign points.
	achievement = [[[GKAchievement alloc] initWithIdentifier: indentifier] autorelease];
	if (achievement)
	{
		// Report score.
		achievement.percentComplete = percentComplete;
		[achievement reportAchievementWithCompletionHandler: ^(NSError *error)
		{
			if (error != nil)
			{
				if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:gameCenterFailure:error:)]))
					[_delegate localPlayer: self gameCenterFailure: @"reportAchievementWithCompletionHandler" error: error];
			}
		}];
	}
	
bail:
	
	return;
}

// -------------------------------------------------------------------------------- mergeLocalAchievementsWithGameCenter

- (void) mergeLocalAchievementsWithGameCenter: (NSArray *) gameCenterAchievements
{
	for (GKAchievement *oneAchievement in gameCenterAchievements)
	{
		NSDictionary	*localAchievement;
		
		localAchievement = [_achievements objectForKey: oneAchievement.identifier];
		if (localAchievement)
		{
			NSNumber	*percentValue;
			double		localPercent = 0;
			
			// If we have a precent-completed value, get it.
			percentValue = [localAchievement objectForKey: @"percentComplete"];
			if (percentValue)
				localPercent = [percentValue doubleValue];
			
			// Is our local data out of date?
			if ((percentValue == nil) || (oneAchievement.percentComplete != localPercent))
			{
				NSMutableDictionary	*newAchievement;
				
				// Create new dictionary.
				newAchievement = [NSMutableDictionary dictionaryWithDictionary: localAchievement];
				
				// Add or replace (if greater) achievement properties with those from the Game Center.
				if (oneAchievement.percentComplete > localPercent)
					[newAchievement setObject: [NSNumber numberWithDouble: oneAchievement.percentComplete] forKey: @"percentComplete"];
				else if (localPercent > oneAchievement.percentComplete)
					[self reportAchievementForIdentifier: oneAchievement.identifier percentComplete: localPercent];
				
				// Assign back to our local achievements.
				[_achievements setObject: newAchievement forKey: oneAchievement.identifier];		
				_achievementsDirty = YES;
#if DEBUG_LOCAL_PLAYER
				printf ("mergeLocalAchievementsWithGameCenter: merged achievement = %s\n", [[oneAchievement description] cStringUsingEncoding: NSUTF8StringEncoding]);
#endif	// DEBUG_LOCAL_PLAYER
			}
		}
		else
		{
			NSMutableDictionary	*newAchievement;
			
			// Create new dictionary.
			newAchievement = [NSMutableDictionary dictionaryWithCapacity: 1];
			
			// Copy over achievement property.
			[newAchievement setObject: [NSNumber numberWithDouble: oneAchievement.percentComplete] forKey: @"percentComplete"];
			
			// Assign back to our local achievements.
			[_achievements setObject: newAchievement forKey: oneAchievement.identifier];		
			_achievementsDirty = YES;
			
#if DEBUG_LOCAL_PLAYER
			printf ("mergeLocalAchievementsWithGameCenter: created achievement = %s\n", [[oneAchievement description] cStringUsingEncoding: NSUTF8StringEncoding]);
#endif	// DEBUG_LOCAL_PLAYER
		}
	}
}

// --------------------------------------------------------------------- mergeLocalAchievementDescriptionsWithGameCenter

- (void) mergeLocalAchievementDescriptionsWithGameCenter: (NSArray *) descriptions
{
	for (GKAchievementDescription *oneDescription in descriptions)
	{
		NSDictionary		*localDescription;
		NSMutableDictionary	*newDescription;
		
		// Get our local achievement dictionary or create one if missing.
		localDescription = [_descriptions objectForKey: oneDescription.identifier];
		if (localDescription == nil)
			newDescription = [NSMutableDictionary dictionaryWithCapacity: 3];
		else
			newDescription = [NSMutableDictionary dictionaryWithDictionary: localDescription];
		
		// Copy achievement description properties.
		[newDescription setObject: oneDescription.title forKey: @"title"];
		[newDescription setObject: oneDescription.achievedDescription forKey: @"achievedDescription"];
		[newDescription setObject: oneDescription.unachievedDescription forKey: @"unachievedDescription"];
		[newDescription setObject: [NSNumber numberWithInteger: oneDescription.maximumPoints] forKey: @"maximumPoints"];
		
		// Assign back to our local achievements.
		[_descriptions setObject: newDescription forKey: oneDescription.identifier];
		_descriptionsDirty = YES;
		
		// Fetch the image on a separate thread.
		if ([newDescription objectForKey: @"imageData"] == nil)
		{
			[oneDescription loadImageWithCompletionHandler: ^(UIImage *image, NSError *error)
			{
#if DEBUG_LOCAL_PLAYER
				printf ("mergeLocalAchievementDescriptionsWithGameCenter: new image = %s\n", [oneDescription.identifier cStringUsingEncoding: NSUTF8StringEncoding]);
#endif	// DEBUG_LOCAL_PLAYER
				
				if (error)
				{
					if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:gameCenterFailure:error:)]))
						[_delegate localPlayer: self gameCenterFailure: @"loadImageWithCompletionHandler" error: error];
				}
				
				if (image)
				{
					NSDictionary		*localDescription;
					NSMutableDictionary	*newDescription;
					
					localDescription = [_descriptions objectForKey: oneDescription.identifier];
					if (localDescription)
					{
						NSData	*imageData;
						
						imageData = UIImagePNGRepresentation (image);
						if (imageData)
						{
							newDescription = [NSMutableDictionary dictionaryWithDictionary: localDescription];
							[newDescription setObject: imageData forKey: @"imageData"];
							[_descriptions setObject: newDescription forKey: oneDescription.identifier];
							_descriptionsDirty = YES;
						}
					}
					
					// Tell delegate a new image was fetched.
					if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:loadedImage:forAchievement:)]))
						[_delegate localPlayer: self loadedImage: image forAchievement: oneDescription.identifier];
				}
			}];
		}
	}
}

// --------------------------------------------------------------------------------------------- completedInitialization

- (void) completedInitialization
{
	// Write out achievements and descriptions if modified.
	[self storeLocalAchievements];
	[self storeLocalAchievementDescriptions];
	
	// Tell delegate we're a wrap.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayerInitializationComplete:)]))
		[_delegate localPlayerInitializationComplete: self];
}

// ------------------------------------------------------------------------------------------ unflattenAchievementImages

- (void) unflattenAchievementImages
{
	NSArray		*achievementKeys;
	
	achievementKeys = [_achievements allKeys];
	for (NSString *identifier in achievementKeys)
	{
		NSDictionary		*localAchievement;
		NSMutableDictionary	*newAchievement;
		NSData				*imageData;
		
		// Get our local achievement dictionary.
		localAchievement = [_achievements objectForKey: identifier];
		if (localAchievement == nil)
			continue;
		
		// Create new dictionary.
		newAchievement = [NSMutableDictionary dictionaryWithDictionary: localAchievement];
		
		// If we have image data, unflatten it, put it back as a proper image and remove the image data.
		imageData = [newAchievement objectForKey: @"imageData"];
		if (imageData)
		{
			[newAchievement setObject: [UIImage imageWithData: imageData] forKey: @"image"];
			[newAchievement removeObjectForKey: @"imageData"];
		}
		
		// Assign back to our local achievements.
		[_achievements setObject: newAchievement forKey: identifier];
	}
}

// -------------------------------------------------------------------------------------- loadAchievementsFromGameCenter

- (void) loadAchievementsFromGameCenter
{
	// Load achievements from GameCenter.
	[GKAchievement loadAchievementsWithCompletionHandler: ^(NSArray *achievements, NSError *error)
	{
		// If we got achievements back....
		if (achievements)
		{
#if DEBUG_LOCAL_PLAYER
	printf ("loadAchievementsFromGameCenter: Game Center achievements = %s\n", [[achievements description] cStringUsingEncoding: NSUTF8StringEncoding]);
#endif	// DEBUG_LOCAL_PLAYER
			
			// Merge achievements with our local achievements.
			[self mergeLocalAchievementsWithGameCenter: achievements];
			
			// See if there are missing descriptions that need to be fetched.
			if ([self needAchievementDescriptions: achievements])
			{
				// Retrieve achievement descriptions.
				[GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler: ^(NSArray *descriptions, NSError *error)
				{
#if DEBUG_LOCAL_PLAYER
					printf ("loadAchievementsFromGameCenter: achievement descriptions = %s\n", [[descriptions description] cStringUsingEncoding: NSUTF8StringEncoding]);
#endif	// DEBUG_LOCAL_PLAYER
					
					if (error != nil)
					{
						if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:gameCenterFail:error:)]))
							[_delegate localPlayer: self gameCenterFailure: @"loadAchievementDescriptionsWithCompletionHandler" error: error];
					}
					
					if (descriptions != nil)
						[self mergeLocalAchievementDescriptionsWithGameCenter: descriptions];
					
					// We're done.
					[self completedInitialization];
				}];
			}
			else
			{
				// We're done.
				[self completedInitialization];
			}
		}
		else
		{
			// Report error.
			if ((error) && (_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:gameCenterFailure:error:)]))
				[_delegate localPlayer: self gameCenterFailure: @"loadAchievementsWithCompletionHandler" error: error];
			
			// There's nothing else to do.
			[self completedInitialization];
		}
	}];
}

// ----------------------------------------------------------------------------------------------- loadLocalAchievements

- (void) loadLocalAchievements
{
	NSUserDefaults	*defaults;
	NSDictionary	*localAchievements;
	
	// Get local achievements.
	defaults = [NSUserDefaults standardUserDefaults];
	if (_alias)
		localAchievements = [defaults dictionaryForKey: [NSString stringWithFormat: @"LocalPlayer_achievements_%@", _alias]];
	else
		localAchievements = [defaults dictionaryForKey: @"LocalPlayer_achievements_local"];
	if (localAchievements)
		[_achievements addEntriesFromDictionary: localAchievements];
	
#if DEBUG_LOCAL_PLAYER
	printf ("loadLocalAchievements: [_achievements count] = %d\n", [_achievements count]);
#endif	// DEBUG_LOCAL_PLAYER
}

// ---------------------------------------------------------------------------------------------- storeLocalAchievements

- (void) storeLocalAchievements
{
	// Write out achievements dictionary if it was modified.
	if (_achievementsDirty)
	{
		NSUserDefaults	*defaults;
		
		// Get local achievements.
		defaults = [NSUserDefaults standardUserDefaults];
		if (_alias)
			[defaults setObject: _achievements forKey: [NSString stringWithFormat: @"LocalPlayer_achievements_%@", _alias]];
		else
			[defaults setObject: _achievements forKey: @"LocalPlayer_achievements_local"];
		_achievementsDirty = ([defaults synchronize] == NO);
	}
}

// ------------------------------------------------------------------------------------ loadLocalAchievementDescriptions

- (void) loadLocalAchievementDescriptions
{
	NSUserDefaults	*defaults;
	NSDictionary	*localDescriptions;
	
	// Get local achievements.
	defaults = [NSUserDefaults standardUserDefaults];
	localDescriptions = [defaults dictionaryForKey: @"LocalPlayer_achievementDescriptions"];
	if (localDescriptions)
		[_descriptions addEntriesFromDictionary: localDescriptions];
	
#if DEBUG_LOCAL_PLAYER
	printf ("loadLocalAchievementDescriptions: [_descriptions count] = %d\n", [_descriptions count]);
#endif	// DEBUG_LOCAL_PLAYER
}

// ----------------------------------------------------------------------------------- storeLocalAchievementDescriptions

- (void) storeLocalAchievementDescriptions
{
	// Write out descriptions dictionary if it was modified.
	if (_descriptionsDirty)
	{
		NSUserDefaults	*defaults;
		
		// Get local achievements.
		defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject: _descriptions forKey: @"LocalPlayer_achievementDescriptions"];
		_descriptionsDirty = ([defaults synchronize] == NO);
	}
}

// --------------------------------------------------------------------------------------------- authenticateLocalPlayer

- (void) authenticateLocalPlayer
{
	if ([self gameCenterAPIAvailable])
	{
		GKLocalPlayer	*localPlayer;
		
		localPlayer = [GKLocalPlayer localPlayer];
		[localPlayer authenticateWithCompletionHandler: ^(NSError *error)
		{
			// Authentication has completed.
			_authenticationCompleted = YES;
			
			if (localPlayer.isAuthenticated)
			{
				// Fetch the playerID and alias, indicate Game Center is being used.
				_playerID = [[NSString alloc] initWithString: localPlayer.playerID];
				_alias = [[NSString alloc] initWithString: localPlayer.alias];
				_usingGameCenter = YES;
				
				// Get local achievements and descriptions.				
				[self loadLocalAchievements];
				[self loadLocalAchievementDescriptions];
				
				// Call on Game Center for achievements (and possibly descriptiosn as well).
				[self loadAchievementsFromGameCenter];
			}
			else
			{
				// Player may have logged out when we were in the background.
				// Write out achievements and descriptions if modified.
				[self storeLocalAchievements];
				[self storeLocalAchievementDescriptions];
				
				// Toss stale used data.
				[_playerID release];
				_playerID = nil;
				[_alias release];
				_alias = nil;
				_usingGameCenter = NO;
				[_descriptions removeAllObjects];
				_descriptionsDirty = NO;
				[_achievements removeAllObjects];
				_achievementsDirty = NO;
				
				// Report error.
				if ((_delegate) && ([_delegate respondsToSelector: @selector (localPlayer:gameCenterFailure:error:)]))
					[_delegate localPlayer: self gameCenterFailure: @"authenticateWithCompletionHandler" error: error];
				
				// There's nothing else to do.
				[self completedInitialization];
			}
		}];
	}
	else
	{
		NSUserDefaults	*defaults;
		NSDictionary	*localAchievements;
		
		// Authentication complete, Game Center is not happening.
		_authenticationCompleted = YES;
		_usingGameCenter = NO;
		
		// Get local achievement descriptions.				
		[self loadLocalAchievementDescriptions];
		
		// Get local achievements (no Game Center).
		defaults = [NSUserDefaults standardUserDefaults];
		localAchievements = [defaults dictionaryForKey: @"local"];
		if (localAchievements)
			[_achievements addEntriesFromDictionary: localAchievements];
		[self unflattenAchievementImages];
		
		// There's nothing more to do.
		[self completedInitialization];
	}
}

@end
