//
//  kflHTLPManager.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflHTLPManager.h"
#import "PdBase.h"
#import "kflLinkedCircleRegion.h"

#define PI 3.141592653589793
#define TWO_PI (2.0*PI)

@implementation kflHTLPManager

@synthesize scapeRegions, scapeSoundfiles; // currentActiveRegions, currentPausedRegions,
@synthesize audioFileRouter, lastLatitude;

+ (id)sharedManager {
    static kflHTLPManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id) init {

    if (self = [super init]) {
        
        [self reset];
        self.audioFileRouter = [kflAudioFileRouter audioFileRouterForPatch:@"empac_ios.pd" withNumberOfSlots:4];
    }
    return self;    
}

- (void)killAll {
    DLog(@"kill 'em all!");
    [self processEnterAndExitEvents:[NSArray arrayWithObject:[NSNumber numberWithInt:-1]]];
    [NSThread sleepForTimeInterval:0.1];
    for (NSString *key in [self.scapeRegions allKeys]) {
        [[self.scapeRegions objectForKey:key] setState:@"ready"];
    }
    self.lastLatitude = 0.0;
}

- (void)reset {

    DLog(@"\n\n\n********RESET HTLP MANAGER*****\n\n\n");
    
    if (scapeRegions == nil) {
        scapeRegions = [NSMutableDictionary dictionaryWithCapacity:1];
    } else {
        [scapeRegions removeAllObjects];
    }
    if (scapeSoundfiles == nil) {
        scapeSoundfiles = [NSMutableDictionary dictionaryWithCapacity:1];
    } else {
        [scapeSoundfiles removeAllObjects];
    }
    self.lastLatitude = 0.0;
}

//- (void)addCircRegion:(kflLinkedCircleSFRegion *)lcr forIndex:(NSNumber *)index {
//    [self.scapeRegions setObject:lcr forKey:index];
//}
//
//- (void)addRectRegion:(kflLinkedRectangleRegion *)lrr forIndex:(NSNumber *)index {
//    [self.scapeRegions setObject:lrr forKey:index];
//}

-(void) addRegion:(kflLinkedRegion *)lr forIndex:(NSNumber *)index {
    [self.scapeRegions setObject:lr forKey:index];
}

- (NSString *)hitTestRegionsWithLocation:(CGPoint)location {
    
    HTLPLog(@"SCAPE: %@", scapeRegions);
    HTLPLog(@">>HIT-TESTING LOCATION: %f, %f", location.x, location.y);
    HTLPLog(@"loc x: %f y: %f last: %f", location.x, location.y, lastLatitude);
    
    if (ABS(location.x - lastLatitude) < 0.00001) { return @"Not moving..."; } else { lastLatitude = location.x; }
    
    NSMutableArray *hitRegions = [NSMutableArray arrayWithCapacity:1];
    
    for (NSString *lrkey in self.scapeRegions) {
        HTLPLog(@"::: %@", [scapeRegions objectForKey:lrkey]);
        if ([[scapeRegions objectForKey:lrkey] isKindOfClass:[kflLinkedCircleSFRegion class]]) {
            
            kflLinkedCircleSFRegion *lcr = [scapeRegions objectForKey:lrkey];
//            HTLPLog(@"lr key: %@ || pt: %f, %f | rad: %f", lrkey, lcr.center.x, lcr.center.y, lcr.radius);
            float dist = sqrtf(powf((lcr.center.x - location.x), 2.0) + powf((lcr.center.y - location.y), 2.0));
            
            //HTLPLog(@"lat/lon/radius||x,y: %f, %f, %f || %f, %f", lcr.center.x, lcr.center.y, (lcr.radius+0.00001), location.x, location.y);
            
            if (dist <= (lcr.radius+0.00001)) { // && (![[self.scapeSoundfiles objectForKey:[lcr.linkedSoundfiles objectAtIndex:0]] playing])) {
                
                lcr.internalDistance = dist / lcr.radius;
                HTLPLog(@"====== circle HIT: %i ====== int. dist: %f", lcr.idNum, lcr.internalDistance);
                [hitRegions addObject:lcr];
            }
            
        } else if ([[scapeRegions objectForKey:lrkey] isKindOfClass:[kflLinkedCircleSynthRegion class]]) {
            
            kflLinkedCircleSynthRegion *lcsr = [scapeRegions objectForKey:lrkey];
            //            HTLPLog(@"lr key: %@ || pt: %f, %f | rad: %f", lrkey, lcr.center.x, lcr.center.y, lcr.radius);
            float dist = sqrtf(powf((lcsr.center.x - location.x), 2.0) + powf((lcsr.center.y - location.y), 2.0));
            
            //HTLPLog(@"lat/lon/radius||x,y: %f, %f, %f || %f, %f", lcr.center.x, lcr.center.y, (lcr.radius+0.00001), location.x, location.y);
            
            if (dist <= lcsr.radius+0.00001) {
                
                float angle = atan2f((location.y - lcsr.center.y), (location.x - lcsr.center.x));
                NSLog(@"angle----------");
                NSLog(@"angle1: %f", angle);
                
                lcsr.internalDistance = dist / lcsr.radius;
                
                angle -= (lcsr.angleOffset * PI);
                NSLog(@"angle2: %f", angle);
                
                if (angle <= -PI) {
                    angle += TWO_PI;
                }
                NSLog(@"angle3: %f", angle);
                
                angle = ABS(angle);
                NSLog(@"angle4: %f", angle);
                
                lcsr.angle = angle;
                HTLPLog(@"====== circle HIT: %i ====== int. dist: %f", lcsr.idNum, lcsr.internalDistance);
                [hitRegions addObject:lcsr];
            }
        }
    }
    HTLPLog(@"hit regions count: %i", [hitRegions count]);
    if ([hitRegions count] > 0) {
        
        [self processEnterAndExitEvents:hitRegions];
        return [NSString stringWithFormat:@"HIT(S): %i", [hitRegions count]];

    } else { // nothing hit!
        
        // if there are no hit regions, then process-enter-and-exit events with a dummy event    
        [self processEnterAndExitEvents:[NSArray arrayWithObject:[NSNumber numberWithInt:-1]]];
        HTLPLog(@"miss...");
        return @"MISS!";
        
    }
    return nil;
}

