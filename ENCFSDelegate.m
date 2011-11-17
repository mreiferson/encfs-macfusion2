//
//  ENCFSDelegate.m
//  MacFusion2
//
//  Created by Tobias Haeberle on 15.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import "ENCFSDelegate.h"
#import <MFCore/MFConstants.h>
#import <MFCore/MGUtilities.h>
#import <MFCore/MFError.h>
#import <MFCore/MFNetworkFS.h>
#import <MFCore/MFSecurity.h>
#import <MFCore/MFLogging.h>
#import <Security/Security.h>
#import <MFCore/MFClientFSUI.h>
#import "EncfsConfigurationController.h"
//#import "ENCFSServerFS.h"


#import "ENCFSErrors.h"


static NSString* primaryViewControllerKey = @"encfsPrimaryView";
static NSString* advancedViewControllerKey = @"encfsAdvancedView";

NSString *kENCFSRawPathKey = @"rawPath"; 

@interface ENCFSDelegate ()
@property(copy) NSString *tempMountPoint;
@end


@implementation ENCFSDelegate

@synthesize tempMountPoint=_tempMountPoint;

- (NSString *)tempMountPoint
{
	if (!_tempMountPoint) {
		char *tempNam = tempnam("/Volumes", NULL);
		if (tempNam == NULL)
		{
			return nil;
		}
		
		_tempMountPoint = [[NSString stringWithCString:tempNam encoding:NSUTF8StringEncoding] retain];
		free(tempNam);
	}
	
	return _tempMountPoint;
}

- (NSString*)askpassPath
{
	return [[NSBundle bundleForClass: [self class]]
			pathForResource:@"encfs_askpass"
			ofType:nil
			inDirectory:nil];
}

// Task arguments
- (NSArray*)taskArgumentsForParameters:(NSDictionary*)parameters
{
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject: [NSString stringWithFormat:@"%@",
						   [parameters objectForKey: kENCFSRawPathKey]]];
		
	[arguments addObject: [parameters objectForKey: kMFFSMountPathParameter ]];
	
	[arguments addObject:[NSString stringWithFormat:@"--extpass=\"%@\"", [self askpassPath]]];
	
	[arguments addObject:@"-f"]; // run in foreground
	
	/*
	 if ([parameters objectForKey: kNetFSUserParameter])
		[arguments addObject: [NSString stringWithFormat: @"-ouser=%@", 
							   [parameters objectForKey: kNetFSUserParameter]]]; */
	
	[arguments addObject:@"--"];
	
	[arguments addObject: [NSString stringWithFormat: @"-ovolname=%@", 
						   [parameters objectForKey: kMFFSVolumeNameParameter]]];
	
	[arguments addObject: [NSString stringWithFormat: @"-ovolicon=%@", 
						   [parameters objectForKey: kMFFSVolumeIconPathParameter]]];
	
	[arguments addObject: @"-osubtype=10"];
	
	return [arguments copy];
}

- (NSDictionary*)taskEnvironmentForParameters:(NSDictionary*)params	
{
	NSMutableDictionary* env = [NSMutableDictionary dictionaryWithDictionary: 
								[[NSProcessInfo processInfo] environment]];
	[env setObject: mfsecTokenForFilesystemWithUUID([params objectForKey: @"uuid"])
			forKey: @"ENCFS_TOKEN"];
	[env setObject: [self askpassPath] forKey:@"ENCFS_ASKPASS"];
	
	return [env copy];
}

// Parameters



- (NSArray*)secretsClientsList;
{
	return [NSArray arrayWithObjects: [self askpassPath], nil];
}


- (NSArray*)parameterList
{
	return [NSArray arrayWithObjects: kENCFSRawPathKey, nil ];
}

- (NSArray*)secretsList
{
	return [NSArray arrayWithObjects: @"password", nil];
}

- (NSDictionary*)defaultParameterDictionary
{
	NSDictionary* defaultParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"", kENCFSRawPathKey, nil];
	
	return defaultParameters;
}

- (id)impliedValueParameterNamed:(NSString*)parameterName 
				 otherParameters:(NSDictionary*)parameters;
{
	// TODO: Anpassen
	if ([parameterName isEqualToString: kMFFSMountPathParameter] )
	{
		return [self tempMountPoint];
	}
	if ([parameterName isEqualToString: kMFFSVolumeNameParameter] &&
		[parameters objectForKey: kMFFSNameParameter] )
	{
		return [parameters objectForKey: kMFFSNameParameter];
	}
	
	if ([parameterName isEqualToString: kMFFSVolumeIconPathParameter])
	{
		return [[NSBundle bundleForClass: [self class]] 
				pathForImageResource:@"encfs_icon"];
	}
	if ([parameterName isEqualToString: kMFFSVolumeImagePathParameter])
	{
		return [[NSBundle bundleForClass: [self class]]
				pathForImageResource: @"encfs"];
	}
	/* if ([parameterName isEqualToString: kMFFSNameParameter])
		return [parameters objectForKey: kNetFSHostParameter]; */
	
	return nil;
}

