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

+ (kflLinkedParameter *)kflLinkedParameterWithString:(NSString *)name
                                        lowMappedVal:(float)low
                                     andHighMappedValue:(float)high;
@end
