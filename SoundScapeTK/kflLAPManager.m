//
//  kflLAPManager.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflLAPManager.h"
#import <CoreLocation/CoreLocation.h>

#define MIN_DIST_LIMIT  0.0
#define MIN_TIME_BETWEEN_HITS 0.0
#define NPTS 3

@implementation kflLAPManager

//@synthesize currentLocation;
@synthesize lastLocationSegment, pastTrackingMarkers;  // .. other markers or segments ?
@synthesize predictedNextLocation, predictedNextTimeStamp, predictedNextAccuracy;
@synthesize timeDelta, timeout, df, df2, lastNLocationPoints;

+ (id)sharedManager {
    static kflLAPManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id) init {
    
    if (self = [super init]) {
                
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yy-MM-dd_HH:mm:ss"];
        df2 = [[NSDateFormatter alloc] init];
        [df2 setDateFormat:@"HH:mm:ss"];
        
        [self reset];
    }
    return self;    
}


- (void) reset {
    // init with bad values
    self.lastLocationSegment = nil;
    if (self.pastTrackingMarkers == nil) {
        self.pastTrackingMarkers = [[NSMutableArray alloc] init];
    } else {
        [self clearLocations];
    }

    // init trail of last N points or clear
    if (lastNLocationPoints == nil) {
        lastNLocationPoints = [NSMutableArray arrayWithCapacity:NPTS];
    } else {
        [lastNLocationPoints removeAllObjects];
    }
    
    self.predictedNextLocation = CLLocationCoordinate2DMake(0.0, 0.0);
    self.predictedNextTimeStamp = [NSDate dateWithTimeIntervalSince1970:0.0];
    self.predictedNextAccuracy = 9999.0;
    
    a = [NSDate distantPast];
    b = [NSDate distantPast];
    lcoord = CLLocationCoordinate2DMake(0.0, 0.0);
}


- (CGPoint) recordLocationWithLocation:(CLLocation*)location {
    // THIS IS WHERE SOME PREPROCESSING WOULD GO
    //  - lowpass filtering
    //  - moving-average filter
    //  - median filter
    
    float dist, timeIntervalThisUpdate = 0;
    
    if ((a == [NSDate distantPast]) && (b == [NSDate distantPast])) {

        a = [NSDate dateWithTimeIntervalSinceNow:0];
        b = [NSDate dateWithTimeIntervalSinceNow:0];
        lcoord = location.coordinate;
        LocUpdateLog(@"LAPmngr: update a, b, lcoord...initially: b - a: %f", [b timeIntervalSinceDate:a]);
        
        LocUpdateLog(@"LAPmngr: record initial location!");
        kflLocationSegment *ls = [kflLocationSegment segmentWithCoord:location.coordinate accuracy:location.horizontalAccuracy timeA:a timeB:b];
        [self recordTrackingMarkerWithType:@"INITIAL LOC" andArgs:[NSArray arrayWithObjects:ls, nil]];
        lastLocationSegment = ls;
        
        timeIntervalThisUpdate = 0.0;
        return CGPointMake(location.coordinate.latitude, location.coordinate.longitude);
        
    } else {
    
        kflLocationSegment *last = self.lastLocationSegment;
        CLLocation *cllast = [[CLLocation alloc] initWithLatitude:last.coord.latitude longitude:last.coord.longitude];
        
        dist = [location distanceFromLocation:cllast];
    
        LocUpdateLog(@"LAPmngr: ====>   %@ DIST: %f", [location description], dist);
    
        if (dist > MIN_DIST_LIMIT) {
            
            [lastLocationSegment setTsB:b]; // to whatever b was last updated to
            LocUpdateLog(@"LAPmngr: ...updated last segment");
            
            LocUpdateLog(@"LAPmngr: update a, b, lcoord for new segment\n     ...drop a new 0-time-length segment into the array...");
            a = [NSDate dateWithTimeIntervalSinceNow:0];
            b = [NSDate dateWithTimeIntervalSinceNow:0];
            lcoord = location.coordinate;
            kflLocationSegment *ls = [kflLocationSegment segmentWithCoord:location.coordinate accuracy:location.horizontalAccuracy timeA:a timeB:b];
            [self recordTrackingMarkerWithType:@"LOC" andArgs:[NSArray arrayWithObjects:ls, nil]];
            lastLocationSegment = ls;
            
        } else {
            
            b = [NSDate dateWithTimeIntervalSinceNow:0];
            LocUpdateLog(@"LAPmngr: just update the time end point... %@", [df2 stringFromDate:b]);
            
        }
         timeIntervalThisUpdate = ABS(b.timeIntervalSince1970 - a.timeIntervalSince1970);
    }
    
    float newLat = location.coordinate.latitude;
    float newLon = location.coordinate.longitude;
    
    // SHOULDN'T 0 be OK???
    
    // check for TIME-DELTA --> 0
    // * res is the time delta and ignore any
    if (timeIntervalThisUpdate > MIN_TIME_BETWEEN_HITS) {
        
        NSLog(@"        LOCATION POINT: %f, %f", newLat, newLon);
        
        // iterate the list of last N points
        //  - if w/i 5.0 meters of current point add to avg-total, increment counter
        // compute average of all (up to N) points ---> pt for hit test
        [lastNLocationPoints insertObject:location atIndex:0];
        if ([lastNLocationPoints count] > NPTS) {
            [lastNLocationPoints removeLastObject];
        }
        
        float accum_lat = 0.0;
        float accum_lon = 0.0;
        int count = 0;
        CLLocationCoordinate2D avgPt;
        
        for (CLLocation *locn in lastNLocationPoints) {
                accum_lat += locn.coordinate.latitude;
                accum_lon += locn.coordinate.longitude;
                count++;
            }
        
        /**
         *  post=processing : average the last 3 points, not very sophisticated
         */
        if (count > 0) {
            LocUpdateLog(@"count: %i, totals: %f, %f", count, accum_lat, accum_lon);
            avgPt = CLLocationCoordinate2DMake((accum_lat/(float)count), (accum_lon/(float)count));
            
        }
        CGPoint pt = CGPointMake(avgPt.latitude, avgPt.longitude);
        LocUpdateLog(@"AVERAGED POINT: %f, %f", avgPt.latitude, avgPt.longitude);
        return pt;
    }
    return CGPointMake(0, 0);
}

