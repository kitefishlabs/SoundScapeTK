//
//  kflLinkedRegion.h
//  SoundScapeTK
//
//  Abstract superclass for Linked______Regions.
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface kflLinkedRegion : NSObject

typedef enum finishRules {
    kREGION_FINISH = 0,
    kREGION_CUTOFF = 1
} kflRegionFinishRule;

@property           CGPoint                 center;
@property (strong)  NSArray                 *idsToActivate;
@property           BOOL                    active;
@property           int                     idNum, numLives, attackTime, releaseTime;
@property (strong)  NSString                *state, *label;
@property           CLLocationCoordinate2D  anchor;
@property           float                   internalDistance;

@end
