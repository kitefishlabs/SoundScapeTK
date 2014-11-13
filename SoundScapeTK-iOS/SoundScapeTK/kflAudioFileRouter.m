//
//  kflAudioFileRouter.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflAudioFileRouter.h"
#import "PdBase.h"
#import <math.h>

#define SLOTS 4
#define PI 3.141592653589793
#define TWO_PI (2.0*PI)

//@interface kflAudioFileRouter () {}
//@end

@implementation kflAudioFileRouter

@synthesize patchString, sndDirString, activeHash;

+ (kflAudioFileRouter *)audioFileRouterForPatch:(NSString *)patchString withNumberOfSlots:(int)numSlots {
    
    kflAudioFileRouter *afr = [[kflAudioFileRouter alloc] init];
    
    afr.patchString = patchString;
    afr.sndDirString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    afr.activeHash = [NSMutableDictionary dictionaryWithCapacity:SLOTS];
    
    ARLog(@"open patch... %@", afr.patchString);
    NSFileManager *fm = [[NSFileManager alloc] init];
    ARLog(@"exists? %i", [fm fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], patchString]]);

    [PdBase openFile:patchString path:[[NSBundle mainBundle] bundlePath]];
	
    return afr;
}

- (void)resetRouter {
    [self.activeHash removeAllObjects];
}

- (float) playLinkedSoundFile:(kflLinkedSoundfile *)lsf forRegion:(kflLinkedCircleSFRegion *)lcr atVolume:(float)vol {

    // slot is the PRIMARY KEY!!!
    int slot = lsf.assignedSlot;
    ARLog(@"INSIDE playLSF -- slot lookup: %i", slot);

    //trigger read
    if (slot > -1) {
        
        [lsf markStart]; // start = timenow - offset
        ARLog(@"path: %@", lsf.fileName);
        ARLog(@"slot: %i", slot);
        ARLog(@"onset: %f", lsf.pausedOffset);
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSURL *docsURL = [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:lsf.fileName]];
        
        [self openSFilePath:[docsURL path] inSlot:slot withOnsetTime:lsf.pausedOffset];
        [self adjustVolumeForLSF:lsf to:vol withRampTime:1000];
        [self adjustAttackForLSF:lsf to:lsf.attackTime];
        [self adjustReleaseForLSF:lsf to:lsf.releaseTime];

        DLog(@"STATE for region ID %i -- %@ ----> playing", lcr.idNum, lcr.state);
        lcr.state = @"playing";
        //trigger play
        ARLog(@"PLAY: %@", [NSString stringWithFormat:@"%i_in", slot]);
        [PdBase sendMessage:@"play" withArguments:nil toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
        
        
        
        __block UIBackgroundTaskIdentifier bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTaskID != UIBackgroundTaskInvalid)
                {
                    [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
                    bgTaskID = UIBackgroundTaskInvalid;
                }
            });
        }];
        
        
        NSDictionary *dict = [NSDictionary dictionaryWithObject:lcr forKey:@"lcr"];
        NSLog(@"schedule timer %f seconds from now.", (lsf.length - lsf.pausedOffset));
        NSTimer *stopTimer = [NSTimer timerWithTimeInterval:(lsf.length - lsf.pausedOffset) target:self selector:@selector(stopLinkedSoundFileForTimer:) userInfo:dict repeats:NO];
        
        lcr.stopTimer = stopTimer;
        NSLog(@"stop timer: %@", lcr.stopTimer);
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //change to NSRunLoopCommonModes
            [ [NSRunLoop currentRunLoop] addTimer:stopTimer
                                          forMode:NSRunLoopCommonModes];
            
            // Create/get a run loop an run it
            // Note: will return after the last timer's delegate has completed its job
            [[NSRunLoop currentRunLoop] run];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTaskID != UIBackgroundTaskInvalid)
                {
                    // if you don't call endBackgroundTask, the OS will exit your app.
                    [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
                    bgTaskID = UIBackgroundTaskInvalid;
                }
            });
        });
        NSLog(@"At end of play call:\nSTATE for region ID %i -- %@", lcr.idNum, lcr.state);
        
        
        return lsf.pausedOffset;
    } else {
        return -1.f;
    }
}

