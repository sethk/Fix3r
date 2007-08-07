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
static NSString						*kErrorDomain = @"F3Document Error Domain";
static NSString						*kDocumentType = @"MPEG Audio Layer 3";
#if XSETHK_TODO
static NSString						*kBackupExtension = @"backup.id3";
#endif // XSETHK_TODO
static NSDictionary					*kUndoStrings;

#define F3DocumentError(desc...)	[NSError errorWithDomain:kErrorDomain\
														code:-1\
													userInfo:\
								[NSDictionary dictionaryWithObject:[NSString stringWithFormat:desc]\
															forKey:NSLocalizedDescriptionKey]]

@interface F3Document (PrivateAPI)

- (NSString *)convertString:(NSString *)string;
- (void)transformStrings;
- (void)writeStrings;
- (void)setUndoValue:(NSObject *)newValue forKey:(NSString *)key;
- (void)setValue:(NSObject *)newValue forKey:(NSString *)key iVar:(NSObject **)pIVar tagValue:(NSObject *)tagValue;

@end

@implementation F3Document (PrivateAPI)

+ (NSError *)errorWithLocalizedDescription:(NSString *)description
{
	return [NSError errorWithDomain:kErrorDomain
							   code:-1
						   userInfo:[NSDictionary dictionaryWithObject:description
																forKey:NSLocalizedDescriptionKey]];
}

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

- (void)writeStrings
{
	if ([self willWriteName])
		[tag setTitle:[self name]];
	if ([self willWriteArtist])
		[tag setArtist:[self artist]];
	if ([self willWriteAlbum])
		[tag setAlbum:[self album]];
	if ([self willWriteComments])
		[tag setComments:[self comments]];
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

	if (![typeName isEqualToString:kDocumentType])
	{
		*outError = F3DocumentError(NSLocalizedString(@"Unsupported file type %@", nil), typeName);
		return NO;
	}

	if (![absoluteURL isFileURL])
	{
		*outError = F3DocumentError(NSLocalizedString(@"Can't read from a non-file URL", nil));
		return NO;
	}

	if (![tag examineFile:[absoluteURL path]])
	{
		*outError = F3DocumentError(NSLocalizedString(@"Could not read ID3 tag from file", nil));
		return NO;
	}

	[undoManager disableUndoRegistration];
	[self transformStrings];
	[undoManager enableUndoRegistration];

	return YES;
}

-	(BOOL)writeToURL:(NSURL *)absoluteURL
			  ofType:(NSString *)typeName
	forSaveOperation:(NSSaveOperationType)saveOperation
 originalContentsURL:(NSURL *)absoluteOriginalContentsURL
			   error:(NSError **)outError
{
#if SETHK_TODO
	NSString *backupPath = nil;

	if ([absoluteURL isFileURL] && [absoluteURL isEqual:absoluteOriginalContentsURL] && [tag v1TagPresent])
	{
		// Make a backup of just the tag:
		NSData *tagData;

		backupPath = [[absoluteURL path] stringByAppendingPathExtension:kBackupExtension];

		if ([tag v2TagPresent])
			tagData = [tag getV2Tag]->tag;
		else
			tagData = [tag getV1Tag]->tag;
		if (![tagData writeToFile:backupPath options:NSAtomicWrite error:outError])
		{
			F3DocumentError(NSLocalizedString(@"Could not write backup tag to \"%@\"", nil), backupPath);
			return NO;
		}
	}
#endif // SETHK_TODO

	if (![super writeToURL:absoluteURL
					ofType:typeName
		  forSaveOperation:saveOperation
	   originalContentsURL:absoluteOriginalContentsURL
					 error:outError])
	{
#if SETHK_TODO
		if (backupPath)
			[[NSFileManager defaultManager] removeFileAtPath:backupPath handler:nil];
#endif // SETHK_TODO

		return NO;
	}

	return YES;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString *oldPath, *newPath;

	if (![absoluteURL isFileURL])
	{
		*outError = F3DocumentError(NSLocalizedString(@"Can't write to non-file URL", nil));
		return NO;
	}

	oldPath = [tag getPath];
	newPath = [absoluteURL path];
	if (![oldPath isEqualToString:newPath])
	{
		if (![[NSFileManager defaultManager] copyPath:oldPath toPath:newPath handler:nil])
		{
			*outError = F3DocumentError(NSLocalizedString(@"Could not copy path \"%@\" to \"%@\"", nil),
					oldPath, newPath);
			return NO;
		}

		if (![tag examineFile:newPath])
		{
			*outError = F3DocumentError(NSLocalizedString(@"Could not read ID3 tag from file copy", nil));
			return NO;
		}
	}

	[self writeStrings];
	if ([tag updateFile] != 0)
	{
		*outError = F3DocumentError(NSLocalizedString(@"Could not update tag in file \"%@\"", nil), newPath);
		return NO;
	}

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
