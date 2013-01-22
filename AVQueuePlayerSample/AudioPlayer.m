//
//  AudioPlayer.m
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 1/21/13.
//  Copyright (c) 2013 Yuichi Fujiki. All rights reserved.
//

#import "AudioPlayer.h"

@interface AudioPlayer ()

@property (nonatomic, strong) AVQueuePlayer * queuePlayer;
@property (nonatomic, strong) AVPlayer * silentPlayer;

@property (nonatomic, strong) NSArray * tracks;
@property (nonatomic, strong) NSString * silentTrack;

@property (nonatomic, strong) NSTimer * timer;

@end

@implementation AudioPlayer

static NSString * PlayerStatusContext = @"PlayerStatus";
static NSString * PlayerRateContext = @"PlayerRate";
static NSString * CurrentItemContext = @"CurrentItem";
static NSString * PlaybackLikelyToKeepUp = @"PlaybackLikelyToKeepUp";
static NSString * ItemStatusContext = @"ItemStatus";

static NSString * SilentPlayerStatusContext = @"SilentPlayerStatus";
static NSString * SilentPlayerRateContext = @"SilentPlayerRate";
static NSString * SilentPlayerCurrentItemContext = @"SilentPlayerCurrentItem";
static NSString * SilentPlayerPlaybackLikelyToKeepUp = @"SilentPlayerPlaybackLikelyToKeepUp";
static NSString * SilentPlayerItemStatusContext = @"SilentPlayerItemStatus";

- (id) init {
    self = [super init];
    if(self) {
//        [self loadSilentTracks];
        [self loadTracks];
        [self registerObservers];
    }
    return self;
}

- (void)loadTracks {
    
    self.tracks = @[
        @"http://s3.amazonaws.com/deliradio/uploads/track/band/11722/43168/purchase_and_radio_Charlie_Robison_Good_Times.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/1575/5071/purchase_and_radio_11_Leave.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/25/248/radio_01_Goodbye_California.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/758/2444/radio_02_Pass_The_Peas.mp3",
        @"http://s3.amazonaws.com/deliradio/uploads/track/band/12274/44973/radio_The_Fontaine_Classic_-_Latest_Faith_EP_-_05_Pioneer.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/6752/26169/purchase_and_radio_RudePrudeFINAL.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/5700/23251/radio_4_Western_Steppes.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/4487/17668/radio_02_Green___Gold.mp3",
        @"https://deliradio.s3.amazonaws.com/uploads/track/band/451/1352/purchase_and_radio_04_Church_of_Hanging_Leaders.mp3"
    ];
    
    NSMutableArray * items = [@[] mutableCopy];
    
    [self.tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL URLWithString:obj]];
        AVPlayerItem * item = [[AVPlayerItem alloc] initWithAsset:asset];
        [items addObject:item];
    }];
    
    self.queuePlayer = [[AVQueuePlayer alloc] initWithItems:items];
    
//    self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(timer:) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timer:(id)sender {
    NSLog(@"(Timer) Player Status : %d", self.queuePlayer.status);
    NSLog(@"(Timer) Current Item Status : %d", self.queuePlayer.currentItem.status);
    NSLog(@"(Timer) Playback Rate : %f", self.queuePlayer.rate);
}

- (void)reloadSilentTracks {
    [self.silentPlayer removeObserver:self forKeyPath:@"status"];
    [self.silentPlayer removeObserver:self forKeyPath:@"currentItem"];
    [self.silentPlayer removeObserver:self forKeyPath:@"rate"];
    
    [self.silentPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.silentPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepup"];
    
    [self loadSilentTracks];
}

- (void)loadSilentTracks {
    self.silentTrack = [[NSBundle mainBundle] URLForResource:@"blank-1sec" withExtension:@"mp3"].absoluteString;
    
    AVPlayerItem * item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.silentTrack]];
    self.silentPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
    self.silentPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.silentPlayer.rate = 0.001f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSilentTrackFinishedNotification:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];
    
    [self.silentPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&SilentPlayerStatusContext];
    [self.silentPlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&SilentPlayerCurrentItemContext];
    [self.silentPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&SilentPlayerRateContext];
    
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&SilentPlayerItemStatusContext];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepup" options:NSKeyValueObservingOptionNew context:&SilentPlayerPlaybackLikelyToKeepUp];
    
