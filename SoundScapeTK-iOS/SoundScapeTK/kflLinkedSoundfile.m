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

        NSString *filePathFromAppBundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
        NSURL *bundleURL = [NSURL fileURLWithPath:filePathFromAppBundle];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSURL *docsURL = [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:fileName]];
        
        DLog(@"\n\nLSF BUNDLE URL: %@: \n(GOOD:%i)\n\n", [bundleURL path], [[NSFileManager defaultManager] fileExistsAtPath:[bundleURL path]]);
        DLog(@"\n\nLSF DOCS URL:   %@: \n(GOOD:%i)\n\n", [docsURL path], [[NSFileManager defaultManager] fileExistsAtPath:[docsURL path]]);
        
        /**
         *  Attempt to copy file to docs dir if it exists.
         *  Abort and return nil if there is an error.
         *  TODO: better error reporting
         */
        if ((![[NSFileManager defaultManager] fileExistsAtPath:[docsURL path]]) && ([[NSFileManager defaultManager] fileExistsAtPath:[bundleURL path]])) {
            // copy from bundle
            DLog(@"BUNDLE PATH: %@", [bundleURL path]);
            NSError *error = nil;
            // copy file from bundle to documents dir
            
            [[NSFileManager defaultManager] copyItemAtPath:[bundleURL path] toPath:[docsURL path] error:&error];
            if (error) {
                DLog(@"***ERROR: %@", [error description]);
            }

            BOOL res = [self addSkipBackupAttributeToItemAtURL:docsURL]; // how to really test this???
            NSLog(@"res: %i", res);

        }
        
        NSError *error;
        AVAudioPlayer *dumbPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:docsURL error:&error];
        if (error) {
            
            NSLog(@"(Dumb) AudioPlayer init error: %@", [error description]);
            return nil;

        } else {
            
            DLog(@"dur: %f", dumbPlayer.duration);
            self.length = dumbPlayer.duration;
            self.channels = (int)dumbPlayer.numberOfChannels;
            self.audioPlayer.volume = 1.0;
            
            /**
             *  Check length as proxy for existence of file.
             *  TODO: more robust error checking.
             */
            if (self.length <= 0.f) {
                return nil;
            }
        }
        // remember - NO communication in LSF to Pd!
        dumbPlayer = nil;
    }
    return self;
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}


// VERY IMPORTANT THAT THE START TIME TAKES INTO ACCOUNT THE OFFSET HERE
- (void) markStart {
    self.startTime = [NSDate dateWithTimeIntervalSinceNow:(0 - self.pausedOffset)];
}

/**
 *  Set the start to nil -- since we cannot set to 0.
 */
- (void) clearStart {
    self.startTime = nil;
}

- (void) markOffset {
    NSDate *d = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval interval = [d timeIntervalSinceDate:self.startTime];
    self.pausedOffset = (float)interval;
}

/**
 *  Set the offset back to 0.
 */
- (void) clearOffset {
    self.pausedOffset = 0.f;
}



@end
