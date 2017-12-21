//
//  WJItemsControlView.h
//  SliderSegment
//
//  Created by silver on 15/11/3.
//  Copyright (c) 2015年 Fsilver. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FWItemsConfig : NSObject

/**
 *  子控件单元宽度
 */
@property(nonatomic,assign)float itemWidth; 

/**
 *  文字大小 default is 16
 */
@property(nonatomic,strong)UIFont *itemFont;       

/**
 *  文字颜色 default is COLOR_Gray_Dark
 */
@property(nonatomic,strong)UIColor *textColor;    

/**
 *  文字选中后的颜色 default is COLOR_Green
 */
@property(nonatomic,strong)UIColor *selectedColor; 

/**
 *  下划线宽度 / 单元格宽度 default is 0.8
 */
@property(nonatomic,assign)float linePercent; 

/**
 *  下划线绝对高度default is 2.5
 */
@property(nonatomic,assign)float lineHieght;   


@end




@interface FWItemsControlView : UIScrollView

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

//初始化
-(id)initWithFrame:(CGRect)frame config:(FWItemsConfig*)config titles:(NSArray*)titles;

//当前选中的第几个
-(NSInteger)getCurrentSelectedIndex;

//点击第几个
-(void)tapAtIndex:(void(^)(NSInteger index,BOOL animation))tap;

//called in scrollViewDidScroll
-(void)moveToIndex:(float)index; 

//called in scrollViewDidEndDecelerating
-(void)endMoveToIndex:(float)index;  


@end
