//
//  UIImageView_CRWebCache.h
//  imv4i
//
//  Created by Croath on 12-12-26.
//  Copyright (c) 2012年 Croath. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (CRWebCache)

@property (nonatomic, retain) NSString* apiURL;
@property (nonatomic, readonly) BOOL isShow;
@property (nonatomic) BOOL isShowLoading;

+ (void)createDirectory;
- (void)startLoadImage;
- (void)cancelLoadImage;
+ (void)clearImageCache;
- (NSString*)digest_md5:(NSString*)string;
@end
