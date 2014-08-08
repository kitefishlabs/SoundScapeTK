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
#define SECONDS_IN_DAY 86400.0
#define TIMEZONE_OFFSET 0.0 //2160.0

#define LOFREQ 7.83
#define HIFREQ 14.3


@interface kflAudioFileRouter () {}
- (int) secondsSinceMidnight:(NSDate *)date;
@end

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

    void *x = [PdBase openFile:patchString path:[[NSBundle mainBundle] bundlePath]];
	
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
        [self openSFilePath:lsf.fileName inSlot:slot withOnsetTime:lsf.pausedOffset];
        [self adjustVolumeForLSF:lsf to:vol withRampTime:1000];
        [self adjustAttackForLSF:lsf to:lsf.attackTime];
        [self adjustReleaseForLSF:lsf to:lsf.releaseTime];

        DLog(@"STATE for region ID %i -- %@ ----> playing", lcr.idNum, lcr.state);
        lcr.state = @"playing";
        //trigger play
        [NSThread sleepForTimeInterval:0.1];
        ARLog(@"PLAY: %@", [NSString stringWithFormat:@"%i_in", slot]);
        [PdBase sendMessage:@"play" withArguments:nil toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
        return lsf.pausedOffset;
    } else {
        return -1.f;
    }
}

- (void) openSFilePath:(NSString *)sfilePath inSlot:(int)slot withOnsetTime:(int)onset {
    NSString *openSlot = [NSString stringWithFormat:@"%i_open", slot];
    ARLog(@"openslot: %@", openSlot);
    [PdBase sendMessage:sfilePath
          withArguments:[NSArray arrayWithObject:[NSNumber numberWithFloat:onset]] //onsetTime is in seconds!
             toReceiver:openSlot];
}

- (NSString *) keyStringForRegionID:(int)rID {
    return [NSString stringWithFormat:@"%i", rID];
}

- (void)stopLinkedSoundFile:(kflLinkedSoundfile *)lsf forRegion:(kflLinkedCircleSFRegion *)lcr {
    
    DLog(@"stop SF with ID: %i", lsf.idNum);
    
    int slot = lsf.assignedSlot;
    if (slot > -1) {
        [PdBase sendMessage:@"stop" withArguments:nil toReceiver:[NSString stringWithFormat:@"%i_in", slot]];
    }
    // mark the offset for a paused sound
    
    
    // @@@ have to remove the file from the active hash!
    DLog(@"removing slot: %i from active hash", slot);
    [self.activeHash removeObjectForKey:[NSString stringWithFormat:@"%i", slot]];
    
    [self freeSlotForLSF:lsf];
    
    DLog(@"STATE for region ID %i -- %@ ----> ready", lcr.idNum, lcr.state);
    lcr.state = @"ready";
    DLog(@"state is now: %@", lcr.state);
//    DLog(@"adding slot %i back to iPool.", slot);
////    [self.iPool addObject:[NSNumber numberWithInt:slot]];
//    // should now have < SLOTS in the active hash
//    DLog(@"after NOT adding back to ipool:\n%@\n%@", self.iPool, self.activeHash);
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
    
    ARLog(@"active hash size @ time of assignment: %i", [self.activeHash count]);
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

    if ([lcsr.linkedParameters count] ==2) {
        
        kflLinkedParameter *lpA = [lcsr.linkedParameters objectAtIndex:0];
        ARLog(@"lpA type: %@", [lpA class]);
        ARLog(@"lpA type: %@, %@, %i", [lpA.paramName class], lpA.paramName, [lpA.paramName intValue]);
        
        if ([lpA.paramName compare:@"x"] != NSOrderedSame) {
            float normedDist = lcsr.internalDistance;
            float interpolatedParamVal = (normedDist * (lpA.highValue - lpA.lowValue)) + lpA.lowValue;
            ARLog(@"%f | %f | %f", normedDist, lpA.lowValue, lpA.highValue);
            ARLog(@"interped: %f TO: %@", interpolatedParamVal, lpA.paramName);
            [PdBase sendFloat:interpolatedParamVal toReceiver:lpA.paramName];
        }
        
        kflLinkedParameter *lpB = [lcsr.linkedParameters objectAtIndex:1];
        ARLog(@"lpB type: %@", [lpB class]);
        ARLog(@"lpB type: %@", [lpB.paramName class]);
        
        if ([lpB.paramName compare:@"x"] != NSOrderedSame) {
            float angle = lcsr.angle;
            ARLog(@"angle: %f", lcsr.angle);
            ARLog(@"offset: %f", lcsr.angleOffset);

            float interpolatedParamVal = angle / PI;
            ARLog(@"%f", interpolatedParamVal);
            
            ARLog(@"interped: %f TO: %@", interpolatedParamVal, lpB.paramName);
            [PdBase sendFloat:interpolatedParamVal toReceiver:lpB.paramName];
        }
    }
}

