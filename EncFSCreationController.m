//
//  EncFSCreationContoller.m
//  EncFS
//
//  Created by Tobias Haeberle on 17.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EncFSCreationController.h"
#import <MFCore/MFLogging.h>

@interface EncFSCreationController ()
- (BOOL) passwordsMatch;
- (void) sendDefaultCommands;
- (void) unmount;
- (void)removeMountPoint;
- (BOOL) setupMountPoint;
- (void) launchTask;
- (BOOL) pathExists;
- (void) endModal;

@property (retain) NSTask *task;
@property (copy) NSString *mountPath;
@end


@implementation EncFSCreationController



@synthesize representedObject;
@synthesize task=_task, mountPath=_mountPath;

- (void)awakeFromNib
{
	NSPanel *panel = (NSPanel *)[self window];
	[panel setWorksWhenModal:YES];	
}

- (void) endModal
{
	[[self window] orderOut:self];
	[[NSApplication sharedApplication] stopModal];
}


#pragma mark -
#pragma mark Task
- (BOOL) pathExists
{
	NSString *path = [[self representedObject] valueForKeyPath:@"parameters.rawPath"];
	if (path) {
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL isDirectory = NO;
		return ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory && [fm isWritableFileAtPath:path]);
	} else {
		return NO;
	}
}

- (void) launchTask
{
	if (!self.task) {
		NSTask *task = [[NSTask alloc] init];
		self.task = task;
		
		
		NSPipe *inputPipe = [NSPipe pipe];
		NSPipe *outputPipe = [NSPipe pipe];
		
		
		[task setStandardInput:inputPipe];
		[task setStandardOutput:outputPipe];
		[task setStandardError:outputPipe];
	} 
	
	
	
	NSMutableArray *arguments = [NSMutableArray array];
	
	char *tempNam = tempnam("/Volumes", NULL);
	NSAssert(tempNam, @"Could not create a temporary mount point.");
	
	self.mountPath = [NSString stringWithCString:tempNam];
	
	[arguments addObject:@"-S"];
	[arguments addObject:[[self representedObject] valueForKeyPath:@"parameters.rawPath"]];
	[arguments addObject:self.mountPath];
	
	[self.task setArguments:[arguments copy]];
	[self.task setLaunchPath:@"/usr/local/bin/encfs"];
	MFLog(@"Using %@ as LaunchPath.", [self.task launchPath]);
	
	NSFileHandle *outputHandle = [[self.task standardOutput] fileHandleForReading];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(fileHandleDataAvailable:) 
												 name:NSFileHandleDataAvailableNotification 
											   object:outputHandle];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskDidTerminate:) 
												 name:NSTaskDidTerminateNotification 
											   object:self.task];
	if ( [self setupMountPoint] ) {
		[self performSelector:@selector(timeOutCheck) withObject:nil afterDelay:5.0f inModes:[NSArray arrayWithObjects:NSModalPanelRunLoopMode, NSDefaultRunLoopMode, nil]];
		[self.task launch];
        [[[self.task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
		[self sendDefaultCommands];
	} else {
		MFLog(@"could not setup mountpath");
	}
}

- (void) sendDefaultCommands
{
	NSString *pw = [[self representedObject] valueForKeyPath:@"secrets.password"];
	NSString *commands = [NSString stringWithFormat:@"x\n1\n256\n512\n1\nYes\nYes\nNo\nNo\n%@\n%@", pw,pw];
	//MFLog(@"sending: %@", commands);
	NSPipe *inputPipe = [self.task standardInput];
	NSFileHandle *handle = [inputPipe fileHandleForWriting];
	[handle writeData:[commands dataUsingEncoding:NSUTF8StringEncoding]];
}


- (void) timeOutCheck
{
	MFLog(@"timeout check");
	if ([self.task isRunning]) {
		[self.task terminate];
	}
	
	
}

- (void)fileHandleDataAvailable:(NSNotification *)notif
{
    NSFileHandle *handle = [notif object];
    
    NSData *data;
    if ((data = [handle availableData]) && [data length] > 0) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        MFLog(@"output: %@", string);
        [string release];
        
        [handle readInBackgroundAndNotify];
    }
}

- (void)taskDidTerminate:(NSNotification *)notif
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // cancel timeout check
	
	int returnCode = [[self task] terminationStatus];
	if (returnCode == 0) {
		MFLog(@"Task succeeded.");
		[self unmount];
	} else {
		MFLog(@"Task failed.");
	}
	
	
	[okButton setEnabled:YES];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:[self task]];
	self.task = nil;
	[self endModal];
}

