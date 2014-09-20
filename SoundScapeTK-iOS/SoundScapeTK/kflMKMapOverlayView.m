//
//  kflMKMapOverlayView.m
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 5/21/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflMKMapOverlayView.h"

@class kflMapOverlay;

@interface kflMKMapOverlayView ()
@property (nonatomic, strong) UIImage *overlayImage;
@end


@implementation kflMKMapOverlayView

@synthesize overlayImage = _overlayImage;

- (id)initWithOverlay:(id<MKOverlay>)overlay overlayImage:(UIImage *)overlayImage {
    NSLog(@"INIT: %@", overlay);
    self = [super initWithOverlay:overlay];
    if (self) {
        _overlayImage = overlayImage;
    }
    NSLog(@"overlay image: %@", _overlayImage);
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context {
    CGImageRef imageReference = self.overlayImage.CGImage;
    
    MKMapRect theMapRect = self.overlay.boundingMapRect;
    CGRect theRect = [self rectForMapRect:theMapRect];
    
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0.0, -theRect.size.height);
    CGContextDrawImage(context, theRect, imageReference);
}

//-(BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale { return TRUE; }



//-(void)setNeedsDisplayInMapRect:(MKMapRect)mapRect {}
//-(void)setNeedsDisplayInMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {}


@end
