// =====================================================================================================================
//  Clock.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@protocol ClockDelegate;


@interface Clock : NSObject
{
	BOOL			_useDisplayLink;
	BOOL			_running;
	id				_delegate;
	CADisplayLink	*_displayLink;					// Private.
	NSTimer			*_timer;						// Private.
	BOOL			_delegateDoesExecuteFrame;		// Private.
}

// Returns the global shared clock instance.
+ (Clock *) sharedClock;

@property(nonatomic,readonly)	BOOL				running;	// Indicates whether the clock is running or not.
@property(nonatomic,assign)		id <ClockDelegate>	delegate;	// Delegate called for each execution of a frame.

- (void) start;													// Starts the clock
- (void) pause;													// Pauses the clock

@end


@protocol ClockDelegate<NSObject>

@optional

// When the clock is running (not paused) this method is called 60 times a second.
- (void) executeFrame: (id) sender;

@end

