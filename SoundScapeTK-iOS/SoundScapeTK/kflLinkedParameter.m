//
//  kflLinkedParameter.m
//  SoundScapeTK
//
//  Created by Kitefish Labs on 7/2/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import "kflLinkedParameter.h"

@implementation kflLinkedParameter

@synthesize paramName;
@synthesize lowValue, highValue, angle, angleOffset;

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                  andHighMappedValue:(float)high {

    kflLinkedParameter *lp = [[kflLinkedParameter alloc] init];
    
    if (lp) {
        lp.paramName = name;
        lp.lowValue = low;
        lp.highValue = high;
        lp.angle = 0.0;
        lp.angleOffset = 0.0;
    }
    return lp;
}

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                     highMappedValue:(float)high
                                               angle:(float)angl
                                      andAngleOffset:(float)anglOffset {

    kflLinkedParameter *lp = [[kflLinkedParameter alloc] init];
    
    if (lp) {
        lp.paramName = name;
        lp.lowValue = low;
        lp.highValue = high;
        lp.angle = angl;
        lp.angleOffset = anglOffset;
    }
    return lp;
}

@end
