//
//  kflGPSViewController.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "kflScapeManagerViewController.h"

@class kflScapeManagerViewController;

@interface kflGPSViewController : UIViewController

//@property (strong, nonatomic)   IBOutlet    UISwitch  *locTrackingSwitch;
@property (strong, nonatomic)   IBOutlet    UILabel     *latLbl;
@property (strong, nonatomic)   IBOutlet    UILabel     *longLbl;
//@property (strong, nonatomic)   IBOutlet UILabel      *accLbl;
@property (strong, nonatomic)   IBOutlet    UILabel     *activeLbl;
//@property (strong, nonatomic)   IBOutlet UILabel      *timedeltaLbl;
@property (strong, nonatomic)   IBOutlet    UILabel     *stateLbl;

@property (strong, nonatomic)   IBOutlet    UILabel    *avgAccLbl;

@property (strong, nonatomic)   kflScapeManagerViewController     *scapeManager;

- (IBAction)toggleLocationTracking:(UISwitch *)sender;
- (IBAction)resetAppState:(UIButton *)sender;


@end
