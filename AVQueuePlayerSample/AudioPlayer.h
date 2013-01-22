//
//  AudioPlayer.h
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 1/21/13.
//  Copyright (c) 2013 Yuichi Fujiki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


#define kPlayerReadyEvent       @"PlayerReadyEvent"
#define kPlayerItemChangedEvent @"PlayerItemChangedEvent"
#define kPlayerStartedEvent     @"PlayerStartedEvent"
#define kPlayerPausedEvent      @"PlayerPausedEvent"
#define kPlayerProgressUpdatedEvent @"PlayerProgressUpdatedEvent"

@interface AudioPlayer : NSObject

- (void) play;
- (void) pause;
- (void) seekToTime:(CMTime)currentTime completionHandler:(void (^)(BOOL finished))completionHandler;

@property (nonatomic) CMTime currentTime;
@property (nonatomic) CMTime duration;


@end
