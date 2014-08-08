//
//  kflScapeManagerViewController.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflScapeManagerViewController.h"
#import "kflAppDelegate.h"
#import "kflModalAboutViewController.h"
#import <MessageUI/MessageUI.h>
//#import "SimulatedRoute.h"

#define NUMBER_OF_ACTIVE_REGIONS 32
#define NPTS 3
#define MIN_TIME_BETWEEN_HITS 0.1

@interface kflScapeManagerViewController()<MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) kflAppDelegate *appDelegate;

@end

@implementation kflScapeManagerViewController

@synthesize appDelegate, notifyLbl, goBtn;
@synthesize jsonFilePath, locationManager, lapManager, htlpManager;
@synthesize bLocationTrackingActive, timeout, timedelta, runningAcc, bubbleCutoff;
@synthesize titleCirclesImgView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.appDelegate = (kflAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // setup "ENV" variables
        timeout = 0.75;             // time to wait for a location fix after requesting it
        timedelta = 1.0;            // time interval between location requests
        runningAcc = 0.0;           // var for tracking the running avg. of the accuracy

        bubbleCutoff = 0.00009;     //
        
        for (int i=0; i<NPTS; i++) {    //
            runningAvgs[i] = 0.0;
        }
        raIndex = 0;                // running avg. index - index to the running avg. array
        
        [self resetTimingLoop];     //
        
        if (![CLLocationManager locationServicesEnabled]) { // class method!
            UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                                                            message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
            [servicesDisabledAlert show];
        } else if ([CLLocationManager locationServicesEnabled]) {
            
            DLog(@"Core Location services are enabled!");
            self.locationManager = [[CLLocationManager alloc] init];
            
            [locationManager setDelegate:self];
            [locationManager setDistanceFilter:kCLDistanceFilterNone];
            [locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
//            [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        }
#ifdef MKMAP
        self.mapVC = [[kflMKMapViewController alloc] initWithScapeVC:self];
#else
//        self.mapVC = [[kflMapViewController alloc] initWithScapeVC:self];
#endif
        
    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self setUpViewForOrientation:interfaceOrientation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (void)setUpViewForOrientation:(UIInterfaceOrientation)orientation
{
    if(UIInterfaceOrientationIsLandscape(orientation))
    {
        
        NSString *version = [[UIDevice currentDevice] systemVersion];
        int ver = [version intValue];
        if (ver < 7){
            [self.titleCirclesImgView setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.height * 0.3), ([UIScreen mainScreen].bounds.size.width * 0.4)+0)];
        }
        else{
            [self.titleCirclesImgView setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.height * 0.3), ([UIScreen mainScreen].bounds.size.width * 0.4)+20)];
        }
        
        [self.goBtn setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.height * 0.75), ([UIScreen mainScreen].bounds.size.width * 0.7))];
        
        [self.notifyLbl setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.height * 0.75), ([UIScreen mainScreen].bounds.size.width * 0.3))];
    }
    else
    {
        [self.titleCirclesImgView setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.width * 0.5), ([UIScreen mainScreen].bounds.size.height * 0.45) + 20)];
        
        [self.goBtn setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.width * 0.5), ([UIScreen mainScreen].bounds.size.height * 0.8))];
        
        [self.notifyLbl setCenter:CGPointMake(([UIScreen mainScreen].bounds.size.width * 0.5), ([UIScreen mainScreen].bounds.size.height * 0.2))];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setUpViewForOrientation:toInterfaceOrientation];
}

- (void)launchMapView:(UIButton *)sender {
    NSLog(@"number of regions: %i", [self.mapVC.scapeRegions count]);
    [self.navigationController pushViewController:self.mapVC animated:YES];
}

#pragma mark reset and startup methods

- (IBAction)toggleGoBtn:(UIButton *)sender {
    NSLog(@"toggle go button!");
    [self toggleLocationTracking];
}

