//
//  M3uContainer.m
//  M3u
//
//  Created by Zaphod Beeblebrox on 10/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "M3uContainer.h"


@implementation M3uContainer

+ (NSArray *)fileTypes
{
	return [NSArray arrayWithObject:@"m3u"];
}

+ (NSArray *)mimeTypes
{
	return [NSArray arrayWithObjects:@"audio/x-mpegurl", @"audio/mpegurl", nil];
}

+ (NSURL *)urlForPath:(NSString *)path relativeTo:(NSString *)baseFilename
{
	NSRange protocolRange = [path rangeOfString:@"://"];
	if (protocolRange.location != NSNotFound) 
	{
		return [NSURL URLWithString:path];
	}

	NSMutableString *unixPath = [path mutableCopy];

	NSString *fragment = @"";
	NSRange fragmentRange = [path rangeOfString:@"#"];
	if (fragmentRange.location != NSNotFound) 
	{
		fragmentRange = NSMakeRange(fragmentRange.location, [unixPath length] - fragmentRange.location);
		
		fragment = [unixPath substringWithRange:fragmentRange];
		[unixPath deleteCharactersInRange:fragmentRange];
	}

	if (![unixPath hasPrefix:@"/"]) {
		//Only relative paths would have windows backslashes.
		[unixPath replaceOccurrencesOfString:@"\\" withString:@"/" options:0 range:NSMakeRange(0, [unixPath length])];
		
		NSString *basePath = [[[baseFilename stringByStandardizingPath] stringByDeletingLastPathComponent] stringByAppendingString:@"/"];

		[unixPath insertString:basePath atIndex:0];
	}
	
	//Append the fragment
	return [NSURL URLWithString:[[[NSURL fileURLWithPath:unixPath] absoluteString] stringByAppendingString: fragment]];
}

+ (NSArray *)urlsForContainerURL:(NSURL *)url
{
	if (![url isFileURL]) 
		return [NSArray array];
	
	NSString *filename = [url path];
	
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
	if (error || !contents) {
		NSLog(@"Could not open file...%@ %@", contents, error);
		return NO;
	}
	
	NSString *entry;
	NSEnumerator *e = [[contents componentsSeparatedByString:@"\n"] objectEnumerator];
	NSMutableArray *entries = [NSMutableArray array];
	
	while (entry = [[e nextObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])
	{
		if ([entry hasPrefix:@"#"] || [entry isEqualToString:@""]) //Ignore extra info
			continue;
		
		//Need to add basePath, and convert to URL
		[entries addObject:[self urlForPath:entry relativeTo:filename]];		
	}
	
	return entries;
}

@end
