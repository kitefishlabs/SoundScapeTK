//
//  kflMapOverlay.h
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 5/21/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface kflMapOverlay : NSObject <MKOverlay>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MKMapRect boundingMapRect;

@end
