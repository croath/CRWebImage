//
//  UIImageViewAPI.m
//  woula
//
//  Created by bh on 12-5-8.
//  Copyright (c) 2012年 com.dms.woula. All rights reserved.
//

#define IMAGE_CACHE_PATH     @"imageCache"
#define IMAGE_CACHE_TIME     60*60*24*7

#import "UIImageView+CRWebCache.h"
#import "ASIDownloadCache.h"

@interface UIImageView (CRWebCache){
  ASIHTTPRequest *req;
  
  UIActivityIndicatorView *loadingView;
}

@synthesize apiURL = _apiURL;
@synthesize isShow, isShowLoading;

+ (void)createDirectory{
  NSString* diskCachePath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), IMAGE_CACHE_PATH];
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
  {
    [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
  }
}

- (void)setApiURL:(NSString *)url{
  if (url && (!_apiURL || ![_apiURL isEqualToString:url])) {
    [req clearDelegatesAndCancel];
    req = nil;
    [url retain];
    [_apiURL release];
    _apiURL = url;
    isShow = NO;
    if (!isShow && _apiURL) {
      NSString *path = [NSString stringWithFormat:@"%@/Documents/%@/%@_%@", NSHomeDirectory(), IMAGE_CACHE_PATH,[self digest_md5:_apiURL], [_apiURL lastPathComponent]];
      UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
      if (image) {
        self.image = image;
        isShow = YES;
      }
      [image release];
    }
  }
  
}

- (void)showLoading{
  [self hideLoading];
  loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  loadingView.frame = CGRectMake((self.frame.size.width-20)/2.0, (self.frame.size.height-20)/2.0, 20, 20);
  [self addSubview:loadingView];
  [loadingView startAnimating];
  [loadingView release];
}

- (void)hideLoading{
  if (loadingView) {
    [loadingView stopAnimating];
    [loadingView removeFromSuperview];
    loadingView = nil;
  }
}

- (void)startLoadImage{
  if (!isShow && !req && _apiURL) {
    NSString *path = [NSString stringWithFormat:@"%@/Documents/%@/%@_%@", NSHomeDirectory(), IMAGE_CACHE_PATH,[API digest_md5:_apiURL], [_apiURL lastPathComponent]];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image) {
      self.image = image;
      isShow = YES;
      NSLog(@"use cache image");
    }else {
      NSLog(@"use req image: %@", _apiURL);
      if (isShowLoading) {
        [self showLoading];
      }
      req = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.apiURL]];
      [req setDownloadCache:[ASIDownloadCache sharedCache]];
      [req setDownloadDestinationPath:path];
      [req setSecondsToCache:IMAGE_CACHE_TIME];
      req.delegate = self;
      [req startAsynchronous];
    }
    [image release];
  }
}

- (void)cancelLoadImage{
  if (req) {
    [req clearDelegatesAndCancel];
    req = nil;
  }
}

- (void)requestFinished:(ASIHTTPRequest *)request{
  if (isShowLoading) {
    [self hideLoading];
  }
  UIImage *image = [[UIImage alloc] initWithContentsOfFile:request.downloadDestinationPath];
  if (image) {
    self.image = image;
    isShow = YES;
    if (![request didUseCachedResponse]) {
      self.alpha = 0.6;
      [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 1.0;
      }];
    }
  }else {
    NSLog(@"UIImageViewAPI: [%d] %@", request.responseStatusCode, [request responseString]);
  }
  [image release];
  req = nil;
}

- (void)requestFailed:(ASIHTTPRequest *)request{
  if (isShowLoading) {
    [self hideLoading];
  }
  NSLog(@"UIImageViewAPI: [%d] %@", request.responseStatusCode, [request responseString]);
  req = nil;
}

- (void)dealloc{
  [self cancelLoadImage];
  [_apiURL release];
  _apiURL = nil;
  [super dealloc];
}

+ (void)clearImageCache{
  dispatch_queue_t cacheQ = dispatch_queue_create("imageCacheQueue", nil);
  dispatch_async(cacheQ, ^{
    NSString *imageCachePath = [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), IMAGE_CACHE_PATH];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:imageCachePath]) {
      NSError *err = nil;
      [fileManager createDirectoryAtPath:imageCachePath withIntermediateDirectories:NO attributes:nil error:&err];
      if (err) {
        NSLog(@"create imageCache dir failed: %@", err);
      }
    }
    NSArray *images = [fileManager contentsOfDirectoryAtPath:imageCachePath error:nil];
    if (images && images.count > 0) {
      //            NSLog(@"images: %@", images);
      NSDate *now = [NSDate date];
      for (NSString *image in images) {
        NSError *err = nil;
        NSString *path = [imageCachePath stringByAppendingPathComponent:image];
        NSDictionary *attr = [fileManager attributesOfItemAtPath:path error:&err];
        if (!err) {
          NSDate *cd = [attr valueForKey:NSFileCreationDate];
          NSTimeInterval ti = [now timeIntervalSinceDate:cd];
          if (ti > IMAGE_CACHE_TIME) {
            [fileManager removeItemAtPath:path error:nil];
          }
        }
      }
    }
  });
  dispatch_release(cacheQ);
}

- (NSString*)digest_md5:(NSString*)string{
  const char *cStr = [string UTF8String];
  unsigned char result[16];
  CC_MD5(cStr, strlen(cStr), result);
  NSString* sig = [NSString stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   result[0], result[1], result[2], result[3],
                   result[4], result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11],
                   result[12], result[13], result[14], result[15]
                   ];
  return sig;
}

@end
