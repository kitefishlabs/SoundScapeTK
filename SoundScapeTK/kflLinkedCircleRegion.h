//
//  kflLinkedCircleRegion.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "kflLinkedRegion.h"

@interface kflLinkedCircleSFRegion : kflLinkedRegion

@property           float                   radius;
@property           int                     numLinkedSoundfiles, numLoops;
@property           NSArray                 *linkedSoundfiles;
@property           kflRegionLoopRule       loopRule;

+ (kflLinkedCircleSFRegion *)kflLinkedCircleSFRegionWithCenter:(CGPoint)center
                                                        radius:(float)radius
                                                         idNum:(int)idNum
                                                         label:(NSString *)label
                                              linkedSoundFiles:(NSArray *)lsf
                                                        attack:(int)atk
                                                       release:(int)rel
                                                         loops:(int)loops
                                                      loopRule:(kflRegionLoopRule)rule
                                                         lives:(int)lives
                                                        active:(BOOL)activeFlag
                                                    toActivate:(NSArray *)regionIDS
                                                      andState:(NSString *)state;
@end

@interface kflLinkedCircleSynthRegion : kflLinkedRegion

@property           float                   radius, angle, angleOffset;
@property           int                     numLinkedParams;
@property           NSArray                 *linkedParameters;

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
                                                            andState:(NSString *)state;

@end
