//
//  kflLinkedRectangleRegion.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "kflLinkedRegion.h"

@interface kflLinkedRectangleRegion : kflLinkedRegion

@property (strong)  NSArray                 *points;
@property           CGRect                  prect;
@property           int                     numPoints;
@property           float                   halfDiag;

@property           int                     numLinkedSoundfiles, numLoops;
@property           NSArray                 *linkedSoundfiles;
@property           kflRegionFinishRule     finishRule;


+ (kflLinkedRectangleRegion *)linkedRectangleRegionWithPoints:(NSArray *)points
                                             linkedSoundfiles:(NSArray *)lsf
                                                        idNum:(int)idNum
                                                       attack:(int)atk
                                                      release:(int)rel
                                                        loops:(int)loops
                                                   finishRule:(kflRegionFinishRule)rule
                                                        lives:(int)lives
                                                       active:(BOOL)activeFlag
                                                   toActivate:(NSArray *)regionIDS
                                                        state:(NSString *)state
                                                      andRect:(CGRect)rect;

@end
