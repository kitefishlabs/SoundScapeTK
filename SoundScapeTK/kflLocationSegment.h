//
//  kflLocationSegment.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface kflLocationSegment : NSObject


@property (strong, nonatomic)   NSDate                  *tsA, *tsB;
@property                       CLLocationCoordinate2D  coord;
@property                       CLLocationAccuracy      accuracy;

+ (kflLocationSegment *)segmentWithCoord:(CLLocationCoordinate2D)coordinate accuracy:(CLLocationAccuracy)accuracy timeA:(NSDate *)timeA timeB:(NSDate *)timeB;

@end

@interface kflTrackingMarker : NSObject


@property (strong, nonatomic)   NSDate                  *timestamp;
@property (strong, nonatomic)   NSString                *type;
@property (strong, nonatomic)   NSArray                 *args;

+ (kflTrackingMarker *)trackingMarkerWithTimestamp:(NSDate *)timestamp type:(NSString *)type andArgs:(NSArray *)args;
//- (NSString *) computeMarkerString;

@end