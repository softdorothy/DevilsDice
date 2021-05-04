// =====================================================================================================================
//  Clock.m
// =====================================================================================================================


#import <QuartzCore/QuartzCore.h>
#import "Clock.h"


#define USE_DISPLAY_LINK	1


static Clock			*_gSharedClock = nil;


@implementation Clock
// =============================================================================================================== Clock
// --------------------------------------------------------------------------------------------------------- @synthesize

@synthesize running = _running;
@synthesize delegate = _delegate;

// --------------------------------------------------------------------------------------------------------- sharedClock

+ (Clock *) sharedClock
{
	if (_gSharedClock == nil)
		_gSharedClock = [[Clock alloc] init];
	
	return _gSharedClock;
}

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	if ((self = [super init]))
	{
		_running = NO;
	}
	
	return self;
}

// ------------------------------------------------------------------------------------------------------------ delegate

- (id <ClockDelegate>) delegate
{
	return _delegate;
}

// --------------------------------------------------------------------------------------------------------- setDelegate

- (void) setDelegate: (id <ClockDelegate>) delegate
{
	_delegate = delegate;
	_delegateDoesExecuteFrame = ([_delegate respondsToSelector: @selector (executeFrame:)]);
}

// --------------------------------------------------------------------------------------------------------------- start

- (void) start
{
	// NOP.
	if (_running)
		return;
	
#if USE_DISPLAY_LINK
	if (_displayLink == nil)
	{
		_displayLink = [CADisplayLink displayLinkWithTarget: self selector: @selector (callDelegateExecuteFrame:)];
		[_displayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
	}
#else	// USE_DISPLAY_LINK
	if (_timer == nil)
	{
		_timer = [NSTimer scheduledTimerWithTimeInterval: 1 / 60 target: self 
				selector: @selector (callDelegateExecuteFrame:) userInfo: nil repeats: YES];
	}
#endif	// USE_DISPLAY_LINK
	
	_running = YES;
}

// --------------------------------------------------------------------------------------------------------------- pause

- (void) pause
{
	_running = NO;
	
	// No timers or display links.
	if (_displayLink)
		[_displayLink removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
	_displayLink = nil;
	
	if (_timer)
		[_timer invalidate];
		_timer = nil;
}

// -------------------------------------------------------------------------------------------- callDelegateExecuteFrame

- (void) callDelegateExecuteFrame: (NSTimer *) timer
{
	if (_delegateDoesExecuteFrame)
		[_delegate executeFrame: self];
}

@end

