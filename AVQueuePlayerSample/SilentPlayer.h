//
//  SilentPlayer.h
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 1/22/13.
//  Copyright (c) 2013 Yuichi Fujiki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SilentPlayer : NSObject {
    AudioComponentInstance _toneUnit;

@public
    time_t timeoutBase;
    time_t timeout;
    double theta;
}

+ (SilentPlayer *)sharedInstance;

- (void)togglePlay;
- (void)start;
- (void)stop;
- (void)play;
- (void)pause;

@end
