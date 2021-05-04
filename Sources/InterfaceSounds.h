// =====================================================================================================================
//  InterfaceSounds.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@interface InterfaceSounds : NSObject
{
	BOOL			_enabled;
}

// Returns the global shared InterfaceSounds instance.
+ (InterfaceSounds *) sharedInterfaceSounds;

@property(nonatomic)	BOOL	enabled;	// Indicates whether sounds are enabled.

- (void) buttonPressed;						// Plays a button pressed sound.
- (void) buttonReleased;					// Plays a button released sound.
- (void) sampleSound;						// Plays a sample sound.

@end

