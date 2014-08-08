//
//  kflMKMapViewController.h
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 4/3/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "kflLinkedCircleRegion.h"

#define METERS_PER_MILE 1609.344

@interface kflMKMapViewController : UIViewController<MKMapViewDelegate>

@property (strong, nonatomic)   IBOutlet    MKMapView               *mapView;
@property (strong, nonatomic)               NSMutableDictionary     *scapeRegions;
@property (strong, nonatomic)               NSMutableArray          *regionAnnotationPts, *hiddenRegionAnnotationPts; //, *pathAnnotationPts;
@property (strong, nonatomic)   IBOutlet    UISwitch                *regionAnnotationsTgl;

@property (strong, nonatomic)               UIImage                 *customMapOverlayImg;

- (id)initWithScapeVC:(id)scapeVC;
- (void) clearRegions;
- (void) addRegion:(kflLinkedRegion *)region;

@end
