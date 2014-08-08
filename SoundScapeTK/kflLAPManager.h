//
//  LAPManager.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "kflLocationSegment.h"

@interface kflLAPManager : NSObject {

    NSDate *a, *b;
    CLLocationCoordinate2D lcoord;
    
}

+ (id)sharedManager;

@property (strong, nonatomic)       kflLocationSegment          *lastLocationSegment;
@property (strong, nonatomic)       NSMutableArray              *pastTrackingMarkers;

@property                           CLLocationCoordinate2D      predictedNextLocation;
@property (strong, nonatomic)       NSDate                      *predictedNextTimeStamp;
@property                           CLLocationAccuracy          predictedNextAccuracy;

@property                           float                       timeDelta, timeout;

@property (strong, nonatomic)       NSDateFormatter             *df, *df2;
@property (strong, nonatomic)       NSMutableArray              *lastNLocationPoints;

- (void)            reset;

- (CGPoint)         recordLocationWithLocation:(CLLocation*)location;
- (void)            clearLocations;
- (NSString *)      dumpTrackingMarkers;

- (void)            recordTrackingMarkerWithType:(NSString *)type andArgs:(NSArray *)args;
- (void)            recordHitMarker:(NSString *)annotation;
- (void)            recordPlayMarker:(NSString *)annotation;
- (void)            recordPauseMarker:(NSString *)annotation;
- (void)            recordStopMarker:(NSString *)annotation;
- (NSString *)      setupMarkerString;

- (void)            makePrediciton;
- (void)            checkPrediciton;


@end
