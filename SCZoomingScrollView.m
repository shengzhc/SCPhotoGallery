//
//  SCZoomingScrollView.m
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import "SCZoomingScrollView.h"
#import "SCPhoto.h"
#import "SCPhotoGalleryViewController.h"

@interface SCPhotoGalleryViewController ()

- (UIImage *)imageForPhoto:(id<SCPhotoProtocol>)photo;

@end

@interface SCZoomingScrollView ()
{
	UIImageView *_photoImageView;
	UIActivityIndicatorView *_loadingIndicator;
    CGPoint _panOrigin;
    BOOL _isAnimating;
}

@property (nonatomic, weak) SCPhotoGalleryViewController *photoGallery;

@end

@implementation SCZoomingScrollView

- (id)initWithPhotoGallery:(SCPhotoGalleryViewController *)photoGallery
{
    if ((self = [super init])) {

        self.photoGallery = photoGallery;
        
		_photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:_photoImageView];
		
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _loadingIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _loadingIndicator.userInteractionEnabled = NO;
        _loadingIndicator.hidesWhenStopped = YES;
        
		_loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:_loadingIndicator];

		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addMultiGestures];
    }
    
    return self;
}

- (void)addMultiGestures
{
    UITapGestureRecognizer *twoFingerTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTwoFingerTap:)];
    twoFingerTapGesture.numberOfTapsRequired = 1;
    twoFingerTapGesture.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:twoFingerTapGesture];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:singleTapRecognizer];
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDobleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:doubleTapRecognizer];
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    panGestureRecognizer.delegate = self;
    panGestureRecognizer.delaysTouchesBegan = NO;
    panGestureRecognizer.cancelsTouchesInView = YES;
    [self addGestureRecognizer:panGestureRecognizer];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setPhoto:(id <SCPhotoProtocol> )photo
{
    _photoImageView.image = nil;
    
    if (_photo != photo) {
        _photo = photo;
    }
    
    [self displayImage];
}

- (void)prepareForReuse
{
    self.photo = nil;
}

- (void)displayImage
{
	if (_photo && _photoImageView.image == nil) {
        
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		self.contentSize = CGSizeMake(0, 0);
        
        UIImage *img = [self.photoGallery imageForPhoto:_photo];
        
		if (img) {
            [self hideLoadingIndicator];
			_photoImageView.image = img;
			_photoImageView.hidden = NO;
			CGRect photoImageViewFrame;
			photoImageViewFrame.origin = CGPointZero;
			photoImageViewFrame.size = img.size;
			_photoImageView.frame = photoImageViewFrame;
			self.contentSize = photoImageViewFrame.size;
            [self setMaxMinZoomScalesForCurrentBounds];
		} else {
            _photoImageView.hidden = YES;
			[self showLoadingIndicator];
		}
        
		[self setNeedsLayout];
	}
}

- (void)displayImageFailure
{
    [self hideLoadingIndicator];
}

