//
//  OutputCoreAudio.m
//  Cog
//
//  Created by Zaphod Beeblebrox on 8/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OutputCoreAudio.h"


@implementation OutputCoreAudio

- (id)initWithController:(id)c
{
	self = [super init];
	if (self)
	{
		outputController = c;
	}
	
	return self;
}

static OSStatus Sound_Renderer(void *inRefCon,  AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp  *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList  *ioData)
{
	OutputCoreAudio *output = (OutputCoreAudio *)inRefCon;
	OSStatus err = noErr;
	void *readPointer = ioData->mBuffers[0].mData;
	
	int amountToRead, amountRead;

	if ([output->outputController shouldContinue] == NO)
	{
        AudioOutputUnitStop(output->outputUnit);

		return err;
	}
	
	amountToRead = inNumberFrames*(output->deviceFormat.mBytesPerPacket);
	amountRead = [output->outputController readData:(readPointer) amount:amountToRead];
	
	ioData->mBuffers[0].mDataByteSize = amountRead;

	return err;
}	

- (BOOL)setup
{
	NSLog(@"SETUP");
	ComponentDescription desc;  
	OSStatus err;
	
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_DefaultOutput;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	Component comp = FindNextComponent(NULL, &desc);  //Finds an component that meets the desc spec's
	if (comp == NULL)
		return NO;
	
	err = OpenAComponent(comp, &outputUnit);  //gains access to the services provided by the component
	if (err)
		return NO;
	
	// Initialize AudioUnit 
	err = AudioUnitInitialize(outputUnit);
	if (err != noErr)
		return NO;
	
	
	UInt32 size = sizeof (AudioStreamBasicDescription);
	Boolean outWritable;
	//Gets the size of the Stream Format Property and if it is writable
	AudioUnitGetPropertyInfo(outputUnit,  
							 kAudioUnitProperty_StreamFormat,
							 kAudioUnitScope_Output, 
							 0, 
							 &size, 
							 &outWritable);
	//Get the current stream format of the output
	err = AudioUnitGetProperty (outputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Output,
								0,
								&deviceFormat,
								&size);
	
	if (err != noErr)
		return NO;
	
	// change output format...
	///Seems some 3rd party devices return incorrect stuff...or I just don't like noninterleaved data.
	deviceFormat.mFormatFlags &= ~kLinearPCMFormatFlagIsNonInterleaved;
//	deviceFormat.mFormatFlags &= ~kLinearPCMFormatFlagIsFloat;
//	deviceFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
	deviceFormat.mBytesPerFrame = deviceFormat.mChannelsPerFrame*(deviceFormat.mBitsPerChannel/8);
	deviceFormat.mBytesPerPacket = deviceFormat.mBytesPerFrame * deviceFormat.mFramesPerPacket;
	//	DBLog(@"stuff: %i %i %i %i", deviceFormat.mBitsPerChannel, deviceFormat.mBytesPerFrame, deviceFormat.mBytesPerPacket, deviceFormat.mFramesPerPacket);
	err = AudioUnitSetProperty (outputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Output,
								0,
								&deviceFormat,
								size);
	
	//Set the stream format of the output to match the input
	err = AudioUnitSetProperty (outputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Input,
								0,
								&deviceFormat,
								size);
	
	//setup render callbacks
	renderCallback.inputProc = Sound_Renderer;
	renderCallback.inputProcRefCon = self;
	
	AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(AURenderCallbackStruct));	

	[outputController setFormat:&deviceFormat];
	
	DBLog(@"Audio output successfully initialized");

	return (err == noErr);	
}

- (void)setVolume:(double)v
{
	AudioUnitSetParameter (outputUnit,
							kHALOutputParam_Volume,
							kAudioUnitScope_Global,
							0,
							v * 0.01f,
							0);
}	

- (void)start
{
	NSLog(@"START OUTPUT\n");
	AudioOutputUnitStart(outputUnit);
}

- (void)stop
{
	NSLog(@"STOP!");
	if (outputUnit)
	{
        AudioOutputUnitStop(outputUnit);
		AudioUnitUninitialize (outputUnit);
		CloseComponent(outputUnit);
	}
}

- (void)pause
{
	AudioOutputUnitStop(outputUnit);
}

- (void)resume
{
	AudioOutputUnitStart(outputUnit);
}

@end