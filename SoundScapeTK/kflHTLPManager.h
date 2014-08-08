//
//  kflHTLPManager.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "kflLinkedCircleRegion.h"
#import "kflLinkedRectangleRegion.h"
#import "kflLinkedSoundfile.h"
#import "kflLAPManager.h"
#import "kflAudioFileRouter.h"


@interface kflHTLPManager : NSObject

@property (strong, nonatomic)   NSMutableDictionary     *scapeSoundfiles, *scapeRegions;
@property (strong, nonatomic)   kflAudioFileRouter      *audioFileRouter;
@property                       float                   lastLatitude;

+ (id)sharedManager;

- (void)reset;
- (void)killAll;

//- (void)addCircRegion:(kflLinkedCircleSFRegion *)lcr forIndex:(NSNumber *)index;
//- (void)addRectRegion:(kflLinkedRectangleRegion *)lrr forIndex:(NSNumber *)index;
- (void)addRegion:(kflLinkedRegion *)lr forIndex:(NSNumber *)index;

- (NSString *)hitTestRegionsWithLocation:(CGPoint)location;

- (NSString *) pairForFileName:(NSString *)fileName andRegionID:(int)rID;

- (void) processEnterAndExitEvents:(NSArray *)regionList;

- (void) stopLSFForRegion:(kflLinkedCircleSFRegion *)lcr;

- (void) scheduleLSFToPlay:(kflLinkedSoundfile *)lsf forRegion:(kflLinkedCircleSFRegion *)lcr afterDelay:(NSTimeInterval)delay;
//- (void) cancelLSF:(NSNumber *)idNum afterDelay:(NSTimeInterval)delay;

@end
