/* 
 Boxer is copyright 2010 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXMultiFileTransfer.h"
#import "BXSingleFileTransfer.h"


#pragma mark -
#pragma mark Implementation

@implementation BXMultiFileTransfer
@synthesize pathsToTransfer, copyFiles;

#pragma mark -
#pragma mark Initialization and deallocation

+ (id) transferForPaths: (NSDictionary *)paths
			  copyFiles: (BOOL)copy
{
	return [[[self alloc] initForPaths: paths copyFiles: copy] autorelease];
}

- (id) initForPaths: (NSDictionary *)paths copyFiles: (BOOL)copy
{
	if ((self = [self init]))
	{
		[self setPathsToTransfer: paths];
		[self setCopyFiles: copy];
	}
	return self;
}

- (void) dealloc
{
	[self setPathsToTransfer: nil], [pathsToTransfer release];
	
	[super dealloc];
}


#pragma mark -
#pragma mark Transfer status

+ (NSSet *)keyPathsForValuesAffectingValueForKey: (NSString *)key
{
	NSSet *baseKeys = [super keyPathsForValuesAffectingValueForKey: key];
	
	NSSet *progressKeys = [NSSet setWithObjects: @"numBytes", @"numFiles", @"bytesTransferred", @"filesTransferred", nil]; 
	
	if ([progressKeys containsObject: key]) return [baseKeys setByAddingObject: @"currentProgress"];
	else return baseKeys;
}
   
- (BXOperationProgress) currentProgress
{
	//If we haven't begun yet, return an indeterminate result.
	if (![self numBytes]) return BXOperationProgressIndeterminate;
	
	//If not all of our file operations know where they're at yet, return an indeterminate result.
	for (BXOperation <BXFileTransfer> *transfer in [self operations])
	{
		if ([transfer currentProgress] == BXOperationProgressIndeterminate) return BXOperationProgressIndeterminate;
	}
	
	return (BXOperationProgress)[self bytesTransferred] / (BXOperationProgress)[self numBytes];
}

- (unsigned long long) numBytes
{
	unsigned long long bytes = 0;
	for (BXOperation <BXFileTransfer> *operation in [self operations])
	{
		bytes += [operation numBytes];
	}
	return bytes;
}

- (unsigned long long) bytesTransferred
{
	unsigned long long bytes = 0;
	for (BXOperation <BXFileTransfer> *operation in [self operations])
	{
		bytes += [operation bytesTransferred];
	}
	return bytes;
}

- (NSUInteger) numFiles
{
	NSUInteger files = 0;
	for (BXOperation <BXFileTransfer> *operation in [self operations])
	{
		files += [operation numFiles];
	}
	return files;
}

- (NSUInteger) filesTransferred
{
	NSUInteger files = 0;
	for (BXOperation <BXFileTransfer> *operation in [self operations])
	{
		files += [operation filesTransferred];
	}
	return files;
}

- (NSString *) currentPath
{
	for (BXOperation <BXFileTransfer> *transfer in [self operations])
	{
		if ([transfer isExecuting]) return [transfer currentPath];
	}
	return nil;
}

#pragma mark -
#pragma mark Performing the transfer

- (void) start
{
	[super start];
	
	if (![self succeeded]) [self undoTransfer];
}

- (void) main
{
	if ([self isCancelled]) return;
	
	//Build file transfer operations for each pair of paths
	for (NSString *sourcePath in [[self pathsToTransfer] keyEnumerator])
	{
		NSString *destinationPath = [[self pathsToTransfer] objectForKey: sourcePath];
		
		BXSingleFileTransfer *transfer = [BXSingleFileTransfer transferFromPath: sourcePath
																		 toPath: destinationPath
																	  copyFiles: [self copyFiles]];
		[[self operations] addObject: transfer];
	}
	
	[super main];
}

- (void) _sendInProgressNotificationWithInfo: (NSDictionary *)info
{	
	NSMutableDictionary *extendedInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 [NSNumber numberWithUnsignedInteger:	[self filesTransferred]],	BXFileTransferFilesTransferredKey,
										 [NSNumber numberWithUnsignedLongLong:	[self bytesTransferred]],	BXFileTransferBytesTransferredKey,
										 [NSNumber numberWithUnsignedInteger:	[self numFiles]],			BXFileTransferFilesTotalKey,
										 [NSNumber numberWithUnsignedLongLong:	[self numBytes]],			BXFileTransferBytesTotalKey,
										 [self currentPath], BXFileTransferCurrentPathKey,
										 nil];
	
	if (info) [extendedInfo addEntriesFromDictionary: info];
	
	[super _sendInProgressNotificationWithInfo: info];
}

- (void) undoTransfer
{
	if ([self copyFiles])
	{
		//Delete all destination paths to clean up.
		//TODO: for move operations, we should put the files back.
		NSFileManager *manager = [[NSFileManager alloc] init];
		for (NSString *destinationPath in [[self pathsToTransfer] objectEnumerator])
		{
			[manager removeItemAtPath: destinationPath error: NULL];		
		}
		[manager release];
	}
}
@end