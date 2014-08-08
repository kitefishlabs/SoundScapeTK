//
//  kflAppDelegate.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "kflScapeManagerViewController.h"
#import "kflAboutViewController.h"
#import "kflMKMapViewController.h"
#import "kflGPSViewController.h"

#import "PdBase.h"

@interface kflAppDelegate : UIResponder <UIApplicationDelegate, PdListener, PdReceiverDelegate>

@property (strong, nonatomic) UIWindow                          *window;
//@property (strong, nonatomic) UINavigationController          *navController;
@property (strong, nonatomic) UITabBarController                *tabController;
@property (strong, nonatomic) kflAboutViewController            *aboutVC;
@property (strong, nonatomic) kflScapeManagerViewController     *scapeManagerVC;
@property (strong, nonatomic) kflGPSViewController              *gpsVC;
@property (strong, nonatomic) kflMKMapViewController            *mapVC;

- (void)activateAudio:(BOOL)onFlag;
- (void)launchMapView;

@end
