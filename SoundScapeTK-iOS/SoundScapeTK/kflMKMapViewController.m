//
//  kflMapViewController.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 14 Kitefish Labs. All rights reserved.
//


#import "kflMKMapViewController.h"
#import "kflPin.h"
#import "kflLinkedCircleRegion.h"
#import "kflLinkedSoundfile.h"
#import "kflScapeManagerViewController.h"

#define METERS_PER_DEGREE_LAT 111079.08
#define METERS_PER_DEGREE_LON 82460.44
#define METERS_PER_DEGREE_AVG ((111079.08 + 82460.44) / 2.0)

@interface kflMKMapViewController ()
@property (nonatomic)           int                                 screenWidth, screenHeight;
@property (strong, nonatomic)   kflScapeManagerViewController       *scapeManager;
@end


@implementation kflMKMapViewController

@synthesize mapView = _mapView;
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
    }
    return self;
}

//-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    [_mapView setBounds:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width)];
//}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        _mapView = [[MKMapView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    } else {
        CGRect screen = [[UIScreen mainScreen] bounds];
        _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, screen.size.height, screen.size.height)];
    }
    
    _mapView.delegate = self;
    _mapView.mapType = MKMapTypeHybrid;
    [_mapView setZoomEnabled:YES];
    [_mapView setScrollEnabled:YES];
    _mapView.showsUserLocation = YES;
    
    CLLocationCoordinate2D centerCoodinates;

    centerCoodinates.latitude = 42.925704; // Soldier's Circle
    centerCoodinates.longitude= -78.873758;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(centerCoodinates, 100, 100);
    [_mapView setRegion:viewRegion animated:YES];
    [_mapView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *doubleTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewTapped:)];
    [doubleTapper setNumberOfTapsRequired:3];
    [_mapView addGestureRecognizer:doubleTapper];
    
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        self.regionAnnotationsTgl = [[UISwitch alloc] initWithFrame:CGRectMake(0, ([[UIScreen mainScreen] bounds].size.height - 30), 40, 20)];
    } else {
        self.regionAnnotationsTgl = [[UISwitch alloc] initWithFrame:CGRectMake(0, ([[UIScreen mainScreen] bounds].size.width - 30), 40, 20)];
    }
    [self.regionAnnotationsTgl addTarget:self action:@selector(toggleAnnotations:) forControlEvents:UIControlEventTouchUpInside];
    [self.regionAnnotationsTgl setSelected:NO];
    [_mapView addSubview:regionAnnotationsTgl];
    
    MapKitLog(@"MAP VIEW DID LOAD!");
    MapKitLog(@"regions: %i", [[self.scapeRegions allKeys] count]);
    
    for (NSString *key in self.scapeRegions) {
        
        MapKitLog(@"key: %@", key);
        
        if ([[self.scapeRegions objectForKey:key] isKindOfClass:[kflLinkedCircleSFRegion class]]) {
            
            kflLinkedCircleSFRegion *lcr = [self.scapeRegions objectForKey:key];
            
            MKCircle *circ = [MKCircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(lcr.center.x, lcr.center.y) radius:(lcr.radius*METERS_PER_DEGREE_AVG)];
            circ.title = @"CirC";
            
            MapKitLog(@"========%f, %f, %f", circ.coordinate.latitude, circ.coordinate.longitude, (circ.radius));
            //MapKitLog(@"========%f, %f, %f", lcr.center.x, lcr.center.y, (lcr.radius*100000.0));
            
            kflPin *cpa = [[kflPin alloc] initWithCoordinate:CLLocationCoordinate2DMake(lcr.center.x, lcr.center.y)
                                                   placeName:[NSString stringWithFormat:@"id: %i -- %@",
                                                              lcr.idNum, //[[lcr.linkedSoundfiles objectAtIndex:0] fileName]]
                                                              lcr.label]
                                                 description:[NSString stringWithFormat:@"%i | %i | st: %@ || %i | %i", lcr.attackTime, lcr.releaseTime, lcr.state, lcr.numLives, lcr.numLoops]
                                                      andHit:YES];
            
            [_mapView addOverlay:circ];
            if (regionAnnotationsTgl.selected) {
                [regionAnnotationPts addObject:cpa];
                [_mapView addAnnotation:cpa];
                MapKitLog(@"E: %i, %i, %i", [_mapView.annotations count], [regionAnnotationPts count], [hiddenRegionAnnotationPts count]);
            } else {
                [hiddenRegionAnnotationPts addObject:cpa];
                MapKitLog(@"F: %i, %i, %i", [_mapView.annotations count], [regionAnnotationPts count], [hiddenRegionAnnotationPts count]);
            }
        } else if ([[self.scapeRegions objectForKey:key] isKindOfClass:[kflLinkedCircleSynthRegion class]]) {
            
            kflLinkedCircleSynthRegion *lcsr = [self.scapeRegions objectForKey:key];
            
            MKCircle *circ = [MKCircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(lcsr.center.x, lcsr.center.y) radius:(lcsr.radius*METERS_PER_DEGREE_AVG)];
            circ.title = @"CirC";
            
            MapKitLog(@"========%f, %f, %f", circ.coordinate.latitude, circ.coordinate.longitude, (circ.radius));
            //MapKitLog(@"========%f, %f, %f", lcr.center.x, lcr.center.y, (lcr.radius*100000.0));
            
            kflPin *cpa = [[kflPin alloc] initWithCoordinate:CLLocationCoordinate2DMake(lcsr.center.x, lcsr.center.y)
                                                   placeName:[NSString stringWithFormat:@"id: %i -- %@",
                                                              lcsr.idNum, //[[lcr.linkedSoundfiles objectAtIndex:0] fileName]]
                                                              lcsr.label]
                                                 description:[NSString stringWithFormat:@"%i | %i | st: %@ || %i", lcsr.attackTime, lcsr.releaseTime, lcsr.state, lcsr.numLives]
                                                      andHit:YES];
            [_mapView addOverlay:circ];
            if (regionAnnotationsTgl.selected) {
                [regionAnnotationPts addObject:cpa];
                [_mapView addAnnotation:cpa];
                MapKitLog(@"E: %i, %i, %i", [_mapView.annotations count], [regionAnnotationPts count], [hiddenRegionAnnotationPts count]);
            } else {
                [hiddenRegionAnnotationPts addObject:cpa];
                MapKitLog(@"F: %i, %i, %i", [_mapView.annotations count], [regionAnnotationPts count], [hiddenRegionAnnotationPts count]);
            }
        }
    }
    
    [self.view addSubview:_mapView];
    