- (void) executeTimedParamChanges {
    
    float currentSecondsInDay = fmodf((float)([self secondsSinceMidnight:[NSDate dateWithTimeIntervalSinceNow:0]] - TIMEZONE_OFFSET), SECONDS_IN_DAY);
    ARLog(@"NOW: %f", currentSecondsInDay);
    
    ARLog(@"2-00: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 0.0) )));
    ARLog(@"2-01: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 1.0) )));
    ARLog(@"2-02: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 2.0) )));
    ARLog(@"2-03: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 3.0) )));
    ARLog(@"2-04: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 4.0) )));
    ARLog(@"2-05: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 5.0) )));
    ARLog(@"2-06: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 6.0) )));
    ARLog(@"2-07: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 7.0) )));
    ARLog(@"2-08: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 8.0) )));
    ARLog(@"2-09: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 9.0) )));
    ARLog(@"2-10: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 10.0))));
    ARLog(@"2-11: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 11.0))));
    ARLog(@"2-12: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 12.0))));
    ARLog(@"2-13: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 13.0))));
    ARLog(@"2-14: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 14.0))));
    ARLog(@"2-15: %f", fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 15.0))));
    
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 0.0) )) toReceiver:@"0_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 1.0) )) toReceiver:@"1_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 2.0) )) toReceiver:@"2_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 3.0) )) toReceiver:@"3_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 4.0) )) toReceiver:@"4_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 5.0) )) toReceiver:@"5_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 6.0) )) toReceiver:@"6_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 7.0) )) toReceiver:@"7_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 8.0) )) toReceiver:@"8_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 9.0) )) toReceiver:@"9_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 10.0) )) toReceiver:@"10_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 11.0) )) toReceiver:@"11_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 12.0) )) toReceiver:@"12_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 13.0) )) toReceiver:@"13_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 14.0) )) toReceiver:@"14_lfo_phase"];
    [PdBase sendFloat:fmodf(currentSecondsInDay, (SECONDS_IN_DAY / powf(2.0, 15.0) )) toReceiver:@"15_lfo_phase"];
    
    
}

- (void) executeFundamentalFrequencyChange {
    
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    NSInteger dc = [currentCalendar  ordinalityOfUnit:NSDayCalendarUnit
                                               inUnit:NSYearCalendarUnit
                                              forDate:today];
    
    int sunrises[31] = { 0, 0, 0, 0, 0, 0, 324, 324, 325, 326, 327, 327, 328, 329, 530, 531, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545 }; //in minutes!
    int sunsets[31] = { 0, 0, 0, 0, 0, 0, 995, 995, 995, 994, 994, 993, 993, 992, 992, 991, 990, 990, 989, 988, 987, 986, 986, 985, 984, 983, 982, 981, 980, 979, 977 };
    
    float currentSecondsInDay = fmodf((float)([self secondsSinceMidnight:[NSDate dateWithTimeIntervalSinceNow:0]] - TIMEZONE_OFFSET), SECONDS_IN_DAY);
    ARLog(@"NOW: %f", currentSecondsInDay);
    
    int sr = sunrises[(dc - 182)];
    int ss = sunsets[(dc - 182)];
    int dl = ABS(ss - sr);
    int nl = (SECONDS_IN_DAY - ss) + sr;
    float freq = 0.f;
    
    if ((currentSecondsInDay >= 0) && (currentSecondsInDay < sr)) {
        freq = ((((sinf((float)(currentSecondsInDay + SECONDS_IN_DAY - sr)/nl) * 0.5) + 1) * (HIFREQ - LOFREQ)) + LOFREQ);
    } else if ((currentSecondsInDay >= sr) && (currentSecondsInDay < ss)) {
        freq = ((((sinf((float)(currentSecondsInDay - sr)/dl) * 0.5) + 1) * (HIFREQ - LOFREQ)) + LOFREQ);
    } else if ((currentSecondsInDay >= ss) && (currentSecondsInDay < SECONDS_IN_DAY)) {
        freq = ((((sinf((float)(currentSecondsInDay - ss)/nl) * 0.5) + 1) * (HIFREQ - LOFREQ)) + LOFREQ);
    }
    ARLog(@"THE FREQUENCY IS %f RIGHT NOW!!!", freq);
    [PdBase sendFloat:freq toReceiver:@"_center_freq"];
}

- (int) secondsSinceMidnight:(NSDate *)date {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned unitFlags =  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *components = [gregorian components:unitFlags fromDate:date];
    return (3600 * [components hour]) + (60 * [components minute]) + [components second];
}

@end