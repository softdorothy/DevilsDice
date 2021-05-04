// =====================================================================================================================
//  RootViewController.m
// =====================================================================================================================


#import <GameKit/GameKit.h>
#import "InfoViewController.h"
#import "InterfaceSounds.h"
#import "RootViewController.h"
#import "SimpleAudioEngine.h"


#define kTurnLeverCenterOffset		136		// 142
#define kTurnLeverCenterVOffset		16		// 20
#define kTurnLeverYCurvatureScalar	583		// = (kTurnLeverRange * kTurnLeverRange) / 5 {5 is  the pixel delta}
#define kTurnLeverRange				56
#define	kMaxTurnLeverVelocity		8

#define kRollLeverVOffset			288
#define kRollLeverRange				86
#define kRollLeverShaftHeight		83
#define kRollLeverShaftY			405
#define kRollLeverShadowWide		77
#define kRollLeverShadowTall		79
#define kShadowRotationScalar		1.5
#define kMaxRollLeverVelocity		6

#define kIndicatorVOffset			370

#define kWheelBaseSpins				82		// (n * 24) + 10; here n = 3.
#define kDieWheelVOffset			86
#define kMaxWheelVelocity			14
#define kMaxDieWheelPosition		336		// 6 * 56 (56 points is how tall each die+gap is)


enum
{
	kGameStateIdle = 0, 
	kGameStateRolling = 1, 
	kGameStateTurnLeverMoving = 2, 
	kGameStateGameOver = 3
};

enum
{
	kTrackingNothing = 0, 
	kTrackingTurnLever = 1,
	kTrackingRollLever = 2
};

enum
{
	kWheelStationary = 0, 
	kWheelAccelerating = 1,
	kWheelFreewheeling = 2, 
	kWheelStopping = 3
};

enum
{
	kDevilStateThinking = 0, 
	kDevilStatePullingLever = 1
};

enum
{
	kGameOverJeopardyClimbing = 0, 
	kGameOverSafeClimbing = 1, 
	kGameOverCounting = 2, 
	kGameOverReseting = 3
};


@interface RootViewController ()
{
	BOOL		_displayAds;
}
@end


static bool	_gRandomizedSeed = false;


@implementation RootViewController
// ================================================================================================== RootViewController
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

// ------------------------------------------------------------------------------------------------------- randomizeSeed

static void randomizeSeed (void)
{
	// Randomize random number seed.
	srand (time (nil));
	_gRandomizedSeed = true;
}

// ----------------------------------------------------------------------------------------------------------- randomInt

int randomInt (int range)
{
	// Make sure we set the random seed to a unique value.
	if (_gRandomizedSeed == false)
		randomizeSeed();
	
	if (range <= 0)
		return 0;
	else
		return (rand () % range);
}

#pragma mark ----- UI-Elements Positioning
// ------------------------------------------------------------------------------------------- positionTurnLeverForValue

- (void) positionTurnLeverForValue: (CGFloat) value
{
	CGRect		frame;
	
	frame = _smallHandle.frame;
	frame.origin.x = kTurnLeverCenterOffset + value;
	frame.origin.y = kTurnLeverCenterVOffset + ((value * value) / kTurnLeverYCurvatureScalar);
	_smallHandle.frame = frame;
}

// ------------------------------------------------------------------------------------------ valueFromTurnLeverPosition

- (CGFloat) valueFromTurnLeverPosition
{
	CGRect		frame;
	
	frame = _smallHandle.frame;
	
	return frame.origin.x - kTurnLeverCenterOffset;
}

// ------------------------------------------------------------------------------------------- positionRollLeverForValue

- (void) positionRollLeverForValue: (CGFloat) value
{
	CGRect				frame;
	CGAffineTransform	transform;
	
	// Position handle.
	frame = _largeHandle.frame;
	frame.origin.y = kRollLeverVOffset + value;
	_largeHandle.frame = frame;
	
	// Scale lever shaft.
	frame = _handleShaft.frame;
	frame.size.height = (kRollLeverRange - value) * kRollLeverShaftHeight / kRollLeverRange;
	frame.origin.y = kRollLeverShaftY - frame.size.height;
	_handleShaft.frame = frame;
	
	// Rotate lever shadow.
	transform = CGAffineTransformMakeTranslation (-kRollLeverShadowWide / 2, kRollLeverShadowTall / 2);
	transform = CGAffineTransformRotate (transform, value / kRollLeverRange * kShadowRotationScalar);
	transform = CGAffineTransformTranslate(transform, kRollLeverShadowWide / 2, -kRollLeverShadowTall / 2);
	_handleShadow.transform = transform;
}

// ------------------------------------------------------------------------------------------ valueFromRollLeverPosition

- (CGFloat) valueFromRollLeverPosition
{
	CGRect		frame;
	
	frame = _largeHandle.frame;
	
	return frame.origin.y - kRollLeverVOffset;
}

// -------------------------------------------------------------------------------------------- positionDieWheelForValue

- (void) positionDieWheelForValue: (CGFloat) value
{
	CGRect		frame;
	
	// Position wheel.
	frame = _dieWheel.frame;
	frame.origin.y = kDieWheelVOffset - value;
	_dieWheel.frame = frame;
}

// ----------------------------------------------------------------------------- positionPlayerJeopardyIndicatorForValue

- (void) positionPlayerJeopardyIndicatorForValue: (CGFloat) value
{
	CGRect		frame;
	
	// Position indicator.
	frame = _secondaryIndicatorLeft.frame;
	frame.origin.y = kIndicatorVOffset - (value * 3);
	_secondaryIndicatorLeft.frame = frame;
}

// ---------------------------------------------------------------------------- valueFromPlayerJeopardyIndicatorPosition

- (CGFloat) valueFromPlayerJeopardyIndicatorPosition
{
	CGRect		frame;
	
	frame = _secondaryIndicatorLeft.frame;
	return ((kIndicatorVOffset - frame.origin.y) / 3);
}

// --------------------------------------------------------------------------------- positionPlayerSafeIndicatorForValue

- (void) positionPlayerSafeIndicatorForValue: (CGFloat) value
{
	CGRect		frame;
	
	// Position indicator.
	frame = _primaryIndicatorLeft.frame;
	frame.origin.y = kIndicatorVOffset - (value * 3);
	_primaryIndicatorLeft.frame = frame;
}

