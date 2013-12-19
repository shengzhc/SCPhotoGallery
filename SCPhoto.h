//
//  SCPhoto.h
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#define SCPHOTO_LOADING_DID_END_NOTIFICATION @"SCPHOTO_LOADING_DID_END_NOTIFICATION"

#import <Foundation/Foundation.h>
#import "SCPhotoProtocol.h"

@interface SCPhoto : NSObject < SCPhotoProtocol >

@property (nonatomic, strong) NSString *caption;

+ (SCPhoto *)photoWithPlaceHolder:(UIImage *)placeHolder url:(NSURL *)url;
- (id)initWithPlaceHolder:(UIImage *)placeHolder url:(NSURL *)url;

@end

