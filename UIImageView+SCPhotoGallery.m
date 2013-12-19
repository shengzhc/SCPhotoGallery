//
//  UIImageView+SCPhotoGallery.m
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import "UIImageView+SCPhotoGallery.h"
#import "UIImage+Services.h"
#import "SCPhotoGalleryTapGestureRecognizer.h"

@implementation UIImageView (SCPhotoGallery)

- (void)setupPhotoGalleryWithDelegate:(id<SCPhotoGalleryViewControllerDelegate>)delegate initialIndex:(NSInteger)initialIndex originalFrame:(CGRect)originalFrame
{
    self.userInteractionEnabled = YES;
    SCPhotoGalleryViewController *photoGalleryViewController = [[SCPhotoGalleryViewController alloc] initWithDelegate:delegate];
    [photoGalleryViewController setCurrentPhotoIndex:initialIndex];
    photoGalleryViewController.originalFrame = originalFrame;
    
    SCPhotoGalleryTapGestureRecognizer *tapGestureRecognizer = [[SCPhotoGalleryTapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.photoGalleryViewController = photoGalleryViewController;
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)removePhotoGallery
{
    for (UIGestureRecognizer * gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[SCPhotoGalleryTapGestureRecognizer class]]) {
            [self removeGestureRecognizer:gesture];
            SCPhotoGalleryTapGestureRecognizer *tapGesture = (SCPhotoGalleryTapGestureRecognizer *)gesture;
            tapGesture.delegate = nil;
        }
    }
}

- (void)didTap:(SCPhotoGalleryTapGestureRecognizer *)tapGestureRecognizer
{
    SCPhotoGalleryViewController *photoGallery = tapGestureRecognizer.photoGalleryViewController;
    if (photoGallery) {
        photoGallery.screenshot = [UIImage screenshot];
        if (photoGallery.delegate && [photoGallery.delegate isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)photoGallery.delegate;
            photoGallery.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [vc presentViewController:photoGallery animated:YES completion:nil];
        }
    }
}
@end