// -------------------------------------------------------------------------------- valueFromPlayerSafeIndicatorPosition

- (CGFloat) valueFromPlayerSafeIndicatorPosition
{
	CGRect		frame;
	
	frame = _primaryIndicatorLeft.frame;
	return ((kIndicatorVOffset - frame.origin.y) / 3);
}

// --------------------------------------------------------------------------- positionOpponentJeopardyIndicatorForValue

- (void) positionOpponentJeopardyIndicatorForValue: (CGFloat) value
{
	CGRect		frame;
	
	// Position indicator.
	frame = _secondaryIndicatorRight.frame;
	frame.origin.y = kIndicatorVOffset - (value * 3);
	_secondaryIndicatorRight.frame = frame;
}

// -------------------------------------------------------------------------- valueFromOpponentJeopardyIndicatorPosition

- (CGFloat) valueFromOpponentJeopardyIndicatorPosition
{
	CGRect		frame;
	
	frame = _secondaryIndicatorRight.frame;
	return ((kIndicatorVOffset - frame.origin.y) / 3);
}

// ------------------------------------------------------------------------------- positionOpponentSafeIndicatorForValue

- (void) positionOpponentSafeIndicatorForValue: (CGFloat) value
{
	CGRect		frame;
	
	// Position indicator.
	frame = _primaryIndicatorRight.frame;
	frame.origin.y = kIndicatorVOffset - (value * 3);
	_primaryIndicatorRight.frame = frame;
}

// ------------------------------------------------------------------------------ valueFromOpponentSafeIndicatorPosition

- (CGFloat) valueFromOpponentSafeIndicatorPosition
{
	CGRect		frame;
	
	frame = _primaryIndicatorRight.frame;
	return ((kIndicatorVOffset - frame.origin.y) / 3);
}

#pragma mark ----- Game Methods
// --------------------------------------------------------------------------------------- updatePlayerViewAchievementUI

- (void) updatePlayerViewAchievementUI
{
	NSDictionary	*achievements;
	NSArray			*achievementKeys;
	
	// Get achievements.
	achievements = _localPlayer.achievements;
	[_playController enableAchievements: [achievements count] > 0];
	
	// Itterate over keys (identifiers).
	achievementKeys = [achievements allKeys];
	for (NSString *identifier in achievementKeys)
	{
		NSDictionary	*descriptionDictionary;
		
		descriptionDictionary = [achievements objectForKey: identifier];
		if ([identifier isEqualToString: @"com.softdorothy.devilsdice.shut_out_the_devil"])
			[_playController updateAchievement: descriptionDictionary atIndex: 0];
		else if ([identifier isEqualToString: @"com.softdorothy.devilsdice.100_point_run"])
			[_playController updateAchievement: descriptionDictionary atIndex: 1];
		else if ([identifier isEqualToString: @"com.softdorothy.devilsdice.75_point_run"])
			[_playController updateAchievement: descriptionDictionary atIndex: 2];
		else if ([identifier isEqualToString: @"com.softdorothy.devilsdice.50_point_run"])
			[_playController updateAchievement: descriptionDictionary atIndex: 3];
		else if ([identifier isEqualToString: @"com.softdorothy.devilsdice.25_point_run"])
			[_playController updateAchievement: descriptionDictionary atIndex: 4];
		else if ([identifier isEqualToString: @"com.softdorothy.devilsdice.3_in_a_row"])
			[_playController updateAchievement: descriptionDictionary atIndex: 5];
	}
}

// -------------------------------------------------------------------------------------------------------- achievements

- (NSDictionary *) achievements
{
	return _localPlayer.achievements;
}

// ------------------------------------------------------------------------------------------------- noteAchievementMade

- (BOOL) noteAchievementMade: (NSString *) identifier
{
	double	percentCompleted;
	BOOL	newAchievment = NO;
	
	percentCompleted = [_localPlayer percentCompletedForAchievement: identifier];
	if (percentCompleted != 100)
	{
		CGRect	newFrame;
		
		// Note achievement.
		[_localPlayer achievementAttained: identifier percentComplete: 100];
		newAchievment = YES;
		
		// Music!
		[[SimpleAudioEngine sharedEngine] playEffect: @"Achievement.wav"];
		
		// Animation!
		[UIView beginAnimations: @"Achievement Unlocked Revealed" context: nil];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector (animationDidStop:finished:context:)];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
		newFrame = _achievementUnlockedView.frame;
		newFrame.origin.x = 23;
		_achievementUnlockedView.frame = newFrame;
		[UIView commitAnimations];
	}
	
	return newAchievment;
}

// ------------------------------------------------------------------------------------------------------- saveGameState

- (void) saveGameState
{
	NSUserDefaults	*defaults;
	
	// NOP (if no score).
	if ((_playerSafeScore == 0) && (_playerJeopardizedScore == 0) && 
			(_opponentSafeScore == 0) && (_opponentJeopardizedScore == 0))
	{
		return;
	}
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Store relevant game state information.
	[defaults setBool: YES forKey: @"SavedGame"];
	[defaults setInteger:_gameMode forKey: @"GameMode"];
	[defaults setInteger:_playerSafeScore forKey: @"PlayerSafe"];
	[defaults setInteger:_playerJeopardizedScore forKey: @"PlayerJeopardized"];
	[defaults setInteger:_opponentSafeScore forKey: @"OpponentSafe"];
	[defaults setInteger:_opponentJeopardizedScore forKey: @"OpponentJeopardized"];
	[defaults setBool: _playersTurn forKey: @"PlayersTurn"];
}

// ------------------------------------------------------------------------------------------------------ clearSavedGame

- (void) clearSavedGame
{
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"SavedGame"];
}

// --------------------------------------------------------------------------------------------------------- handleWheel

