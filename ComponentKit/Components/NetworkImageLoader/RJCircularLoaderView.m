//
//  DSFancyLoaderView.m
//  Design Shots
//
//  Created by Rounak Jain on 19/12/14.
//  Copyright (c) 2014 Rounak Jain. All rights reserved.
//

#import "RJCircularLoaderView.h"

#define MAX_RADIUS 20

@interface RJCircularLoaderView ()
@property (nonatomic, strong) CAShapeLayer *circlePathLayer;
@end

@implementation RJCircularLoaderView

+ (CGFloat)radiusForPoint:(CGPoint)point
{
    return sqrtf((point.x*point.x) + (point.y*point.y));
}

+ (CGFloat)distanceBetweenPoint1:(CGPoint)point1 point2:(CGPoint)point2
{
    return [self radiusForPoint:CGPointMake(point1.x - point2.x, point1.y - point2.y)];
}

- (CGPathRef)circlePath
{
    CGRect circleFrame = CGRectMake(0, 0, 2*MAX_RADIUS, 2*MAX_RADIUS);
    circleFrame.origin.x = CGRectGetMidX(self.circlePathLayer.bounds) - CGRectGetMidX(circleFrame);
    circleFrame.origin.y = CGRectGetMidY(self.circlePathLayer.bounds) - CGRectGetMidY(circleFrame);
    return [UIBezierPath bezierPathWithOvalInRect:circleFrame].CGPath;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _circlePathLayer = [CAShapeLayer layer];
        _circlePathLayer.frame = self.bounds;
        _circlePathLayer.lineWidth = 6;
        _circlePathLayer.fillColor = [UIColor clearColor].CGColor;
        _circlePathLayer.strokeStart = 0;
        _circlePathLayer.strokeColor = self.tintColor.CGColor;
        _circlePathLayer.strokeEnd = 0;
        [self.layer addSublayer:_circlePathLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.circlePathLayer.frame = self.bounds;
    self.circlePathLayer.path = self.circlePath;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.circlePathLayer.strokeColor = self.tintColor.CGColor;
}

- (void)reveal
{
    // 1
    //backgroundColor = UIColor.clearColor()
    //progress = 1
    self.backgroundColor = [UIColor clearColor];
    self.progress = 1;
    
    // 2
    //circlePathLayer.removeAnimationForKey("strokeEnd")
    [self.circlePathLayer removeAnimationForKey:NSStringFromSelector(@selector(strokeEnd))];
    
    // 3
    //circlePathLayer.removeFromSuperlayer()
    //superview?.layer.mask = circlePathLayer
    [self.circlePathLayer removeFromSuperlayer];
}

- (void)setProgress:(CGFloat)progress
{
    if (progress > 1) {
        progress = 1;
    }
    if (progress < 0) {
        progress = 0;
    }
    _progress = progress;
    self.circlePathLayer.strokeEnd = _progress;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.superview.layer.mask = nil;
    [self.circlePathLayer removeAllAnimations];
    [self removeFromSuperview];
}

@end
