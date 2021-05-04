// =====================================================================================================================
//  main.m
// =====================================================================================================================


#import <UIKit/UIKit.h>


int main (int argc, char *argv[])
{
	NSAutoreleasePool	*pool;
	int					returnValue;
	
	pool = [[NSAutoreleasePool alloc] init];
	returnValue = UIApplicationMain (argc, argv, nil, nil);
	[pool release];
	
	return returnValue;
}