- (void)hideLoadingIndicator
{
    [_loadingIndicator stopAnimating];
    _loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator
{
    _loadingIndicator.hidden = NO;
    [_loadingIndicator startAnimating];
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
	
	if (_photoImageView.image == nil) return;
	
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.frame.size;
    
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
	CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        maxScale = 4;
    }
    
	if (xScale >= 1 && yScale >= 1) {
		minScale = 1.0;
	}
    
    CGFloat zoomScale = minScale;
    if (self.photoGallery.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        if (ABS(boundsAR - imageAR) < 0.3) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(minScale, zoomScale), maxScale);
        }
    }
	
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
	self.zoomScale = zoomScale;
    
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    if (zoomScale != minScale) {
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * zoomScale - boundsSize.height) / 2.0);
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.scrollEnabled = NO;
    }
    
	[self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews
{
	
	if (!_loadingIndicator.hidden) {
        _loadingIndicator.center = CGPointMake(CGRectGetMidX(self.bounds),
                                               CGRectGetMidY(self.bounds));
    }
    
	[super layoutSubviews];
	
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
		_photoImageView.frame = frameToCenter;
	
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollEnabled = YES; // reset
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Zooming
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
- (void)didTwoFingerTap:(UITapGestureRecognizer*)recognizer
{
    CGFloat newZoomScale = self.zoomScale / 1.5f;
    newZoomScale = MAX(newZoomScale, self.minimumZoomScale);
    [self setZoomScale:newZoomScale animated:YES];
}

- (void)didSingleTap:(UITapGestureRecognizer*)recognizer
{
    if(self.zoomScale == self.maximumZoomScale) {
        CGPoint pointInView = [recognizer locationInView:_photoImageView];
            [self zoomInZoomOut:pointInView];
    } else if (self.zoomScale == self.minimumZoomScale) {
        [self toggleFrontView];
    }
}

- (void)didDobleTap:(UITapGestureRecognizer*)recognizer
{
    CGPoint pointInView = [recognizer locationInView:_photoImageView];
    [self zoomInZoomOut:pointInView];
}

- (void)zoomInZoomOut:(CGPoint)point
{
    // Check if current Zoom Scale is greater than half of max scale then reduce zoom and vice versa
    CGFloat newZoomScale = self.zoomScale > (self.maximumZoomScale/2)?self.minimumZoomScale:self.maximumZoomScale;
    
    CGSize scrollViewSize = self.bounds.size;
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    [self zoomToRect:rectToZoomTo animated:YES];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        if (gestureRecognizer.view == self && [gestureRecognizer isMemberOfClass:[UIPanGestureRecognizer class]]) {
            
            if (self.zoomScale != self.minimumZoomScale) {
                return NO;
            }
            CGPoint touchLocation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self];
            return fabs(touchLocation.x) < fabs(touchLocation.y);
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (void)didPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if(self.zoomScale != self.minimumZoomScale || _isAnimating) {
        return;
    }
    
    if (_doneButton.alpha == 1.0f) {
        [self toggleFrontView];
    }
    
    CGPoint currentPoint = [panGestureRecognizer translationInView:self];
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _panOrigin = _photoImageView.frame.origin;
        return;
    }
    
    CGFloat y = currentPoint.y + _panOrigin.y;
    CGRect frame = _photoImageView.frame;
    frame.origin = CGPointMake(0, y);
    _photoImageView.frame = frame;
    
    CGFloat yDiff = abs((y + _photoImageView.frame.size.height/2) - _blackMask.bounds.size.height/2);
    _blackMask.alpha = MAX(1 - yDiff/(_blackMask.bounds.size.height/2), 0.3);
    
    if ((panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled) && self.zoomScale == self.minimumZoomScale) {
        if(_blackMask.alpha < 0.7) {
            [self dismissViewController];
        }else {
            [self rollbackViewController];
        }
    }
}

- (void)rollbackViewController
{
    _isAnimating = YES;
    [UIView animateWithDuration:0.2f delay:0.0f options:0 animations:^{
        _photoImageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        _blackMask.alpha = 1;
    }   completion:^(BOOL finished) {
        if (finished) {
            _isAnimating = NO;
        }
    }];
}

- (void)dismissViewController
{
    _isAnimating = YES;
    self.scrollEnabled = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        _photoImageView.clipsToBounds = YES;
        [UIView animateWithDuration:0.4
                              delay:0.0f
                            options:0
                         animations:^{
            _photoImageView.frame = self.photoGallery.originalFrame;
            _blackMask.alpha = 0.0f;
            _photoImageView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            _isAnimating = NO;
            [self.photoGallery dismissViewControllerAnimated:NO
                                                  completion:^
            {
                _photoImageView.frame = [self originalPhotoFrame];
                _blackMask.alpha = 1.0f;
                _photoImageView.alpha = 1.0f;
            }];
        }];
    });
}

- (void)toggleFrontView
{
    CGFloat alpha = _doneButton.alpha == 0.0f ? 1.0f : 0.0f;
    [UIView animateWithDuration:.2
                     animations:^
    {
        _doneButton.alpha = alpha;
    }];
}

- (CGRect)originalPhotoFrame
{
    return CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
}

@end
