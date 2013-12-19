//
//  SCZoomingScrollView.h
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "SCPhotoProtocol.h"

@class SCPhotoGalleryViewController, SCPhoto;

@interface SCZoomingScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) id < SCPhotoProtocol > photo;
@property (nonatomic, weak) UIView *blackMask;
@property (nonatomic, weak) UIButton *doneButton;

- (id)initWithPhotoGallery:(SCPhotoGalleryViewController *)photoGallery;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end
