//
//  kflLinkedRectangleRegion.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflLinkedRectangleRegion.h"

@implementation kflLinkedRectangleRegion

@synthesize points, numPoints, prect, halfDiag;

+ (kflLinkedRectangleRegion *)linkedRectangleRegionWithPoints:(NSArray *)points
                                                linkedSoundfiles:(NSArray *)lsf
                                                           idNum:(int)idNum
                                                          attack:(int)atk
                                                         release:(int)rel
                                                           loops:(int)loops
                                                        loopRule:(kflRegionLoopRule)rule
                                                           lives:(int)lives
                                                          active:(BOOL)activeFlag
                                                      toActivate:(NSArray *)regionIDS
                                                           state:(NSString *)state
                                                         andRect:(CGRect)rect {
    
    kflLinkedRectangleRegion *lrr = [[kflLinkedRectangleRegion alloc] init];

    if (lrr) {
        lrr.idNum = idNum;
        lrr.numPoints = [points count];
        lrr.prect = rect;
        lrr.linkedSoundfiles = lsf;
        lrr.numLinkedSoundfiles = [lsf count];
        lrr.attackTime = atk;
        lrr.releaseTime = rel;
        lrr.numLoops = loops;
        lrr.loopRule = rule;
        lrr.numLives = lives;
        lrr.active = activeFlag;
        lrr.idsToActivate = regionIDS;
        lrr.state = state;
        lrr.points = points;
        lrr.anchor = CLLocationCoordinate2DMake(rect.origin.x+(rect.size.width*0.5), rect.origin.y+(rect.size.height*0.5));
        lrr.internalDistance = 0.0;
        lrr.halfDiag = sqrtf(powf(lrr.prect.size.width,2.0)+powf(lrr.prect.size.height,2.0))/2.0;
    }    
    return lrr;
}

- (NSString *)description {
    NSString *str = [NSString stringWithFormat:@"%i\n%i\n%f, %f, %f, %f\n%@\n%@\n%@", self.idNum, self.numPoints, self.prect.origin.x, self.prect.origin.y, self.prect.size.width, self.prect.size.height, self.linkedSoundfiles, self.state, self.points];
    
    
    return str;
}

@end
