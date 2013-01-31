//
//  ViewController.m
//  AVQueuePlayerSample
//
//  Created by Yuichi Fujiki on 12/17/12.
//  Copyright (c) 2012 Yuichi Fujiki. All rights reserved.
//

#import "ViewController.h"
#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) AudioPlayer * player;

@property (nonatomic, weak) IBOutlet UIButton * playButton;
@property (nonatomic, weak) IBOutlet UISlider * slider;
@property (nonatomic, weak) IBOutlet UILabel * currenTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel * progressLabel;
@property (nonatomic, weak) IBOutlet UILabel * timeleftLabel;

- (IBAction)playPause:(id)sender;
- (IBAction)valueChanged:(id)sender;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self registerForNotifications];
    
    self.player = [[AudioPlayer alloc] init];
    [self.playButton setEnabled:NO];
}

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted:) name:kPlayerStartedEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPaused:) name:kPlayerPausedEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemChanged:) name:kPlayerItemChangedEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerReady:) name:kPlayerReadyEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:kPlayerProgressUpdatedEvent object:nil];
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
    [self.player play];
}

- (void) pause {
    [self.player pause];
}

- (void)playerStarted:(NSNotification *)notification {
    [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (void)playerPaused:(NSNotification *)notification {
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
}

- (void)playerItemChanged:(NSNotification *)notification {
    AVURLAsset * asset = (AVURLAsset *)(notification.object);
    self.currenTitleLabel.text = asset.URL.path;
}

- (void)playerReady:(NSNotification *)notification {
    [self.playButton setEnabled:YES];
}

- (void)updateProgress:(NSNotification *)notification {

    NSDictionary * progressDict = (NSDictionary *)notification.object;
    
    NSTimeInterval currentTime = [progressDict[@"currentTime"] doubleValue];
    NSTimeInterval duration = [progressDict[@"duration"] doubleValue];
    
    if(duration == 0 || isnan(duration) || isnan(currentTime)) {
        self.slider.value = 0.0f;
        self.progressLabel.text = @"";
        self.timeleftLabel.text = @"Finished";
        return;
    }
    float progress = currentTime / duration;
    self.slider.value = progress;
    
    self.progressLabel.text = [NSString stringWithFormat:@"%.1f", currentTime];
    self.timeleftLabel.text = [NSString stringWithFormat:@"%.1f", currentTime - duration];
}

- (IBAction)valueChanged:(id)sender {
    CMTime currentTime = self.player.currentTime;
    CMTime duration = self.player.duration;

    float progress = self.slider.value;
    currentTime.value = (duration.value * 1.0f / duration.timescale) * progress * currentTime.timescale;
    
    [self.player pause];
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        [self.player play];
    }];
}
@end


