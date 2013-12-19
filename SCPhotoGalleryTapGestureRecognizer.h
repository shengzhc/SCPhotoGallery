//
//  SCPhotoGalleryTapGestureRecognizer.h
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCPhotoGalleryViewController;

@interface SCPhotoGalleryTapGestureRecognizer : UITapGestureRecognizer

@property (nonatomic, strong) SCPhotoGalleryViewController *photoGalleryViewController;

@end
