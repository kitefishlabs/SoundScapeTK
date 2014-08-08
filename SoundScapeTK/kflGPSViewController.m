//
//  kflGPSViewController.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflGPSViewController.h"
#import "kflAppDelegate.h"
#import "kflScapeManagerViewController.h"


//@interface kflGPSViewController ()
//
//@end

@implementation kflGPSViewController

@synthesize scapeManager = _scapeManager, latLbl, longLbl, activeLbl, stateLbl, avgAccLbl;;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //
    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

- (IBAction)toggleLocationTracking:(UISwitch *)sender {
//    NSLog(@"selected? %i", sender.on);
//    [_scapeManager.goBtn setSelected:sender.on];
//    [_scapeManager toggleLocationTracking:sender.on];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.scapeManager.bLocationTrackingActive) {
//        [self.locTrackingSwitch setOn:YES];
    } else {
//        [self.locTrackingSwitch setOn:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSLog(@":<:>: %i", self.isMovingFromParentViewController);
    if (self.isMovingFromParentViewController) {
        if (_scapeManager.bLocationTrackingActive) {
            [_scapeManager launchMapView:nil];
        }
    }
}

- (void)viewDidUnload {
    [self setLatLbl:nil];
    [self setLongLbl:nil];
    [self setActiveLbl:nil];
    [self setStateLbl:nil];
    [self setAvgAccLbl:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)resetAppState:(UIButton *)sender {
    
//    if (self.scapeManager.bLocationTrackingActive) {
//        [self.scapeManager toggleLocationTracking];
//    }
    [self.scapeManager resetUserState];
}
@end
