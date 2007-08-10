//
//  F3Document.h
//  Fix3r
//
//  Created by Seth Kingsley on 6/16/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TagAPI;
@class id3V1Tag;

@interface F3Document : NSDocument
{
@protected
	TagAPI *tag;
	id3V1Tag *v1Tag;

@private
	NSStringEncoding stringEncoding;
	NSString *name;
	BOOL willWriteName;
	NSString *artist;
	BOOL willWriteArtist;
	NSString *album;
	BOOL willWriteAlbum;
	NSString *comments;
	BOOL willWriteComments;
}

- (NSStringEncoding)stringEncoding;
- (void)setStringEncoding:(NSStringEncoding)newStringEncoding;
- (NSString *)name;
- (void)setName:(NSString *)newName;
- (BOOL)willWriteName;
- (void)setWillWriteName:(BOOL)newWillWriteName;
- (NSString *)artist;
- (void)setArtist:(NSString *)newArtist;
- (BOOL)willWriteArtist;
- (void)setWillWriteArtist:(BOOL)newWillWriteArtist;
- (NSString *)album;
- (void)setAlbum:(NSString *)newAlbum;
- (BOOL)willWriteAlbum;
- (void)setWillWriteAlbum:(BOOL)newWillWriteAlbum;
- (NSString *)comments;
- (void)setComments:(NSString *)newComments;
- (BOOL)willWriteComments;
- (void)setWillWriteComments:(BOOL)newWillWriteComments;

@end
