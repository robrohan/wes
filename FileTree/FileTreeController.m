//
//  FileTreeController.m
//  Cog
//
//  Created by Vincent Spader on 2/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PlaylistController.h"
#import "FileTreeController.h"


@implementation FileTreeController

- (IBAction)addToPlaylist:(id)sender
{
	NSUInteger index;
	NSIndexSet *selectedIndexes = [outlineView selectedRowIndexes];
	NSMutableArray *urls = [[NSMutableArray alloc] init];

	for (index = [selectedIndexes firstIndex];
		 index != NSNotFound; index = [selectedIndexes indexGreaterThanIndex: index])  
	{
        NSObject* o = [outlineView itemAtRow:index];
        if (o != nil) {
            [urls addObject:[o URL]];
        }
    }
	
	[controller addToPlaylist:urls];
	[urls release];
}

- (IBAction)setAsPlaylist:(id)sender
{
	[controller clear:sender];
	[self addToPlaylist:sender];
}

- (IBAction)playPauseResume:(NSObject *)id
{
	[controller playPauseResume:id];
}

- (IBAction)showEntryInFinder:(id)sender
{
	unsigned int index;
	NSWorkspace* ws = [NSWorkspace sharedWorkspace];
	NSIndexSet *selectedIndexes = [outlineView selectedRowIndexes];
	
	for (index = [selectedIndexes firstIndex];
		 index != NSNotFound; index = [selectedIndexes indexGreaterThanIndex: index])  
	{
		NSURL *url = [[outlineView itemAtRow:index] URL];
		[ws selectFile:[url path] inFileViewerRootedAtPath:[url path]];
	}
}

- (IBAction)setAsRoot:(id)sender
{
	unsigned int index = [[outlineView selectedRowIndexes] firstIndex];
	
	if (index != NSNotFound)
	{
		[dataSource changeURL:[[outlineView itemAtRow:index] URL]];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	SEL action = [menuItem action];

	if ([outlineView numberOfSelectedRows] == 0)
		return NO;

	if (action == @selector(setAsRoot:))
	{
		BOOL isDir;
		NSInteger row = [outlineView selectedRow];

		if ([outlineView numberOfSelectedRows] > 1)
			return NO;

		// Only let directories be Set as Root
		[[NSFileManager defaultManager] fileExistsAtPath:[[[outlineView itemAtRow:row] URL] path] isDirectory:&isDir];
		return isDir;
	}

	return YES;
}
@end
