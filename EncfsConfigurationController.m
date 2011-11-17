//
//  EncfsConfigurationController.m
//  MacFusion2
//
//  Created by Tobias Haeberle on 15.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EncfsConfigurationController.h"
#import "EncFSCreationController.h"
#import "ENCFSErrors.h"
#import <MFCore/MFLogging.h>

@implementation EncfsConfigurationController

+ (BOOL) checkRawPath:(NSString *)dirPath withError:(NSError **)error
{
	// MFLog(@"checkRawPath: %@, withError: %@", dirPath, *error);
	NSArray *contentArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:error];
	if (nil != *error) {
		return NO;
	}
	
	NSEnumerator *e = [contentArray objectEnumerator];
	BOOL foundKeyFile = NO;
	NSString *path;
	while (!foundKeyFile && (path = [e nextObject])) {
		// MFLog(@"checking: %@ with lastComponent %@", path, [path lastPathComponent]);
		if ( [[path lastPathComponent] isEqualToString:@".encfs5"] || [[path lastPathComponent] isEqualToString:@".encfs6.xml"] ) {
			foundKeyFile = YES;
		}
	}
	
	if (foundKeyFile) {
		NSLog(@"found path: %@", dirPath);
		return YES;
	} else {
		// NSLog Error
		
		*error = [NSError errorWithDomain:kENCFSErrorDomain code:kENCFSErrorNoKeyFile userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No EncFS key file found", NSLocalizedDescriptionKey, nil]];
		MFLog(@"error: %@", [*error localizedDescription]);
		return NO;
	}		
}


- (void) showCreationWindow
{
	
	[creationController setRepresentedObject:[self representedObject]];
	[NSApp runModalForWindow:[creationController window]];
}

- (void) shouldCreateEncFSAtPath:(NSString *)dirPath
{
	NSUInteger clickedButton = NSRunAlertPanel(@"No EncFS key file found", @"This path is not an Encrypted File System. Do you want to create a new filesystem?", @"Yes", @"No", nil);
	if ( NSOKButton == clickedButton ) {
		[self showCreationWindow];
	}
}

- (IBAction) createNewFS: (id)sender
{
	[self showCreationWindow];
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
		
		NSString *dirPath = [[openPanel filenames] lastObject];
		if ( [EncfsConfigurationController checkRawPath:dirPath withError:&error] ) {
			[[self representedObject] setValue:dirPath forKeyPath:@"parameters.rawPath"];
		} else {
			if ( [[error domain] isEqualToString:kENCFSErrorDomain] && [error code] == kENCFSErrorNoKeyFile) {
				[self shouldCreateEncFSAtPath:dirPath];
			}
		}
		return;
		
	} else {
		NSLog(@"cancel");
	}
	
	return;
}

@end