- (void) handleWheel
{
	switch (_wheelState)
	{
		case kWheelAccelerating:				// Accelerate wheel up to maximum velocity.
		_wheelVelocity = _wheelVelocity + 1;
		
		[[SimpleAudioEngine sharedEngine] playEffect: @"Spin.wav"];
		
		if (_wheelVelocity >= kMaxWheelVelocity)
		{
			// At maximum velocity, switch wheel to freewheeling mode.
			_wheelVelocity = kMaxWheelVelocity;
			_wheelState = kWheelFreewheeling;
			
			// Adding the extra counts will cause the wheel to stop on a new (random) value.
			_wheelCounter = kWheelBaseSpins + (randomInt (6) * 4);
			
			// Hide the static die wheel, show the motion-blurred die wheel.
			_dieWheel0.hidden = YES;
			_dieWheel16.hidden = NO;
			_dieWheel = _dieWheel16;
		}
		break;
		
		case kWheelFreewheeling:				// Free-wheel until counter reaches zero.
		_wheelCounter = _wheelCounter - 1;
		
		[[SimpleAudioEngine sharedEngine] playEffect: @"Spin.wav"];
		
		if (_wheelCounter <= 0)
		{
			// When counter drops to zero, switch wheel to stopping (decelerating) mode.
			_wheelState = kWheelStopping;
			
			// Now hide the motion-blurred wheel, and switch in the static (not blurred) die wheel.
			_dieWheel0.hidden = NO;
			_dieWheel16.hidden = YES;
			_dieWheel = _dieWheel0;
			
			// Sound of wheel stopping.
			[[SimpleAudioEngine sharedEngine] playEffect: @"SpinStop.wav"];
		}
		break;
		
		case kWheelStopping:					// Decelerate the wheel down to zero velocity.
		_wheelVelocity =_wheelVelocity - 1;
		if (_wheelVelocity <= 0)
		{
			int		dieRoll;
			
			// When velocity slopws to zero, switch wheel to stationary state.
			_wheelState = kWheelStationary;
			_wheelVelocity = 0;
			
			// Calculate the (final) die roll.
			dieRoll = round (_wheelPosition / 56) + 1;
			if (dieRoll > 6)
				dieRoll -= 6;
			
			// The die roll determines the game state.
			if (dieRoll == 1)
			{
				// A roll of 1 ends the current player's turn.
				// A sound effect.
				[[SimpleAudioEngine sharedEngine] playEffect: @"Buzz.wav"];
				
				if (_playersTurn == YES)
				{
					// Drop back the player's jeopardized score to their last safe score.
					_playerJeopardizedScore = _playerSafeScore;
					
					// Lever will move to the right (maximum range) indicating its the opponent's turn.
					_turnLeverDestination = kTurnLeverRange;
				}
				else
				{
					// Drop back the opponent's jeopardized score to their last safe score.
					_opponentJeopardizedScore = _opponentSafeScore;
					
					// Lever will move to the left (minimum range) indicating its the player's turn.
					_turnLeverDestination = -kTurnLeverRange;
				}
				
				// Lever will automatically move to other player.
				_gameState = kGameStateTurnLeverMoving;
				_turnLeverMoveDelayCounter = 30;
				_turnLeverVelocity = 0;
			}
			else
			{
				if (_playersTurn == YES)
				{
					int		wasScore;
					
					// Bump jeopardized score.
					wasScore = _playerJeopardizedScore - _playerSafeScore;
					_playerJeopardizedScore += dieRoll;
					
					// Achievement check - '25 Point Run'.
					if ((wasScore < 25) && ((_playerJeopardizedScore - _playerSafeScore) >= 25))
					{
						if ([self noteAchievementMade: @"com.softdorothy.devilsdice.25_point_run"])
							_achievementEarned = 4;
					}
					
					// Achievement check - '50 Point Run'.
					if ((wasScore < 50) && ((_playerJeopardizedScore - _playerSafeScore) >= 50))
					{
						if ([self noteAchievementMade: @"com.softdorothy.devilsdice.50_point_run"])
							_achievementEarned = 3;
					}
					
					// Achievement check - '75 Point Run'.
					if ((wasScore < 75) && ((_playerJeopardizedScore - _playerSafeScore) >= 75))
					{
						if ([self noteAchievementMade: @"com.softdorothy.devilsdice.75_point_run"])
							_achievementEarned = 2;
					}
					
					// Achievement check - '100 Point Run'.
					if ((wasScore < 100) && ((_playerJeopardizedScore - _playerSafeScore) >= 100))
					{
						if ([self noteAchievementMade: @"com.softdorothy.devilsdice.100_point_run"])
							_achievementEarned = 1;
					}
					
					// Check for game won.
					if (_playerJeopardizedScore >= 100)
					{
						_playerJeopardizedScore = 100;
						_gameState = kGameStateGameOver;
						_gameOverState = kGameOverJeopardyClimbing;
						
						// Going to fade in the 'spotlight' art to show the winner.
						if (CGRectGetHeight ([UIScreen mainScreen].bounds) == 568)
							_baseWinnerView.image = [UIImage imageNamed: @"BaseYouWin-568h"];
						else
							_baseWinnerView.image = [UIImage imageNamed: @"BaseYouWin"];
					}
					else
					{
						_gameState = kGameStateIdle;
						[self saveGameState];
					}
				}
				else
				{
					// Bump jeopardized score.
					_opponentJeopardizedScore += dieRoll;
					if (_opponentJeopardizedScore >= 100)
					{
						_opponentJeopardizedScore = 100;
						_gameState = kGameStateGameOver;
						_gameOverState = kGameOverJeopardyClimbing;
						
						// Going to fade in the 'spotlight' art to show the winner.
						if (CGRectGetHeight ([UIScreen mainScreen].bounds) == 568)
							_baseWinnerView.image = [UIImage imageNamed: @"BaseDevilWins-568h"];
						else
							_baseWinnerView.image = [UIImage imageNamed: @"BaseDevilWins"];
					}
					else
					{
						_gameState = kGameStateIdle;
						[self saveGameState];
					}
				}
				
				if (_gameState == kGameStateGameOver)
				{
					// No longer a saved game.
					[self clearSavedGame];
					
					// Update devil stats.
					if (_gameMode == kGamePlayerVsDevil)
					{
						NSUserDefaults	*defaults;
						NSInteger		played = 0;
						
						defaults = [NSUserDefaults standardUserDefaults];
						
						// Update games played.
						if ([defaults objectForKey: @"DevilPlayed"] != nil)
							played = [defaults integerForKey: @"DevilPlayed"];
						played += 1;
						[defaults setInteger: played forKey: @"DevilPlayed"];
						
						// Update games won.
						if (_playersTurn)
						{
							NSInteger	winningStreak = 0;
							
							if ([defaults objectForKey: @"PlayerWinningStreak"] != nil)
								winningStreak = [defaults integerForKey: @"PlayerWinningStreak"];
							
							winningStreak += 1;
							
							// Player won, increase their winning streak.
							[defaults setInteger: winningStreak forKey: @"PlayerWinningStreak"];
							
							// Achievement check - '3 In A Row'.
							if (winningStreak >= 3)
							{
								if ([self noteAchievementMade: @"com.softdorothy.devilsdice.3_in_a_row"])
									_achievementEarned = 5;
							}
						}
						else
						{
							NSInteger	won = 0;
							
							if ([defaults objectForKey: @"DevilWon"] != nil)
								won = [defaults integerForKey: @"DevilWon"];
							won += 1;
							[defaults setInteger: won forKey: @"DevilWon"];
							
							// Player lost, thus ends their winning streak.
							[defaults setInteger: 0 forKey: @"PlayerWinningStreak"];
						}
						[defaults synchronize];
						
						// Achievement check - 'Shut Out the Devil'.
						if ((_playerJeopardizedScore == 100) && (_opponentJeopardizedScore == 0))
						{
							if ([self noteAchievementMade: @"com.softdorothy.devilsdice.shut_out_the_devil"])
								_achievementEarned = 0;
						}
					}
					
					// Fade in the 'spotlight' art...
					_shaftMaskView.alpha = 1;
					_baseWinnerView.alpha = 0;
					_baseWinnerView.hidden = NO;
					[UIView beginAnimations: @"Fade In Spotlight" context: nil];
					[UIView setAnimationDuration: 3];
					_baseWinnerView.alpha = 1;
					_shaftMaskView.alpha = 0;
					[UIView commitAnimations];
				}
			}
		}
		break;
		
		default:		// kWheelStationary
		break;
	}
	
	// Move wheel.
	if (_wheelVelocity > 0)
	{
		_wheelPosition = _wheelPosition + _wheelVelocity;
		if (_wheelPosition > kMaxDieWheelPosition)
			_wheelPosition = _wheelPosition - kMaxDieWheelPosition;
		[self positionDieWheelForValue: _wheelPosition];
	}
}

