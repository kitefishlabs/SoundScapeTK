//
//  kflArnoldTile.h
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 9/13/13.
//  - Modified 5/21/14 - renamed.
//  Copyright (c) 2013-14 Kitefish Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface kflArnoldTile : NSObject

@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) UIImageView *tileImageView;
@property (nonatomic) int imgWidth, imgHeight;


+ (kflArnoldTile *)tileForImageFile:(NSString *)filePath;

- (void) showFile:(BOOL)show withGestureRecognizer:(UITapGestureRecognizer *)tgr;


@end