- (void) openSFilePath:(NSString *)sfilePath inSlot:(int)slot withOnsetTime:(int)onset {
    NSString *openSlot = [NSString stringWithFormat:@"%i_open", slot];
    ARLog(@"openslot: %@", openSlot);
    [PdBase sendMessage:sfilePath
          withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:(int)(onset * 44100.0)]] // BEWARE: onsetTime is in seconds!
             toReceiver:openSlot];
}

- (NSString *) keyStringForRegionID:(int)rID {
    return [NSString stringWithFormat:@"%i", rID];
}

- (void)stopLinkedSoundFileForRegion:(kflLinkedCircleSFRegion *)lcr {
    
    kflLinkedSoundfile *lsf = [lcr.linkedSoundfiles objectAtIndex:0];
    
    if ([lcr.state compare:@"stop"] == NSOrderedSame) {
        
        [lsf markOffset];
        
        if (lsf.pausedOffset > (lsf.length - 1)) {
            [lsf clearOffset];
        }
        
        DLog(@"stopping SF with ID: %i", lsf.idNum);
        int slot = lsf.assignedSlot;
        if (slot > -1) {
            [PdBase sendMessage:@"stop" withArguments:nil toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
        }
        // mark the offset for a paused sound
        [[lcr.linkedSoundfiles objectAtIndex:0] setUniqueID:0]; // invalidate the shit out of it
        // @@@ have to remove the file from the active hash!
        DLog(@"STATE for region ID %i -- %@ ----> fadingOut", lcr.idNum, lcr.state);
        lcr.state = @"fadingOut";
        
        NSLog(@"is validated?: %i", lcr.stopTimer.isValid);
        if ([lcr.stopTimer isValid]) {
            NSLog(@"stop region: %@ (%i)", lcr.stopTimer, lcr.stopTimer.isValid);
            [lcr.stopTimer invalidate];
            NSLog(@"is validated?: %i", lcr.stopTimer.isValid);
            lcr.stopTimer = nil;
        }
    } else {
        NSLog(@"UH-OH! not coming from a playing state! stop region: %@ (%i, %@)", lcr, lcr.idNum, lcr.state);
        //        if (lcr.stopTimer != nil) {
        //            [lcr.stopTimer invalidate];
        //            lcr.stopTimer = nil;
        //        }
    }
}

- (void)stopLinkedSoundFileForTimer:(NSTimer *)timer {
    
    kflLinkedCircleSFRegion *lcr = [[timer userInfo] objectForKey:@"lcr"];
    kflLinkedSoundfile *lsf = [lcr.linkedSoundfiles objectAtIndex:0];
    
    if ([lcr.state compare:@"playing"] == NSOrderedSame) {
        
        [lsf clearOffset];
        [lsf clearStart];
        
        DLog(@"stopping SF with TIMER with ID: %i", lsf.idNum);
        int slot = lsf.assignedSlot;
        if (slot > -1) {
            [PdBase sendMessage:@"stop" withArguments:nil toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
        }
        // mark the offset for a paused sound
        [[lcr.linkedSoundfiles objectAtIndex:0] setUniqueID:0]; // invalidate the shit out of it
        // @@@ have to remove the file from the active hash!
        DLog(@"STATE for region ID %i -- %@ ----> fadingOut", lcr.idNum, lcr.state);
        lcr.state = @"fadingOut";
        
        NSLog(@"is validated?: %i", lcr.stopTimer.isValid);
        if ([lcr.stopTimer isValid]) {
            NSLog(@"stop timer: %@ (%i)", lcr.stopTimer, lcr.stopTimer.isValid);
            [lcr.stopTimer invalidate];
            NSLog(@"is validated?: %i", lcr.stopTimer.isValid);
            lcr.stopTimer = nil;
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObject:lcr forKey:@"lcr"];
        NSLog(@"schedule timer for reset %f seconds from now.", (lsf.releaseTime * 0.001));
        [NSTimer scheduledTimerWithTimeInterval:(lsf.releaseTime * 0.001) target:self selector:@selector(resetLinkedSoundFileForTimer:) userInfo:dict repeats:NO];
    } else {
        NSLog(@"UH-OH! not coming from a playing state! stop TIMER: %@ (%i)", lcr.stopTimer, lcr.stopTimer.isValid);
        //        if (lcr.stopTimer != nil) {
        //            [lcr.stopTimer invalidate];
        //            lcr.stopTimer = nil;
        //        }
    }
}

- (void)resetLinkedSoundFileForRegion:(kflLinkedCircleSFRegion *)lcr {
    
    if ([lcr.state compare:@"fadingOut"] == NSOrderedSame) {
        kflLinkedSoundfile *lsf = [lcr.linkedSoundfiles objectAtIndex:0];
        int slot = lsf.assignedSlot;
        
        DLog(@"removing slot: %i from active hash", slot);
        [self.activeHash removeObjectForKey:[NSString stringWithFormat:@"%i", slot]];
        DLog(@"STATE for region ID %i -- %@ ----> ready", lcr.idNum, lcr.state);
        [self freeSlotForLSF:lsf];
        lcr.state = @"ready";
        DLog(@"state is now: %@", lcr.state);
    } else {
        NSLog(@"UH-OH! not coming from a fadingOut state! stop region: %@ (%i, %@)", lcr, lcr.idNum, lcr.state);
        //        if (lcr.stopTimer != nil) {
        //            NSLog(@"have to invalidate, too!");
        //            [lcr.stopTimer invalidate];
        //            lcr.stopTimer = nil;
        //        }
    }
}

- (void)resetLinkedSoundFileForTimer:(NSTimer *)timer {
    
    kflLinkedCircleSFRegion *lcr = [[timer userInfo] objectForKey:@"lcr"];
    kflLinkedSoundfile *lsf = [lcr.linkedSoundfiles objectAtIndex:0];
    
    if ([lcr.state compare:@"fadingOut"] == NSOrderedSame) {
        
        int slot = lsf.assignedSlot;
        
        DLog(@"removing slot: %i from active hash", slot);
        [self.activeHash removeObjectForKey:[NSString stringWithFormat:@"%i", slot]];
        DLog(@"STATE for region ID %i -- %@ ----> ready", lcr.idNum, lcr.state);
        [self freeSlotForLSF:lsf];
        lcr.state = @"ready";
        DLog(@"state is now: %@", lcr.state);
        
    } else {
        NSLog(@"UH-OH! not coming from a fadingOut state! stop TIMER: %@ (%i)", lcr.stopTimer, lcr.stopTimer.isValid);
        //        if (lcr.stopTimer != nil) {
        //            NSLog(@"have to invalidate, too!");
        //            [lcr.stopTimer invalidate];
        //            lcr.stopTimer = nil;
        //        }
    }
}

- (void)adjustAttackForLSF:(kflLinkedSoundfile *)lsf to:(int)attack {

    // look up the slot (assume it is already properly mapped to a pString!)
    int slot = lsf.assignedSlot;
    DLog(@"attack: %i slot: %@", MAX(attack, 5), [NSString stringWithFormat:@"%i_in", slot]);
    [PdBase sendMessage:@"attack" 
          withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:MAX(attack, 5)]] 
             toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
                                                    
}
- (void)adjustReleaseForLSF:(kflLinkedSoundfile *)lsf to:(int)release {

    int slot = lsf.assignedSlot;
    DLog(@"release: %i slot: %@", release, [NSString stringWithFormat:@"%i_in", slot]);
    [PdBase sendMessage:@"release" 
          withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:release]]
             toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
}