// ---------------------------------------------------------------------------------------------------- handleIndicators

- (void) handleIndicators
{
	int			scoreShowing;
	
	// Bump indicator count.
	_indicatorCounter += 1;
	
	// Handle player jeopardy indicator.
	scoreShowing = [self valueFromPlayerJeopardyIndicatorPosition];
	if (_playerJeopardizedScore < scoreShowing)
	{
		[self positionPlayerJeopardyIndicatorForValue: scoreShowing - 1];
		if ((scoreShowing - 1) == _playerJeopardizedScore)
			[[SimpleAudioEngine sharedEngine] playEffect: @"Retreat.wav"];
	}
	
	// Handle player safe indicator.
	scoreShowing = [self valueFromPlayerSafeIndicatorPosition];
	if (_playerSafeScore < scoreShowing)
	{
		[self positionPlayerSafeIndicatorForValue: scoreShowing - 1];
		if ((scoreShowing - 1) == _playerSafeScore)
			[[SimpleAudioEngine sharedEngine] playEffect: @"Retreat.wav"];
	}
	
	// Handle opponent jeopardy indicator.
	scoreShowing = [self valueFromOpponentJeopardyIndicatorPosition];
	if (_opponentJeopardizedScore < scoreShowing)
	{
		[self positionOpponentJeopardyIndicatorForValue: scoreShowing - 1];
		if ((scoreShowing - 1) == _opponentJeopardizedScore)
			[[SimpleAudioEngine sharedEngine] playEffect: @"Retreat.wav"];
	}
	
	// Handle opponent safe indicator.
	scoreShowing = [self valueFromOpponentSafeIndicatorPosition];
	if (_opponentSafeScore < scoreShowing)
	{
		[self positionOpponentSafeIndicatorForValue: scoreShowing - 1];
		if ((scoreShowing - 1) == _opponentSafeScore)
			[[SimpleAudioEngine sharedEngine] playEffect: @"Retreat.wav"];
	}
	
	// Every 8 frames advance the indicators if they're climbing.
	if ((_indicatorCounter % 8) == 0)
	{
		// Handle player jeopardy indicator.
		scoreShowing = [self valueFromPlayerJeopardyIndicatorPosition];
		if (_playerJeopardizedScore > scoreShowing)
		{
			[self positionPlayerJeopardyIndicatorForValue: scoreShowing + 1];
			[[SimpleAudioEngine sharedEngine] playEffect: @"Advance.wav"];
		}
		
		// Handle player safe indicator.
		scoreShowing = [self valueFromPlayerSafeIndicatorPosition];
		if (_playerSafeScore > scoreShowing)
		{
			[self positionPlayerSafeIndicatorForValue: scoreShowing + 1];
			[[SimpleAudioEngine sharedEngine] playEffect: @"Advance.wav"];
		}
		
		// Handle opponent jeopardy indicator.
		scoreShowing = [self valueFromOpponentJeopardyIndicatorPosition];
		if (_opponentJeopardizedScore > scoreShowing)
		{
			[self positionOpponentJeopardyIndicatorForValue: scoreShowing + 1];
			[[SimpleAudioEngine sharedEngine] playEffect: @"Advance.wav"];
		}
		
		// Handle opponent safe indicator.
		scoreShowing = [self valueFromOpponentSafeIndicatorPosition];
		if (_opponentSafeScore > scoreShowing)
		{
			[self positionOpponentSafeIndicatorForValue: scoreShowing + 1];
			[[SimpleAudioEngine sharedEngine] playEffect: @"Advance.wav"];
		}
	}
}

// ----------------------------------------------------------------------------------------------------- handleTurnLever

