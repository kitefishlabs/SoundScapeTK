//
//  kflSSTKJSONTests.m
//  SoundScapeTK
//
//  Created by Kitefish Labs on 12/3/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "kflHTLPManager.h"
#import "kflLinkedCircleRegion.h"

#import "kflScapeManagerViewController.h" // soon to be scape manager?!

@interface kflSSTKJSONTests : XCTestCase

@end

@implementation kflSSTKJSONTests {
    kflScapeManagerViewController *scapeMngr;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    scapeMngr = [[kflScapeManagerViewController alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNonRelativeOrigin {
    [scapeMngr readScapeFromJSON:@"test.gpson"];
    
    kflLinkedCircleRegion *lcr1 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"1"];
    XCTAssertEqual(lcr1.idNum, 1);
    XCTAssertEqualWithAccuracy(lcr1.center.x, 42.925118, 0.00001);
    XCTAssertEqualWithAccuracy(lcr1.center.y, -78.872459, 0.00001);
    XCTAssertEqualWithAccuracy(lcr1.radius, 0.0002, 0.00001);
    
    kflLinkedCircleRegion *lcr2 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"2"];
    XCTAssertEqual(lcr2.idNum, 2);
    XCTAssertEqualWithAccuracy(lcr2.center.x, 42.919674, 0.00001);
    XCTAssertEqualWithAccuracy(lcr2.center.y, -78.87145, 0.00001);
    XCTAssertEqualWithAccuracy(lcr2.radius, 0.00036, 0.00001);
    
    kflLinkedCircleRegion *lcr3 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"3"];
    XCTAssertEqual(lcr3.idNum, 3);
    XCTAssertEqualWithAccuracy(lcr3.center.x, 42.925704, 0.00001);
    XCTAssertEqualWithAccuracy(lcr3.center.y, -78.873758, 0.00001);
    XCTAssertEqualWithAccuracy(lcr3.radius, 0.00024, 0.00001);
}

- (void)testRelativeOrigin {
    [scapeMngr readScapeFromJSON:@"test_relative_origin.gpson"];
    
    kflLinkedCircleRegion *lcr1 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"1"];
    XCTAssertEqual(lcr1.idNum, 1);
    XCTAssertEqualWithAccuracy(lcr1.center.x, 42.925118, 0.00001);
    XCTAssertEqualWithAccuracy(lcr1.center.y, -78.872459, 0.00001);
    XCTAssertEqualWithAccuracy(lcr1.radius, 0.0002, 0.00001);
    
    kflLinkedCircleRegion *lcr2 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"2"];
    XCTAssertEqual(lcr2.idNum, 2);
    XCTAssertEqualWithAccuracy(lcr2.center.x, 42.919674, 0.00001);
    XCTAssertEqualWithAccuracy(lcr2.center.y, -78.87145, 0.00001);
    XCTAssertEqualWithAccuracy(lcr2.radius, 0.00036, 0.00001);
    
    kflLinkedCircleRegion *lcr3 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"3"];
    XCTAssertEqual(lcr3.idNum, 3);
    XCTAssertEqualWithAccuracy(lcr3.center.x, 42.925704, 0.00001);
    XCTAssertEqualWithAccuracy(lcr3.center.y, -78.873758, 0.00001);
    XCTAssertEqualWithAccuracy(lcr3.radius, 0.00024, 0.00001);
}

- (void)testLCRNonDefaults {
    [scapeMngr readScapeFromJSON:@"test.gpson"];
    
    kflLinkedCircleRegion *lcr1 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"1"];
    XCTAssertEqual(lcr1.attackTime, 2000);
    XCTAssertEqual(lcr1.releaseTime, 4000);
    XCTAssertNil(lcr1.idsToActivate);
    XCTAssertEqual(lcr1.numLives, 99);
    XCTAssertTrue([lcr1.label isEqualToString:@"no1"]);
}

- (void)testLCRDefaults {
    [scapeMngr readScapeFromJSON:@"test.gpson"];
    
    kflLinkedCircleRegion *lcr2 = [[[kflHTLPManager sharedManager] scapeRegions] objectForKey:@"2"];
    XCTAssertEqual(lcr2.attackTime, 1000);
    XCTAssertEqual(lcr2.releaseTime, 1000);
    XCTAssertNil(lcr2.idsToActivate);
    XCTAssertEqual(lcr2.numLives, 99);
    NSLog(@"--- %@", lcr2.label);
    XCTAssertTrue([lcr2.label isEqualToString:@""]);
}


@end
