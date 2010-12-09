/* 
 Boxer is copyright 2010 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXOperationSet.h"

//The standard interval in seconds at which to poll the progress of our dependent operations
#define BXOperationSetDefaultPollInterval 0.1


#pragma mark -
#pragma mark Private method declarations

@interface BXOperationSet ()

//Runs a single iteration of the internal run loop while we wait for the queue to finish.
//This simply sends an in-progress notification signal.
- (void) _postUpdateWithTimer: (NSTimer *)timer;

@end


@implementation BXOperationSet
@synthesize operations = _operations;
@synthesize pollInterval = _pollInterval;

#pragma mark -
#pragma mark Initialization and deallocation

+ (id) setWithOperations: (NSArray *)operations
{
	return [[[self alloc] initWithOperations: operations] autorelease];
}

- (id) init
{
	if ((self = [super init]))
	{
		[self setPollInterval: BXOperationSetDefaultPollInterval];
		[self setOperations: [NSMutableArray arrayWithCapacity: 5]];
	}
	return self;
}

- (id) initWithOperations: (NSArray *)operations
{
	if ((self = [self init]))
	{
		if (operations)
			[self setOperations: [[operations mutableCopy] autorelease]];
	}
	return self;
}

- (void) dealloc
{
	[self setOperations: nil], [_operations release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark Running the operations

- (BXOperationProgress) currentProgress
{
	//Treat the current progress as the average across all our operations
	NSUInteger numOperations = 0;
	BXOperationProgress totalProgress = 0.0f;
	
	for (BXOperation *operation in [self operations])
	{
		BXOperationProgress progress = [operation currentProgress];
		
		//If any operation's progress cannot be determined, then we cannot give an overall progress either
		if (progress == BXOperationProgressIndeterminate)
			return BXOperationProgressIndeterminate;
		
		totalProgress += progress;
		numOperations++;
	}
	
	return totalProgress / (BXOperationProgress)numOperations;
}

- (void) main
{
	if ([self isCancelled]) return;
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];

	//Queue up all transfer operations before letting them all start at once
	[queue setSuspended: YES];
	for (NSOperation *operation in [self operations]) [queue addOperation: operation];
	[queue setSuspended: NO];
	
	//Use a timer to execute our polling method. (This also keeps the runloop below alive.)
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: [self pollInterval]
													  target: self
													selector: @selector(_postUpdateWithTimer:)
													userInfo: queue
													 repeats: YES];
	
	
	//Poll until all operations are finished, but cancel them all if we ourselves are cancelled.
	while ([[queue operations] count] && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
																  beforeDate: [NSDate dateWithTimeIntervalSinceNow: [self pollInterval]]])
	{
		if ([self isCancelled]) [queue cancelAllOperations];
	}
	[timer invalidate];
	
	if (![self error])
	{
		for (BXOperation *operation in [self operations])
		{
			if ([operation error])
			{
				[self setError: error];
				break;
			}
		}		
	}
	
	[self setSucceeded: [self error] == nil];
	
	[queue release];
}

- (void) _postUpdateWithTimer: (NSTimer *)timer
{
	[self willChangeValueForKey: @"currentProgress"];
	[self didChangeValueForKey: @"currentProgress"];
		
	[self _sendInProgressNotificationWithInfo: nil];
}

@end