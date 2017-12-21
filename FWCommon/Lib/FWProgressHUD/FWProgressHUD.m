//
//  FWProgressHUD.m
//  UIViewTest
//
//  Created by silver on 2017/9/5.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import "FWProgressHUD.h"

#define FWMainThreadAssert() NSAssert([NSThread isMainThread], @"FWProgressHUD must be called in main thread.");

@interface FWProgressHUD()
{
    NSTimer *_timer;
    
    UIView *_indicatorView;
    NSArray *_bezelConstraints;
}
@end

@implementation FWProgressHUD


+(instancetype)showHUDAddedTo:(UIView *)view {
    
    FWProgressHUD *hud = [[FWProgressHUD alloc]initWithView:view];
    [view addSubview:hud];
    [hud show];
    return hud;
}

+ (BOOL)hideHUDForView:(UIView*)view {
    
    UIView *hud = nil;
    for (UIView *subView in view.subviews) {
        
        if([subView isKindOfClass:self]){
         
            hud = subView;
            break;
        }
    }
    if(hud){
        [(FWProgressHUD*)hud hide];
        return YES;
    }
    return NO;
}


- (instancetype)initWithView:(UIView*)view {
    NSAssert(view, @"view must not be nil.");
    self = [super initWithFrame:view.bounds];
    if(!self) return nil;
    
    self.alpha = 0.f;
    [self commonInit];
    [self updateConstraints];
    
    return self;
}


-(void)commonInit {
    
    _margin = 20.f;
    _contentColor = [UIColor whiteColor];
    _mode = FWProgressHUDModeIndeterminate;
    
    _backgroundView = [[UIView alloc]initWithFrame:self.bounds];
    [self addSubview:_backgroundView];
    
    _bezelView = [[UIView alloc]init];
    _bezelView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.6];
    _bezelView.translatesAutoresizingMaskIntoConstraints = NO;
    _bezelView.layer.cornerRadius = 5.f;
    _bezelView.alpha = 3.f;
    [self addSubview:_bezelView];

    UILabel *label = [UILabel new];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:16.f];
    label.opaque = NO;
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textColor = _contentColor;
    _label = label;
    [_bezelView addSubview:label];
    
    [self udpateIndicators];
}


-(void)udpateIndicators {
    
    switch (_mode) {
        case FWProgressHUDModeIndeterminate:
        {
            [_indicatorView removeFromSuperview];
            
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [indicator setTintColor:[UIColor redColor]];
            [indicator startAnimating];
            indicator.translatesAutoresizingMaskIntoConstraints = NO;
            indicator.color = _contentColor;
            [self.bezelView addSubview:indicator];
            _indicatorView = indicator;
        }
            break;
        case FWProgressHUDModeText:
        {
            [_indicatorView removeFromSuperview];
            _indicatorView = nil;
        }
            break;
        case FWProgressHUDModeCustomView:
        {
            [_indicatorView removeFromSuperview];
            if(_customView){
                
                _customView.translatesAutoresizingMaskIntoConstraints = NO;
                [self.bezelView addSubview:_customView];
                _indicatorView = _customView;
                
                CGFloat width = _customView.frame.size.width;
                CGFloat height = _customView.frame.size.height;
                NSLayoutConstraint *constraintWidth = [NSLayoutConstraint constraintWithItem:_customView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.f constant:width];
                NSLayoutConstraint *constraintHeight = [NSLayoutConstraint constraintWithItem:_customView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.f constant:height];
                [_customView addConstraint:constraintWidth];
                [_customView addConstraint:constraintHeight];
            }
        }
            break;
    } 
    
    [self setNeedsUpdateConstraints];
}




#pragma mark - override
-(void)layoutSubviews {
    
    [self setNeedsUpdateConstraints];
    [super layoutSubviews];
}


-(void)updateConstraints {
    
    UIView *bezel = _bezelView;
    CGFloat margin = _margin;
    NSDictionary *metrics = @{@"margin": @(margin)};
    
    // Remove existing constraints
    [self removeConstraints:self.constraints];
   
    if (_bezelConstraints) {
        [bezel removeConstraints:_bezelConstraints];
        _bezelConstraints = nil;
    }

    NSMutableArray *bezelConstraints = [NSMutableArray array];
    NSMutableArray *subviews = [NSMutableArray arrayWithObjects:_label, nil];
    if (_indicatorView) {
        [subviews insertObject:_indicatorView atIndex:0];
    }
    

    //make bezel'center equal to self's center.
    CGPoint offset = CGPointMake(0, 0);
    NSMutableArray *centeringConstraints = [NSMutableArray array];
    [centeringConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_backgroundView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:offset.x]];
    [centeringConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_backgroundView attribute:NSLayoutAttributeCenterY multiplier:1.f constant:offset.y]];
    [self addConstraints:centeringConstraints];
    
    // Ensure minimum side margin is kept
    NSMutableArray *sideConstraints = [NSMutableArray array];
    [sideConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=margin)-[bezel]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(bezel)]];
    [sideConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=margin)-[bezel]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(bezel)]];
    [self applyConstraints:sideConstraints property:998.f];
    [self addConstraints:sideConstraints];

    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
       
        // set view Center in bezel
        [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        [bezelConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=margin)-[view]-(>=margin)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:metrics views:NSDictionaryOfVariableBindings(view)]];
        
        if (idx == 0) {
            // First, ensure spacing to bezel edge
            [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeTop multiplier:1.f constant:margin]];
        } 
        
        if (idx == subviews.count - 1) {
            // Last, ensure spacing to bezel edge
            [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeBottom multiplier:1.f constant:-margin]];
        }
        
        if (idx > 0) {
            // Has previous
            NSLayoutConstraint *padding = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:subviews[idx - 1] attribute:NSLayoutAttributeBottom multiplier:1.f constant:0.f];
            [bezelConstraints addObject:padding];

        }
    }];
    
    [self addConstraints:bezelConstraints];
    _bezelConstraints = bezelConstraints;
    [super updateConstraints];
}

-(void)applyConstraints:(NSArray*)constraints property:(CGFloat)priority {
    
    [constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        obj.priority = priority;
        
    }];
    
    
}

#pragma mark - change

-(void)setMode:(FWProgressHUDMode)mode {
    
    FWMainThreadAssert();
    if(_mode != mode){
        _mode = mode;
        [self udpateIndicators];
    }
}

-(void)setCustomView:(UIView *)customView {
    
    FWMainThreadAssert();
    if(_customView != customView){
        _customView = customView;
        if(self.mode == FWProgressHUDModeCustomView){
            [self udpateIndicators];
        }
    }
}



#pragma mark - show & hidden

-(void)show {
    
    FWMainThreadAssert();
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1.f;
    } completion:^(BOOL finished) {
        
    }];
    
    
    
}

-(void)hide {
    
    FWMainThreadAssert();
    if(_timer){
        [_timer invalidate];
        _timer = nil;
    }
    
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)hideAfterDelay:(NSTimeInterval)delay {
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(hide) userInfo:nil repeats:NO];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
