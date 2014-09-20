//
//  kflMapOverlay.m
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 5/21/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflMapOverlay.h"

@implementation kflMapOverlay

@synthesize coordinate;
@synthesize boundingMapRect;

- (id)init {
    self = [super init];
    if (self) {
        coordinate = CLLocationCoordinate2DMake(42.298731, -71.1167395);
        boundingMapRect = MKMapRectMake(-71.120752, 42.300612, 0.008025, 0.003762); //x, y, w, h
        
        NSLog(@":::::::::: %f, %f", self.coordinate.latitude, coordinate.longitude);
        NSLog(@":::::::::: %f, %f, %f, %f", self.boundingMapRect.origin.x, self.boundingMapRect.origin.y, self.boundingMapRect.size.width, self.boundingMapRect.size.height);
    }
    return self;
}

- (BOOL)canReplaceMapContent {
    return 1;
}

@end
