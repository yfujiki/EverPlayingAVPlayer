//
//  ViewController.m
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 12/17/12.
//  Copyright (c) 2012 Yuichi Fujiki. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) AVQueuePlayer * queuePlayer;

@property (nonatomic, strong) NSArray * tracks;
@property (nonatomic, weak) IBOutlet UIButton * playButton;
@property (nonatomic, weak) IBOutlet UISlider * slider;
@property (nonatomic, weak) IBOutlet UILabel * currenTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * progressLabel;
@property (nonatomic, weak) IBOutlet UILabel * timeleftLabel;

@property (nonatomic, strong) NSTimer * timer;

- (IBAction)playPause:(id)sender;
- (IBAction)valueChanged:(id)sender;

@end

@implementation ViewController

static NSString * PlayerStatusContext = @"PlayerStatus";
static NSString * PlayerRateContext = @"PlayerRate";
static NSString * CurrentItemContext = @"CurrentItem";
static NSString * PlaybackLikelyToKeepUp = @"PlaybackLikelyToKeepUp";
static NSString * ItemStatusContext = @"ItemStatus";


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadTracks];
    
    [self registerObservers];
    
    [self prepareTimer];
}

- (void)loadTracks {
    
    [self.playButton setEnabled:NO];
    
    self.tracks = @[
//        [[NSBundle mainBundle] URLForResource:@"cyclone" withExtension:@"mp3"].absoluteString,
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
}

- (void)registerObservers {    
    [self.queuePlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&PlayerStatusContext];
    [self.queuePlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&CurrentItemContext];
    [self.queuePlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&PlayerRateContext];
    
    [self.queuePlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f)
                                                   queue:dispatch_get_main_queue()
                                              usingBlock:^(CMTime time) {
                                                  NSLog(@"Progress : %lld", time.value);
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTrackFinishedNotification:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)registerObserversForItem : (AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:&PlaybackLikelyToKeepUp];
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:&ItemStatusContext];
}

- (void)unregisterObserversForItem : (AVPlayerItem *)item {
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [item removeObserver:self forKeyPath:@"status"];
}

- (void)prepareTimer {
    self.timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0f target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)playPause:(id)sender {
    if([[self.playButton titleForState:UIControlStateNormal] isEqualToString:@"Play"]) {
        [self play];
    } else {
        [self pause];
    }
}

- (void) play {
    [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    
    [self.queuePlayer play];    
}

- (void) pause {
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    
    [self.queuePlayer pause];    
}

- (void)updateProgress:(id)sender {
    CMTime currentTime = self.queuePlayer.currentItem.currentTime;
    CMTime duration = self.queuePlayer.currentItem.duration;
    
    NSTimeInterval currentTime_ = currentTime.value * 1.0f / currentTime.timescale;
    NSTimeInterval duration_ = duration.value * 1.0f / duration.timescale;
    
    float progress = currentTime_ / duration_;
    self.slider.value = progress;
    
    self.progressLabel.text = [NSString stringWithFormat:@"%.1f", currentTime_];
    self.timeleftLabel.text = [NSString stringWithFormat:@"%.1f", currentTime_ - duration_];
}

- (IBAction)valueChanged:(id)sender {
    CMTime currentTime = self.queuePlayer.currentItem.currentTime;
    CMTime duration = self.queuePlayer.currentItem.duration;

    float progress = self.slider.value;
    currentTime.value = (duration.value * 1.0f / duration.timescale) * progress * currentTime.timescale;
    
    [self.queuePlayer pause];
    [self.queuePlayer seekToTime:currentTime completionHandler:^(BOOL finished) {
        [self.queuePlayer play];
    }];
}

#pragma mark - key value observation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &PlayerStatusContext) {
        AVPlayer *thePlayer = (AVPlayer *)object;
        if ([thePlayer status] == AVPlayerStatusFailed) {
            NSError *error = [thePlayer error];
            NSLog(@"Some error occured while preparing player : %@", [error localizedDescription]);
            return;
        } else {
            [self.playButton setEnabled:YES];
            
            [self registerObserversForItem:self.queuePlayer.currentItem];
            
            AVURLAsset * asset = (AVURLAsset *)self.queuePlayer.currentItem.asset;
            self.currenTitleLabel.text = asset.URL.path;
        }
    } else if(context == &CurrentItemContext) {
        AVPlayerItem * oldPlayerItem = change[NSKeyValueChangeOldKey];
        if(oldPlayerItem) {
            [self unregisterObserversForItem:oldPlayerItem];
        }
        [self registerObserversForItem:self.queuePlayer.currentItem];
        
        AVURLAsset * asset = (AVURLAsset *)self.queuePlayer.currentItem.asset;
        self.currenTitleLabel.text = asset.URL.path;

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
        
    } else if(context == &PlaybackLikelyToKeepUp) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.playbackLikelyToKeepUp) {
            [self play];
            NSLog(@"Play item due to likelyToKeepUp");
        } else {
            [self pause];
            NSLog(@"Pause (not) item due to likelyToKeepUp");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self play];
            });
        }
    } else if(context == &ItemStatusContext) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if(item.status == AVPlayerItemStatusReadyToPlay) {
            [self play];
            NSLog(@"Play item due to status");
        } else if(item.status == AVPlayerItemStatusFailed) {
            NSLog(@"Item status failed !!!!!!!!!!!!!!!!!!");
//            [self pause];
//            NSLog(@"Pause (not) item due to status");
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                [self play];
//            });

        } else {
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


