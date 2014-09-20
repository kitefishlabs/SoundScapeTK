//
//  kflStatusViewController.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 9/16/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflStatusViewController.h"
#import "kflAppDelegate.h"
#import "kflScapeManagerViewController.h"


//@interface kflStatusViewController ()
//@end

@implementation kflStatusViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