- (void)toggleLocationTracking {
    
    self.bLocationTrackingActive = !self.bLocationTrackingActive;
    NSLog(@"loc. tracking active? %i", self.bLocationTrackingActive);
    
    if (self.bLocationTrackingActive) {
        // TURNING ON
        [self resetTimingLoop];
        [self backgroundUpdate];
        NSLog(@"activate audio");
        [self.appDelegate activateAudio:YES];
//        [self.gpsVC.locTrackingSwitch setOn:YES];
        [self.goBtn setTitle:@"stop tracking" forState:UIControlStateNormal];
        [self.appDelegate launchMapView];
        NSLog(@"ON!");
    } else {
        //TURNING OFF
        [htlpManager killAll];
        [htlpManager.audioFileRouter resetRouter];
        [self.appDelegate activateAudio:NO];
//        [self.gpsVC.locTrackingSwitch setOn:NO];
        [self.goBtn setTitle:@"start tracking" forState:UIControlStateNormal];
        NSLog(@"off.");
    }
    
    // should the raIndex be reset? no
    // *** what else should be reset?
}

- (void) resetTimingLoop {
    
    lapManager.timeout = timeout;
}

- (void) resetUserState {
    
    DLog(@"Reset user state...");
    // check to see that the managers exist or create them on reset
    if (lapManager == nil) {
        lapManager = [kflLAPManager sharedManager];
    } else {
        [lapManager reset];
    }
    if (htlpManager == nil) {
        htlpManager = [kflHTLPManager sharedManager];
    } else {
        [htlpManager reset];
    }
        
    // init trail of last N points or clear -- now contained in lapManager reset
    
    // grab the defaults for the app
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
//    // create LSFs MANUALLY! <<when saving sound files in the app bundle>>
//    // *** to-do: create this array (and other data structures?) dynamically based on the json file
//    static int activeRegions[NUMBER_OF_ACTIVE_REGIONS] = {1,2,3,4,6,5,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32};
//    
//    // set up file manager and setup documents dir string
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    
//    for (int i=0; i<NUMBER_OF_ACTIVE_REGIONS; i++) {
//        // each file is named with a two digit (zero-padded) integer
//        NSString *fileName = [NSString stringWithFormat:@"%02d.mp3", activeRegions[i]];
//        NSString *docPath = [docDir stringByAppendingPathComponent:fileName];
//        DLog(@"DOC PATH: %@", docPath);
//        DLog(@"???: %i", [fileManager fileExistsAtPath:docPath]);
//        // check whether mp3 already exists in the docs directory
//        if (![fileManager fileExistsAtPath:docPath]) {
//            // if not, determine bundle path for mp3
//            NSString *filePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
//            DLog(@"BUNDLE PATH: %@", filePathFromApp);
//            NSError *error = nil;
//            // copy file from bundle to documents dir
//            [fileManager copyItemAtPath:filePathFromApp toPath:docPath error:&error];
//            if (error) {
//                DLog(@"***ERROR: %@", [error description]);
//            }
//            // attempt to skip backup to iCloud or some BS that doesn't actually work, so skipping *** follow up on whther this is even necessary
//            //BOOL res = [self addSkipBackupAttributeToItemAtURL:[NSURL URLWithString:docPath]];
//            //DLog(@"===========RES: %i", res);
//        }
//        DLog(@"FILE NAME: %@", [docDir stringByAppendingPathComponent:fileName]);
//        // create a LSF object for the file and put it in the manager's sound files list
//        kflLinkedSoundfile *lsf = [kflLinkedSoundfile linkedSoundfileForFile:fileName idNum:activeRegions[i] attack:1000 andRelease:4000];
//        DLog(@"LSF: %@", lsf);
//        [htlpManager.scapeSoundfiles setObject:lsf
//                                        forKey:[NSString stringWithFormat:@"%i", activeRegions[i]]];
//        DLog(@"SFs: %@", htlpManager.scapeSoundfiles);
//        
//    }
    
    self.jsonFilePath = [defaults objectForKey:@"gpsonFile"];
    DLog(@"Default gpson path: %@", self.jsonFilePath);
    
    // LSFs are already set up, so we can use them to set up LCRs!
    [self readScapeFromJSON:self.jsonFilePath];
    // at this this point, this method returns, init returns, and then app delegate returns
    
    [self.htlpManager.audioFileRouter executeTimedParamChanges];
}

