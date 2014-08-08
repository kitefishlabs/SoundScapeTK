//
//  kflLinkedSoundfile.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflLinkedSoundfile.h"

@implementation kflLinkedSoundfile

@synthesize fileName, startTime, length, pausedOffset, idNum, routerSlot, channels, assignedSlot, audioPlayer, attackTime, releaseTime, uniqueID; // playing, signalStop;

+ (kflLinkedSoundfile *) linkedSoundfileForFile:(NSString *)fileName idNum:(int)idNum attack:(int)attack andRelease:(int)release {
    
    kflLinkedSoundfile *lsf = [[self alloc] initWithFileName:fileName idNum:idNum attack:attack andRelease:release];
    return lsf;
}
- (id) initWithFileName:(NSString *)soundFileName idNum:(int)regionIDNum attack:(int)attack andRelease:(int)release {

    if (self = [super init]) {
        self.fileName = soundFileName;
        self.idNum = regionIDNum;
        self.pausedOffset = 0;
        self.routerSlot = -1;
        self.startTime = nil;
        self.attackTime = attack;
        self.releaseTime = release;
        self.assignedSlot = -1;
        self.uniqueID = [[NSDate date] timeIntervalSince1970];

        NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSURL *url = [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:fileName]];
        DLog(@"LSF URL: %@: (GOOD:%i)", [url path], [[NSFileManager defaultManager] fileExistsAtPath:[url path]]);
        
        NSError *error;
        AVAudioPlayer *dumbPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (dumbPlayer == nil) {
            
            NSLog(@"(Dumb) AudioPlayer init error: %@", [error description]);
            return nil;

        } else {
            
            DLog(@"dur: %f", dumbPlayer.duration);
            self.length = dumbPlayer.duration;
            self.channels = dumbPlayer.numberOfChannels;
            self.audioPlayer.volume = 1.0;
        }
        // remember - NO communication in LSF to Pd!
        dumbPlayer = nil;
    }
    return self;
}

- (void) markStart {
    self.startTime = [NSDate dateWithTimeIntervalSinceNow:(0 - self.pausedOffset)];
}
// VERY IMPORTANT THAT THE START TIME TAKES INTO ACCOUNT THE OFFSET HERE

- (void) clearStart {
    self.startTime = nil;
}

- (void) markOffset {
    NSDate *d = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval interval = [d timeIntervalSinceDate:self.startTime];
    self.pausedOffset = (float)interval;
}

- (void) clearOffset {
    self.pausedOffset = 0.f;
}



@end
