//
//  kflPin.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflPin.h"

@implementation kflPin

@synthesize coordinate, title, subtitle, hit;

- (id)initWithCoordinate:(CLLocationCoordinate2D)location placeName:placeName description:description andHit:(BOOL)success {
    self = [super init];
    if (self != nil) {
        coordinate = location;
        title = placeName;
        subtitle = description;
        hit = success;
    }
    return self;
}

@end