- (void) handleTurnLever
{
	if (_turnLeverMoveDelayCounter > 0)
	{
		// We have a small delay before the lever starts to move over. This allows the player a moment to recognize 
		// the 1 that came up on the die wheel.
		_turnLeverMoveDelayCounter -= 1;
	}
	else
	{
		CGFloat		leverValue;
		CGFloat		wasLeverValue;
		BOOL		wasGreaterThanZero;
		
		// Get the value of the turn lever.
		leverValue = [self valueFromTurnLeverPosition];
		wasLeverValue = leverValue;
		wasGreaterThanZero = leverValue > 0;
		
		if (leverValue < _turnLeverDestination)
		{
			// Handle destination to the right of current lever position.
			if (_turnLeverVelocity < kMaxTurnLeverVelocity)
				_turnLeverVelocity += 1;
			leverValue += _turnLeverVelocity;
			if (leverValue > _turnLeverDestination)
				leverValue = _turnLeverDestination;
			[self positionTurnLeverForValue: leverValue];
		}
		else if (leverValue > _turnLeverDestination)
		{
			// Handle destination to the left of current lever position.
			if (_turnLeverVelocity > -kMaxTurnLeverVelocity)
				_turnLeverVelocity -= 1;
			leverValue += _turnLeverVelocity;
			if (leverValue < _turnLeverDestination)
				leverValue = _turnLeverDestination;
			[self positionTurnLeverForValue: leverValue];
		}
		
		// If we're passing the threshold, play a sound to indicate it.
		if (((wasGreaterThanZero == YES) && (leverValue <= 0)) || ((wasGreaterThanZero == NO) && (leverValue > 0)))
			[[SimpleAudioEngine sharedEngine] playEffect: @"Threshold.wav"];
		
		// The turn lever has reached its destination. Switch the game state.
		if (leverValue == _turnLeverDestination)
		{
			// Play sound of lever hitting stop.
			if (wasLeverValue != _turnLeverDestination)
				[[SimpleAudioEngine sharedEngine] playEffect: @"Limit.wav"];
			
			if (_gameState == kGameStateTurnLeverMoving)
			{
				if (_turnLeverDestination == kTurnLeverRange)
				{
					_playersTurn = NO;
				}
				else
				{
					// Lock in devil's score.
					if (_gameMode == kGamePlayerVsDevil)
						_opponentSafeScore = _opponentJeopardizedScore;
					_playersTurn = YES;
				}
				_gameState = kGameStateIdle;
				[self saveGameState];
			}
		}
	}
}

// --------------------------------------------------------------------------------------------------------- handleDevil

- (void) handleDevil
{
	if ((_gameMode == kGamePlayerVsDevil) && (_playersTurn == NO))
	{
		CGFloat		leverValue;
		
		switch (_devilState)
		{
			case kDevilStateThinking:			// So the devil's decision isn't immediate, we add a 'thinking' delay.
			if (_devilWaitCounter > 0)
				_devilWaitCounter -= 1;
			if (_devilWaitCounter == 0)
			{
				// If either player has 71 points or more, we'll roll to win.
				if ((_playerSafeScore >= 71) || (_opponentSafeScore >= 71))
				{
					[[SimpleAudioEngine sharedEngine] playEffect: @"Touch.wav"];
					_rollLeverVelocity = 0;
					_devilState = kDevilStatePullingLever;
				}
				else
				{
					int		turnTotalGoal;
					
					// Otherwise, we ostensibly want to roll 21 points or more.
					turnTotalGoal = 21;
					
					// However, if the player has a lead on us, we'll adjust upward our desired point total.
					if (_playerSafeScore > _opponentSafeScore)
						turnTotalGoal += ((_playerSafeScore - _opponentSafeScore) / 8);
					if ((_opponentJeopardizedScore - _opponentSafeScore) < turnTotalGoal)
					{
						[[SimpleAudioEngine sharedEngine] playEffect: @"Touch.wav"];
						_rollLeverVelocity = 0;
						_devilState = kDevilStatePullingLever;
					}
					else
					{
						// Move lever to player position.
						_turnLeverDestination = -kTurnLeverRange;
						_gameState = kGameStateTurnLeverMoving;
						_turnLeverMoveDelayCounter = 30;
						_turnLeverVelocity = 0;
					}
				}
				
				// Reset counter for next time.
				_devilWaitCounter = 45;
			}
			break;
			
			case kDevilStatePullingLever:		// The lever takes time to draw back.
			leverValue = [self valueFromRollLeverPosition];
			if (leverValue < kRollLeverRange)
			{
				// Continue to draw back the lever.
				if (_rollLeverVelocity < kMaxRollLeverVelocity)
					_rollLeverVelocity += 1;
				leverValue += _rollLeverVelocity;
				if (leverValue > kRollLeverRange)
					leverValue = kRollLeverRange;
				
				[self positionRollLeverForValue: leverValue];
			}
			else
			{
				// We've fully pulled back the roll lever — start the wheel spinning.
				[[SimpleAudioEngine sharedEngine] playEffect: @"StartSpin.wav"];
				
				_gameState = kGameStateRolling;
				_wheelState = kWheelAccelerating;
				_devilState = kDevilStateThinking;
				
				// Animate the roll lever back to its rest position.
				[UIView beginAnimations: @"Roll Lever Return" context: nil];
				[UIView setAnimationDelegate: self];
				[UIView setAnimationDidStopSelector: @selector (animationDidStop:finished:context:)];
				[self positionRollLeverForValue: 0];
				[UIView commitAnimations];
			}
			break;
		}
	}
}

// ------------------------------------------------------------------------------------------------------ handleGameOver

