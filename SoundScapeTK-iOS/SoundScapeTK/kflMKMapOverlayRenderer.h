//
//  kflMKMapOverlayRenderer.h
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 5/21/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface kflMKMapOverlayRenderer : MKOverlayRenderer

- (instancetype)initWithOverlay:(id<MKOverlay>)overlay overlayImage:(UIImage *)overlayImage;

@end
