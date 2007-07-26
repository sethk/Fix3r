//
//  F3AppDelegate.m
//  Fix3r
//
//  Created by Seth Kingsley on 6/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "F3AppDelegate.h"

@implementation F3AppDelegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	[[NSDocumentController sharedDocumentController] openDocument:sender];

	return NO;
}

@end
