//
//  kflMapViewController.m
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 4/3/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflMapViewController.h"
#import "kflPin.h"
#import "LinkedCircleRegion.h"
#import "LinkedSoundfile.h"
#import "ScapeManagerVC2.h"

#import "kflArnoldTile.h"

#define METERS_PER_DEGREE_LAT 111079.08
#define METERS_PER_DEGREE_LON 82460.44
#define METERS_PER_DEGREE_AVG ((111079.08 + 82460.44) / 2.0)

#define SCALING_FACTOR 2.0
#define FUDGE (300.0 / SCALING_FACTOR)
#define HFUDGE (FUDGE / 2.0)

@interface kflMapViewController ()
@property (nonatomic)           int                     screenWidth, screenHeight;
@property (strong, nonatomic)   ScapeManagerVC2         *scapeManager;
@property (strong, nonatomic)   UILabel                 *offMapLbl;
@end


@implementation kflMapViewController

@synthesize containerView = _containerView, targetView = _targetView;
@synthesize scapeManager, scapeRegions, regionAnnotationPts, hiddenRegionAnnotationPts, regionAnnotationsTgl, customMapOverlayImg;

- (id)initWithScapeVC:(id)scapeVC
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        self.scapeRegions = [[NSMutableDictionary alloc] initWithCapacity:2];
        self.scapeManager = scapeVC;
        self.regionAnnotationPts = [NSMutableArray arrayWithCapacity:1];
        self.hiddenRegionAnnotationPts = [NSMutableArray arrayWithCapacity:1];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.screenWidth = screenRect.size.width;
        self.screenHeight = screenRect.size.height;
        
        self.title = @"Map";

    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

//-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    [_mapView setBounds:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width)];
//}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setUpViewForOrientation:toInterfaceOrientation];
}

- (void)setUpViewForOrientation:(UIInterfaceOrientation)orientation
{
    if(UIInterfaceOrientationIsLandscape(orientation))
    {
        [self.offMapLbl setCenter:CGPointMake((self.screenHeight / 2.0), (self.screenWidth / 2.0))];
    }
    else
    {
        [self.offMapLbl setCenter:CGPointMake((self.screenWidth / 2.0), (self.screenHeight / 2.0))];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.scapeManager.bLocationTrackingActive) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil message:@"Start Tracking?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [av show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Cancel...do nothing.");
    }
    else {
        [self.scapeManager toggleLocationTracking];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    kflArnoldTile *tile = [kflArnoldTile tileForImageFile:@"map4.png"]; //map4_noalpha
    
    [tile showFile:YES withGestureRecognizer:nil];
    _containerView = [[UIView alloc] initWithFrame:CGRectMake( 0,0, (int)(tile.imgWidth/SCALING_FACTOR), (int)(tile.imgHeight/SCALING_FACTOR) )];
    [_containerView addSubview:tile.tileImageView];
    
    UIImage *targetImg = [UIImage imageNamed:@"target.png"];
    _targetView = [[UIImageView alloc] initWithImage:targetImg];
    [_targetView setFrame:CGRectMake((self.screenWidth/2 - 4), (self.screenHeight/2 - 4), 8, 8)];
    
    CLLocationCoordinate2D centerCoodinates;
    centerCoodinates.latitude = ORIGIN_LAT - (EXTENT_LAT * 0.5);
    centerCoodinates.longitude = ORIGIN_LON + (EXTENT_LON * 0.5);

    [_containerView setCenter:CGPointMake( self.screenWidth/2, self.screenHeight/2 )];

#ifdef SHOW_CIRCLES
    MapKitLog(@"MAP VIEW DID LOAD!");
    MapKitLog(@"regions: %i", [[self.scapeRegions allKeys] count]);

    for (NSString *key in [scapeRegions allKeys]) {
        LinkedCircleRegion *lcr = [scapeRegions objectForKey:key];
        MapKitLog(@"%i . %f . %f", lcr.idNum, lcr.center.x, lcr.center.y);
        float x = ((lcr.center.y - ORIGIN_LON) / EXTENT_LON);
        float y = ((ORIGIN_LAT - lcr.center.x) / EXTENT_LAT);

        MapKitLog(@"%f | %f || %f | %f | %f | %f",
              lcr.center.y, ORIGIN_LON, // ||
              EXTENT_LON, x, y, ((ABS(EXTENT_LAT) + ABS(EXTENT_LON)) / 2.0));

        float rad = (lcr.radius / ((ABS(EXTENT_LAT) + ABS(EXTENT_LON)) / 2.0)) * ((tile.imgWidth + tile.imgHeight) / 2.0);

        MapKitLog(@"%f | %f | %f | %f", lcr.radius, ((ABS(EXTENT_LAT) + ABS(EXTENT_LON)) / 2.0), (lcr.radius / ((ABS(EXTENT_LAT) + ABS(EXTENT_LON)) / 2.0)), ((tile.imgWidth + tile.imgHeight) / 2.0));

        UIView *circleView = [[UIView alloc] initWithFrame:CGRectMake(((x * (tile.imgWidth/SCALING_FACTOR - FUDGE))-(rad/SCALING_FACTOR) + HFUDGE),((y * (tile.imgHeight/SCALING_FACTOR - FUDGE))-(rad/SCALING_FACTOR) + HFUDGE),rad,rad)];
        MapKitLog(@"%f | %f || %f | %f", ((x * tile.imgWidth/SCALING_FACTOR)-(rad/SCALING_FACTOR)),((y * tile.imgHeight/SCALING_FACTOR)-(rad/SCALING_FACTOR)),rad,rad);
        circleView.alpha = 0.5;
        circleView.layer.cornerRadius = rad / SCALING_FACTOR;
        circleView.backgroundColor = [UIColor orangeColor];
        [_containerView addSubview:circleView];
    }
#endif
    
    [self.view addSubview:_containerView];
    [self.view addSubview:_targetView];
    
    self.offMapLbl = [[UILabel alloc] initWithFrame:CGRectMake((self.screenWidth/2)-100, (self.screenHeight/2)-24, 200, 48)];
    [self.offMapLbl setText:@"You must be in Bussey Brook Meadow to use this app."];
    [self.offMapLbl setTextAlignment:NSTextAlignmentCenter];
    [self.offMapLbl setFont:[UIFont systemFontOfSize:14.0]];
    [self.offMapLbl setBackgroundColor:[UIColor whiteColor]];
    [self.offMapLbl setNumberOfLines:2];
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self setUpViewForOrientation:interfaceOrientation];
    
    [self.view addSubview:self.offMapLbl];
}