- (void) handleGameOver
{
	switch (_gameOverState)
	{
		case kGameOverJeopardyClimbing:		// First, allow the jeopardy indicator to climb to 100.
		if (_playersTurn)
		{
			if ([self valueFromPlayerJeopardyIndicatorPosition] == 100)
			{
				_playerSafeScore = 100;
				_gameOverState = kGameOverSafeClimbing;
			}
		}
		else
		{
			if ([self valueFromOpponentJeopardyIndicatorPosition] == 100)
			{				
				_opponentSafeScore = 100;
				_gameOverState = kGameOverSafeClimbing;
			}
		}
		
		if (_gameOverState == kGameOverSafeClimbing)
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Win.wav"];
			
			// Fade in the 'spotlight' art..
			_shaftMaskView.alpha = 1;
			_baseWinnerView.alpha = 0;
			_baseWinnerView.hidden = NO;
			[UIView beginAnimations: @"Fade In Spotlight" context: nil];
			[UIView setAnimationDuration: 3];
			_baseWinnerView.alpha = 1;
			_shaftMaskView.alpha = 0;
			[UIView commitAnimations];
		}
		break;
		
		case kGameOverSafeClimbing:			// Second, allow the safe indicator to match the jeopardy indicator (100).
		if (((_playersTurn == YES) && ([self valueFromPlayerSafeIndicatorPosition] == 100)) || 
				((_playersTurn == NO) && ([self valueFromOpponentSafeIndicatorPosition] == 100)))
		{
			_gameOverCounter = 120;
			_gameOverState = kGameOverCounting;
			_turnLeverDestination = -kTurnLeverRange;
		}
		break;
		
		case kGameOverCounting:				// Third, pause a second, (turn lever may reset to left if opponent won).
		[self handleTurnLever];
		_gameOverCounter -= 1;
		if (_gameOverCounter == 0)
		{
			// Reset scores.
			_playerSafeScore = 0;
			_playerJeopardizedScore = 0;
			_opponentSafeScore = 0;
			_opponentJeopardizedScore = 0;
			
			_gameOverState = kGameOverReseting;
			_gameOverCounter = 60;
		}
		break;
		
		case kGameOverReseting:				// Fourth, drop the indicators back to zero.
		[self handleTurnLever];
		_gameOverCounter -= 1;
		if (_gameOverCounter == 0)
		{
			// Game state goes back to idle.
			_gameState = kGameStateIdle;
			_playersTurn = YES;
			
			// Re-load achievement descriptions.
			if (_achievementEarned != NSNotFound)
				[self updatePlayerViewAchievementUI];
			
			// Finally, bring up the 'play view'.
			[self playAction: self];
		}
		break;
	}
}

#pragma mark ----- Clock Delegate Method
// -------------------------------------------------------------------------------------------------------- executeFrame

- (void) executeFrame: (id) sender
{
	switch (_gameState)
	{
		case kGameStateIdle:
		[self handleIndicators];
		[self handleDevil];
		break;
		
		case kGameStateRolling:
		[self handleWheel];	
		[self handleIndicators];
		break;
		
		case kGameStateTurnLeverMoving:
		[self handleIndicators];
		[self handleTurnLever];
		break;
		
		case kGameStateGameOver:
		[self handleIndicators];
		[self handleGameOver];
		break;
	}
}

#pragma mark ----- Touches
// ---------------------------------------------------------------------------------------------- touchesBegan:withEvent

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch		*touch;
	CGPoint		location;
	
	// Get touch location.
	touch = [touches anyObject];
	location = [touch locationInView: self.view];
	
	// Hit-test the handles the user may interact with.
	if (CGRectContainsPoint (_smallHandle.frame, location))
	{
		// Player or opponent touched the turn-lever handle.
		if ((_gameState == kGameStateIdle) && ((_gameMode == kGamePlayerVsPlayer) || (_playersTurn == YES)))
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Touch.wav"];
			
			_trackingControl = kTrackingTurnLever;
			_trackingOffset = location;
			_wasValue = [self valueFromTurnLeverPosition];
		}
	}
	else if (CGRectContainsPoint (_largeHandle.frame, location))
	{
		// Player touched the wheel-spin (roll) handle.
		if ((_gameState == kGameStateIdle) && ((_gameMode == kGamePlayerVsPlayer) || (_playersTurn == YES)))
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Touch.wav"];
			
			_trackingControl = kTrackingRollLever;
			_trackingOffset = location;
			_wasValue = [self valueFromRollLeverPosition];
		}
	}
}

// ---------------------------------------------------------------------------------------------- touchesMoved:withEvent

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	BOOL		wasHitSliderLimit;
	UITouch		*touch;
	CGPoint		location;
	
	// Get touch location.
	touch = [touches anyObject];
	location = [touch locationInView: self.view];
	
	if (_trackingControl == kTrackingTurnLever)
	{
		CGFloat		wasCenterDelta;
		CGFloat		centerDelta;
		
		// Handle turn lever.
		wasHitSliderLimit = _hitSliderLimit;
		_hitSliderLimit = NO;
		
		// Determine how far off center the handle was.
		wasCenterDelta = [self valueFromTurnLeverPosition];
		
		// Determine how far off center the handle is.
		centerDelta = _wasValue + (location.x - _trackingOffset.x);
		
		// Pin to within allowable range.
		if (centerDelta < -kTurnLeverRange)
		{
			centerDelta = -kTurnLeverRange;
			_hitSliderLimit = YES;
		}
		else if (centerDelta > kTurnLeverRange)
		{
			centerDelta = kTurnLeverRange;
			_hitSliderLimit = YES;
		}
		
		// Move knob to new location.
		[self positionTurnLeverForValue: centerDelta];
		
		// If we passed the threshold, play a sound to indicate it.
		if ((_gameState == kGameStateIdle) && (((_playersTurn == YES) && (wasCenterDelta <= 0) && (centerDelta > 0)) || 
				((_playersTurn == NO) && (wasCenterDelta > 0) && (centerDelta <= 0))))
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Threshold.wav"];
		}
		
		// If we hit up against a slider limit, play sound.
		if ((_hitSliderLimit == YES) && (wasHitSliderLimit == NO))
			[[SimpleAudioEngine sharedEngine] playEffect: @"Limit.wav"];
	}
	else if (_trackingControl == kTrackingRollLever)
	{
		CGFloat		valueDelta;
		
		// Handle roll lever.
		_hitSliderLimit = NO;
		
		// Determine how far off center the handle is.
		valueDelta = _wasValue + (location.y - _trackingOffset.y);
		
		// Pin to within allowable range.
		if (valueDelta < 0)
		{
			valueDelta = 0;
			_hitSliderLimit = YES;
		}
		else if (valueDelta > kRollLeverRange)
		{
			valueDelta = kRollLeverRange;
			_hitSliderLimit = YES;
		}
		
//		printf ("valueDelta = %.1f\n", valueDelta);
		
		// Move knob to new location.
		[self positionRollLeverForValue: valueDelta];
		
		// Start wheel spinning.
		if (valueDelta == kRollLeverRange)
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"StartSpin.wav"];
			
			// Switch to rolling modes. The wheel cannot be spun again while in this mode.
			if (_gameState == kGameStateIdle)
			{
				_gameState = kGameStateRolling;
				_wheelState = kWheelAccelerating;
			}
			
			// We've stopped tracking.
			_trackingControl = kTrackingNothing;
			
			// Animate the roll lever back to its rest position.
			[UIView beginAnimations: @"Roll Lever Return" context: nil];
			[UIView setAnimationDelegate: self];
			[UIView setAnimationDidStopSelector: @selector (animationDidStop:finished:context:)];
			[self positionRollLeverForValue: 0];
			[UIView commitAnimations];
		}
	}
}