#pragma mark -
#pragma mark Mount Path Handling
- (BOOL) setupMountPoint
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mountPath = [self mountPath];
	BOOL pathExists, isDir, returnValue;
	NSString* errorDescription;
	
	NSAssert(mountPath, @"Attempted to filesystem with nil mountPath.");
	
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir == YES) // directory already exists
	{
		BOOL empty = ( [[fm directoryContentsAtPath:mountPath] count] == 0 );
		BOOL writeable = [fm isWritableFileAtPath:mountPath];
		if (!empty)
		{
			errorDescription = @"Mount path directory in use.";
			returnValue = NO;
		}
		else if (!writeable)
		{
			errorDescription = @"Mount path directory not writeable.";
			returnValue = NO;
		}
		else
		{
			returnValue = YES;
		}
	}
	else if (pathExists && !isDir)
	{
		errorDescription = @"Mount path is a file, not a directory.";
		returnValue = NO;
	}
	else
	{
		if ([fm createDirectoryAtPath:mountPath attributes:nil])
			returnValue = YES;
		else
		{
			errorDescription = [NSString stringWithFormat:@"Mount path %@ could not be created.", mountPath];
			returnValue = NO;
		}
	}
	
	if (returnValue == NO)
	{
		return NO;
	}
	else
	{
		return YES;
	}
}
- (void)unmount
{
	MFLogS(self, @"Unmounting");
	NSString* path = [[self mountPath] stringByStandardizingPath];
	NSString* taskPath = @"/sbin/umount";
	NSTask* t = [[NSTask alloc] init];
	[t setLaunchPath: taskPath];
	[t setArguments: [NSArray arrayWithObject: path]];
	[t launch];
	/*
	 [t waitUntilExit];
	 if ([t terminationStatus] != 0)
	 {
	 MFLogS(self, @"Unmount failed. Unmount terminated with %d",
	 [t terminationStatus]);
	 }
	 */
}

- (void)removeMountPoint
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mountPath = [self mountPath];
	BOOL pathExists, isDir;
	

	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir && ([[fm directoryContentsAtPath:mountPath] count] == 0))
	{
		[fm removeFileAtPath:mountPath handler:nil];
	}
}


- (IBAction)create:(id)sender
{
	
	if ( ![self pathExists] ) {
		NSRunAlertPanel (@"Path not valid.",
						 @"Please choose a different directory to create an encrypted filesystem!",
						 @"OK",
						 nil,
						 nil);
		
		return;
	}
	[sender setEnabled:NO];
	[self launchTask];
	
}




- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ( [[passwordField stringValue] length] > 0 && [self passwordsMatch] ) {
		[okButton setEnabled:YES];
	} else {
		[okButton setEnabled:NO];
	}
}


- (IBAction)browse:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanCreateDirectories:YES];
	
	NSUInteger returnCode = [openPanel runModalForTypes:nil];
	
	if (returnCode == NSOKButton) {
		NSLog(@"OK");
		
		NSError *error = nil;
		BOOL isDir;
		
		NSString *dirPath = [[openPanel filenames] lastObject];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir] && isDir) {
			
			NSArray *contentArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
			if (nil != error) {
				[NSAlert alertWithError:error];
				return;
			}
			
			
			if ( [contentArray count] > 0 ) {
				// NSLog Error
				NSRunAlertPanel (@"Path not empty!",
								 @"Please choose an empty directory to create an encrypted filesystem!",
								 @"OK",
								 nil,
								 nil);
			} else  {
				[[self representedObject] setValue:dirPath forKeyPath:@"parameters.rawPath"];
			}
		} else {
			NSRunAlertPanel (@"Path not writable!",
							 @"Unabele to access this directory. Please chosse a different one.",
							 @"OK",
							 nil,
							 nil);
		}
		
		return;
				
	} else {
		NSLog(@"cancel");
	}
	
	return;
}

- (BOOL)passwordsMatch
{
	return ( [[passwordField stringValue] isEqualToString:[passwordVerifyField stringValue]] );
}

- (IBAction)cancel:(id)sender
{
	[[self representedObject] setValue:@"" forKeyPath:@"parameters.rawPath"];
	[[self representedObject] setValue:@"" forKeyPath:@"secrets.password"];
	
	if ( self.task && [self.task isRunning] ) {
		[self.task terminate];
	}
	
	[self endModal];
}

- (void)dealloc
{
	[_task terminate];
	[_task release];
	[super dealloc];
}

@end
