//
//  kflScapeManagerVC2.h
//  SoundScapeTK
//
//  Created by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
//#import <MessageUI/MessageUI.h>

#import "kflLinkedSoundfile.h"
#import "kflLinkedCircleRegion.h"
#import "kflLinkedRectangleRegion.h"
#import "kflLinkedParameter.h"
#import "kflLAPManager.h"
#import "kflHTLPManager.h"
#import "kflMapViewController.h"
#import "kflMKMapViewController.h"
#import "kflStatusViewController.h"

@class kflStatusViewController;
@class kflMKMapViewController;
@class kflMapViewController;

@interface kflScapeManagerViewController : UIViewController <CLLocationManagerDelegate> {
    
    float   runningAvgs[5];
    int     raIndex;
}

@property (strong, nonatomic)   NSString                *jsonFilePath;

@property (strong, nonatomic)   CLLocationManager       *locationManager;
@property (strong, nonatomic)   kflLAPManager           *lapManager;
@property (strong, nonatomic)   kflHTLPManager          *htlpManager;

@property                       BOOL                    bLocationTrackingActive;
@property                       float                   timeout, timedelta, runningAcc;

@property (strong, nonatomic)   kflMKMapViewController  *mapVC;

@property (strong, nonatomic)   kflStatusViewController    *gpsVC;

@property (strong, nonatomic)   IBOutlet UIImageView    *titleCirclesImgView;

//- (IBAction)logToEmail:(UIButton *)sender;
//- (IBAction)resetLog:(UIButton *)sender;
//- (void)    updateSyncProgressForFileName:(NSString *)filename withMessage:(NSString *)message;

@property (strong, nonatomic)   IBOutlet UILabel        *notifyLbl;
@property (strong, nonatomic)   IBOutlet UIButton       *goBtn;


- (IBAction)toggleGoBtn:(id)sender;

- (void)    setUpViewForOrientation:(UIInterfaceOrientation)orientation;
- (void)    toggleLocationTracking;
- (void)    launchMapView:(UIButton *)sender;
- (void)    resetUserState;
- (void)    resetTimingLoop;
- (void)    backgroundUpdate;
- (void)    updateLocation;
- (void)    stopUpdatingLocation:(NSString *)state;
- (void)    updateRunningAccAvg:(float)amount;

- (void)    readScapeFromJSON:(NSString *)jsonPath;
- (void)    writeScapeToJSON;

- (void)    flyToLocation:(CLLocationCoordinate2D)coords;

@end

