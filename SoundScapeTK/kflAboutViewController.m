//
//  kflAboutViewController.h
//  SoundscapeTK
//
//  Created by Thomas Stoll on 6/3/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflAboutViewController.h"

@interface kflAboutViewController ()

@end

@implementation kflAboutViewController

@synthesize aboutTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.aboutTextView = nil;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
//    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
//        [self.aboutTextView setFrame:CGRectMake(25, 25, 270, 400)];
//    } else {
//        [self.aboutTextView setFrame:CGRectMake(25, 25, 400, 270)];
//    }
    
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}

@end
