//
//  kflAppDelegate.m
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import "kflAppDelegate.h"
#import "PdAudioController.h"
#import "PdBase.h"

@interface kflAppDelegate() {}
@property (nonatomic, retain) PdAudioController *audioController;
@end

@implementation kflAppDelegate

@synthesize window = _window, tabController, scapeManagerVC, aboutVC, mapVC, gpsVC;
@synthesize audioController = audioController_;

extern void mp3play_tilde_setup(void);


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // app will not idle-sleep (will still lock)
    // application.idleTimerDisabled = YES;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.audioController = [[PdAudioController alloc] init];
    [self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:NO mixingEnabled:YES];
//    mp3play_tilde_setup();
    [PdBase setDelegate:self];
    
//    UINavigationController *navCtlr;
//    navCtlr = [[UINavigationController alloc] init];
//    [navCtlr.navigationBar setTintColor:[UIColor blackColor]];
    
    self.aboutVC = [[kflAboutViewController alloc] initWithNibName:@"kflAboutViewController"
                                                            bundle:[NSBundle mainBundle]];
    self.aboutVC.title = @"ABOUT";
    [self.aboutVC.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -12)];
    
    self.scapeManagerVC = [[kflScapeManagerViewController alloc] initWithNibName:@"kflScapeManagerViewController"
                                                                       bundle:[NSBundle mainBundle]];
    self.scapeManagerVC.title = @"TRACKING";
    [self.scapeManagerVC.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -12)];
    
    self.mapVC = [[kflMKMapViewController alloc] initWithScapeVC:self.scapeManagerVC];
    self.mapVC.title = @"MAP";
    [self.mapVC.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -12)];
    
    self.gpsVC = [[kflGPSViewController alloc] initWithNibName:@"kflGPSViewController" bundle:[NSBundle mainBundle]];
    self.gpsVC.title = @"TOOLS";
    [self.gpsVC.tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -12)];
    
    self.scapeManagerVC.mapVC = mapVC;
    self.scapeManagerVC.gpsVC = gpsVC;
    
    self.scapeManagerVC.gpsVC.scapeManager = self.scapeManagerVC;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[NSBundle mainBundle] pathForResource:@"empac" ofType:@"gpson"]
                 forKey:@"gpsonFile"];
    NSLog(@"Default GPSON file: %@", [defaults objectForKey:@"gpsonFile"]);
    [defaults synchronize];
    
    [scapeManagerVC resetUserState];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.tabController = [[UITabBarController alloc] init];
    self.tabController.viewControllers = [NSArray arrayWithObjects:aboutVC, scapeManagerVC, mapVC, gpsVC, nil];
    
    [self.window setRootViewController:self.tabController];
    [self.window makeKeyAndVisible];
    
    [self.tabController setSelectedViewController:self.scapeManagerVC];
    
//    NSArray *ver = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
//    if ([[ver objectAtIndex:0] intValue] >= 7) {
//        self.tabController.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
//        self.tabController.navigationController.navigationBar.translucent = NO;
//    }else {
//        self.tabController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
//    }

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
#ifdef MONITOR_PD
    [PdBase subscribe:@"print"];
    [PdBase subscribe:@"lvl"];
    [PdBase subscribe:@"ramp"];
    [PdBase subscribe:@"open"];
    [PdBase subscribe:@"play"];
    [PdBase subscribe:@"stop"];
#endif
    
    
    
    // kick off loc. tracking
    [self.scapeManagerVC toggleLocationTracking];
    [NSThread sleepForTimeInterval:1];
    [self launchMapView];
    return YES;
}

- (void)launchMapView {
    NSLog(@"number of regions: %i", [self.mapVC.scapeRegions count]);
    [self.tabController setSelectedViewController:self.mapVC];
}


- (void)receivePrint:(NSString *)message {
#ifdef MONITOR_PD
    NSLog(@"PD PRINT:\n%@\n", message);
#endif
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
#ifdef MONITOR_PD
    NSMutableString *args =[NSMutableString stringWithCapacity:9];
    PdLog(@"%i", [arguments count]);
    for (NSNumber *item in arguments) {
        PdLog(@"item: %@", item);
        [args appendString:[NSString stringWithFormat:@"%f", [item floatValue]]];
    }
    PdLog(@"%@:: %@ %@", source, message, args);
#endif
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
#ifdef MONITOR_PD
    PdLog(@"the float: %f (from %@)", received, source);
#endif
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
#ifdef MONITOR_PD
    PdLog(@"the symbol: %@ (from %@)", symbol, source);
#endif
}

//- (void)receiveBangFromSource:(NSString *)source {
//#ifdef MONITOR_PD
//    PdLog(@"BANG from %@", source);
//#endif
//}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
#ifdef MONITOR_PD
    int c = 0;
    for (NSString *str in list) {
        NSLog(@"%i:: %@", c++, str);
    }
#endif
}


- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"will resign active!");
//    [self.scapeManagerVC toggleLocationTracking];
//    [self.scapeManagerVC.goBtn setSelected:NO];
//    [self.scapeManagerVC.gpsVC.locTrackingSwitch setOn:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"did enter background!");
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    DLog(@"the url: %@", url);
    
    NSString *ext = [url pathExtension];
    if ([ext compare:@"gpson"] == NSOrderedSame) {
        // update scapemanager.jsonfile
        DLog(@"updating GPSON PATH: %@ (was: %@)", url.path, scapeManagerVC.jsonFilePath);
        scapeManagerVC.jsonFilePath = url.path;
        
        // se
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:scapeManagerVC.jsonFilePath forKey:@"gpsonFile"];
        [defaults synchronize];
        [scapeManagerVC resetUserState];
        
        DLog(@"check GPSONFILE: %@", [defaults objectForKey:@"gpsonFile"]);
        
    }
    // if not a .json, then ignore
    //   return NO???
    // else
    //   userstate reset method MUST DO ALL NEC. RESETTING!!!
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"will enter foreground!");
    // activate location tracking and start audio if not already running in the background
    if (!scapeManagerVC.bLocationTrackingActive) {
        // kick off loc. tracking
        [self.scapeManagerVC toggleLocationTracking];
        [NSThread sleepForTimeInterval:1];
        [self launchMapView];

    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"will terminate!");
    if (scapeManagerVC.bLocationTrackingActive) {
        // kill loc. tracking
        [self.scapeManagerVC toggleLocationTracking];
        [NSThread sleepForTimeInterval:5];
    }
}

- (void)activateAudio:(BOOL)onFlag {
    NSLog(@"on flag: %i", onFlag);
    if (!onFlag) {
        self.scapeManagerVC.gpsVC.stateLbl.text = @"Not tracking...";
        [NSThread sleepForTimeInterval:3.0];
    } else {
        self.scapeManagerVC.gpsVC.stateLbl.text = @"Tracking...";
    }
    [self.audioController setActive:onFlag];
    NSLog(@"=====================ACTIVE: %i", self.audioController.active);
}


@end
