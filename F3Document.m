//
//  F3Document.m
//  Fix3r
//
//  Created by Seth Kingsley on 6/16/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "F3Document.h"
#import	<ID3/TagAPI.h>

static const NSStringEncoding		kDefaultStringEncoding = NSUTF8StringEncoding;
static NSDictionary					*kUndoStrings;

@interface F3Document (PrivateAPI)

- (NSString *)convertString:(NSString *)string;
- (void)transformStrings;
- (void)setUndoValue:(NSObject *)newValue forKey:(NSString *)key;
- (void)setValue:(NSObject *)newValue forKey:(NSString *)key iVar:(NSObject **)pIVar tagValue:(NSObject *)tagValue;

@end

@implementation F3Document (PrivateAPI)

- (NSString *)convertString:(NSString *)string
{
	const char *cString = [string cStringUsingEncoding:[NSString defaultCStringEncoding]];

	if (cString)
	{
		NSString *convertedString = [NSString stringWithCString:cString encoding:[self stringEncoding]];

		if (convertedString)
			return convertedString;
	}

	return string;
}

- (void)transformStrings
{
	[self setName:[self convertString:[tag getTitle]]];
	[self setArtist:[self convertString:[tag getArtist]]];
	[self setAlbum:[self convertString:[tag getAlbum]]];
	[self setComments:[self convertString:[tag getComments]]];
}

// Wrapper for undo:
- (void)setUndoValue:(NSObject *)newValue forKey:(NSString *)key
{
	[self setValue:newValue forKey:key];
}

- (void)setValue:(NSObject *)newValue forKey:(NSString *)key iVar:(NSObject **)pIVar tagValue:(NSObject *)tagValue
{
	if (*pIVar != newValue)
	{
		NSUndoManager *undoManager = [self undoManager];
		NSObject *oldValue = [[*pIVar copy] autorelease];

		[*pIVar release];
		*pIVar = [newValue copy];

		[self setValue:[NSNumber numberWithBool:(*pIVar && ![*pIVar isEqual:tagValue])]
				forKey:[NSString stringWithFormat:@"willWrite%@", [key capitalizedString]]];

		[[undoManager prepareWithInvocationTarget:self] setUndoValue:oldValue forKey:key];
		if (![undoManager isUndoing])
			[undoManager setActionName:[kUndoStrings objectForKey:key]];
	}
}

@end

@implementation F3Document

+ (void)initialize
{
	if (!kUndoStrings)
		kUndoStrings = [[NSDictionary alloc] initWithObjectsAndKeys:
				NSLocalizedString(@"Change Name", @"Undo action -- change name"), @"name",
				NSLocalizedString(@"Change Artist", @"Undo action -- change artist"), @"artist",
				NSLocalizedString(@"Change Album", @"Undo action -- change album"), @"album",
				NSLocalizedString(@"Change Comments", @"Undo action -- change comments"), @"comments",
				nil];
}

- init
{
	if ((self = [super init]))
	{
		tag = [[TagAPI alloc] initWithGenreList:nil];
		stringEncoding = kDefaultStringEncoding;
		NSAssert(tag, @"Could not initialize ID3 library");
	}

	return self;
}

- (NSString *)windowNibName
{
	return @"F3Document";
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSUndoManager *undoManager = [self undoManager];

	if (![absoluteURL isFileURL])
		return NO;

	if (![tag examineFile:[absoluteURL path]])
		return NO;

	[undoManager disableUndoRegistration];
	[self transformStrings];
	[undoManager enableUndoRegistration];

	return YES;
}

- (NSStringEncoding)stringEncoding
{
	return stringEncoding;
}

- (void)setStringEncoding:(NSStringEncoding)newStringEncoding
{
	if (stringEncoding != newStringEncoding)
	{
		NSUndoManager *undoManager = [self undoManager];
		NSStringEncoding oldStringEncoding = stringEncoding;

		stringEncoding = newStringEncoding;
		if (![undoManager isUndoing] && ![undoManager isRedoing])
			[self transformStrings];

		[[undoManager prepareWithInvocationTarget:self] setStringEncoding:oldStringEncoding];
		if (![undoManager isUndoing])
			[undoManager setActionName:NSLocalizedString(@"Change String Encoding",
					@"Undo action -- change string encoding")];
	}
}

- (NSString *)name
{
	return name;
}

- (void)setName:(NSString *)newName
{
	[self setValue:newName forKey:@"name" iVar:&name tagValue:[tag getTitle]];
}

- (BOOL)willWriteName
{
	return willWriteName;
}

- (void)setWillWriteName:(BOOL)newWillWriteName
{
	NSUndoManager *undoManager = [self undoManager];

	[[undoManager prepareWithInvocationTarget:self] setWillWriteName:willWriteName];
	if (![undoManager isUndoing])
		[undoManager setActionName:NSLocalizedString(@"Toggle Write Name", @"Undo action -- toggle write name")];

	willWriteName = newWillWriteName;
}

- (NSString *)artist
{
	return artist;
}

- (void)setArtist:(NSString *)newArtist
{
	[self setValue:newArtist forKey:@"artist" iVar:&artist tagValue:[tag getArtist]];
}

- (BOOL)willWriteArtist
{
	return willWriteArtist;
}

- (void)setWillWriteArtist:(BOOL)newWillWriteArtist
{
	NSUndoManager *undoManager = [self undoManager];

	[[undoManager prepareWithInvocationTarget:self] setWillWriteArtist:willWriteArtist];
	if (![undoManager isUndoing])
		[undoManager setActionName:NSLocalizedString(@"Toggle Write Artist", @"Undo action -- toggle write artist")];

	willWriteArtist = newWillWriteArtist;
}

- (NSString *)album
{
	return album;
}

- (void)setAlbum:(NSString *)newAlbum
{
	[self setValue:newAlbum forKey:@"album" iVar:&album tagValue:[tag getAlbum]];
}

- (BOOL)willWriteAlbum
{
	return willWriteAlbum;
}

- (void)setWillWriteAlbum:(BOOL)newWillWriteAlbum
{
	NSUndoManager *undoManager = [self undoManager];

	[[undoManager prepareWithInvocationTarget:self] setWillWriteAlbum:willWriteAlbum];
	if (![undoManager isUndoing])
		[undoManager setActionName:NSLocalizedString(@"Toggle Write Album", @"Undo action -- toggle write album")];

	willWriteAlbum = newWillWriteAlbum;
}

- (NSString *)comments
{
	return comments;
}

- (void)setComments:(NSString *)newComments
{
	[self setValue:newComments forKey:@"comments" iVar:&comments tagValue:[tag getComments]];
}

- (BOOL)willWriteComments
{
	return willWriteComments;
}

- (void)setWillWriteComments:(BOOL)newWillWriteComments
{
	NSUndoManager *undoManager = [self undoManager];

	[[undoManager prepareWithInvocationTarget:self] setWillWriteComments:willWriteComments];
	if (![undoManager isUndoing])
		[undoManager setActionName:NSLocalizedString(@"Toggle Write Comments",
				@"Undo action -- toggle write comments")];

	willWriteComments = newWillWriteComments;
}

@end
