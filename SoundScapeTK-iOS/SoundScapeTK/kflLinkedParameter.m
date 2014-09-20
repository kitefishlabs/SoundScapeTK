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
@synthesize lowValue, highValue;

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                  andHighMappedValue:(float)high {
    
    kflLinkedParameter *lp = [[kflLinkedParameter alloc] init];
    
    if (lp) {
        lp.paramName = name;
        lp.lowValue = low;
        lp.highValue = high;
    }
    return lp;
}

@end
