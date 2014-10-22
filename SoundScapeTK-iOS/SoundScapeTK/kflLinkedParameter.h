//
//  kflLinkedParameter.h
//  SoundScapeTK
//
//  Created by Kitefish Labs on 7/2/14.
//  Copyright (c) 2014 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface kflLinkedParameter : NSObject

@property   NSString    *paramName;
@property   float       lowValue, highValue;
@property   float       angle, angleOffset;

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                  andHighMappedValue:(float)high;

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                     highMappedValue:(float)high
                                               angle:(float)angl
                                      andAngleOffset:(float)anglOffset;
@end
