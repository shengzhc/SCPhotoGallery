//
//  SCPhotoGalleryViewController.m
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SCPhotoGalleryViewController.h"
#import "SCZoomingScrollView.h"
#import "MBProgressHUD.h"
#import "UIImage+Services.h"

#define PADDING                 10
#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)
#define ACTION_SHEET_OLD_ACTIONS 2000

@interface SCPhotoGalleryViewController ()
{
    NSUInteger _photoCount;
    NSMutableArray *_photos;
    
	UIScrollView *_pagingScrollView;
    UIImageView *_screenshotImageView;
	
	NSMutableSet *_visiblePages, *_recycledPages;
	NSUInteger _currentPageIndex;
	NSUInteger _pageIndexBeforeRotation;
    
    UIButton *_doneButton;

	BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    
}

@property (nonatomic) UIActivityViewController *activityViewController;

- (void)performLayout;

- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (SCZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (SCZoomingScrollView *)pageDisplayingPhoto:(id<SCPhotoProtocol>)photo;
- (SCZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(SCZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)gotoPreviousPage;
- (void)gotoNextPage;

- (NSUInteger)numberOfPhotos;
- (id < SCPhotoProtocol >)photoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<SCPhotoProtocol>)photo;
- (void)loadAdjacentPhotosIfNecessary:(id<SCPhotoProtocol>)photo;
- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent;

@end

@implementation SCPhotoGalleryViewController

- (id)init
{
    if ((self = [super init])) {
        [self _initialisation];
    }
    
    return self;
}

- (id)initWithDelegate:(id <SCPhotoGalleryViewControllerDelegate>)delegate
{
    if ((self = [self init])) {
        _delegate = delegate;
        [self _initialisation];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
        [self _initialisation];
	}
    
	return self;
}

- (void)_initialisation
{
    _photoCount = NSNotFound;
    _currentPageIndex = 0;
    _performingLayout = NO;
    _zoomPhotosToFill = YES;
    _rotating = NO;
    _viewIsActive = NO;
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos = [[NSMutableArray alloc] init];
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]){
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSCPhotoLoadingDidEndNotification:)
                                                 name:SCPHOTO_LOADING_DID_END_NOTIFICATION
                                               object:nil];
}

- (void)dealloc
{
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos:NO];
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent
{
    NSArray *photosCopy = [_photos copy];
    for (id p in photosCopy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self photoAtIndex:self.currentIndex]) {
                continue; // skip current
            }
            [p unloadImage];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [self releaseAllUnderlyingPhotos:YES];
	[_recycledPages removeAllObjects];
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    self.view.clipsToBounds = YES;
	
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
	_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
    [self reloadData];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _doneButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_doneButton setBackgroundImage:[UIImage imageNamed:@"Done"] forState:UIControlStateNormal];
    [_doneButton sizeToFit];
    _doneButton.alpha = 0.0f;
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_doneButton];
    
    _blackMask = [[UIView alloc] initWithFrame:self.view.bounds];
    _blackMask.backgroundColor = [UIColor blackColor];
    _blackMask.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:_blackMask atIndex:0];
    
    _screenshotImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _screenshotImageView.image = _screenshot;
    [self.view insertSubview:_screenshotImageView belowSubview:_blackMask];
    
    [super viewDidLoad];
    
}

- (void)performLayout
{
    _performingLayout = YES;
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
    
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
}

- (void)viewDidUnload
{
	_currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
	
	_performingLayout = YES;
	NSUInteger indexPriorToLayout = _currentPageIndex;
	
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView.frame = pagingScrollViewFrame;
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (SCZoomingScrollView *page in _visiblePages) {
        
        NSUInteger index = PAGE_INDEX(page);
		page.frame = [self frameForPageAtIndex:index];
        
        static CGRect previousBounds = {0};
        if (!CGRectEqualToRect(previousBounds, self.view.bounds)) {
            [page setMaxMinZoomScalesForCurrentBounds];
            previousBounds = self.view.bounds;
        }
	}
	
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	[self didStartViewingPageAtIndex:_currentPageIndex];
    _currentPageIndex = indexPriorToLayout;
	
    [_doneButton sizeToFit];
    _doneButton.frame = CGRectMake(self.view.bounds.size.width - _doneButton.bounds.size.width - 10, 10, _doneButton.bounds.size.width, _doneButton.bounds.size.height);
    
    _blackMask.frame = self.view.bounds;
    
    _performingLayout = NO;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	_pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	_currentPageIndex = _pageIndexBeforeRotation;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	_rotating = NO;
}

- (void)reloadData
{
    _photoCount = NSNotFound;
    
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos:YES];
    [_photos removeAllObjects];
    
    for (int i = 0; i < numberOfPhotos; i++) {
        [_photos addObject:[NSNull null]];
    }
    
    while (_pagingScrollView.subviews.count) {
        [[_pagingScrollView.subviews lastObject] removeFromSuperview];
    }
    
    _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfPhotos - 1));
    [self performLayout];
    [self.view setNeedsLayout];
}

- (NSUInteger)numberOfPhotos
{
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoGallery:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoGallery:self];
        }
    }
    
    if (_photoCount == NSNotFound) {
        _photoCount = 0;
    }
    
    return _photoCount;
}

