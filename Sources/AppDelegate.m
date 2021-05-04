// =====================================================================================================================
//  AppDelegate.m
// =====================================================================================================================


#import "AppDelegate.h"
#import "Clock.h"
#import "InterfaceSounds.h"
#import "RootViewController.h"


@interface AppDelegate ()
{
	BOOL		_displayAds;
}
@end


@implementation AppDelegate
// ========================================================================================================= AppDelegate
// --------------------------------------------------------------------------------------------------------- @synthesize

@synthesize window =_window;
@synthesize viewController =_viewController;

#pragma mark ----- Application Lifecycle
// --------------------------------------------------------------------------- application:didFinishLaunchingWithOptions

- (BOOL) application: (UIApplication *) application didFinishLaunchingWithOptions: (NSDictionary *) launchOptions
{
	// Set up view controller.
	[_window makeKeyAndVisible];
	
#if !USING_COCOS_DENSHION
	[InterfaceSounds sharedInterfaceSounds].enabled = YES;
#endif	// !USING_COCOS_DENSHION
	
	// Determine if Ads will be displayed. We grandfather in users who had Devil's Dice before the ads were added.
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey: @"ShowAds"] == nil)
	{
		if ([defaults objectForKey: @"DevilPlayed"] == nil)
			[defaults setObject: [NSNumber numberWithBool: YES] forKey: @"ShowAds"];
		else
			[defaults setObject: [NSNumber numberWithBool: NO] forKey: @"ShowAds"];
		[defaults synchronize];
	}
	
	// Are ads to be displayed?
	_displayAds = [defaults boolForKey: @"ShowAds"];
	
	// One-time set-up for root view controller.
	[_viewController setup: _displayAds];
	
	// Either restore a saved game or begin a new one.
	if ([_viewController hasSavedGame])
		[_viewController restoreSavedGame];
	else
		[_viewController beginGameWhenViewAppears];
	
	return YES;
}

// ----------------------------------------------------------------------------------------- applicationWillResignActive

- (void) applicationWillResignActive: (UIApplication *) application
{
	// Stop clock.
	[[Clock sharedClock] pause];
}

// --------------------------------------------------------------------------------------- applicationDidEnterBackground

- (void) applicationDidEnterBackground: (UIApplication *) application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application 
	// state information to restore your application to its current state in case it is terminated later. 
	//  If your application supports background execution, this method is called instead of applicationWillTerminate: 
	// when the user quits.
}

// -------------------------------------------------------------------------------------- applicationWillEnterForeground

- (void) applicationWillEnterForeground: (UIApplication *) application
{
	// Called as part of the transition from the background to the inactive state; 
	// here you can undo many of the changes made on entering the background.
}

// ------------------------------------------------------------------------------------------ applicationDidBecomeActive

- (void) applicationDidBecomeActive: (UIApplication *) application
{
	// Start clock.
	[[Clock sharedClock] start];
}

// -------------------------------------------------------------------------------------------- applicationWillTerminate

- (void) applicationWillTerminate: (UIApplication *) application
{
	// Called when the application is about to terminate. Save data if appropriate.
	// See also applicationDidEnterBackground:.
	[[NSUserDefaults standardUserDefaults] synchronize];
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	[_window release];
	[_viewController release];
	
	// Super.
	[super dealloc];
}

@end
