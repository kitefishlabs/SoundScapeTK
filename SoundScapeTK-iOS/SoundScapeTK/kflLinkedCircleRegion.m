//
//  kflLinkedCircleRegion.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflLinkedCircleRegion.h"

@implementation kflLinkedCircleRegion
@synthesize radius, angle, angleOffset;
@end

@implementation kflLinkedCircleSFRegion

@synthesize numLinkedSoundfiles, numLoops, linkedSoundfiles, finishRule, radiusMapped;

+ (kflLinkedCircleSFRegion *)kflLinkedCircleSFRegionWithCenter:(CGPoint)center
                                                        radius:(float)radius
                                                         idNum:(int)idNum
                                                         label:(NSString *)label
                                              linkedSoundFiles:(NSArray *)lsf
                                                  radiusMapped:(BOOL)radMapped
                                                        attack:(int)atk
                                                       release:(int)rel
                                                         loops:(int)loops
                                                    finishRule:(kflRegionFinishRule)rule
                                                         lives:(int)lives
                                                        active:(BOOL)activeFlag
                                                    toActivate:(NSArray *)regionIDS
                                                      andState:(NSString *)state {

    kflLinkedCircleSFRegion *lcr = [[kflLinkedCircleSFRegion alloc] init];
    
    if (lcr) {
        lcr.center = center;
        lcr.radius = radius;
        lcr.idNum = idNum; // this is the idNum of the region and the primary key
        lcr.label = label;
        lcr.linkedSoundfiles = lsf;
        lcr.radiusMapped = radMapped;
        lcr.numLinkedSoundfiles = (int)[lsf count]; // should always == 1, for now...
        lcr.attackTime = atk;
        lcr.releaseTime = rel;
        lcr.finishRule = rule;
        lcr.numLives = lives;
        lcr.active = activeFlag;
        lcr.idsToActivate = regionIDS;
        lcr.numLoops = loops;
        lcr.state = state;
        lcr.anchor = CLLocationCoordinate2DMake(center.x, center.y);
        lcr.stopTimer = nil;
        lcr.internalDistance = 0.0;
    }    
    return lcr;

}
@end

@implementation kflLinkedCircleSynthRegion

@synthesize linkedParameters, numLinkedParams;

+ (kflLinkedCircleSynthRegion *)kflLinkedCircleSynthRegionWithCenter:(CGPoint)center
                                                              radius:(float)radius
                                                               idNum:(int)idNum
                                                               label:(NSString *)label
                                                        linkedParams:(NSArray *)params
                                                         angleOffset:(float)aoffset
                                                              attack:(int)atk
                                                             release:(int)rel
                                                               lives:(int)lives
                                                              active:(BOOL)activeFlag
                                                          toActivate:(NSArray *)regionIDS
                                                            andState:(NSString *)state {
    
    kflLinkedCircleSynthRegion *lcr = [[kflLinkedCircleSynthRegion alloc] init];
    
    if (lcr) {
        lcr.center = center; //
        lcr.radius = radius; //
        lcr.idNum = idNum; // this is the idNum of the region and the primary key
        lcr.label = label;
        lcr.linkedParameters = params;
        lcr.numLinkedParams = (int)[params count]; // should always == 2 for param regions
        lcr.attackTime = atk;
        lcr.releaseTime = rel;
        lcr.numLives = lives;
        lcr.active = activeFlag;
        lcr.idsToActivate = regionIDS;
        lcr.state = state;
        lcr.anchor = CLLocationCoordinate2DMake(center.x, center.y);
        lcr.internalDistance = 0.0;
        lcr.angle = 0.0;
        lcr.stopTimer = nil;
        lcr.angleOffset = aoffset;
    }    
    return lcr;
    
}

@end
