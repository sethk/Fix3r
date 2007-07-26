//
//  F3TagController.m
//  Fix3r
//
//  Created by Seth Kingsley on 6/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import	"F3Document.h"
#import "F3TagController.h"

@interface F3StringEncoding : NSObject
{
	NSStringEncoding encoding;
}

+ (F3StringEncoding *)encodingWithEncoding:(NSStringEncoding)newEncoding;
- initWithEncoding:(NSStringEncoding)newEncoding;
- (unsigned)unsignedIntValue;
- (NSString *)prefix;
- (NSComparisonResult)compare:(F3StringEncoding *)otherEncoding;
- (NSStringEncoding)encoding;

@end

@implementation F3StringEncoding

+ (F3StringEncoding *)encodingWithEncoding:(NSStringEncoding)newEncoding
{
	return [[[F3StringEncoding alloc] initWithEncoding:newEncoding] autorelease];
}

- initWithEncoding:(NSStringEncoding)newEncoding
{
	if ((self = [super init]))
	{
		encoding = newEncoding;
	}

	return self;
}

- (NSString *)description
{
	return [NSString localizedNameOfStringEncoding:[self encoding]];
}

- (unsigned)unsignedIntValue
{
	return [self encoding];
}

- (NSString *)prefix
{
	NSString *encodingName = [self description];
	unsigned prefixLength = [encodingName rangeOfString:@" ("].location;

	if (prefixLength != NSNotFound)
		return [encodingName substringWithRange:NSMakeRange(0, prefixLength + 2)];

	return encodingName;
}

- (NSComparisonResult)compare:(F3StringEncoding *)otherEncoding
{
	NSStringEncoding theEncoding = [self encoding], theOtherEncoding = [otherEncoding encoding];

	if (theOtherEncoding == theEncoding)
		return NSOrderedSame;
	else
	{
		NSComparisonResult result = [[self prefix] compare:[otherEncoding prefix]];

		if (result == NSOrderedSame)
		{
			if (theOtherEncoding > theEncoding)
				result = NSOrderedAscending;
			else
				result = NSOrderedDescending;
		}

		return result;
	}
}

- (NSStringEncoding)encoding
{
	return encoding;
}

@end

@interface F3TagController (PrivateAPI)

- (void)windowWillClose:(NSNotification *)notification;
- (void)updateStringEncoding;
- (NSMenuItem *)menuItemWithStringEncoding:(NSStringEncoding)encoding title:(NSString *)title;
- (void)addItemInMenu:(NSMenu *)menu forStringEncoding:(F3StringEncoding *)stringEncoding title:(NSString *)title;

@end

@implementation F3TagController (PrivateAPI)

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowWillCloseNotification
												  object:window];

	[document removeObserver:self forKeyPath:@"stringEncoding"];
}

- (void)updateStringEncoding
{
	NSStringEncoding encoding = [document stringEncoding];
	NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
	NSMenuItem *newMenuItem;

	[[[stringEncodingPopUp menu] itemAtIndex:0] setTitle:encodingName];
	[stringEncodingPopUp selectItemAtIndex:0];

	newMenuItem = [menuItemsByEncoding objectForKey:[NSNumber numberWithUnsignedInt:encoding]];
	if (selectedEncodingMenuItem != newMenuItem)
	{
		NSMenu *menu = [selectedEncodingMenuItem menu],
		*newMenu = [newMenuItem menu],
		*supermenu = [stringEncodingPopUp menu];

		if (menu != newMenu)
		{
			if (menu != supermenu)
				[[supermenu itemAtIndex:[supermenu indexOfItemWithSubmenu:menu]] setState:NSOffState];
			if (newMenu != supermenu)
				[[supermenu itemAtIndex:[supermenu indexOfItemWithSubmenu:newMenu]] setState:NSMixedState];
		}

		[selectedEncodingMenuItem setState:NSOffState];
		selectedEncodingMenuItem = newMenuItem;
		[selectedEncodingMenuItem setState:NSOnState];
	}
}

