//
//  kflPin.h
//  SoundScapeTK
//
//  Last revised by Thomas Stoll on 7/2/14.
//  Copyright (c) 2012-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface kflPin : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
//@property (nonatomic, strong) NSString *title;
//@property (nonatomic, strong) NSString *subtitle;
@property BOOL hit;

- (id)initWithCoordinate:(CLLocationCoordinate2D)location placeName:(NSString *)placeName description:(NSString *)description andHit:(BOOL)success;

@end
