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



@interface kflLinkedCircleRegion : kflLinkedRegion

@property           float                   radius, angle, angleOffset;

@end



@interface kflLinkedCircleSFRegion : kflLinkedCircleRegion

@property           int                     numLinkedSoundfiles, numLoops;
@property           NSArray                 *linkedSoundfiles;
@property           kflRegionFinishRule     finishRule;
@property           BOOL                    radiusMapped;

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
                                                      andState:(NSString *)state;
@end



@interface kflLinkedCircleSynthRegion : kflLinkedCircleRegion

@property           int                     numLinkedParams;
@property           NSDictionary            *linkedParameters;

+ (kflLinkedCircleSynthRegion *)kflLinkedCircleSynthRegionWithCenter:(CGPoint)center
                                                              radius:(float)radius
                                                               idNum:(int)idNum
                                                               label:(NSString *)label
                                                        linkedParams:(NSDictionary *)params
                                                         angleOffset:(float)aoffset
                                                              attack:(int)atk
                                                             release:(int)rel
                                                               lives:(int)lives
                                                              active:(BOOL)activeFlag
                                                          toActivate:(NSArray *)regionIDS
                                                            andState:(NSString *)state;

@end
