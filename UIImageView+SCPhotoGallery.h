//
//  UIImageView+SCPhotoGallery.h
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPhotoProtocol.h"
#import "SCPhotoGalleryViewController.h"

@interface UIImageView (SCPhotoGallery)

- (void)setupPhotoGalleryWithDelegate:(id<SCPhotoGalleryViewControllerDelegate>)delegate initialIndex:(NSInteger)initialIndex originalFrame:(CGRect)originalFrame;

- (void)removePhotoGallery;

@end
