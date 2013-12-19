//
//  SCPhotoGalleryViewController.h
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPhoto.h"
#import "SCPhotoProtocol.h"

@class SCPhotoGalleryViewController;

@protocol SCPhotoGalleryViewControllerDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoGallery:(SCPhotoGalleryViewController *)photoGallery;
- (id < SCPhotoProtocol >)photoGallery:(SCPhotoGalleryViewController *)photoGallery photoAtIndex:(NSUInteger)index;

@optional

- (void)photoGallery:(SCPhotoGalleryViewController *)photoGallery didDisplayPhotoAtIndex:(NSUInteger)index;

@end

@interface SCPhotoGalleryViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate >

// Properties
@property (nonatomic, weak) id < SCPhotoGalleryViewControllerDelegate > delegate;
@property (nonatomic, readonly) NSUInteger currentIndex;
@property (nonatomic, assign) BOOL zoomPhotosToFill;
@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, strong) UIView *blackMask;
@property (nonatomic, strong) UIImage *screenshot;

- (id)initWithDelegate:(id <SCPhotoGalleryViewControllerDelegate>)delegate;
- (void)reloadData;
- (void)setCurrentPhotoIndex:(NSUInteger)index;
- (void)showNextPhotoAnimated:(BOOL)animated;
- (void)showPreviousPhotoAnimated:(BOOL)animated;

@end