//    [self.silentPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f)
//                                                   queue:dispatch_get_main_queue()
//                                              usingBlock:^(CMTime time) {
//                                                  NSLog(@"Checking int...");
//                                              }];

}

- (void)registerObservers {
    [self.queuePlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&PlayerStatusContext];
    [self.queuePlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&CurrentItemContext];
    [self.queuePlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&PlayerRateContext];
    
    __weak id weakSelf = self;
    [self.queuePlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f)
                                                   queue:dispatch_get_main_queue()
                                              usingBlock:^(CMTime time) {
                                                  [weakSelf updateProgress:nil];
                                                  NSLog(@"Player Status : %d", self.queuePlayer.status);
                                                  NSLog(@"Current Item Status : %d", self.queuePlayer.currentItem.status);
                                                  NSLog(@"Playback Rate : %f", self.queuePlayer.rate);                                                  
                                              }];    
}

- (void)registerObserversForItem : (AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:&PlaybackLikelyToKeepUp];
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&ItemStatusContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTrackFinishedNotification:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];
}

- (void)unregisterObserversForItem : (AVPlayerItem *)item {
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [item removeObserver:self forKeyPath:@"status"];
}

- (CMTime) currentTime {
    return self.queuePlayer.currentItem.currentTime;
}

- (CMTime) duration {
    return self.queuePlayer.currentItem.duration;
}

- (CGFloat) currentProgress {
    NSTimeInterval currentTime = self.currentTime.value / self.currentTime.timescale;
    NSTimeInterval duration = self.duration.value / self.duration.timescale;
    return (currentTime / duration);
}

- (void) play {
    [self.queuePlayer play];
    [self.silentPlayer play];
    
    // Issue play event
}

- (void) pause {    
    [self.queuePlayer pause];
    [self.silentPlayer pause];
    
    // Issue pause event
}

- (void) seekToTime:(CMTime)currentTime completionHandler:(void (^)(BOOL finished))completionHandler {
//    [self.silentPlayer pause];
    [self.queuePlayer pause];
    
    [self.queuePlayer seekToTime:currentTime completionHandler:^(BOOL finished) {

//        [self reloadSilentTracks];
        
        [self.queuePlayer play];
        
        completionHandler(finished);
    }];
}

