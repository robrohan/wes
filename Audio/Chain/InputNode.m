//
//  InputNode.m
//  Cog
//
//  Created by Vincent Spader on 8/2/05.
//  Copyright 2005 Vincent Spader. All rights reserved.
//

#import "InputNode.h"
#import "BufferChain.h"
#import "Plugin.h"
#import "CoreAudioUtils.h"

@implementation InputNode

- (BOOL)openURL:(NSURL *)url withSource:(id<CogSource>)source outputFormat:(AudioStreamBasicDescription)of
{
	outputFormat = of;
	
	NSLog(@"Opening: %@", url);
	decoder = [AudioDecoder audioDecoderForURL:url];
	[decoder retain];

	converter = [[Converter alloc] init];
	if (converter == nil)
		return NO;
	
	[self registerObservers];

	NSLog(@"Got decoder...%@", decoder);
	if (decoder == nil)
		return NO;

	if (![decoder open:source])
	{
		NSLog(@"Couldn't open decoder...");
		return NO;
	}
	
	shouldContinue = YES;
	shouldSeek = NO;
	
	NSLog(@"OPENED");
	return YES;
}

- (void)registerObservers
{
	[decoder addObserver:self
			  forKeyPath:@"properties" 
				 options:(NSKeyValueObservingOptionNew)
				 context:NULL];

	NSLog(@"ADDED OBSERVER!!!");
	
	[decoder addObserver:self
			  forKeyPath:@"metadata" 
				 options:(NSKeyValueObservingOptionNew)
				 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if ([keyPath isEqual:@"properties"]) {
		NSLog(@"Properties changed!");
		//Setup converter!
		[converter cleanUp];
		NSLog(@"CLEANED UP");
		[converter setupWithInputFormat:propertiesToASBD([decoder properties]) outputFormat:outputFormat];
		NSLog(@"CREATED CONVERTED");
		//Inform something of properties change
	}
	else if ([keyPath isEqual:@"metadata"]) {
		//Inform something of metadata change
	}
}

- (void)process
{
	int amountRead, amountConverted;
	void *inputBuffer = malloc(CHUNK_SIZE);
	
	NSLog(@"Playing file: %i", self);
	
	while ([self shouldContinue] == YES && [self endOfStream] == NO)
	{
		if (shouldSeek == YES)
		{
			NSLog(@"Actually seeking");
			[decoder seekToTime:seekTime];
			shouldSeek = NO;
		}
		
		amountRead = [decoder fillBuffer:inputBuffer ofSize:CHUNK_SIZE];
		amountConverted = [converter convert:inputBuffer amount:amountRead]; //Convert fills in converter buffer, til the next call
		if (amountConverted <= 0)
		{
			endOfStream = YES;
			[controller endOfInputReached];
			break; //eof
		}
		
		[self writeData:[converter outputBuffer] amount:amountConverted];
	}
	
	[decoder close];
	[converter cleanUp];
	
	free(inputBuffer);
	
	NSLog(@"CLOSED: %i", self);
}

- (void)seek:(double)time
{
	NSLog(@"SEEKING WEEE");
	seekTime = time;
	shouldSeek = YES;
}

- (void)dealloc
{
	[decoder removeObserver:self forKeyPath:@"properties"];
	[decoder removeObserver:self forKeyPath:@"metadata"];

	[decoder release];
	
	[super dealloc];
}

- (NSDictionary *) properties
{
	return [decoder properties];
}

@end
