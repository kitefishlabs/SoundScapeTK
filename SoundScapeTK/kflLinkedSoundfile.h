//
//  kflLinkedSoundfile.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface kflLinkedSoundfile : NSObject {
    int assignedSlot;
}

@property (strong, nonatomic)   NSString        *fileName;
@property (strong, nonatomic)   NSDate          *startTime;
@property                       float           length, pausedOffset;   // in seconds
@property                       int             channels, idNum, routerSlot, attackTime, releaseTime, assignedSlot, uniqueID; // attack and release are in MS!!!

@property (strong)              AVAudioPlayer   *audioPlayer;

+ (kflLinkedSoundfile *) linkedSoundfileForFile:(NSString *)fileString idNum:(int)idNum attack:(int)attack andRelease:(int)release;

- (id) initWithFileName:(NSString *)soundFileName idNum:(int)regionIDNum attack:(int)attack andRelease:(int)release;

- (void) markStart;
- (void) clearStart;
- (void) markOffset;
- (void) clearOffset;
@end