- (NSMenuItem *)menuItemWithStringEncoding:(NSStringEncoding)encoding title:(NSString *)title
{
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title
												   action:@selector(stringEncodingChanged:)
											keyEquivalent:@""] autorelease];

	[item setTarget:self];
	[item setTag:encoding];

	return item;
}

- (void)addItemInMenu:(NSMenu *)menu forStringEncoding:(F3StringEncoding *)stringEncoding title:(NSString *)title
{
	NSStringEncoding encoding = [stringEncoding encoding];
	NSMenuItem *item = [self menuItemWithStringEncoding:encoding title:title];

	[menu addItem:item];
	[menuItemsByEncoding setObject:item forKey:[NSNumber numberWithUnsignedInt:encoding]];
}

@end

@implementation F3TagController

- init
{
	if ((self = [super init]))
	{
		menuItemsByEncoding = [NSMutableDictionary new];
	}

	return self;
}

- (void)dealloc
{
	[menuItemsByEncoding release];

	[super dealloc];
}

- (void)awakeFromNib
{
	NSMutableArray *stringEncodings = [NSMutableArray new];
	const NSStringEncoding *encodings = [NSString availableStringEncodings];
	unsigned i;
	NSMenu *menu, *submenu;
	NSEnumerator *enm;
	F3StringEncoding *encoding;

	[document addObserver:self forKeyPath:@"stringEncoding" options:0 context:NULL];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:window];

	for (i = 0; encodings[i]; ++i)
		[stringEncodings addObject:[F3StringEncoding encodingWithEncoding:encodings[i]]];
	[stringEncodings sortUsingSelector:@selector(compare:)];

	menu = submenu = [[[NSMenu alloc] initWithTitle:@"String Encodings"] autorelease];

	[menu addItemWithTitle:@"[Current Item]" action:NULL keyEquivalent:@""];
	[menu addItem:[NSMenuItem separatorItem]];

	enm = [stringEncodings objectEnumerator];
	encoding = [enm nextObject];
	while (encoding)
	{
		NSString *encodingName = [encoding description];
		// TODO: Use [encoding prefix]:
		unsigned prefixLength = [encodingName rangeOfString:@" ("].location;
		F3StringEncoding *nextEncoding = [enm nextObject];
		NSString *nextEncodingName = [nextEncoding description];
		NSMenu *submenu = nil;

		if (prefixLength != NSNotFound)
		{
			NSString *prefix = [encodingName substringWithRange:NSMakeRange(0, prefixLength + 2)];

			if ([nextEncodingName hasPrefix:prefix])
			{
				NSString *itemTitle;
				F3StringEncoding *subEncoding = nextEncoding;
				NSString *subEncodingName = nextEncodingName;

				itemTitle = [encodingName substringWithRange:NSMakeRange(prefixLength + 2,
						[encodingName length] - (prefixLength + 3))];
				encodingName = [encodingName substringWithRange:NSMakeRange(0, prefixLength)];
				submenu = [[[NSMenu alloc] initWithTitle:encodingName] autorelease];

				[self addItemInMenu:submenu forStringEncoding:encoding title:itemTitle];

				do
				{
					[self addItemInMenu:submenu
					  forStringEncoding:subEncoding
								  title:[subEncodingName substringWithRange:NSMakeRange(prefixLength + 2,
										  [subEncodingName length] - (prefixLength + 3))]];

					subEncoding = [enm nextObject];
					subEncodingName = [subEncoding description];
				} while ([subEncodingName hasPrefix:prefix]);
				nextEncoding = subEncoding;
			}
		}

		if (submenu)
			[[menu addItemWithTitle:encodingName action:NULL keyEquivalent:@""] setSubmenu:submenu];
		else
			[self addItemInMenu:menu forStringEncoding:encoding title:encodingName];

		encoding = nextEncoding;
	}

	[stringEncodingPopUp setMenu:menu];

	[self updateStringEncoding];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ([keyPath isEqualToString:@"stringEncoding"])
		[self updateStringEncoding];
}

- (IBAction)stringEncodingChanged:(id)sender
{
	int tag = [sender tag];

	[document setStringEncoding:tag];
}

@end