// ---------------------------------------------------------------------------------------------- touchesEnded:withEvent

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch		*touch;
	CGPoint		location;
	
	// Get touch location.
	touch = [touches anyObject];
	location = [touch locationInView: self.view];
	
	if (_trackingControl == kTrackingTurnLever)
	{
		CGFloat		centerDelta;
		
		// Handle turn lever.
		// Determine how far off center the handle is.
		centerDelta = _wasValue + (location.x - _trackingOffset.x);
		
		// Pin to within allowable range.
		if (centerDelta < -kTurnLeverRange)
			centerDelta = -kTurnLeverRange;
		else if (centerDelta > kTurnLeverRange)
			centerDelta = kTurnLeverRange;
		
		// Did lever cross the threshold?
		if (centerDelta > 0)
		{
			// Pin lever to far right.
			centerDelta = kTurnLeverRange;
			
			// Lock in player score.
			_playerSafeScore = _playerJeopardizedScore;
			
			// Play goes to either the devil or the other (human) player.
			_playersTurn = NO;
		}
		else
		{
			// Pin lever to far left.
			centerDelta = -kTurnLeverRange;
			
			// If player vs. player, the play passes from opponent back to the first player.
			// Lock in opponent score.
			_opponentSafeScore = _opponentJeopardizedScore;
			
			// Play returns to the first player.
			_playersTurn = YES;
		}
		
		[[SimpleAudioEngine sharedEngine] playEffect: @"Limit.wav"];
		
		[self positionTurnLeverForValue: centerDelta];
	}
	else if (_trackingControl == kTrackingRollLever)
	{
		// Animate the roll lever back to its rest position.
		[UIView beginAnimations: @"Roll Lever Return" context: nil];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector (animationDidStop:finished:context:)];
		[self positionRollLeverForValue: 0];
		[UIView commitAnimations];
	}
	
	// Finished tracking touches.
	_trackingControl = kTrackingNothing;
}

// ------------------------------------------------------------------------------------------ touchesCancelled:withEvent

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
	// Abort any tracking in process.
	[self positionTurnLeverForValue: -kTurnLeverRange];
	[self positionRollLeverForValue: 0];
	_trackingControl = kTrackingNothing;
}

#pragma mark ----- Animation Delegate
// ----------------------------------------------------------------------------------- animationDidStop:finished:context

- (void) animationDidStop: (NSString *) animationID finished: (NSNumber *) finished context: (void *)context
{
	if ([animationID isEqualToString: @"Roll Lever Return"])
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"Limit.wav"];
	}
	else if ([animationID isEqualToString: @"Achievement Unlocked Revealed"])
	{
		CGRect	newFrame;
		
		[UIView beginAnimations: @"Achievement Unlocked Return" context: nil];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
		[UIView setAnimationDelay: 2];
		newFrame = _achievementUnlockedView.frame;
		newFrame.origin.x = 320;
		_achievementUnlockedView.frame = newFrame;
		[UIView commitAnimations];
	}
}

#pragma mark ----- Actions
// -------------------------------------------------------------------------------------------------------- hasSavedGame

- (BOOL) hasSavedGame
{
	return [[NSUserDefaults standardUserDefaults] boolForKey: @"SavedGame"];
}

// ---------------------------------------------------------------------------------------------------- restoreSavedGame

- (void) restoreSavedGame
{
	NSUserDefaults	*defaults;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	_gameMode = [defaults integerForKey: @"GameMode"];
	_playerSafeScore = [defaults integerForKey: @"PlayerSafe"];
	_playerJeopardizedScore = [defaults integerForKey: @"PlayerJeopardized"];
	_opponentSafeScore = [defaults integerForKey: @"OpponentSafe"];
	_opponentJeopardizedScore = [defaults integerForKey: @"OpponentJeopardized"];
	_playersTurn = [defaults boolForKey: @"PlayersTurn"];
	
	// Set up UI to reflect current game state.
	if (_playersTurn)
		[self positionTurnLeverForValue: -kTurnLeverRange];
	else
		[self positionTurnLeverForValue: kTurnLeverRange];
	[self positionPlayerSafeIndicatorForValue: _playerSafeScore];
	[self positionPlayerJeopardyIndicatorForValue: _playerJeopardizedScore];
	[self positionOpponentSafeIndicatorForValue: _opponentSafeScore];
	[self positionOpponentJeopardyIndicatorForValue: _opponentJeopardizedScore];
}

// ----------------------------------------------------------------------------------------------- beginTouchClickAction

- (void) beginTouchClickAction: (id) sender
{
	[[InterfaceSounds sharedInterfaceSounds] buttonPressed];
}

// ---------------------------------------------------------------------------------------------------------- infoAction

- (void) infoAction: (id) sender
{
	// Play sound.
	[[InterfaceSounds sharedInterfaceSounds] buttonReleased];
	
	// Bring up 'info view'.
	[self presentModalViewController: _infoController animated: YES];
}

// ---------------------------------------------------------------------------------------------------------- playAction

- (void) playAction: (id) sender
{
	// Update the stats.
	_playController.delegate = self;
	[_playController updateStatistics: self];
	[_playController displayAchievementEarned: _achievementEarned];
	
	// Bring up 'play view'.
	[self presentModalViewController: _playController animated: YES];
}

// --------------------------------------------------------------------------------------------------------------- setup

