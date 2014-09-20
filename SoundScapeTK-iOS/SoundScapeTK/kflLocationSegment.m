//
//  kflLocationSegment.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//


#import "kflLocationSegment.h"

@implementation kflLocationSegment

@synthesize tsA, tsB, coord, accuracy;

+ (kflLocationSegment *)segmentWithCoord:(CLLocationCoordinate2D)coordinate accuracy:(CLLocationAccuracy)accuracy timeA:(NSDate *)timeA timeB:(NSDate *)timeB {
    kflLocationSegment *ls = [[kflLocationSegment alloc] init];
    ls.coord = coordinate;
    ls.accuracy = accuracy;
    ls.tsA = timeA;
    ls.tsB = timeB;
    return ls;
}

@end


@implementation kflTrackingMarker

@synthesize timestamp, type, args;

+ (kflTrackingMarker *)trackingMarkerWithTimestamp:(NSDate *)timestamp type:(NSString *)type andArgs:(NSArray *)args {
    kflTrackingMarker *tm = [[kflTrackingMarker alloc] init];
    tm.timestamp = ((timestamp != nil) ? timestamp : [NSDate dateWithTimeIntervalSinceNow:0]); // default to now!
    tm.type = type;
    tm.args = args;
    return tm;
}

@end