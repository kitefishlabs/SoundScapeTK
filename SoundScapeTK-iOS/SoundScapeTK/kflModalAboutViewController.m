//
//  ModalAboutViewController.m
//  RuebGPSNPWN
//
//  Created by Thomas Stoll on 9/8/12.
//  Copyright (c) 2012 Kitefish Labs. All rights reserved.
//

#import "ModalAboutViewController.h"

@interface ModalAboutViewController ()

@end

@implementation ModalAboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UITapGestureRecognizer *dtdGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissModalViewControllerAnimated:)];
    dtdGR.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtdGR];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