- (id <SCPhotoProtocol> )photoAtIndex:(NSUInteger)index
{
    id <SCPhotoProtocol> photo = nil;
    
    if (index < _photos.count) {
        
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            
            if ([_delegate respondsToSelector:@selector(photoGallery:photoAtIndex:)]) {
                photo = [_delegate photoGallery:self photoAtIndex:index];
            }
            
            if (photo) {
                [_photos replaceObjectAtIndex:index withObject:photo];
            }
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    
    return photo;
}

- (UIImage *)imageForPhoto:(id<SCPhotoProtocol>)photo
{
	if (photo) {
        if ([photo downloadedImage]) {
            return [photo downloadedImage];
        } else {
            [photo loadImage];
            return [photo placeholderImage];
        }
    }
    
	return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(id<SCPhotoProtocol>)photo
{
    SCZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    
    if (page) {
        
        page.blackMask = _blackMask;
        page.doneButton = _doneButton;
        NSUInteger pageIndex = PAGE_INDEX(page);
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                id <SCPhotoProtocol> photo = [self photoAtIndex:pageIndex-1];
                if (![photo downloadedImage]) {
                    [photo loadImage];
                }
            }
            
            if (pageIndex < [self numberOfPhotos] - 1) {
                
                id <SCPhotoProtocol> photo = [self photoAtIndex:pageIndex+1];
                if (![photo downloadedImage]) {
                    [photo loadImage];
                }
            }
        }
    }
}

- (void)handleSCPhotoLoadingDidEndNotification:(NSNotification *)notification
{
    id <SCPhotoProtocol> photo = [notification object];
    SCZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo downloadedImage]) {
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            [page displayImageFailure];
        }
    }
}

- (void)tilePages
{
	CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
	
	// Recycle no longer needed pages
    NSInteger pageIndex;
	for (SCZoomingScrollView *page in _visiblePages) {
        pageIndex = PAGE_INDEX(page);
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
			[_recycledPages addObject:page];
            [page prepareForReuse];
			[page removeFromSuperview];
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
	
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
			SCZoomingScrollView *page = [self dequeueRecycledPage];
			if (!page) {
				page = [[SCZoomingScrollView alloc] initWithPhotoGallery:self];
			}
			[self configurePage:page forIndex:index];
			[_visiblePages addObject:page];
			[_pagingScrollView addSubview:page];
		}
	}
	
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
	for (SCZoomingScrollView *page in _visiblePages) {
		if (PAGE_INDEX(page) == index) return YES;
    }
    
	return NO;
}

- (SCZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index
{
	SCZoomingScrollView *thePage = nil;
    
	for (SCZoomingScrollView *page in _visiblePages) {
		if (PAGE_INDEX(page) == index) {
			thePage = page;
            break;
		}
	}
    
	return thePage;
}

- (SCZoomingScrollView *)pageDisplayingPhoto:(id<SCPhotoProtocol>)photo
{
	SCZoomingScrollView *thePage = nil;
    
	for (SCZoomingScrollView *page in _visiblePages) {
		if (page.photo == photo) {
			thePage = page;
            break;
		}
	}
	return thePage;
}

- (void)configurePage:(SCZoomingScrollView *)page forIndex:(NSUInteger)index
{
	page.frame = [self frameForPageAtIndex:index];
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    page.photo = [self photoAtIndex:index];
}

- (SCZoomingScrollView *)dequeueRecycledPage
{
	SCZoomingScrollView *page = [_recycledPages anyObject];
	if (page) {
		[_recycledPages removeObject:page];
	}
    
	return page;
}

- (void)didStartViewingPageAtIndex:(NSUInteger)index
{
    if (![self numberOfPhotos]) {
        return;
    }
    
    id <SCPhotoProtocol> currentPhoto = [self photoAtIndex:index];
    if ([currentPhoto downloadedImage]) {
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
    static NSUInteger prevIndex = NSUIntegerMax;
    if (index != prevIndex) {
        if ([_delegate respondsToSelector:@selector(photoGallery:didDisplayPhotoAtIndex:)])
            [_delegate photoGallery:self didDisplayPhotoAtIndex:index];
        prevIndex = index;
    }
}

- (CGRect)frameForPagingScrollView
{
    CGRect frame = self.view.bounds;
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index
{
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (CGSize)contentSizeForPagingScrollView
{
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index
{
	CGFloat pageWidth = _pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (!_viewIsActive || _performingLayout || _rotating) return;
	
	[self tilePages];
	
	CGRect visibleBounds = _pagingScrollView.bounds;
	int index = (int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
	if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
	NSUInteger previousCurrentPage = _currentPageIndex;
	_currentPageIndex = index;
    
	if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated
{
	if (index < [self numberOfPhotos]) {
		CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:animated];
	}
}

- (void)gotoPreviousPage
{
    [self showPreviousPhotoAnimated:NO];
}

- (void)gotoNextPage
{
    [self showNextPhotoAnimated:NO];
}

- (void)showPreviousPhotoAnimated:(BOOL)animated
{
    [self jumpToPageAtIndex:_currentPageIndex-1 animated:animated];
}

- (void)showNextPhotoAnimated:(BOOL)animated
{
    [self jumpToPageAtIndex:_currentPageIndex+1 animated:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)setInitialPageIndex:(NSUInteger)index
{
    [self setCurrentPhotoIndex:index];
}

- (void)setCurrentPhotoIndex:(NSUInteger)index
{
    if (index >= [self numberOfPhotos])
        index = [self numberOfPhotos]-1;
    
    _currentPageIndex = index;
	
    if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index animated:NO];
        
        if (!_viewIsActive) {
            [self tilePages];
        }
    }
}

- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end

