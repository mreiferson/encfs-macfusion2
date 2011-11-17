//
//  EncfsConfigurationController.h
//  MacFusion2
//
//  Created by Tobias Haeberle on 15.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EncFSCreationController;

@interface EncfsConfigurationController : NSViewController {
	IBOutlet NSTextField *pathField;
	IBOutlet EncFSCreationController *creationController;
}

+ (BOOL) checkRawPath:(NSString *)dirPath withError:(NSError **)error;

- (IBAction)browse:(id)sender;
- (IBAction) createNewFS: (id)sender;
@end
