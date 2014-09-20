//
//  kflMapViewController.h
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 4/3/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "kflLinkedCircleRegion.h"
#import "kflScapeManagerViewController.h"

#define METERS_PER_MILE 1609.344


@interface kflMapViewController : UIViewController<CLLocationManagerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic)   IBOutlet    UIView                  *containerView;
@property (strong, nonatomic)   IBOutlet    UIImageView             *targetView;
@property (strong, nonatomic)               NSMutableDictionary     *scapeRegions;
@property (strong, nonatomic)               NSMutableArray          *regionAnnotationPts, *hiddenRegionAnnotationPts; //, *pathAnnotationPts;
@property (strong, nonatomic)   IBOutlet    UISwitch                *regionAnnotationsTgl;

@property (strong, nonatomic)               UIImage                 *customMapOverlayImg;

- (id)      initWithScapeVC:(id)scapeVC;
- (void)    clearRegions;
- (void)    addRegion:(kflLinkedCircleSFRegion *)region;
- (void)    didUpdateLocation:(CLLocation *)location;

@end
