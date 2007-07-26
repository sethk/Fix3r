//
//  F3TagController.h
//  Fix3r
//
//  Created by Seth Kingsley on 6/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class F3Document;

@interface F3TagController : NSObject
{
@public
	IBOutlet F3Document *document;
	IBOutlet NSWindow *window;
	IBOutlet NSPopUpButton *stringEncodingPopUp;

@protected
	NSMenuItem *selectedEncodingMenuItem;
	NSMutableDictionary *menuItemsByEncoding;
}

- (IBAction)stringEncodingChanged:(id)sender;

@end