-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    DLog(@"path: %@", [URL path]);
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error:&error];
    if(!success){
        DLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

#pragma mark GUI update methods

//- (IBAction)updateTimeDelta:(UISlider *)sender {
//    
//    self.timedelta = floor(sender.value);
//    [timedeltaLbl setText:[NSString stringWithFormat:@"%.2f", self.timedelta]];
//}

- (void) updateRunningAccAvg:(float)amount {
    
    runningAvgs[raIndex] = amount;
    float sum = 0.0;
    for (int i=0; i<NPTS; i++) {
        sum += runningAvgs[i];
    }
    raIndex = (raIndex + 1) % NPTS;
    [self.gpsVC.avgAccLbl setText:[NSString stringWithFormat:@"%.02f", (sum / (float)NPTS)]];
}
#ifdef LOG_TO_EMAIL
#pragma mark logging to email

- (IBAction)logToEmail:(UIButton *)sender 
{
    
    [lapManager recordTrackingMarkerWithType:@"SEND EMAIL LOG" andArgs:nil];
    
    NSDateFormatter *df2 = [[NSDateFormatter alloc] init];
    [df2 setDateFormat:@"HH:mm:ss"];
    
    NSString *dString = [lapManager dumpTrackingMarkers];
    //CREATE FILE
    NSError *error;
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"past_locations.txt"];
    //    DLog(@"string to write:%@",dString);
    // Write to the file
    [dString writeToFile:filePath 
              atomically:YES 
                encoding:NSUTF8StringEncoding
                   error:&error];
    NSString *endPointString = [NSString stringWithFormat:@"Report time: %@", [df2 stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]]];
    [endPointString writeToFile:filePath 
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];
    
    if (dString != nil) {
        
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        [picker setSubject:@"Test location points output."];
        [picker addAttachmentData:[dString dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"past_locations.txt"];
        [picker setToRecipients:[NSArray arrayWithObject:@"tms@kitefishlabs.com"]];
        [picker setMessageBody:dString isHTML:NO];
        [picker setMailComposeDelegate:self];
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction) resetLog:(UIButton *)sender {
    
    [lapManager clearLocations];
}
#endif

#pragma mark location managment and updating

- (void)backgroundUpdate
{
    DLog(@"check loc. active flag: %i", self.bLocationTrackingActive);
    if (self.bLocationTrackingActive) {
        [self updateLocation];
    LocUpdateLog(@"check that loc. tracking is active: %i", self.bLocationTrackingActive);
        __block UIBackgroundTaskIdentifier back = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            [self updateLocation];
            [[UIApplication sharedApplication] endBackgroundTask:back];
            
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Create and register your timers
            // ...
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timedelta
                                                              target:self
                                                            selector:@selector(backgroundUpdate)
                                                            userInfo:nil
                                                             repeats:NO];
            
            //change to NSRunLoopCommonModes
            [ [NSRunLoop currentRunLoop] addTimer:timer
                                          forMode:NSRunLoopCommonModes];
            
            // Create/get a run loop an run it
            // Note: will return after the last timer's delegate has completed its job
            [[NSRunLoop currentRunLoop] run];
            
        });
    }
}

