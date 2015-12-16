/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKNetworkImageComponent.h"
#import "RJCircularLoaderView.h"
#import "FLAnimatedImage.h"
#import "objc/runtime.h"

@interface CKNetworkImageSpecifier : NSObject
- (instancetype)initWithURL:(NSURL *)url
               defaultImage:(UIImage *)defaultImage
            imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                  scenePath:(id)scenePath
                   cropRect:(CGRect)cropRect;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, strong, readonly) UIImage *defaultImage;
@property (nonatomic, strong, readonly) id<CKNetworkImageDownloading> imageDownloader;
@property (nonatomic, strong, readonly) id scenePath;
@property (nonatomic, assign, readonly) CGRect cropRect;
@end

@interface CKNetworkImageComponentView : FLAnimatedImageView
@property (nonatomic, strong) CKNetworkImageSpecifier *specifier;
@property (nonatomic, strong) RJCircularLoaderView *loaderView;
- (void)didEnterReusePool;
- (void)willLeaveReusePool;
@end

@implementation CKNetworkImageComponent

+ (instancetype)newWithURL:(NSURL *)url
           imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                 scenePath:(id)scenePath
                      size:(const CKComponentSize &)size
                   options:(const CKNetworkImageComponentOptions &)options
                attributes:(const CKViewComponentAttributeValueMap &)passedAttributes
{
    CGRect cropRect = options.cropRect;
    if (CGRectIsEmpty(cropRect)) {
        cropRect = CGRectMake(0, 0, 1, 1);
    }
    CKViewComponentAttributeValueMap attributes(passedAttributes);
    attributes.insert({
        {@selector(setSpecifier:), [[CKNetworkImageSpecifier alloc] initWithURL:url
                                                                   defaultImage:options.defaultImage
                                                                imageDownloader:imageDownloader
                                                                      scenePath:scenePath
                                                                       cropRect:cropRect]},
        
    });
    return [super newWithView:{
        {[CKNetworkImageComponentView class], @selector(didEnterReusePool), @selector(willLeaveReusePool)},
        std::move(attributes)
    } size:size];
}

@end

@implementation CKNetworkImageSpecifier

- (instancetype)initWithURL:(NSURL *)url
               defaultImage:(UIImage *)defaultImage
            imageDownloader:(id<CKNetworkImageDownloading>)imageDownloader
                  scenePath:(id)scenePath
                   cropRect:(CGRect)cropRect
{
    if (self = [super init]) {
        _url = [url copy];
        _defaultImage = defaultImage;
        _imageDownloader = imageDownloader;
        _scenePath = scenePath;
        _cropRect = cropRect;
    }
    return self;
}

- (NSUInteger)hash
{
    return [_url hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[self class]]) {
        CKNetworkImageSpecifier *other = object;
        return CKObjectIsEqual(_url, other->_url)
        && CKObjectIsEqual(_defaultImage, other->_defaultImage)
        && CKObjectIsEqual(_imageDownloader, other->_imageDownloader)
        && CKObjectIsEqual(_scenePath, other->_scenePath);
    }
    return NO;
}

@end

@implementation CKNetworkImageComponentView
{
    BOOL _inReusePool;
    id _download;
}

- (void)updateImageDownloadProgress:(CGFloat)progress
{
    _loaderView.progress = progress;
}

- (void)startLoaderWithTintColor:(UIColor *)color
{
    _loaderView = [[RJCircularLoaderView alloc] initWithFrame:self.bounds];
    _loaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _loaderView.tintColor = color;
    _loaderView.frame = self.bounds;
    [self addSubview:_loaderView];
    _loaderView.progress = 0;
}

- (void)reveal
{
    [_loaderView reveal];
}

- (void)dealloc
{
    if (_download) {
        [_specifier.imageDownloader cancelImageDownload:_download];
        [self reveal];
    }
}

- (void)didDownloadImage:(CGImageRef)image error:(NSError *)error data:(NSData *)imageData
{
    if([[_specifier.url absoluteString] hasSuffix:@"gif"] && (imageData != nil)) {
        self.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
        [self updateContentsRect];
    } else if(image) {
        self.image = [UIImage imageWithCGImage:image];
        [self updateContentsRect];
    }
    _download = nil;
}

- (void)setSpecifier:(CKNetworkImageSpecifier *)specifier
{
    if (CKObjectIsEqual(specifier, _specifier)) {
        return;
    }
    
    if (_download) {
        [_specifier.imageDownloader cancelImageDownload:_download];
        [self reveal];
        _download = nil;
    }
    
    _specifier = specifier;
    self.image = specifier.defaultImage;
    
    [self _startDownloadIfNotInReusePool];
}

- (void)didEnterReusePool
{
    _inReusePool = YES;
    if (_download) {
        [_specifier.imageDownloader cancelImageDownload:_download];
        [self reveal];
        _download = nil;
    }
    // Release the downloaded image that we're holding to lower memory usage.
    self.image = _specifier.defaultImage;
}

- (void)willLeaveReusePool
{
    _inReusePool = NO;
    [self _startDownloadIfNotInReusePool];
}

- (void)_startDownloadIfNotInReusePool
{
    if (_inReusePool) {
        return;
    }
    
    if (_specifier.url == nil) {
        return;
    }
    
    __weak CKNetworkImageComponentView *weakSelf = self;
    [self startLoaderWithTintColor:[UIColor colorWithRed:18.0f/255.0f green:156.0f/255.0f blue:207.0f/255.0f alpha:1.0f]];
    _download = [_specifier.imageDownloader downloadImageWithURL:_specifier.url
                                                       scenePath:_specifier.scenePath
                                                          caller:self
                                                   callbackQueue:dispatch_get_main_queue()
                                           downloadProgressBlock:^(CGFloat progress)
                 {
                     [weakSelf updateImageDownloadProgress:progress];
                 }
                                                      completion:^(CGImageRef image, NSError *error, NSData *imageData)
                 {
                     [weakSelf reveal];
                     [weakSelf didDownloadImage:image error:error data:imageData];
                 }];
}

- (void)updateContentsRect
{
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    // If we're about to crop the width or height, make sure the cropped version won't be upscaled
    CGFloat croppedWidth = self.image.size.width * _specifier.cropRect.size.width;
    CGFloat croppedHeight = self.image.size.height * _specifier.cropRect.size.height;
    if ((_specifier.cropRect.size.width == 1 || croppedWidth >= self.bounds.size.width) &&
        (_specifier.cropRect.size.height == 1 || croppedHeight >= self.bounds.size.height)) {
        self.layer.contentsRect = _specifier.cropRect;
    }
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateContentsRect];
}

@end