- (void) didUpdateLocation:(CLLocation *)location {
    
    MapKitLog(@"-------- %f | %f ", location.coordinate.latitude, location.coordinate.longitude);
    CLLocationCoordinate2D jitLoc = CLLocationCoordinate2DMake(location.coordinate.latitude + LAT_OFFSET, location.coordinate.longitude + LON_OFFSET);
    
    MapKitLog(@"-------- %f | %f ", jitLoc.latitude, jitLoc.longitude);
    
    [self reCenterMap:jitLoc];
    
}

//- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
//    MapKitLog(@"Location fauled with Error: %@", [error description]);
//}

- (void) reCenterMap:(CLLocationCoordinate2D)loc {
    
    float xlon = ((loc.longitude - ORIGIN_LON) / EXTENT_LON);
    float ylat = ((ORIGIN_LAT - loc.latitude) / EXTENT_LAT);
    
    MapKitLog(@"XLON: %f || YLAT: %f", xlon, ylat);
    
    if ((xlon >= 0.0) && (xlon < 1.0) && (ylat >= 0.0) && (ylat < 1.0)) {
        
        // center
        MapKitLog(@"width: %f | height: %f", _containerView.bounds.size.width, _containerView.bounds.size.height);
        
        int containerVecX = (int)(xlon * (_containerView.bounds.size.width - FUDGE));
        int containerVecY = (int)(ylat * (_containerView.bounds.size.height - FUDGE)); // in _containerView pixels
        
        MapKitLog(@"X cont. vec.: %i || Y cont. vec.: %i", containerVecX, containerVecY);
        MapKitLog(@"X: %i || Y: %i", (int)((self.screenWidth/2.0) + (_containerView.bounds.size.width/2.0) - containerVecX - HFUDGE), (int)((self.screenHeight/2.0) + (_containerView.bounds.size.height/2.0) - containerVecY - HFUDGE));

        [_containerView setCenter:CGPointMake((int)((self.screenWidth/2.0) + (_containerView.bounds.size.width/2.0) - containerVecX - HFUDGE), (int)((self.screenHeight/2.0) + (_containerView.bounds.size.height/2.0) - containerVecY - HFUDGE))];
        [_containerView setHidden:NO];
        [_containerView setNeedsDisplay];
        [self.offMapLbl setHidden:YES];

    } else {
        // we are not on the map
        
        [_containerView setHidden:YES];
        [_containerView setNeedsDisplay];
        [self.offMapLbl setHidden:NO];
        
//        self.trackingLocation = NO;
        
        NSLog(@"you're off the map!");
    }
}

