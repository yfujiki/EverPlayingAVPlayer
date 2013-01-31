//
//  AudioPlayer.m
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 1/21/13.
//  Copyright (c) 2013 Yuichi Fujiki. All rights reserved.
//

#import "AudioPlayer.h"
#import "SilentPlayer.h"

@interface AudioPlayer ()

@property (nonatomic, strong) AVQueuePlayer * queuePlayer;
@property (nonatomic, strong) NSArray * tracks;
@property (nonatomic, strong) id timeObserver;

@end

@implementation AudioPlayer

static NSString * PlayerStatusContext = @"PlayerStatus";
static NSString * PlayerRateContext = @"PlayerRate";
static NSString * CurrentItemContext = @"CurrentItem";
static NSString * PlaybackLikelyToKeepUp = @"PlaybackLikelyToKeepUp";
static NSString * ItemStatusContext = @"ItemStatus";

- (id) init {
    self = [super init];
    if(self) {
        [self loadTracks];
        [self registerObservers];
    }
    return self;
}


- (void)loadTracks {
    
    self.tracks = @[
        @"http://assets2.deliradio.com/uploads/track/band/5557/22448/radio_01_Helicopter_Mack.mp3",
        @"http://assets1.deliradio.com/uploads/track/band/822/2558/purchase_and_radio_05_Emma.mp3",
        @"http://assets2.deliradio.com/uploads/track/band/4196/16478/radio_03_Worried_Man_Blues_320.mp3",
        @"http://assets2.deliradio.com/uploads/track/band/2013/7015/purchase_and_radio_Being_and_Time.mp3",
        @"http://s3.amazonaws.com/deliradio/uploads/track/band/11722/43168/purchase_and_radio_Charlie_Robison_Good_Times.mp3",
//        @"http://assets2-staging.deliradio.com/deliradio/uploads/track/band/12904/46975/purchase_and_radio_05_Muscle_For_The_Wing.m4a"
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
}

- (void)rebuildPlayer {
    if(self.queuePlayer) {
        [self unregisterObservers];
        if(self.queuePlayer.currentItem) {
            [self unregisterObserversForItem:self.queuePlayer.currentItem];
        }
    }
    [self loadTracks];
    
    [self registerObservers];
    
    [self play];
}

- (void)timer:(id)sender {
    NSLog(@"(Timer) Player Status : %d", self.queuePlayer.status);
    NSLog(@"(Timer) Current Item Status : %d", self.queuePlayer.currentItem.status);
    NSLog(@"(Timer) Playback Rate : %f", self.queuePlayer.rate);
}

- (void)registerObservers {
    [self.queuePlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&PlayerStatusContext];
    [self.queuePlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&CurrentItemContext];
    [self.queuePlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&PlayerRateContext];
    
    __weak id weakSelf = self;
    self.timeObserver =
        [self.queuePlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f)
                                                       queue:dispatch_get_main_queue()
                                                  usingBlock:^(CMTime time) {
                                                  
                                                      [weakSelf updateProgress:nil];
                                                      NSLog(@"Player Status : %d", self.queuePlayer.status);
                                                      NSLog(@"Current Item Status : %d", self.queuePlayer.currentItem.status);
                                                      NSLog(@"Playback Rate : %f", self.queuePlayer.rate);
                                                  }];    
}

- (void)unregisterObservers {
    [self.queuePlayer removeObserver:self forKeyPath:@"status"];
    [self.queuePlayer removeObserver:self forKeyPath:@"currentItem"];
    [self.queuePlayer removeObserver:self forKeyPath:@"rate"];
    [self.queuePlayer removeTimeObserver:self.timeObserver];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerStartedEvent object:nil];
}

- (void) pause {    
    [self.queuePlayer pause];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerPausedEvent object:nil];
}

- (void) seekToTime:(CMTime)currentTime completionHandler:(void (^)(BOOL finished))completionHandler {
    [self.queuePlayer pause];
    
    [self.queuePlayer seekToTime:currentTime completionHandler:^(BOOL finished) {

        [self.queuePlayer play];
        
        completionHandler(finished);
    }];
}

- (void)updateProgress:(id)sender {
    [SilentPlayer sharedInstance]->timeoutBase = time(NULL);
    
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
    
    if (context == &PlayerStatusContext) {
        AVPlayer *thePlayer = (AVPlayer *)object;
        if ([thePlayer status] == AVPlayerStatusFailed) {
            NSError *error = [thePlayer error];
            NSLog(@"Some error occured while preparing player : %@", [error localizedDescription]);

            int64_t delayInSeconds = 5.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self rebuildPlayer];
            });

            return;
        } else {
            [self registerObserversForItem:self.queuePlayer.currentItem];
            
            // Issue player ready event
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerReadyEvent object:nil];
            
            // Issue item changed event
            AVURLAsset * asset = (AVURLAsset *)self.queuePlayer.currentItem.asset;
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerItemChangedEvent object:asset];
        }
    } else if(context == &CurrentItemContext) {
        NSLog(@"Current item changed to %@", self.queuePlayer.currentItem);
        AVPlayerItem * oldPlayerItem = change[NSKeyValueChangeOldKey];
        if(oldPlayerItem) {
            [self unregisterObserversForItem:oldPlayerItem];
        }
        [self registerObserversForItem:self.queuePlayer.currentItem];
        
        // Issue item changed event
        AVURLAsset * asset = (AVURLAsset *)self.queuePlayer.currentItem.asset;
        [[NSNotificationCenter defaultCenter] postNotificationName:kPlayerItemChangedEvent object:asset];
        
    } else if(context == &PlayerRateContext) {
        
        float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
        float newRate = [change[NSKeyValueChangeNewKey] floatValue];
        NSLog(@"Player rate changed from %f to %f", oldRate, newRate);
        
    } else if(context == &PlaybackLikelyToKeepUp) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.playbackLikelyToKeepUp) {
            [self play];
            NSLog(@"Play item due to likelyToKeepUp");
        } else {
            [self pause];
            NSLog(@"Pause item due to likelyToKeepUp");
        }
    } else if(context == &ItemStatusContext) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.status == AVPlayerItemStatusReadyToPlay) {
            [self play];
            NSLog(@"Play item due to status");
        } else if(item.status == AVPlayerItemStatusFailed) {            
//            NSLog(@"Item status failed !!!!!!!!!!!!!!!!!!");
        } else {
            [self pause];
            NSLog(@"Pausing since item status has changed to unknown");
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

@end