- (void) setup: (BOOL) displayAds
{
	_gameMode = kGamePlayerVsPlayer;
	_playersTurn = YES;
	_devilState = kDevilStateThinking;
	_devilWaitCounter = 45;
	_gameState = kGameStateIdle;
	_displayAds = displayAds;
	
	// Create banner ad view.
	if (_displayAds)
	{
		// On iOS 6 ADBannerView introduces a new initializer, use it when available.
		if (_bannerView == nil)
		{
			if ([ADBannerView instancesRespondToSelector: @selector (initWithAdType:)])
				_bannerView = [[ADBannerView alloc] initWithAdType: ADAdTypeBanner];
			else
				_bannerView = [[ADBannerView alloc] init];
			_bannerView.delegate = self;
		}
	}
	
	_trackingControl = kTrackingNothing;
	[self positionTurnLeverForValue: -kTurnLeverRange];
	[self positionRollLeverForValue: 0];
	_baseWinnerView.hidden = YES;
	
	// Load sounds.
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Limit.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Threshold.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"StartSpin.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Spin.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"SpinStop.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Advance.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Retreat.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Buzz.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Win.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Touch.wav"];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"Volume"] != nil)
		[[SimpleAudioEngine sharedEngine] setEffectsVolume: [[NSUserDefaults standardUserDefaults] floatForKey: @"Volume"]];
	else
		[[SimpleAudioEngine sharedEngine] setEffectsVolume: 0.5];
	
	// Initialize wheel state.
	_wheelState = kWheelStationary;
	_wheelVelocity = 0;
	_dieWheel0.hidden = NO;
	_dieWheel16.hidden = YES;
	_dieWheel = _dieWheel0;
	
	// Clock.
	[Clock sharedClock].delegate = self;
}

#pragma mark ----- PlayViewController Delegate Method
// --------------------------------------------------------------------------------------------------------- setGameMode

- (void) setGameMode: (int) mode
{
	_gameMode = mode;
	_achievementEarned = NSNotFound;
	
	// In case it is visible, hide the 'spotlight' art.
	_baseWinnerView.hidden = YES;
	_shaftMaskView.alpha = 1;
}

// -------------------------------------------------------------------------------------------- beginGameWhenViewAppears

- (void) beginGameWhenViewAppears
{
	_beginGameWhenViewAppears = YES;
}

// ------------------------------------------------------------------------------------------------ layoutBannerAnimated

- (void) layoutBannerAnimated: (BOOL) animated
{
	// As of iOS 6.0, the banner will automatically resize itself based on its width.
	// To support iOS 5.0 however, we continue to set the currentContentSizeIdentifier appropriately.
	CGRect contentFrame = self.view.bounds;
	if (CGRectGetWidth (contentFrame) < CGRectGetHeight (contentFrame))
		_bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
	else
		_bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
	
	CGRect bannerFrame = _bannerView.frame;
	if (_bannerView.bannerLoaded)
	{
		contentFrame.size.height -= _bannerView.frame.size.height;
		bannerFrame.origin.y = contentFrame.size.height;
	}
	else
	{
		bannerFrame.origin.y = contentFrame.size.height;
	}
	_bannerView.frame = bannerFrame;
	
	[UIView animateWithDuration: animated ? 0.25 : 0.0 animations:
	^{
		_backgroundImageView.frame = contentFrame;
		[_backgroundImageView layoutIfNeeded];
		_bannerView.frame = bannerFrame;
	}];
}

#pragma mark ----- View Lifecycle
// --------------------------------------------------------------------------------------------------------- viewDidLoad

- (void) viewDidLoad
{
	// Super.
	[super viewDidLoad];
	
	
	
	// Adjust background image and scroll view for iPhone5 height.
	if (CGRectGetHeight ([UIScreen mainScreen].bounds) == 568)
		_backgroundImageView.image = [UIImage imageNamed: @"Base-568h"];
}

// ------------------------------------------------------------------------------------------------------- viewDidAppear

- (void) viewDidAppear:(BOOL)animated
{
	// Create local player object.
	if (_localPlayer == nil)
	{
		_localPlayer = [[LocalPlayer alloc] init];
		_localPlayer.delegate = self;
		_achievementEarned = NSNotFound;
	}
}

// ------------------------------------------------------------------------------ shouldAutorotateToInterfaceOrientation

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) orientation
{
	// Return YES for supported orientations.
	return UIInterfaceOrientationIsPortrait (orientation);
}

// ----------------------------------------------------------------------------------------------- viewDidLayoutSubviews

- (void) viewDidLayoutSubviews
{
	if (_bannerView)
		[self layoutBannerAnimated: [UIView areAnimationsEnabled]];
}

#pragma mark ------ LocalPlayer delegate methods
// ----------------------------------------------------------------------------------- localPlayerInitializationComplete

- (void) localPlayerInitializationComplete: (LocalPlayer *) player
{
	if (_bannerView)
		[self.view addSubview: _bannerView];
	
	if (_beginGameWhenViewAppears)
	{
		[self performSelector: @selector (playAction:) withObject: nil afterDelay: 0.5];
		_beginGameWhenViewAppears = NO;
	}
}

// ------------------------------------------------------------------------------ localPlayer:loadedImage:forAchievement

- (void) localPlayer: (LocalPlayer *) player loadedImage: (UIImage *) image forAchievement: (NSString *) identifier
{
	[self updatePlayerViewAchievementUI];
}

// --------------------------------------------------------------------------------- localPlayer:gameCenterFailure:error

- (void) localPlayer: (LocalPlayer *) player gameCenterFailure: (NSString *) gameCenterAPI error: (NSError *) error
{
	if (([gameCenterAPI isEqualToString: @"authenticateWithCompletionHandler"] == YES) || 
			([gameCenterAPI isEqualToString: @"loadAchievementsWithCompletionHandler"] == YES))
	{
		[self updatePlayerViewAchievementUI];
	}
	
	printf ("gameCenterFailure (%s), error: %s\n", [gameCenterAPI cStringUsingEncoding: NSUTF8StringEncoding], 
			[[error description] cStringUsingEncoding: NSUTF8StringEncoding]);	
}

#pragma mark ------ ADBannerView delegate methods
// ------------------------------------------------------------------------------------------------- bannerViewDidLoadAd

- (void) bannerViewDidLoadAd: (ADBannerView *) banner
{
	[self layoutBannerAnimated: YES];
}

// ------------------------------------------------------------------------------ bannerView:didFailToReceiveAdWithError

- (void) bannerView: (ADBannerView *) banner didFailToReceiveAdWithError: (NSError *)error
{
	[self layoutBannerAnimated: YES];
}

// -------------------------------------------------------------------- bannerViewActionShouldBegin:willLeaveApplication

- (BOOL) bannerViewActionShouldBegin: (ADBannerView *) banner willLeaveApplication: (BOOL) willLeave
{
	return YES;
}

// ------------------------------------------------------------------------------------------- bannerViewActionDidFinish

- (void) bannerViewActionDidFinish: (ADBannerView *) banner
{
}

@end