- (void) flyToLocation:(CLLocationCoordinate2D)coords {
#ifdef FLY_TO_LOC
    float newLat = coords.latitude;
    float newLon = coords.longitude;
    LocUpdateLog(@"%f, %f", newLat, newLon);
    //  update the labels
    [self.gpsVC.latLbl setText:[NSString stringWithFormat:@"%f", newLat]];
    [self.gpsVC.longLbl setText:[NSString stringWithFormat:@"%f", newLon]];
    [self updateRunningAccAvg:9.0];
    
    // CLLocation with offset
    CLLocation *theLoc = [[CLLocation alloc] initWithLatitude:newLat longitude:newLon];
    
    CGPoint pt = [lapManager recordLocationWithLocation:theLoc];
    LocUpdateLog(@"    RES PT: %f | %f", pt.x, pt.y);
    
    if ((pt.x != 0.f)&&(pt.y != 0.f)) {
        //CGPoint pt = CGPointMake(newLat, newLocation.coordinate.longitude);
        NSString *hitRes = [htlpManager hitTestRegionsWithLocation:pt];
        // the hitRes is the state label generated
        // - one of the following:
        //   - HIT!
        //   - MISS!
        //   - NO FIX!
        
        [self.gpsVC.stateLbl setText:hitRes];
        LocUpdateLog(@"hit res: %@", hitRes);
        int num = [self scanStateForHits:hitRes];
        LocUpdateLog(@"num: %i", num);
        [self.gpsVC.activeLbl setText:[NSString stringWithFormat:@"%i", num]];
        [self.view setNeedsDisplay];
    } else {
        DLog(@"*******************BAD POINT FOR HIT-TESTING!!!*******************");
    }
#endif
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
#ifndef FLY_TO_LOC
    LocUpdateLog(@"------- did update!");
    
    // lastObject should always be the most recent, right?
    
    CLLocation *newLocation = [locations lastObject];
    LocUpdateLog(@"%f, %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    
    [self.htlpManager.audioFileRouter executeFundamentalFrequencyChange];
    
    if ((self.bLocationTrackingActive) && (newLocation.coordinate.latitude != 0.0) && (newLocation.coordinate.longitude != 0.0) ) {
    
        float newLat = newLocation.coordinate.latitude + LAT_OFFSET;
        float newLon = newLocation.coordinate.longitude + LON_OFFSET;
        
        //  update the labels
        [self.gpsVC.latLbl setText:[NSString stringWithFormat:@"%f", newLat]];
        [self.gpsVC.longLbl setText:[NSString stringWithFormat:@"%f", newLon]];
        [self updateRunningAccAvg:newLocation.horizontalAccuracy];
        
        LocUpdateLog(@"%f ? <= ? %f", newLocation.horizontalAccuracy, kCLLocationAccuracyNearestTenMeters);
        // check that accuracy is at or below 10 meter theshold
        
        // CLLocation with offset
        CLLocation *theLoc = [[CLLocation alloc] initWithLatitude:newLat longitude:newLon];
        
        // record the new location to our log
        // - check the location before recording!
        // should be different than the last location
        
        // most basic check...gotta be better than 10 M
        if (newLocation.horizontalAccuracy <= kCLLocationAccuracyNearestTenMeters) {

            CGPoint pt = [lapManager recordLocationWithLocation:theLoc];
            NSLog(@"    RES PT: %f | %f", pt.x, pt.y);
        
            //CGPoint pt = CGPointMake(newLat, newLocation.coordinate.longitude);
            NSString *hitRes = [htlpManager hitTestRegionsWithLocation:pt];
            
            // the hitRes is the state label generated
            // - one of the following:
            //   - HIT!
            //   - MISS!
            //   - NO FIX!
            //   - NO MOVEMENT!
        
            [self.gpsVC.stateLbl setText:hitRes];
            int num = [self scanStateForHits:hitRes];
            LocUpdateLog(@"num: %i", num);
            [self.gpsVC.activeLbl setText:[NSString stringWithFormat:@"%i", num]];
            
        } else {
            [self.gpsVC.stateLbl setText:@"No fix..."];
        }
    #ifndef MKMAP
        [self.mapVC didUpdateLocation:newLocation];
    #endif
//        [self.mapVC did :newLocation];
        [self.view setNeedsDisplay];
    }
    [self performSelector:@selector(stopUpdatingLocation:) withObject:@"Timed Out"]; // afterDelay:lapManager.timeout];
#endif
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (error.code == kCLErrorDenied) {
        NSLog(@"CLLocation Error: DENIED!");
        [locationManager stopUpdatingLocation];
    } else if (error.code == kCLErrorLocationUnknown) {
        // retry
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location" 
                                                        message:[error description] 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}


- (void)updateLocation {
    
    LocUpdateLog(@"update location");
    [locationManager startUpdatingLocation];
    [locationManager setDelegate:self];
    LocUpdateLog(@"ScapeManager: Searching...");
    [self.gpsVC.stateLbl setText:@"Searching..."];
    
    [self performSelector:@selector(stopUpdatingLocation:) withObject:@"Timed Out" afterDelay:lapManager.timeout];
    
}

- (int)scanStateForHits:(NSString *)state {
    LocUpdateLog(@"STOP UPDATING LOCATION!\nScapeManager: %@", state);
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"HIT\\(S\\):\\s(\\d+)" options:0 error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:state options:0 range:NSMakeRange(0, [state length])];
    
//    LocUpdateLog(@"#: %i", numberOfMatches);
    
    if (numberOfMatches > 0) {
        
        NSTextCheckingResult *match = [regex firstMatchInString:state
                                                        options:0
                                                          range:NSMakeRange(0, [state length])];
        if (match) {
            LocUpdateLog(@"found: %@", [state substringWithRange:[match rangeAtIndex:1]]);
//            [activeLbl setText:[state substringWithRange:[match rangeAtIndex:1]]];
            return [[state substringWithRange:[match rangeAtIndex:1]] intValue];
        } else {
            return -1;
        }
    } else {
        return 0;
    }
}

- (void)stopUpdatingLocation:(NSString *)state {
    
    LocUpdateLog(@"STOP UPDATING LOCATION!\nScapeManager: %@", state);
        
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"HIT\\(S\\):\\s(\\d)" options:0 error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:state options:0 range:NSMakeRange(0, [state length])];
    
    if (numberOfMatches > 0) {
//        LocUpdateLog(@"#: %i", numberOfMatches);
        NSTextCheckingResult *match = [regex firstMatchInString:state
                                          options:0
                                            range:NSMakeRange(0, [state length])];
        if (match) {
//            LocUpdateLog(@"found: %@", [state substringWithRange:[match rangeAtIndex:1]]);
            [self.gpsVC.activeLbl setText:[state substringWithRange:[match rangeAtIndex:1]]];
        }
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:@"Timed Out"];
    [locationManager stopUpdatingLocation];
    [locationManager setDelegate:nil];
    
}

