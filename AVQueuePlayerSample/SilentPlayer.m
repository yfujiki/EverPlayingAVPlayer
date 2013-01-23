//
//  SilentPlayer.m
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 1/22/13.
//  Copyright (c) 2013 Yuichi Fujiki. All rights reserved.
//

#import "SilentPlayer.h"

#define kSampleRate 44100
#define kFrequency  400

OSStatus RenderTone(void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
	// Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;
    
	// Get the tone parameters out of the view controller
	SilentPlayer *player = (__bridge SilentPlayer *)inRefCon;
	double theta = player->theta;
	double theta_increment = 2.0 * M_PI * kFrequency / kSampleRate;
    
	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++)
	{
		buffer[frame] = sin(theta) * amplitude;
		
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
		}
	}
	
	player->theta = theta;

    if(time(NULL) - player->timeoutBase > player->timeout) {
        [player stop];
    }
    
	return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	SilentPlayer * player =
    (__bridge SilentPlayer *)inClientData;
	
	[player stop];
}

@implementation SilentPlayer

+ (SilentPlayer *)sharedInstance {
    static SilentPlayer *__instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[SilentPlayer alloc] init];
    });
    return __instance;
}

- (id) init {
    self = [super init];
    if(self) {
        timeout = LONG_MAX;
        timeoutBase = 0;
        theta = 0;
    }
    return self;
}

- (void)createToneUnit {
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &_toneUnit);
	NSAssert1(_toneUnit, @"Error creating unit: %d", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(_toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %d", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = kSampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (_toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %d", err);
}

- (void)togglePlay
{
	if (_toneUnit)
	{
		[self pause];
	}
	else
	{
        [self play];
	}
}

- (void)start {
    
	OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
	if (result == kAudioSessionNoError)
	{
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	}
//	AudioSessionSetActive(true);
    
    [self play];
    
    timeoutBase = time(NULL);
}

- (void)stop {
    [self pause];
        
//	AudioSessionSetActive(false);
}

- (void)play
{
    if(!_toneUnit)
    {
		[self createToneUnit];
		
		// Stop changing parameters on the unit
		OSErr err = AudioUnitInitialize(_toneUnit);
//		NSAssert1(err == noErr, @"Error initializing unit: %d", err);
		
		// Start playback
		err = AudioOutputUnitStart(_toneUnit);
//		NSAssert1(err == noErr, @"Error starting unit: %d", err);
    }
}

- (void)pause
{
    if (_toneUnit)
	{
		AudioOutputUnitStop(_toneUnit);
		AudioUnitUninitialize(_toneUnit);
		AudioComponentInstanceDispose(_toneUnit);
		_toneUnit = nil;
	}
}

- (NSTimeInterval) timeoutSeconds {
    return 60;
}

@end
