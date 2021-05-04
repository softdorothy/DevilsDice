// =====================================================================================================================
//  InterfaceSounds.m
// =====================================================================================================================


#import "InterfaceSounds.h"
#import "SimpleAudioEngine.h"


static InterfaceSounds			*_gSharedInterfaceSounds = nil;


@implementation InterfaceSounds
// ===================================================================================================== InterfaceSounds
// --------------------------------------------------------------------------------------------------------- @synthesize

@synthesize enabled = _enabled;

// ----------------------------------------------------------------------------------------------- sharedInterfaceSounds

+ (InterfaceSounds *) sharedInterfaceSounds
{
	if (_gSharedInterfaceSounds == nil)
		_gSharedInterfaceSounds = [[InterfaceSounds alloc] init];
	
	return _gSharedInterfaceSounds;
}

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	if ((self = [super init]))
	{
		_enabled = YES;
		
		[[SimpleAudioEngine sharedEngine] preloadEffect: @"Click.wav"];
		[[SimpleAudioEngine sharedEngine] preloadEffect: @"Release.wav"];
		[[SimpleAudioEngine sharedEngine] preloadEffect: @"Blip.wav"];
	}
	
	return self;
}

// ------------------------------------------------------------------------------------------------------- buttonPressed

- (void) buttonPressed
{
	if (_enabled)
		[[SimpleAudioEngine sharedEngine] playEffect: @"Click.wav"];
}

// ------------------------------------------------------------------------------------------------------ buttonReleased

- (void) buttonReleased
{
	if (_enabled)
		[[SimpleAudioEngine sharedEngine] playEffect: @"Release.wav"];
}

// --------------------------------------------------------------------------------------------------------- sampleSound

- (void) sampleSound
{
	if (_enabled)
		[[SimpleAudioEngine sharedEngine] playEffect: @"Blip.wav"];
}

@end