#pragma mark GPSON/JSON methods

- (void) readScapeFromJSON:(NSString *)jsonPath {
    JSONLog(@"Read JSON...");
    JSONLog(@"%@", jsonPath);
    JSONLog(@"    grab the JSON file; throw error or exit if non-existant.");
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:jsonFilePath ofType:@"json"];
    NSError *error;
    NSString *stringFromFileAtPath = [[NSString alloc] initWithContentsOfFile:jsonPath
                                                                     encoding:NSUTF8StringEncoding
                                                                        error:&error];
    if (error != nil) {
        NSLog(@"Error reading JSON: %@", [error description]);
    }

    NSData *jsonData = [stringFromFileAtPath dataUsingEncoding:NSUTF8StringEncoding];
    
    if ((stringFromFileAtPath == nil) || (jsonData == nil)) {
        
        JSONLog(@"Error reading file at location: %@\n%@",
              jsonPath,
              [error description]);
        
    } else {
        
        JSONLog(@"    read was successful(!), clear any existing data.");
        
        [lapManager clearLocations];
        // clearState includes allocating/clearing scapeRegions
        [htlpManager.scapeRegions removeAllObjects];        // SF HTLP
        JSONLog(@"HTLP SF MANAGER: %@\n%@", htlpManager.scapeRegions, htlpManager.scapeSoundfiles);
        
//        JSONLog(@"    read and convert to temp object.");
//        JSONLog(@"first off, the string: %@\n\n\n", stringFromFileAtPath);
        
//        NSDictionary *dict = [stringFromFileAtPath objectFromJSONString];
        NSError *localError = nil;
        NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&localError];
        
        if (localError != nil) {
            DLog(@" --error: %@", [localError description]);
        }
//        for (NSString *str in [dict allKeys]) {
//            DLog(@"key: %@", str);
//        }
        //        DLog(@"    copy parts of temp object into appropriate data
        DLog(@"    regions: %@\n\n", [dict objectForKey:@"regions"]);
        
//        JSONLog(@"    copy parts of temp object into appropriate data structures.");
//        JSONLog(@"    regions: %@\n\n", [dict objectForKey:@"regions"]);
        
        NSDictionary *rdict = [dict objectForKey:@"regions"];
        NSArray *rdkeys = [rdict allKeys];
        DLog(@"--- %@", rdkeys);
        
        NSNumber *origin_X = [[dict objectForKey:@"origin"] objectAtIndex:0];
        NSNumber *origin_Y = [[dict objectForKey:@"origin"] objectAtIndex:1];
        NSNumber *relativeFlag = [[dict objectForKey:@"origin"] objectAtIndex:2];
        float originX = 0.f, originY = 0.f;
        BOOL relFlag = ((relativeFlag == nil) ? FALSE : [relativeFlag boolValue]);
//        CLLocationCoordinate2D zoomLoc;
        
        JSONLog(@"origin: %@, %@, relative?: %i", origin_X, origin_Y, relFlag);
        
        if ((origin_X != nil) && (origin_Y != nil)) {
            
//            zoomLoc.latitude = [origin_X floatValue];
//            zoomLoc.longitude = [origin_Y floatValue];
            
            if (relFlag) {
                originX = [origin_X floatValue];
                originY = [origin_Y floatValue];
            }
        }  
