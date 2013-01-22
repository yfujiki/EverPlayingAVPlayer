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
    AudioComponentInstance toneUnit;

@public
    double theta;
}

+ (SilentPlayer *)sharedInstance;

- (void)togglePlay;
- (void)pause;
- (void)start;
- (void)stop;

@end
