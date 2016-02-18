//
//  DRPLoadingSpinner.m
//  DRPLoadingSpinner
//
//  Created by Justin Hill on 11/11/14.
//  Copyright (c) 2014 Justin Hill. All rights reserved.
//

#import "DRPLoadingSpinner.h"

#define kInvalidatedTimestamp -1

@interface DRPLoadingSpinner ()

@property BOOL isAnimating;
@property NSUInteger colorIndex;
@property CAShapeLayer *circleLayer;
@property CALayer *circleContainer;
@property CGFloat drawRotationOffsetRadians;
@property BOOL isFirstCycle;

@end

@implementation DRPLoadingSpinner

#pragma mark - Life cycle
- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self refreshCircleFrame];
}

- (void)refreshCircleFrame {
    CGFloat sideLen = MIN(self.layer.frame.size.width, self.layer.frame.size.height) - (2 * self.lineWidth);
    CGFloat xOffset = ceilf((self.frame.size.width - sideLen) / 2.0);
    CGFloat yOffset = ceilf((self.frame.size.height - sideLen) / 2.0);
    
    self.circleContainer.frame = CGRectMake(xOffset, yOffset, sideLen, sideLen);
    self.circleLayer.frame = self.circleContainer.bounds;
    self.circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, sideLen, sideLen)].CGPath;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    
    self.drawCycleDuration = 1;
    self.rotationCycleDuration = 2;
    
    self.minimumArcLength = M_PI_4;
    
    self.colorSequence = @[
        [UIColor redColor],
        [UIColor orangeColor],
        [UIColor purpleColor],
        [UIColor blueColor]
    ];
    
    self.lineWidth = 2.;
    
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    
    self.circleContainer = [CALayer layer];
    self.circleContainer.frame = self.bounds;
    
    self.circleLayer = [[CAShapeLayer alloc] init];
    self.circleLayer.fillColor = [UIColor clearColor].CGColor;
    self.circleLayer.strokeColor = [self.colorSequence[0] CGColor];
    self.circleLayer.anchorPoint = CGPointMake(.5, .5);
    self.circleLayer.frame = self.bounds;
    [self refreshCircleFrame];
}


#pragma mark - Animation control
- (void)startAnimating {
    
    self.circleLayer.hidden = NO;
    [self.circleLayer removeAllAnimations];
    
    self.isAnimating = YES;
    self.isFirstCycle = YES;
    self.colorIndex = 0;
    self.circleLayer.lineWidth = self.lineWidth;
    self.circleLayer.strokeEnd = [self proportionFromArcLengthRadians:self.minimumArcLength];
    
    self.drawRotationOffsetRadians = 0;
    self.circleLayer.actions = @{@"transform": [NSNull null]};
    
    [self animateStrokeOnLayer:self.circleLayer reverse:NO];
//    [self animateRotationOnLayer:self.circleLayer];
}

- (void)animateStrokeOnLayer:(CAShapeLayer *)layer reverse:(BOOL)reverse {
    
    
    CGFloat maxArcLengthRadians = (2 * M_PI) - self.minimumArcLength;
    CABasicAnimation *strokeAnimation;
    
    if (reverse) {
        [CATransaction begin];
        
        strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        CGFloat newStrokeStart = maxArcLengthRadians - self.minimumArcLength;
        
        layer.strokeEnd = [self proportionFromArcLengthRadians:maxArcLengthRadians];
        layer.strokeStart = [self proportionFromArcLengthRadians:newStrokeStart];
        
        strokeAnimation.fromValue = @(0);
        strokeAnimation.toValue = @([self proportionFromArcLengthRadians:newStrokeStart]);
        
    } else {
        if (!self.isFirstCycle) {
            self.drawRotationOffsetRadians -= (2 * self.minimumArcLength);
        }
        
        layer.strokeStart = 0;
        layer.strokeEnd = self.minimumArcLength;
        
        CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.fromValue = @(self.drawRotationOffsetRadians);
        rotationAnimation.toValue = @(self.drawRotationOffsetRadians + (2 * M_PI));
        rotationAnimation.duration = self.rotationCycleDuration;
        rotationAnimation.repeatCount = CGFLOAT_MAX;
        rotationAnimation.fillMode = kCAFillModeForwards;
        [layer addAnimation:rotationAnimation forKey:nil];
        
        [CATransaction begin];
        
        strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeAnimation.fromValue = @([self proportionFromArcLengthRadians:self.minimumArcLength]);
        strokeAnimation.toValue = @([self proportionFromArcLengthRadians:maxArcLengthRadians]);
    }
    
    strokeAnimation.delegate = self;
    strokeAnimation.fillMode = kCAFillModeForwards;
    [CATransaction setAnimationDuration:self.drawCycleDuration];
    [layer removeAnimationForKey:@"strokeEnd"];
    [layer removeAnimationForKey:@"strokeStart"];
    
    NSLog(@"%@", layer.animationKeys);
    [layer addAnimation:strokeAnimation forKey:nil];
    
    [CATransaction commit];
    
    self.isFirstCycle = NO;
}

- (void)animateRotationOnLayer:(CALayer *)layer {
    [CATransaction begin];
    
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"affineTransform"];
    rotation.fromValue = [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    rotation.toValue = [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(M_PI)];
    rotation.repeatCount = CGFLOAT_MAX;
    rotation.duration = 3.0;
    
    [layer addAnimation:rotation forKey:nil];
    
    [CATransaction commit];
}

- (CGFloat)proportionFromArcLengthRadians:(CGFloat)radians {
    return ((fmodf(radians, 2 * M_PI)) / (2 * M_PI));
}

- (void)stopAnimating {
    self.isAnimating = NO;
    [self.circleLayer removeAllAnimations];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    if (!self.circleLayer.superlayer) {
        [self.layer addSublayer:self.circleLayer];
    }
}

#pragma mark - Auto Layout
- (CGSize)intrinsicContentSize {
    return CGSizeMake(40, 40);
}

#pragma mark - Easing
- (double)sinEaseInOutWithCurrentTime:(double)t startVal:(double)b change:(double)c duration:(double)d {
    return -c/2 * (cos(M_PI * t / d) - 1) + b;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSLog(@"Animation stopped: %p, finished: %ld", anim, (long)flag);
    if (flag) {
        if ([anim isKindOfClass:[CABasicAnimation class]]) {
            CABasicAnimation *basicAnim = (CABasicAnimation *)anim;
            
            BOOL isStrokeStart = [basicAnim.keyPath isEqualToString:@"strokeStart"];
            BOOL isStrokeEnd = [basicAnim.keyPath isEqualToString:@"strokeEnd"];
            
            if (isStrokeStart || isStrokeEnd) {
                [self animateStrokeOnLayer:self.circleLayer reverse:isStrokeEnd];
            }
        }
    }
}

@end