//    UIImage *targetImg = [UIImage imageNamed:@"target.png"];
//    UIImageView *targetView = [[UIImageView alloc] initWithImage:targetImg];
//    [targetView setFrame:CGRectMake((self.screenWidth/2 - 8), (self.screenHeight/2 - 4), 8, 8)];
//    [self.view addSubview:targetView];
    
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location fauled with Error: %@", [error description]);
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    NSLog(@"update loc MK: %@", _mapView.overlays);
    MKCoordinateRegion region;
    CLLocationCoordinate2D location;
    location.latitude = userLocation.coordinate.latitude + LAT_OFFSET;
    location.longitude = userLocation.coordinate.longitude + LON_OFFSET;
    region.center = location;
    region = MKCoordinateRegionMakeWithDistance(location, 500, 500);
    [_mapView setRegion:region animated:YES];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {

    NSLog(@"..... %@", [_mapView description]);
    NSLog(@"overlay descr.: %@", overlay);
    
    if ([overlay isKindOfClass:MKCircle.class]) {
        
        NSLog(@"A CIRCLE");
        MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
        
        circleView.lineWidth = 1.0;
        circleView.strokeColor = [UIColor blackColor];
        circleView.fillColor = [UIColor yellowColor];
        circleView.alpha = 0.4;
        circleView.hidden = NO;
        
        return circleView;
    }
    return nil;
}

- (void)toggleAnnotations:(UISwitch *)toggle {
    if (!toggle.selected) {
        NSLog(@"%@", regionAnnotationPts);
        NSLog(@"%@", hiddenRegionAnnotationPts);
        for (kflPin *pin in hiddenRegionAnnotationPts) {
            [regionAnnotationPts addObject:pin];
        }
        [_mapView addAnnotations:regionAnnotationPts];
        [hiddenRegionAnnotationPts removeAllObjects];
        NSLog(@"C: %lu, %lu, %lu", (unsigned long)[_mapView.annotations count], (unsigned long)[regionAnnotationPts count], (unsigned long)[hiddenRegionAnnotationPts count]);
        toggle.selected = YES;
    } else {
        for (kflPin *pin in regionAnnotationPts) {
            [hiddenRegionAnnotationPts addObject:pin];
        }
        [_mapView removeAnnotations:hiddenRegionAnnotationPts];
        [regionAnnotationPts removeAllObjects];
        NSLog(@"D: %lu, %lu, %lu", (unsigned long)[_mapView.annotations count], (unsigned long)[regionAnnotationPts count], (unsigned long)[hiddenRegionAnnotationPts count]);
        toggle.selected = NO;
    }
    [self.view setNeedsDisplay];
}

// Handle touch event
- (void)mapViewTapped:(UITapGestureRecognizer *)recognizer
{
    CGPoint pointTappedInMapView = [recognizer locationInView:recognizer.view];
    CLLocationCoordinate2D geoCoordinatesTapped = [_mapView convertPoint:pointTappedInMapView toCoordinateFromView:_mapView];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        MapKitLog(@"TOUCH: %f | %f", geoCoordinatesTapped.latitude, geoCoordinatesTapped.longitude);
        [self.scapeManager flyToLocation:geoCoordinatesTapped];
    }
}



- (void)clearRegions {
    NSLog(@"CLEAR ALL FROM SCAPE REGIONS!");
    [scapeRegions removeAllObjects];
}

- (void)addRegion:(kflLinkedRegion *)region {
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