- (NSString *)pairForFileName:(NSString *)fileName andRegionID:(int)rID {
    
    return [NSString stringWithFormat:@"%@-%i", fileName, rID];
    
}

- (void)processEnterAndExitEvents:(NSArray *)regionList {
    
    // regionList: the list of all regions returning hits from the hit test or -1 which signals all regions to cutoff
    
    // if only one region, and idnum == -1, this is a signal to EXIT ALL REGIONS!
    // - pause playing ones according to the rule
    // - or allow playing ones to finish!
    NSLog(@" count:: %i || region list: %@", [regionList count], [regionList objectAtIndex:0]);
    
    if (([regionList count] == 1) && ([[regionList objectAtIndex:0] intValue] == -1)) {
        
        for (NSString *activeSlot in [audioFileRouter.activeHash allKeys]) {
            HTLPLog(@"region ID: %@", activeSlot);
            
            kflLinkedSoundfile *lsf = [self.audioFileRouter.activeHash objectForKey:activeSlot];
            kflLinkedCircleSFRegion *lcr = [self.scapeRegions objectForKey:[NSString stringWithFormat:@"%i", lsf.idNum]];
            
            // check each active region:
            //      if cutoff bit == 1, kill & remove
            //      else do nothing

            // if region.rule == 1
            int looprule = lcr.finishRule;
            HTLPLog(@"%i", looprule);
            if ((looprule & 1) == 1) { // cutoff bit set

                // @@@ add this region/lsf to the list of paused regions with it's time offset
//                NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
                
                // activeHash is the list of active regions
                // keys are filename/regionid pairs
                
                // pull the end time from the pair and calculate delta
//                NSDate *then = lsf.startTime;
//                NSTimeInterval delta = [now timeIntervalSinceDate:then];
//                DLog(@"now: %@ - then: %@ = delta: %f", now, then, delta);
                
                // ===== set offset time and pause this region's LSF

                // now stop it (also removes from activeHash!
                DLog(@"\nSTOP from COMPLETE MISS!\nrid: %@ | %i | %i", lcr, lcr.idNum, lsf.idNum);
                lcr.state = @"stop";
                [self stopLSFForRegion:lcr];
                
            } else { // else mark region for loop-end-stop -- cutoff bit not set; allow sound to finish
                lcr.state = @"stopRequested";
                DLog(@"STOP REQUESTED from COMPLETE MISS!");
//                [[LAPManager sharedManager] recordPauseMarker:@"stop signalled"];
            }
        } // end audio file for loop
        
        
        for (NSString *lrkey in self.scapeRegions) {
            NSLog(@"%@", lrkey);
            id region = [self.scapeRegions objectForKey:lrkey];
            if ([region isKindOfClass:[kflLinkedCircleSynthRegion class]]) {
                kflLinkedCircleSynthRegion *lcsr = region;
                NSLog(@"lcsr: %@", lcsr);
                NSArray *params = lcsr.linkedParameters;
                for (kflLinkedParameter *param in params) {
                    // adjust it to 0.0 if it's a _level pararam
                    if (([param.paramName rangeOfString:@"_noise_level"].location != NSNotFound) || ([param.paramName rangeOfString:@"_pulse_level"].location != NSNotFound)) {

                        [PdBase sendFloat:0.0 toReceiver:param.paramName];
                    }
                }
                HTLPLog(@"LCSR: %@ --> ready", lcsr);
                lcsr.state = @"ready";
            }
        }
        NSLog(@"***MASTER VOLUME ---> 0.0!");
        [PdBase sendFloat:0.0 toReceiver:@"_master_volume"];
        
        // empty out region list and return????
        
    } else {
        
        for (id region in regionList) {
            
            if ([region isKindOfClass:[kflLinkedCircleSFRegion class]]) {
                
                kflLinkedCircleSFRegion *lcr = region;
                //lcr = [self.scapeRegions objectForKey:[NSString stringWithFormat:@"%i", lcr.idNum]];
                
                // current state of each LR
                HTLPLog(@"LR: %i | %i | %i | %i | %i | %f", lcr.active, lcr.numLives, lcr.numLinkedSoundfiles, lcr.idNum, lcr.numLoops, lcr.internalDistance);
                HTLPLog(@"%@", lcr.linkedSoundfiles);
                
                // make sure that the region is active and that there is at least one life left
                if ((lcr.active) && (lcr.numLives > 0)) {
                    
                    kflLinkedSoundfile *lsf = [lcr.linkedSoundfiles objectAtIndex:0];
                    HTLPLog(@"LSF: : %@", lsf);
                    HTLPLog(@"state: %@", lcr.state);
                    if ([lcr.state compare:@"ready"] == NSOrderedSame) {
                        //DLog(@"%@\n%@\n", scapeSoundfiles, [scapeSoundfiles objectForKey:[[lr.linkedSoundfiles objectAtIndex:0] stringValue]]);
                        
                        HTLPLog(@"play this: %@", lsf);
                        HTLPLog(@"assign...");
                        int foundSlot = [self.audioFileRouter assignSlotForLSF:lsf];
                        HTLPLog(@"assigned to slot: %i", foundSlot);
                        if (foundSlot > -1) {
                            [self scheduleLSFToPlay:lsf
                                          forRegion:lcr afterDelay:0.f];
                        }
                        
                        // ===== scheduleLSFToPlay should cause audiofilerouter to put this LSF/region into an active hash
                        // AND mark this LSF as @"playing"
                        
                    } else if ([lcr.state compare:@"playing"] == NSOrderedSame) {
                        // adjust the level of an already-playing LSF
                        HTLPLog(@"just adjust the level: %f for %@ + %i", MAX(1.0 - lcr.internalDistance, 0.0), lsf.fileName, lcr.idNum);
                        [self.audioFileRouter adjustVolumeForLSF:lsf to:MAX((1.0 - lcr.internalDistance), 0.0) withRampTime:1000];
                    } else {
                        HTLPLog(@"UHOH! State should have been either playing or ready");
                    }
                }
                
                //            // A region can activate other regions
                //            if (lcr.idsToActivate != nil) {
                //                DLog(@"ids TO BE ACTIVATED: %@", lcr.idsToActivate);
                //
                //                for (NSNumber *idnum in lcr.idsToActivate) {
                //                    DLog(@"setting ID #%i to ACTIVE...", [idnum intValue]);
                //                    DLog(@"before: %i : %i", [idnum intValue], [[scapeRegions objectForKey:[idnum stringValue]] active]);
                //                    [[scapeRegions objectForKey:[idnum stringValue]] setActive:YES];
                //                    DLog(@"after: %i : %i", [idnum intValue], [[scapeRegions objectForKey:[idnum stringValue]] active]);
                //                }
                //                lcr.idsToActivate = nil;
                //            }

            } else if ([region isKindOfClass:[kflLinkedCircleSynthRegion class]]) {
                
                kflLinkedCircleSynthRegion *lcsr = region;
                //lcr = [self.scapeRegions objectForKey:[NSString stringWithFormat:@"%i", lcr.idNum]];
                
                if (([lcsr.state compare:@"ready"] == NSOrderedSame) && (lcsr.active) && (lcsr.numLives > 0)) {
                
                    HTLPLog(@"LCSR: %@ ready --> playing", lcsr);
                    [self.audioFileRouter executeParamChangeforLCSR:lcsr];
                    lcsr.state = @"playing";
                    NSLog(@"***MASTER VOLUME ---> 1.0!");
                    [PdBase sendFloat:1.0 toReceiver:@"_master_volume"];
                    lcsr.numLives -= 1;

                } else if ([lcsr.state compare:@"playing"] == NSOrderedSame) {
                    
                    HTLPLog(@"LCSR: %@ playing --> playing", lcsr);
                    [self.audioFileRouter executeParamChangeforLCSR:lcsr];
                    
                }
            }
        }
        
 // done processing region list...
        
        
        NSMutableArray *lsfsNotInLastRegionHit = [NSMutableArray arrayWithCapacity:1];
        
        HTLPLog(@"curr. active hash (before set-differencing): %@", audioFileRouter.activeHash);

        NSMutableArray *lcrsLSFs = [NSMutableArray arrayWithCapacity:1];
        
        for (id region in regionList) {

            if ([region isKindOfClass:[kflLinkedCircleSFRegion class]]) {
                kflLinkedCircleSFRegion *lcr = region;
                [lcrsLSFs addObject:[[lcr linkedSoundfiles] objectAtIndex:0]];
            }
        }
        HTLPLog(@"curr. REGIONs' LSFs list (before set-differencing): %@", lcrsLSFs);
        NSSet *lcrsLSFSet = [NSSet setWithArray:lcrsLSFs];
        // any active regions that are not in the latest region list are added to tobeDeleted
        // use audio file router's lis of active LSFs to determine the regionIDs to be stopped
        // convert activeHash from dict to array
        
        
        // iterate over the active hash and compare each to the set of all linkedregion's LSFs
        for (NSString *hashKey in [self.audioFileRouter.activeHash allKeys]) {
            kflLinkedSoundfile *activeLSF = [self.audioFileRouter.activeHash objectForKey:hashKey];
            HTLPLog(@"LSF: %@", activeLSF);
            if (![lcrsLSFSet containsObject:activeLSF]) {
                // we have an active lsf that had a region hit, so remove it from the set
                [lsfsNotInLastRegionHit addObject:activeLSF];
            }
        }
        //DLog(@"curr. REGIONs' LSFs list (after set-differencing and removal(s)): %@", lcrsLSFs);

        
        HTLPLog(@"to be deleted: %@", lsfsNotInLastRegionHit);
        for (kflLinkedSoundfile *lsf in lsfsNotInLastRegionHit) {
            
            // get the lcr by looking it up by its region ID (should match)
            kflLinkedCircleSFRegion *lcr = [self.scapeRegions objectForKey:[NSString stringWithFormat:@"%i", lsf.idNum]];
            
            // if region.rule == 1
            HTLPLog(@"loop rule: %i", lcr.finishRule);
            if ((lcr.finishRule & 1) == 1) { // cutoff bit set

                // @@@ add this region/lsf to the list of paused regions with it's time offset

                HTLPLog(@"STOP from toBeDeleted!   LCR: %@", lcr);
                lcr.state = @"stop";
                [self stopLSFForRegion:lcr];
                
            } else { // else mark region for loop-end-stop
                lcr.state = @"stopRequested";
                HTLPLog(@"STOP REQUESTED from toBeDeleted!");
                [[kflLAPManager sharedManager] recordPauseMarker:@"stop requested"];
            }
        }
    }
}

