//
//  kflArnoldTile
//  ArnoldArboretum
//
//  Created by Kitefish Labs on 9/13/13.
//  - Modified 5/21/14 - renamed.
//  Copyright (c) 2013-14 Kitefish Labs. All rights reserved.
//

#import "kflArnoldTile.h"

@implementation kflArnoldTile

@synthesize filePath, tileImageView, imgWidth, imgHeight;

+ (kflArnoldTile *)tileForImageFile:(NSString *)filePath {
    
    kflArnoldTile *tile = [[kflArnoldTile alloc] init];
    
    if (tile) {
        tile.tileImageView = nil;
        tile.filePath = filePath;
        UIImage *customMapImg = [UIImage imageNamed:tile.filePath];
        tile.tileImageView = [[UIImageView alloc] initWithImage:customMapImg];
        
        tile.imgWidth = customMapImg.size.width;
        tile.imgHeight = customMapImg.size.height;
    }
    return tile;
}

- (void)showFile:(BOOL)show withGestureRecognizer:(UITapGestureRecognizer *)tgr {
    
    if (show) {
        
        [self.tileImageView setFrame:CGRectMake(0, 0, (int)(self.imgWidth/2.0), (int)(self.imgHeight/2.0))];
        [self.tileImageView setOpaque:YES];
        [self.tileImageView setUserInteractionEnabled:YES];
        [self.tileImageView setTag:99];
        if (tgr) { [self.tileImageView addGestureRecognizer:tgr]; }

    } else {
        self.tileImageView.gestureRecognizers = nil;
        [self.tileImageView removeFromSuperview]; //??
        self.tileImageView = nil;
    }
}

@end
