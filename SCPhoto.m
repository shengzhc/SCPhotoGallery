//
//  SCPhoto.m
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import "SCPhoto.h"
#import "UIImageView+AFNetworking.h"

@interface SCPhoto ()
{
    BOOL _loadingInProgress;
}

@property (nonatomic, strong) UIImage *downloadedImage;
@property (nonatomic, strong) UIImage *placeHolderImage;
@property (nonatomic, strong) NSURL *photoURL;

@end

@implementation SCPhoto

+ (SCPhoto *)photoWithPlaceHolder:(UIImage *)placeHolder url:(NSURL *)url
{
    return [[SCPhoto alloc] initWithPlaceHolder:placeHolder url:url];
}

- (id)initWithPlaceHolder:(UIImage *)placeHolder url:(NSURL *)url
{
    if (self = [super init]) {
        
        _placeHolderImage = placeHolder;
        _photoURL = [url copy];
        _downloadedImage = nil;
    }
    
    return self;
}

- (void)loadImage
{
    if (_loadingInProgress) {
        return;
    }
    
    _loadingInProgress = YES;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    
    __weak SCPhoto *this = self;
    
    [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:_photoURL]
                     placeholderImage:nil
                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         this.downloadedImage = image;
         [this imageLoadingComplete];
     }
                              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
     {
         [this imageLoadingComplete];
     }];
}

- (void)unloadImage
{
    _downloadedImage = nil;
}

- (UIImage *)placeholderImage
{
    return _placeHolderImage;
}

- (UIImage *)downloadedImage
{
    return _downloadedImage;
}

- (void)imageLoadingComplete
{
    _loadingInProgress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:SCPHOTO_LOADING_DID_END_NOTIFICATION
                                                        object:self];
}

@end