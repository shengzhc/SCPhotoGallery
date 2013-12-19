//
//  SCPhotoProtocol.h
//  Test
//
//  Created by Shengzhe Chen on 12/6/13.
//  Copyright (c) 2013 Shengzhe Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCPhotoProtocol <NSObject>

@required

- (UIImage *)placeholderImage;
- (UIImage *)downloadedImage;

- (void)loadImage;
- (void)unloadImage;

@optional

- (NSString *)caption;

@end
