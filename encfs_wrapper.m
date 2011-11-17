//
//  encfs_wrapper.m
//  MacFusion2
//
//  Created by Tobias Haeberle on 16.02.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    // insert code here...
    NSTask *encfsTask = [[NSTask alloc] init];
	
	NSMutableArray *arguments = [[[NSProcessInfo processInfo] arguments] mutableCopy];
	
	NSLog(@"enfs is supposed to run with the following arguments: %@", arguments);
	
	[arguments release];
	[encfsTask release];
    [pool drain];
    return 0;
}