- (void)updateProgress:(id)sender {
    CMTime currentTime = self.currentTime;
    CMTime duration = self.duration;
    
    NSTimeInterval currentTime_ = currentTime.value * 1.0f / currentTime.timescale;
    NSTimeInterval duration_ = duration.value * 1.0f / duration.timescale;
    
    if(duration_ == 0.f) {
        NSLog(@"EEEEEEEEEEEEEMERGENCY for %@", self.queuePlayer.currentItem);
        NSLog(@"Player status : %d, rate : %f", self.queuePlayer.status, self.queuePlayer.rate);
        NSLog(@"Player item status : %d", self.queuePlayer.currentItem.status);
        currentTime_ = 0.f;
        duration_ = 1.f;
    }
    
    NSDictionary * progress = @{@"currentTime" : [NSNumber numberWithDouble:currentTime_],
                                @"duration" : [NSNumber numberWithDouble:duration_] };
    
    NSLog(@"Progress : %f", currentTime_ * 1.0f/ duration_);

    [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerProgressUpdatedEvent object:progress];
}
#pragma mark - key value observation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &SilentPlayerStatusContext) {
        if ([self.silentPlayer status] == AVPlayerStatusReadyToPlay) {
            [self.silentPlayer play];
        } else if ([self.silentPlayer status] == AVPlayerStatusFailed) {
            NSLog(@"Silent player failed.");
//            [self reloadSilentTracks];
        }
    } else if (context == &PlayerStatusContext) {
        AVPlayer *thePlayer = (AVPlayer *)object;
        if ([thePlayer status] == AVPlayerStatusFailed) {
            NSError *error = [thePlayer error];
            NSLog(@"Some error occured while preparing player : %@", [error localizedDescription]);
            return;
        } else {
            [self registerObserversForItem:self.queuePlayer.currentItem];
            
            // Issue player ready event
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerReadyEvent object:nil];
            
            // Issue item changed event
            AVURLAsset * asset = (AVURLAsset *)self.queuePlayer.currentItem.asset;
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerItemChangedEvent object:asset];
        }
    } else if(context == &SilentPlayerCurrentItemContext) {
        // Nothing to do
    } else if(context == &CurrentItemContext) {
        AVPlayerItem * oldPlayerItem = change[NSKeyValueChangeOldKey];
        if(oldPlayerItem) {
            [self unregisterObserversForItem:oldPlayerItem];
        }
        [self registerObserversForItem:self.queuePlayer.currentItem];
        
        // Issue item changed event
        AVURLAsset * asset = (AVURLAsset *)self.queuePlayer.currentItem.asset;
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerItemChangedEvent object:asset];
        
    } else if(context == &SilentPlayerRateContext) {
        float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
        float newRate = [change[NSKeyValueChangeNewKey] floatValue];
        NSLog(@"Silent Player rate changed from %f to %f", oldRate, newRate);
        if(newRate == 0.0 && oldRate == 1.0) {
            // It means that the player has stopped for whatever reason
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                self.silentPlayer.rate = 1.0;
//            });
        }
        
    } else if(context == &PlayerRateContext) {
        float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
        float newRate = [change[NSKeyValueChangeNewKey] floatValue];
        NSLog(@"Player rate changed from %f to %f", oldRate, newRate);
        if(newRate == 0.0 && oldRate == 1.0) {
            // It means that the player has stopped for whatever reason
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                self.queuePlayer.rate = 1.0;                
            });
        }
        
    } else if(context == &SilentPlayerPlaybackLikelyToKeepUp) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.playbackLikelyToKeepUp) {
            [self.silentPlayer play];
            NSLog(@"Silent Player Play item due to likelyToKeepUp");
        } else {
            NSLog(@"Silent Player Pause (not) item due to likelyToKeepUp");
        }
    } else if(context == &PlaybackLikelyToKeepUp) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.playbackLikelyToKeepUp) {
            [self play];
            NSLog(@"Play item due to likelyToKeepUp");
        } else {
            NSLog(@"Pause (not) item due to likelyToKeepUp");
        }
    } else if(context == &SilentPlayerItemStatusContext) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.status == AVPlayerItemStatusReadyToPlay) {
//            [self.silentPlayer play];
            NSLog(@"Silent Player Play item due to status");
        } else if(item.status == AVPlayerItemStatusFailed) {
            NSLog(@"Silent Player Item status failed !!!!!!!!!!!!!!!!!!");
        } else {
            // Unknown
        }
    } else if(context == &ItemStatusContext) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.status == AVPlayerItemStatusReadyToPlay) {
//            [self play];
            NSLog(@"Play item due to status");
        } else if(item.status == AVPlayerItemStatusFailed) {
            NSLog(@"Item status failed !!!!!!!!!!!!!!!!!!");
        } else {
            NSLog(@"Item status has changed to unknown");
            // Unknown
        }
    } else {
        return [super observeValueForKeyPath:keyPath ofObject:object
                                      change:change context:context];
    }
    return;
}

- (void)onTrackFinishedNotification:(NSNotification *)notification {
    [self.queuePlayer advanceToNextItem];
}

- (void)onSilentTrackFinishedNotification:(NSNotification *)notification {
    AVPlayerItem * item = [notification object];
    [item seekToTime:kCMTimeZero];
    [self.silentPlayer play];
    
    // Check status of main player and resume depending on the Reachability status
    NSLog(@"Checking....");    
}


@end