//         else {
//            // just grab the first point to use for zoomLoc, leave origin {0.0, 0.0}
//            JSONLog(@"%@ | sides: %@", [rdict objectForKey:@"0"], [[rdict objectForKey:@"0"] objectForKey:@"sides"]);
//            if ([[[rdict objectForKey:@"0"] objectForKey:@"sides"] intValue] > 0) {
//                NSArray *vertexes = [[rdict objectForKey:@"0"] objectForKey:@"vertexes"];
//                JSONLog(@"vertexes: %@", vertexes);
//                zoomLoc.latitude = [[[vertexes objectAtIndex:0] objectAtIndex:0] floatValue];
//                zoomLoc.longitude = [[[vertexes objectAtIndex:0] objectAtIndex:1] floatValue];
//            } else {
//                NSArray *cpoints = [[rdict objectForKey:@"0"] objectForKey:@"centrad"];
//                JSONLog(@"cpts: %@", cpoints);
//                zoomLoc.latitude = [[cpoints objectAtIndex:0] floatValue];
//                zoomLoc.longitude = [[cpoints objectAtIndex:1] floatValue];
//            }
//        }
//        JSONLog(@"ORIGIN CHECK: %f, %f, %i | zoomloc: %f, %f", originX, originY, relFlag, zoomLoc.latitude, zoomLoc.longitude);

        for (int i=0; i<[rdkeys count]; i++) {
            
            NSNumber *lrid = [rdkeys objectAtIndex:i];
            JSONLog(@"------------");
            JSONLog(@"LRID: %i", [lrid intValue]);
            JSONLog(@"");
            
            if ([[[rdict objectForKey:lrid] objectForKey:@"sides"] intValue] == 0) {

                NSArray *cpoints = [[rdict objectForKey:lrid] objectForKey:@"centrad"];
                CGPoint ctr = CGPointMake(([[cpoints objectAtIndex:0] floatValue] + originX), ([[cpoints objectAtIndex:1] floatValue] + originY));
                JSONLog(@"reading ctr x: %f", ctr.x);
                JSONLog(@"reading ctr y: %f", ctr.y);
                
                int atk = 1000;
                int rls = 1000;
                
                if ([[rdict objectForKey:lrid] objectForKey:@"attack"] != nil) {
                    atk = [[[rdict objectForKey:lrid] objectForKey:@"attack"] intValue];
                    JSONLog(@"reading attack: %i", atk);
                }
                if ([[rdict objectForKey:lrid] objectForKey:@"release"] != nil) {
                    rls = [[[rdict objectForKey:lrid] objectForKey:@"release"] intValue];
                    JSONLog(@"reading release: %i", rls);
               }
                
                NSString *paramStringA = nil, *paramStringB = nil;
                float lowValA = 0.0, lowValB = 0.0;
                float highValA = 1.0, highValB = 1.0;
                float rotOffsetB = 0.0;

                int lives = 99;
                if ([[rdict objectForKey:lrid] objectForKey:@"lives"] != nil) {
                    lives = [[[rdict objectForKey:lrid] objectForKey:@"lives"] intValue];
                    JSONLog(@"reading lives: %i", lives);
                }
                
                NSString *labelString = nil;
                
                if ([[rdict objectForKey:lrid] objectForKey:@"label"] != nil) {
                    labelString = [[rdict objectForKey:lrid] objectForKey:@"label"];
                    JSONLog(@"reading label: %@", labelString);
                }
                
                if ([[[[rdict objectForKey:lrid] objectForKey:@"sfids"] objectAtIndex:0] intValue] == -1) {
                
                    JSONLog(@"reading a PARAM circle region!");
                    
                    kflLinkedParameter *lpA = nil;
                    kflLinkedParameter *lpB = nil;
                    
                    if (![[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:0] objectAtIndex:0] compare:@"x"] == NSOrderedSame) {
                        paramStringA = [[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:0] objectAtIndex:0];
                        lowValA = [[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:0] objectAtIndex:1] floatValue];
                        highValA = [[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:0] objectAtIndex:2] floatValue];
                        JSONLog(@"reading param string: %@", paramStringA);
                        JSONLog(@"reading low: %f", lowValA);
                        JSONLog(@"reading high: %f", highValA);
                        lpA = [kflLinkedParameter kflLinkedParameterWithString:paramStringA lowMappedVal:lowValA andHighMappedValue:highValA];
                    } else {
                        lpA = [kflLinkedParameter kflLinkedParameterWithString:@"x" lowMappedVal:0 andHighMappedValue:0];
                    }

                    if (![[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:1] objectAtIndex:0] compare:@"x"] == NSOrderedSame) {
                        paramStringB = [[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:1] objectAtIndex:0];
                        lowValB = [[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:1] objectAtIndex:1] floatValue];
                        highValB = [[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:1] objectAtIndex:2] floatValue];
                        rotOffsetB = [[[[[rdict objectForKey:lrid] objectForKey:@"params"] objectAtIndex:1] objectAtIndex:3] floatValue];
                        JSONLog(@"reading param string: %@", paramStringB);
                        JSONLog(@"reading low: %f", lowValB);
                        JSONLog(@"reading high: %f", highValB);
                        lpB = [kflLinkedParameter kflLinkedParameterWithString:paramStringB lowMappedVal:lowValB andHighMappedValue:highValB];
                    } else {
                        lpB = [kflLinkedParameter kflLinkedParameterWithString:@"x" lowMappedVal:0 andHighMappedValue:0];
                    }
                    
                    kflLinkedCircleSynthRegion *lcsr = [kflLinkedCircleSynthRegion kflLinkedCircleSynthRegionWithCenter:ctr
                                                                                                                 radius:[[cpoints objectAtIndex:2] floatValue]
                                                                                                                  idNum:[lrid intValue]
                                                                                                                  label:labelString
                                                                                                           linkedParams:[NSArray arrayWithObjects:lpA, lpB, nil]
                                                                                                            angleOffset:rotOffsetB
                                                                                                                 attack:atk
                                                                                                                release:rls
                                                                                                                  lives:lives
                                                                                                                 active:YES
                                                                                                             toActivate:nil
                                                                                                               andState:@"ready"];

                    [htlpManager addRegion:lcsr forIndex:lrid];
                    [self.mapVC addRegion:lcsr];
                    
                } else {
                    
                    int numloops = lives;
                    int rule = kLOOP_CUTOFF;
                    
                    JSONLog(@"reading a SF circle region!");
                    
                    int sfIndex = [[[[rdict objectForKey:lrid] objectForKey:@"sfids"] objectAtIndex:0] intValue];
                    
                    JSONLog(@"sfid:: %i", sfIndex);
                    
                    kflLinkedSoundfile *lsf = [htlpManager.scapeSoundfiles objectForKey:[NSString stringWithFormat:@"%i", sfIndex]];
                    
                    if (([[rdict objectForKey:lrid] objectForKey:@"looprule"] != nil) && ([[rdict objectForKey:lrid] objectForKey:@"lives"] != nil)) {
                        
                        numloops = [[[rdict objectForKey:lrid] objectForKey:@"lives"] intValue];
                        rule = [[[rdict objectForKey:lrid] objectForKey:@"looprule"] intValue];
                        
                    }
                    
                    [lsf setAttackTime:atk];
                    [lsf setReleaseTime:rls];
                    
                    kflLinkedCircleSFRegion *lcr = [kflLinkedCircleSFRegion kflLinkedCircleSFRegionWithCenter:ctr
                                                                                                       radius:[[cpoints objectAtIndex:2] floatValue]
                                                                                                        idNum:[lrid intValue]
                                                                                                        label:labelString
                                                                                             linkedSoundFiles:[NSArray arrayWithObject:lsf]
                                                                                                       attack: atk
                                                                                                      release:rls
                                                                                                        loops:numloops
                                                                                                     loopRule:rule
                                                                                                        lives:lives
                                                                                                       active:YES
                                                                                                   toActivate:nil
                                                                                                     andState:@"ready"];
                    [htlpManager addRegion:lcr forIndex:lrid];
                    [self.mapVC addRegion:lcr];

                }
            }