- (void)adjustVolumeForLSF:(kflLinkedSoundfile *)lsf to:(float)volume withRampTime:(int)rampTime {

    int slot = lsf.assignedSlot;
    //DLog(@"volume: %f slot: %@", volume, [NSString stringWithFormat:@"%i_in", slot]);
    if (lsf.idNum == 9) {
        [PdBase sendMessage:@"level"
              withArguments:[NSArray arrayWithObject:[NSNumber numberWithFloat:volume]] // volume
                 toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
    } else {
        [PdBase sendMessage:@"level"
              withArguments:[NSArray arrayWithObject:[NSNumber numberWithFloat:1.0]] // volume
                 toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
    }
}

- (void)adjustPanForLSF:(kflLinkedSoundfile *)lsf to:(float)pan withRampTime:(int)rampTime {

    int slot = lsf.assignedSlot;
    DLog(@"pan: %f slot: %@", pan, [NSString stringWithFormat:@"%i_in", slot]);
    [PdBase sendMessage:@"pan"
          withArguments:[NSArray arrayWithObject:[NSNumber numberWithFloat:pan]] 
             toReceiver:[NSString stringWithFormat:@"%i_in", slot]];

}

- (int) assignSlotForLSF:(kflLinkedSoundfile *)lsf {
    int slot = -1;
    int slotsOpen[4] = {0,1,2,3};
    
    ARLog(@"active hash size @ time of assignment: %lu", (unsigned long)[self.activeHash count]);
    if ([self.activeHash count] < SLOTS) {
        // mark slots that are already occupied, then find an open slot
//        for (NSString *existingRegionID in [self.activeHash allKeys]) {
//            // key is a sfstring + region id pair
//            // val is slot + start time pair
        
        for (NSString *slotKey in self.activeHash) {
//            ARLog(@"%i =?= %i", [slotKey intValue], lsf.assignedSlot);
//            if ([slotKey intValue] == lsf.assignedSlot) {
//                // match!
            slotsOpen[ [slotKey intValue] ] = -1;
            ARLog(@"slot found: %i; assigning -1 to slotsOpen @:", [slotKey intValue]);
//            }
        }
//        }
        for (int i=(SLOTS-1);i>-1;i--) {
            ARLog(@"is it open: %i", slotsOpen[i]);
            if (slotsOpen[i] > -1 ) {
                slot = i;
            }

        } // iterating backwards will get you the lowest slot available
        ARLog(@"lowest found: %i", slot);
    }
    [self.activeHash setObject:lsf forKey:[NSString stringWithFormat:@"%i", slot]];
    ARLog(@"active hash: %@", self.activeHash);
    lsf.assignedSlot = slot;
    return slot;
}

- (int) freeSlotForLSF:(kflLinkedSoundfile *)lsf {
    // look up slot for this lsf + set to -1
    lsf.assignedSlot = -1;
    return -1;
}

- (void) executeParamChangeforLCSR:(kflLinkedCircleSynthRegion *)lcsr {
    
    ARLog(@"linked params (%i): %@", lcsr.idNum, lcsr.linkedParameters);

    if ([lcsr.linkedParameters objectForKey:@"rad"] != nil) {
        
        kflLinkedParameter *lpA = [lcsr.linkedParameters objectForKey:@"rad"];
        ARLog(@"lpA type: %@", [lpA class]);
        ARLog(@"lpA type: %@, %@, %i :: %f | %f", [lpA.paramName class], lpA.paramName, [lpA.paramName intValue], lpA.highValue, lpA.lowValue);
        
        float normedDist = lcsr.internalDistance;
        float interpolatedParamVal = (normedDist * (lpA.highValue - lpA.lowValue)) + lpA.lowValue;
        ARLog(@"%f | %f | %f", normedDist, lpA.lowValue, lpA.highValue);
        ARLog(@"interped: %f TO: %@", interpolatedParamVal, lpA.paramName);
        [PdBase sendFloat:interpolatedParamVal toReceiver:lpA.paramName];
    }
        
    if ([lcsr.linkedParameters objectForKey:@"theta"] != nil) {

        kflLinkedParameter *lpB = [lcsr.linkedParameters objectForKey:@"theta"];
        ARLog(@"lpB type: %@", [lpB class]);
        ARLog(@"lpB type: %@, %@, %i :: %f | %f | %f | %f", [lpB.paramName class], lpB.paramName, [lpB.paramName intValue], lpB.highValue, lpB.lowValue, lpB.angle, lpB.angleOffset);
        
        float angle = lcsr.angle;
        ARLog(@"angle: %f", lcsr.angle);
        ARLog(@"offset: %f", lcsr.angleOffset);

        float interpolatedParamVal = angle / PI;
        ARLog(@"%f", interpolatedParamVal);
        
        interpolatedParamVal = (interpolatedParamVal * (lpB.highValue - lpB.lowValue)) + lpB.lowValue;
        ARLog(@"%f", interpolatedParamVal);
            
        ARLog(@"interped: %f TO: %@", interpolatedParamVal, lpB.paramName);
        [PdBase sendFloat:interpolatedParamVal toReceiver:lpB.paramName];
    }
}

@end