- (void) clearLocations {
    [self.pastTrackingMarkers removeAllObjects];
}

- (NSString *) dumpTrackingMarkers {
    
//    DLog(@"LAPmngr: dump tracking markers");
    NSMutableString *printString = [[self setupMarkerString] mutableCopy];
//    DLog(@"LAPmngr: past tracking markers: %@", [pastTrackingMarkers description]);
    
    for (kflTrackingMarker *tm in self.pastTrackingMarkers)
    {
        
        //DLog(@"lat: %f", pastlocSeg.coord.latitude);
        
        if ([tm.type compare:@"LOC"] == NSOrderedSame) {

            kflLocationSegment *ls = [tm.args objectAtIndex:0];
            [printString appendString:[NSString stringWithFormat:@"%@ -> %@ = %3.6f %3.6f %2.1f\n", 
                                       [df2 stringFromDate:ls.tsA],
                                       [df2 stringFromDate:ls.tsB],
                                       ls.coord.latitude, 
                                       ls.coord.longitude, 
                                       ls.accuracy]];
            
        } else if ([tm.type compare:@"PLAY"] == NSOrderedSame) {
            
            NSArray *sfiles = tm.args;
            NSMutableString *sfString = [NSMutableString stringWithCapacity:20];
            for (NSNumber *num in sfiles) {
                [sfString appendFormat:@"%@ ", [num stringValue]];
            }
            [printString appendFormat:@"%@ = PLAY: %@\n", [df2 stringFromDate:tm.timestamp], sfString];

        } else {
            DLog(@"unrecognized tracking marker: %@", tm.type);
        }
    }
    return printString;
}

- (void) recordTrackingMarkerWithType:(NSString *)type andArgs:(NSArray *)args {
    
    kflTrackingMarker *tm;
    
    // type = LOC; args = lat, lon
    if ([type compare:[NSString stringWithFormat:@"INITIAL LOC"]] == NSOrderedSame) {
        NSLog(@"INIT LOC");
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
        // type = LOC; args = ??
    } else if ([type compare:[NSString stringWithFormat:@"LOC"]] == NSOrderedSame) {
        NSLog(@"LOC");
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
        // type = LOC; args = ??
    } else if ([type compare:[NSString stringWithFormat:@"PLAY"]] == NSOrderedSame) {
        NSLog(@"PLAY");
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:args];
        
    } else if ([type compare:[NSString stringWithFormat:@"PAUSE"]] == NSOrderedSame) {
        NSLog(@"PAUSE");
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
        
    } else if ([type compare:[NSString stringWithFormat:@"STOP"]] == NSOrderedSame) {
        NSLog(@"STOP");
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
        
    } else if ([type compare:[NSString stringWithFormat:@"STOP REQUESTED"]] == NSOrderedSame) {

        
        
    } else if ([type compare:[NSString stringWithFormat:@"SEND EMAIL LOG"]] == NSOrderedSame) {
        NSLog(@"STOP");
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
    } else if ([type compare:[NSString stringWithFormat:@"CHANGE ACCURACY LIMIT"]] == NSOrderedSame) {
        
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];

    } else if ([type compare:[NSString stringWithFormat:@"CHANGE MAP"]] == NSOrderedSame) {
        
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];

    } else if ([type compare:[NSString stringWithFormat:@"CHANGE TIMEOUT"]] == NSOrderedSame) {
        
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
        
    } else if ([type compare:[NSString stringWithFormat:@"CHANGE TIMEDELTA"]] == NSOrderedSame) {
        
        tm = [kflTrackingMarker trackingMarkerWithTimestamp:[NSDate dateWithTimeIntervalSinceNow:0] type:type andArgs:[NSArray arrayWithObjects:[args objectAtIndex:0], nil]];
    }

    [pastTrackingMarkers addObject:tm];
}

- (void) recordHitMarker:(NSString *)annotation {
    
}

- (void) recordPlayMarker:(NSString *)annotation {
    
}

- (void) recordPauseMarker:(NSString *)annotation {
    
}

- (void) recordStopMarker:(NSString *)annotation {
    
}

- (NSString *) setupMarkerString {
    NSMutableString *printString = [NSMutableString stringWithString:@""];
    [printString appendString:[NSString stringWithFormat:@"Report generated: %@\n\n", [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]]];
    return printString;

}


- (void) makePrediciton {
    
}

- (void) checkPrediciton {
    
}

@end
