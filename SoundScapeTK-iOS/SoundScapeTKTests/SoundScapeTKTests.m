//
//  SoundScapeTKTests.m
//  SoundScapeTKTests
//
//  Created by Kitefish Labs on 12/3/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "kflLinkedParameter.h"
#import "kflLinkedRegion.h"
#import "kflLinkedCircleRegion.h"
#import "kflLinkedSoundfile.h"


@interface SoundScapeTKTests : XCTestCase
@end

@implementation SoundScapeTKTests


- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLinkedParamCreation {
    kflLinkedParameter *radiusParam = [kflLinkedParameter kflLinkedParameterWithString:@"myParam" lowMappedVal:0.0 andHighMappedValue:1.0];
    XCTAssertEqual(radiusParam.paramName, @"myParam", @"Pass");
    XCTAssertGreaterThan(radiusParam.highValue, radiusParam.lowValue);
    XCTAssertEqual(radiusParam.lowValue, 0.0);
    XCTAssertEqual(radiusParam.highValue, 1.0);
    XCTAssertEqual(radiusParam.angle, 0.0);
    XCTAssertEqual(radiusParam.angleOffset, 0.0);
    radiusParam = nil;
}

- (void)testInvertedLinkedParamCreation {
    kflLinkedParameter *invertedRadiusParam = [kflLinkedParameter kflLinkedParameterWithString:@"myParam" lowMappedVal:1.0 andHighMappedValue:0.0];
    XCTAssertEqual(invertedRadiusParam.paramName, @"myParam", @"Pass");
    XCTAssertGreaterThan(invertedRadiusParam.lowValue, invertedRadiusParam.highValue);
    XCTAssertEqual(invertedRadiusParam.lowValue, 1.0);
    XCTAssertEqual(invertedRadiusParam.highValue, 0.0);
    XCTAssertEqual(invertedRadiusParam.angle, 0.0);
    XCTAssertEqual(invertedRadiusParam.angleOffset, 0.0);
    invertedRadiusParam = nil;
}

- (void)testLCSFRegionCreation {
    kflLinkedCircleSFRegion *lcsfRegion = [kflLinkedCircleSFRegion kflLinkedCircleSFRegionWithCenter:CGPointMake(43.0, -72.0)
                                                                                              radius:0.0035
                                                                                               idNum:100
                                                                                               label:@"circleSFRegion"
                                                                                    linkedSoundFiles:nil
                                                                                        radiusMapped:NO
                                                                                              attack:1000
                                                                                             release:2000
                                                                                               loops:0
                                                                                          finishRule:kREGION_CUTOFF
                                                                                               lives:999
                                                                                              active:YES
                                                                                          toActivate:nil
                                                                                            andState:@"ready"];
    XCTAssertEqual(lcsfRegion.center.x, 43.0);
    XCTAssertEqual(lcsfRegion.center.y, -72.0);
    XCTAssertEqualWithAccuracy(lcsfRegion.radius, 0.0035, 0.0001);
    XCTAssertEqual(lcsfRegion.idNum , 100);
    XCTAssertEqual(lcsfRegion.label, @"circleSFRegion");
    XCTAssertNil(lcsfRegion.linkedSoundfiles);
    XCTAssertEqual(lcsfRegion.numLinkedSoundfiles, 0);
    XCTAssertEqual(lcsfRegion.radiusMapped, NO);
    XCTAssertEqual(lcsfRegion.attackTime , 1000);
    XCTAssertEqual(lcsfRegion.releaseTime , 2000);
    XCTAssertEqual(lcsfRegion.numLoops , 0);
    XCTAssertEqual(lcsfRegion.numLives, 999);
    XCTAssertEqual(lcsfRegion.active , YES);
    XCTAssertNil(lcsfRegion.idsToActivate);
    XCTAssertNil(lcsfRegion.stopTimer);
    XCTAssertEqual(lcsfRegion.internalDistance, 0.0);
    XCTAssertEqual(lcsfRegion.state , @"ready");
    
}

- (void)testLCSynthRegionCreation {
    kflLinkedCircleSynthRegion *lcsRegion = [kflLinkedCircleSynthRegion kflLinkedCircleSynthRegionWithCenter:CGPointMake(43.0, -72.0)
                                                                                                      radius:0.0023
                                                                                                       idNum:200
                                                                                                       label:@"circleSynthRegion"
                                                                                                linkedParams:[NSDictionary dictionaryWithObject:@"FOO" forKey:@"22"]
                                                                                                 angleOffset:1.0
                                                                                                      attack:1000
                                                                                                     release:2000
                                                                                                       lives:999
                                                                                                      active:YES
                                                                                                  toActivate:[NSArray arrayWithObject:@"22"]
                                                                                                    andState:@"ready"];

    XCTAssertEqual(lcsRegion.center.x, 43.0);
    XCTAssertEqual(lcsRegion.center.y, -72.0);
    XCTAssertEqualWithAccuracy(lcsRegion.radius, 0.0023, 0.0001);
    XCTAssertEqual(lcsRegion.idNum , 200);
    XCTAssertEqual(lcsRegion.label, @"circleSynthRegion");
    XCTAssertEqual([lcsRegion.linkedParameters objectForKey:@"22"], @"FOO");
//    XCTAssertEqual(lcsRegion.numLinkedParams, 1); ???
    XCTAssertEqual(lcsRegion.attackTime , 1000);
    XCTAssertEqual(lcsRegion.releaseTime , 2000);
    XCTAssertEqual(lcsRegion.numLives, 999);
    XCTAssertEqual(lcsRegion.active , YES);
    XCTAssertEqual([lcsRegion.idsToActivate objectAtIndex:0], @"22");
    XCTAssertEqual([[lcsRegion.idsToActivate objectAtIndex:0] intValue], 22);
    XCTAssertNil(lcsRegion.stopTimer); // DO WE NEED A STOP TIMER???
    XCTAssertEqual(lcsRegion.internalDistance, 0.0);
    XCTAssertEqual(lcsRegion.state , @"ready");
    XCTAssertEqual(lcsRegion.angleOffset, 1.0);
}

- (void)testLinkedSoundfileCreationAndSimpleLifeCycle {
    kflLinkedSoundfile *lsf = [kflLinkedSoundfile linkedSoundfileForFile:@"01.wav" idNum:88 attack:200 andRelease:400];
    // test creation
    XCTAssertEqual(lsf.fileName, @"01.wav");
    XCTAssertEqual(lsf.idNum, 88);
    XCTAssertEqual(lsf.attackTime, 200);
    XCTAssertEqual(lsf.releaseTime, 400);
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *docsURL = [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:lsf.fileName]];
    XCTAssert([[NSFileManager defaultManager] fileExistsAtPath:[docsURL path]]);
    
    XCTAssertEqualWithAccuracy(lsf.length, 17.528163, 0.000001);
    XCTAssertEqual(lsf.channels, 2);
    
    XCTAssertNil(lsf.startTime);
    XCTAssertEqual(lsf.pausedOffset, 0.0);
    
}



@end