- (NSString*)descriptionForParameters:(NSDictionary*)parameters
{
	return [NSString stringWithFormat:@"Path: %@, Mount Point: %@", [parameters objectForKey:kENCFSRawPathKey], [parameters objectForKey:kMFFSMountPathParameter]];
}

// Validation
- (BOOL)validateValue:(id)value 
	 forParameterName:(NSString*)paramName 
				error:(NSError**)error
{
	
	if ( [paramName isEqualToString:kENCFSRawPathKey] ) {
		NSError *err = nil;
		BOOL ok =  [EncfsConfigurationController checkRawPath:value withError:&err];
		if ( !ok ) {
			*error = [MFError invalidParameterValueErrorWithParameterName: kENCFSRawPathKey
																	value: value
															  description: [err localizedDescription]];
			
			return NO;
		} else {
			return YES;
		}
	}
	
	return YES;
}

- (BOOL)validateParameters:(NSDictionary*)parameters
					 error:(NSError**)error
{
	
	for (NSString* paramName in [parameters allKeys])
	{
		// MFLog(@"validateValue: %@, forKey: %@", [parameters objectForKey: paramName],  paramName);
		BOOL ok = [self validateValue: [parameters objectForKey: paramName]
					 forParameterName: paramName
								error: error];
		
		if (!ok)
		{
			return NO;
		}
	}
	
	/* if (![parameters objectForKey: kENCFSRawPathKey])
	{
		*error = [MFError parameterMissingErrorWithParameterName: kENCFSRawPathKey ];
		return NO;
	} */
	
	return YES;
}



// Plugin Wide Stuff
- (NSString*)executablePath
{
	/* return [[NSBundle bundleForClass: [self class]]
	 pathForResource:@"encfs_wrapper"
	 ofType:nil
	 inDirectory:nil]; */

    return [NSString stringWithString:@"/usr/local/bin/encfs"];
    //return [NSString stringWithString:@"encfs"];
}


// UI
# pragma mark UI
- (NSViewController*)primaryViewController
{
	EncfsConfigurationController* primaryViewController = [[EncfsConfigurationController alloc]
											   initWithNibName:@"encfsConfiguration"
											   bundle: [NSBundle bundleForClass: [self class]]];
	[primaryViewController setTitle: @"EncFS"];
	return primaryViewController;
	
}

- (NSViewController*)advancedviewController
{
	return nil;
}

- (NSArray*)viewControllerKeys
{
	return [NSArray arrayWithObjects: 
			primaryViewControllerKey, kMFUIMacfusionAdvancedViewKey,
			nil];
}

- (NSViewController*)viewControllerForKey:(NSString*)key
{
	if (key == primaryViewControllerKey)
		return [self primaryViewController];
	if (key == advancedViewControllerKey)
		return [self advancedviewController];
	
	return nil;
}

- (NSArray*)urlSchemesHandled
{
	return nil;
}

- (NSDictionary*)parameterDictionaryForURL:(NSURL*)url
									 error:(NSError**)error
{
	return nil;
}


/* - (NSDictionary*)taskEnvironmentForParameters:(NSDictionary*)parameters;*/

#pragma mark -
#pragma mark Errors
- (NSError*)errorForParameters:(NSDictionary*)parameters 
						output:(NSString*)output
{
	NSRange s = [output rangeOfString:@"password incorrect"];
	if ( s.location != NSNotFound  ) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"Decryption failed: wrong password", NSLocalizedDescriptionKey, 
																		@"Check your settings by clicking the edit button.", NSLocalizedRecoverySuggestionErrorKey, nil];
		NSError *error = [[NSError alloc] initWithDomain:kENCFSErrorDomain code:kENCFSErrorWrongPassword userInfo:dict];
		return [error autorelease];
	}
	
	s = [output rangeOfString:@"Creating new encrypted volume"];
	if ( s.location != NSNotFound  ) {
		NSString *suggestion = [NSString stringWithFormat:@"The path \"%@\" is not a valid Encrypted Filesystem. Click the Edit button and choose \"Browse\" to pick a valid directory or create a new one.", [parameters objectForKey:kENCFSRawPathKey]];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"Decryption failed: no EncFS key file found.", NSLocalizedDescriptionKey, 
							  suggestion, NSLocalizedRecoverySuggestionErrorKey, nil];
		NSError *error = [[NSError alloc] initWithDomain:kENCFSErrorDomain code:kENCFSErrorNoKeyFile userInfo:dict];
		return [error autorelease];
	}
	
	return [NSError errorWithDomain:kENCFSErrorDomain code:kENCFSErrorUnknown userInfo:[NSDictionary dictionaryWithObjectsAndKeys:output, NSLocalizedDescriptionKey, nil]];
}

#pragma mark -
#pragma mark Subclassing
// Subclassing
/*- (Class)subclassForClass:(Class)superclass
{
	if ([NSStringFromClass(superclass) isEqualToString: @"MFServerFS"])
		return [ENCFSServerFS class];
	return nil;
}*/

@end