//            } else {
//                
//                NSArray *vertexes = [[rdict objectForKey:lrid] objectForKey:@"vertexes"];
//                float lat = [[[vertexes objectAtIndex:0] objectAtIndex:0] floatValue];
//                float lng = [[[vertexes objectAtIndex:0] objectAtIndex:1] floatValue];
//                float minX = lng;
//                float maxX = lng;
//                float minY = lat;
//                float maxY = lat;
//                JSONLog(@"\n\n%f||%f||%f||%f\n\n", minX, maxX, minY, maxY);
//                
//                NSMutableArray *pts = [NSMutableArray arrayWithCapacity:4];
//                for (int p=0; p<[[[rdict objectForKey:lrid] objectForKey:@"sides"] intValue]; p++) {
//                    
//                    lat = [[[vertexes objectAtIndex:p] objectAtIndex:0] floatValue];
//                    lng = [[[vertexes objectAtIndex:p] objectAtIndex:1] floatValue];
//                    
//                    minY = MIN(lat, minY);
//                    minX = MIN(lng, minX);
//                    maxY = MAX(lat, maxY);
//                    maxX = MAX(lng, maxX);
//                    JSONLog(@"%f|%f|%f|%f|%f|%f", lat, lng, minY, maxY, minX, maxX);
//                    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake((lat + originY), (lng + originX));
//                    [pts addObject:[NSValue valueWithBytes:&coord objCType:@encode(CLLocationCoordinate2D)]];
//                }
//                JSONLog(@"-- %f|%f||%f|%f", minX, minY, (maxY - minY), (maxX - minX));
//                CGRect rect = CGRectMake(minX, minY, (maxY - minY), (maxX - minX));
//                rect = CGRectOffset(rect, originX, originY);
//                JSONLog(@"RECT: %f, %f| %f %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//                
//                
////                JSONLog(@"THE RECT: %f-%f|%f-%f", lrr.rect.origin.x, lrr.rect.origin.y, lrr.rect.size.width, lrr.rect.size.height);
//
//                int numloops = 1;
//                kflRegionLoopRule rule = kNOLOOP_CUTOFF;
//                BOOL active = YES;
//                NSArray *toActivate = nil;
//                int lives = 99;
//                int atk = 100;
//                int rel = 1000;
//                
//                NSArray *sfIndexes = [[rdict objectForKey:lrid] objectForKey:@"sfIDs"];
//
//                NSMutableArray *linkedSFs;
//                if (sfIndexes != nil) {
//                    // pass a reference to the actual LSF, not its index!!!!
//                    linkedSFs = [NSMutableArray arrayWithObject:[htlpManager.scapeSoundfiles objectForKey:[[sfIndexes objectAtIndex:0] stringValue]]];
//                    if ([sfIndexes objectAtIndex:1] != nil)
//                        atk = [[sfIndexes objectAtIndex:1] intValue];
//                    if ([sfIndexes objectAtIndex:2] != nil)
//                        rel = [[sfIndexes objectAtIndex:2] intValue];
//                }
//                
//                
//                if ([[rdict objectForKey:lrid] objectForKey:@"loops"] != nil) {
//                    
//                    numloops = [[[[rdict objectForKey:lrid] objectForKey:@"loops"] objectAtIndex:0] intValue];
//                    rule = [[[[rdict objectForKey:lrid] objectForKey:@"loops"] objectAtIndex:1] intValue];
//                    
//                    JSONLog(@"RULE: %i (%i)", rule, [lrid intValue]);
//                    
//                }
//                JSONLog(@"linkedSFs (%i): %@", [lrid intValue], [linkedSFs description]);
//                
//                NSArray *activeFlags = [[rdict objectForKey:lrid] objectForKey:@"ready"];
//                if (activeFlags != nil) {
//                    
//                    active = [[activeFlags objectAtIndex:0] boolValue];
//                    if ([activeFlags count] == 2) { toActivate = [NSArray arrayWithArray:[activeFlags objectAtIndex:1]]; }
//                }
//                
//                if ([[rdict objectForKey:lrid] objectForKey:@"lives"] != nil) {
//                    
//                    lives = [[[rdict objectForKey:lrid] objectForKey:@"lives"] intValue];
//                }
//
////                NSNumber *r = [[[rdict objectForKey:lrid] objectForKey:@"release"] objectAtIndex:0];
////                if (r != nil) {                    
////                    rel = [r intValue];
////                }
//
//                kflLinkedRectangleRegion *lrr = [kflLinkedRectangleRegion linkedRectangleRegionWithPoints:pts linkedSoundfiles:linkedSFs idNum:[lrid intValue] attack:atk release:rel loops:numloops loopRule:rule lives:lives active:active toActivate:toActivate state:@"ready" andRect:rect];
//                [htlpManager addRectRegion:lrr forIndex:lrid];        // HTLP
//
//                JSONLog(@"RECT: %f, %f| %f %f",
//                      [[htlpManager.scapeRegions objectForKey:lrid] prect].origin.x, 
//                      [[htlpManager.scapeRegions objectForKey:lrid] prect].origin.y, 
//                      [[htlpManager.scapeRegions objectForKey:lrid] prect].size.width, 
//                      [[htlpManager.scapeRegions objectForKey:lrid] prect].size.height);
//            }
        }
    }
}

- (void) writeScapeToJSON {
    JSONLog(@"Write JSON...");    
}

@end

