//
//  EncFSCreationContoller.h
//  EncFS
//
//  Created by Tobias Haeberle on 17.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>




@interface EncFSCreationController : NSWindowController {
	id representedObject;
	IBOutlet NSSecureTextField *passwordField;
	IBOutlet NSSecureTextField *passwordVerifyField;
	IBOutlet NSButton *okButton;
	
	
	NSTask *_task;
	NSString *_mountPath;

}

@property (retain) id representedObject;


- (IBAction) browse:(id)sender;
- (IBAction) create:(id)sender;
- (IBAction)cancel:(id)sender;


@end
