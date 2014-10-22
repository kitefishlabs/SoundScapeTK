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
@synthesize lowValue, highValue, angleOffset, angle;

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                  andHighMappedValue:(float)high {

    kflLinkedParameter *lp = [[kflLinkedParameter alloc] init];
    
    if (lp) {
        lp.paramName = name;
        lp.lowValue = low;
        lp.highValue = high;
        lp.angleOffset = 0.0;   // don't care
        lp.angle = 0.f;         // don't care
    }
    return lp;
}

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                     highMappedValue:(float)high
                                      andAngleOffset:(float)anglOffset {

    kflLinkedParameter *lp = [[kflLinkedParameter alloc] init];
    
    if (lp) {
        lp.paramName = name;
        lp.lowValue = low;
        lp.highValue = high;
        lp.angleOffset = anglOffset;
        lp.angle = 0.f;                 // using this as a temp var
    }
    return lp;
}

@end
