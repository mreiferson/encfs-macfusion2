//
//  ENCFSDelegate.h
//  MacFusion2
//
//  Created by Tobias Haeberle on 15.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFSDelegateProtocol.h"

extern NSString *kENCFSRawPathKey;

@interface ENCFSDelegate : NSObject <MFFSDelegateProtocol> {
	NSString *_tempMountPoint;
}



@end