- (void)stopLSFForRegion:(kflLinkedCircleSFRegion *)lcr {
    
    kflLinkedSoundfile *lsf = [lcr.linkedSoundfiles objectAtIndex:0];
    
    HTLPLog(@"stop this LSF: %@", lsf);
    
    if ([lcr.state compare:@"stop"] == NSOrderedSame) {
        
        HTLPLog(@"stop region with lsfID: %i", lcr.idNum);
        [audioFileRouter stopLinkedSoundFile:lsf forRegion:lcr];
        [lsf markOffset];
        lcr.state = @"ready";
        HTLPLog(@"set paused offset: %f (ID: %i)", lsf.pausedOffset, lsf.idNum);
        
    } else if ([lcr.state compare:@"stopRequested"] == NSOrderedSame) {
        
        [audioFileRouter stopLinkedSoundFile:lsf forRegion:lcr];
        // mark lsf's offset as current time - start time
        [lsf clearOffset];
    }
    HTLPLog(@"ACTIVE HASH AFTER STOP: %@", audioFileRouter.activeHash);
    HTLPLog(@"LCR state: %@", lcr.state);
}


- (void) scheduleLSFToPlay:(kflLinkedSoundfile *)lsf forRegion:(kflLinkedCircleSFRegion *)lcr afterDelay:(NSTimeInterval)delay {
    
    __block UIBackgroundTaskIdentifier bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTaskID != UIBackgroundTaskInvalid)
            {
                [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
                bgTaskID = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    DLog(@" ==== schedule LSF to play...");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // HERE IS WHERE THE PLAYBACK LOGIC IS HOOKED IN...
        
        float duration = lsf.length;
        [NSThread sleepForTimeInterval:delay];
        
        // read out the lsf's current id number
        lsf.uniqueID = [[NSDate date] timeIntervalSince1970];
        int currentID = lsf.uniqueID;
        
        HTLPLog(@"generating unique ID: %i for LSF ID: %i", currentID, lsf.idNum);
        
        // default is to play the sound file until told otherwise or until max num. of loops have played
        for (int i=0; i<lcr.numLoops; i++) {

            HTLPLog(@"testing unique ID: %i for LSF ID: %i -- should not be equal if invalidated!", currentID, lsf.uniqueID);
            // if state == stopRequested, we stop it at the end of its duration (several loops might have already played)
            if (([lcr.state compare:@"stopRequested"] == NSOrderedSame) && (lsf.assignedSlot > -1) && (currentID == lsf.uniqueID)) {
            
//                [[LAPManager sharedManager] recordPauseMarker:@"STOP REQUESTED SIGNAL --> PAUSED"];
                break; // break out of the for loop
            
            } else if (([lcr.state compare:@"ready"] == NSOrderedSame) && (lsf.assignedSlot > -1) && (currentID == lsf.uniqueID)) {
                
                lcr.numLives -= 1;
            
                // audio file router sets state to @"playing"
                [[kflLAPManager sharedManager] recordTrackingMarkerWithType:@"PLAY" andArgs:[NSArray arrayWithObject:[NSNumber numberWithInt:lsf.idNum]]];
                float offset = [audioFileRouter playLinkedSoundFile:lsf
                                                          forRegion:lcr
                                                           atVolume:MAX((1.0 - lcr.internalDistance),0.0)];
                if (offset >= 0.) {
                    HTLPLog(@"async play command, sleep for: %f", (duration-offset));
                    [NSThread sleepForTimeInterval:(duration-offset)]; // sleep for the duration less the offset
                }
            
            // already playing (and looping), so play again!
                
            } else if (([lcr.state compare:@"playing"] == NSOrderedSame) && (lsf.assignedSlot > -1) && (currentID == lsf.uniqueID)) {
                
                HTLPLog(@"inside playing condition.");
                
                lcr.numLives -= 1;
                lsf.pausedOffset = 0.0; // just in case, should already be set!
                
                // audio file router sets state to @"playing" (keeps it at @"playing", actually) OFFSET HAD BETTER == 0 on a loop iteration after the first!
                [[kflLAPManager sharedManager] recordTrackingMarkerWithType:@"PLAY" andArgs:[NSArray arrayWithObject:[NSNumber numberWithInt:lsf.idNum]]];
                float offset = [audioFileRouter playLinkedSoundFile:lsf
                                                          forRegion:lcr
                                                           atVolume:MAX((1.0 - lcr.internalDistance),0.0)];
                HTLPLog(@"loop-sleep offset should be zero: %f", offset);
                [NSThread sleepForTimeInterval:duration]; // sleep for the duration less the offset
            } else {
                HTLPLog(@"BREAK");
                break;
            }
            DLog(@"just inside the for-loop");
        }
        
        if ((lsf.assignedSlot > -1) && (currentID == lsf.uniqueID)) {
            
            HTLPLog(@"Last time!");
            // last time through, we will get here and can stop the player here at the end of the last loop
            lcr.state = @"stop";
            
            // audioFileRouter will clean up!
            [audioFileRouter stopLinkedSoundFile:lsf forRegion:lcr];
    //        [[LAPManager sharedManager] recordTrackingMarkerWithType:@"STOP (from loop clean up)" andArgs:[NSArray arrayWithObject:[NSNumber numberWithInt:lsf.idNum]]];
            // we have to stop the LSF and clean up if we reach this point
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTaskID != UIBackgroundTaskInvalid)
            {
                // if you don't call endBackgroundTask, the OS will exit your app.
                [[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
                bgTaskID = UIBackgroundTaskInvalid;
            }
        });
    });
}

@end