//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
//    NSLog(@"update loc MK: %@", _mapView.overlays);
//    MKCoordinateRegion region;
//    CLLocationCoordinate2D location;
//    location.latitude = userLocation.coordinate.latitude;
//    location.longitude = userLocation.coordinate.longitude;
//    region.center = location;
//    region = MKCoordinateRegionMakeWithDistance(location, 500, 500);
//    [_mapView setRegion:region animated:YES];
//}
//
//- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
//
//    NSLog(@"..... %@", [_mapView description]);
//    NSLog(@"overlay descr.: %@", overlay);
//    
//    if ([overlay isKindOfClass:MKCircle.class]) {
//        
//        NSLog(@"A CIRCLE");
//        MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
//        
//        circleView.lineWidth = 1.0;
//        circleView.strokeColor = [UIColor blackColor];
//        circleView.fillColor = [UIColor yellowColor];
//        circleView.alpha = 0.4;
//        circleView.hidden = NO;
//        
//        return circleView;
//    }
//    return nil;
//}

//- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
//    
//    NSLog(@".... %@", [_mapView description]);
//    
//    NSLog(@"overlay descr.: %@", overlay);
//    
//    if ([overlay isKindOfClass:kflMapOverlay.class]) {
//        
//        kflMKMapOverlayRenderer *overlayRenderer = [[kflMKMapOverlayRenderer alloc] initWithOverlay:overlay overlayImage:customMapOverlayImg];
//        NSLog(@"overlayview: %@", overlayRenderer);
//        return overlayRenderer;
//        
//    } else if ([overlay isKindOfClass:MKCircle.class]) {
//        
//        NSLog(@"A CIRCLE");
////        MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
//        MKCircleRenderer *circleRenderer =  [[MKCircleRenderer alloc] initWithCircle:overlay];
//        
////        circleView.lineWidth = 1.0;
////        circleView.strokeColor = [UIColor blackColor];
////        circleView.fillColor = [UIColor yellowColor];
////        circleView.alpha = 0.4;
////        circleView.hidden = NO;
//        circleRenderer.lineWidth = 1.0;
//        circleRenderer.strokeColor = [UIColor blackColor];
//        circleRenderer.fillColor = [UIColor yellowColor];
//        circleRenderer.alpha = 0.4;
//        
//        return circleRenderer;
//    }
//    return nil;
//}

//- (void)toggleAnnotations:(UISwitch *)toggle {
//    if (!toggle.selected) {
//        NSLog(@"%@", regionAnnotationPts);
//        NSLog(@"%@", hiddenRegionAnnotationPts);
//        for (kflPin *pin in hiddenRegionAnnotationPts) {
//            [regionAnnotationPts addObject:pin];
//        }
//        [_mapView addAnnotations:regionAnnotationPts];
//        [hiddenRegionAnnotationPts removeAllObjects];
//        NSLog(@"C: %i, %i, %i", [_mapView.annotations count], [regionAnnotationPts count], [hiddenRegionAnnotationPts count]);
//        toggle.selected = YES;
//    } else {
//        for (kflPin *pin in regionAnnotationPts) {
//            [hiddenRegionAnnotationPts addObject:pin];
//        }
//        [_mapView removeAnnotations:hiddenRegionAnnotationPts];
//        [regionAnnotationPts removeAllObjects];
//        NSLog(@"D: %i, %i, %i", [_mapView.annotations count], [regionAnnotationPts count], [hiddenRegionAnnotationPts count]);
//        toggle.selected = NO;
//    }
//    [self.view setNeedsDisplay];
//}

//// Handle touch event
//- (void)mapViewTapped:(UITapGestureRecognizer *)recognizer
//{
//    CGPoint pointTappedInMapView = [recognizer locationInView:recognizer.view];
//    CLLocationCoordinate2D geoCoordinatesTapped = [_mapView convertPoint:pointTappedInMapView toCoordinateFromView:_mapView];
//    if (recognizer.state == UIGestureRecognizerStateEnded) {
//        MapKitLog(@"TOUCH: %f | %f", geoCoordinatesTapped.latitude, geoCoordinatesTapped.longitude);
//        [self.scapeManager flyToLocation:geoCoordinatesTapped];
//    }
//}



- (void)clearRegions {
    NSLog(@"CLEAR ALL FROM SCAPE REGIONS!");
    [scapeRegions removeAllObjects];
}

- (void)addRegion:(LinkedCircleRegion *)region {
    MapKitLog(@"ADD REGION: (%i) %@ - %f|%f", region.idNum, region, region.center.x, region.center.y);
    [self.scapeRegions setValue:region forKey:[NSString stringWithFormat:@"%i", region.idNum]];
    MapKitLog(@"regions: %i", [self.scapeRegions count]);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
