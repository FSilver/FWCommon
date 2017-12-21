//
//  FWProgressHUD.h
//  UIViewTest
//
//  Created by silver on 2017/9/5.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    //UIActivityIndicatorView.
    FWProgressHUDModeIndeterminate = 1,
    //Shows only label.
    FWProgressHUDModeText = 2,
    //Shows custom view.
    FWProgressHUDModeCustomView = 3,
    
} FWProgressHUDMode;


@interface FWProgressHUD : UIView

/**
 * Default is FWProgressHUDModeIndeterminate.
 */
@property (nonatomic,assign) FWProgressHUDMode mode;

/**
 *  The minmum distance between bezelView and hud view.
 *  Default is 20.f
 */
@property (assign, nonatomic) CGFloat margin;

/**
 * The color of label ,indicator.
 * Default is blackColor.
 */
@property(nonatomic,strong)UIColor *contentColor;

/**
 * covering entire hud erea, placed behind bezelView.
 */
@property(nonatomic,strong,readonly) UIView *backgroundView;

/**
 * The view contains labels and indicator.
 */
@property(nonatomic,strong,readonly) UIView *bezelView;

/**
 * The label in bezelView for tips text.
 */
@property(nonatomic,strong,readonly) UILabel *label;


@property(nonatomic,strong)UIView *customView;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 * Init frame with view's bounds. Called method show.
 */
+ (instancetype)showHUDAddedTo:(UIView*)view;

/**
 * Remove self from super view.
 */
+ (BOOL)hideHUDForView:(UIView*)view;

/**
 * Init frame with view's bounds.
 */
- (instancetype)initWithView:(UIView*)view;

/**
 * Show self to super view.
 * Ensure super view exists.
 */
- (void)show;

/**
 * Remove self from super view.
 */
- (void)hide;

/**
 * Remove self from super view after delay.
 */
- (void)hideAfterDelay:(NSTimeInterval)delay;

@end
