//
//  kflAudioFileRouter.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 4/5/14.
//  Copyright (c) 2012-14 Thomas Stoll/Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kflLinkedSoundfile.h"
#import "kflLinkedCircleRegion.h"
#import "kflLinkedParameter.h"

@interface kflAudioFileRouter : NSObject {}

@property (nonatomic, strong)   NSString            *patchString, *sndDirString;
@property (nonatomic, strong)   NSMutableDictionary *activeHash;

+ (kflAudioFileRouter *) audioFileRouterForPatch:(NSString *)patchString withNumberOfSlots:(int)numSlots;

- (void)        resetRouter;

- (float)       playLinkedSoundFile:(kflLinkedSoundfile *)lsf forRegion:(kflLinkedCircleSFRegion *)lcr atVolume:(float)vol;
- (void)        stopLinkedSoundFileForRegion:(kflLinkedCircleSFRegion *)lcr;
- (void)        stopLinkedSoundFileForTimer:(NSTimer *)timer;
- (void)        resetLinkedSoundFileForRegion:(kflLinkedCircleSFRegion *)lcr;
- (void)        resetLinkedSoundFileForTimer:(NSTimer *)timer;

- (void)        openSFilePath:(NSString *)sfilePath inSlot:(int)slot withOnsetTime:(int)onset;

- (void)        adjustAttackForLSF:(kflLinkedSoundfile *)lsf to:(int)attack;
- (void)        adjustReleaseForLSF:(kflLinkedSoundfile *)lsf to:(int)release;

- (void)        adjustVolumeForLSF:(kflLinkedSoundfile *)lsf to:(float)volume withRampTime:(int)rampTime;
- (void)        adjustPanForLSF:(kflLinkedSoundfile *)lsf to:(float)pan withRampTime:(int)rampTime;

- (int)         assignSlotForLSF:(kflLinkedSoundfile *)lsf;
- (int)         freeSlotForLSF:(kflLinkedSoundfile *)lsf;

- (void)        executeParamChangeforLCSR:(kflLinkedCircleSynthRegion *)lcsr;

@end
