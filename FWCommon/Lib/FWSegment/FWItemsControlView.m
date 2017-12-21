//
//  WJItemsControlView.m
//  SliderSegment
//
//  Created by silver on 15/11/3.
//  Copyright (c) 2015年 Fsilver. All rights reserved.
//

#import "FWItemsControlView.h"


const int baseTag = 100;
typedef void (^FWItemsControlViewTapBlock)(NSInteger index,BOOL animation);

@implementation FWItemsConfig

-(id)init
{
    self = [super init];
    if(self){
        
        _itemWidth = 0;
        _itemFont = [UIFont boldSystemFontOfSize:16];
        _textColor = [UIColor colorWithRed:142/255.0 green:142/255.0 blue:142/255.0 alpha:1];
        _selectedColor = [UIColor colorWithRed:61/255.0 green:209/255.0 blue:165/255.0 alpha:1];
        _linePercent = 0.8;
        _lineHieght = 2.5;
    }
    return self;
}

@end


@interface FWItemsControlView()
{
    UIView *_line;
    FWItemsConfig *_config;
    NSArray *_titleArray;
    BOOL _tapAnimation;
    NSInteger _currentIndex;
}
@property(nonatomic,copy)FWItemsControlViewTapBlock tapBlock;

@end


@implementation FWItemsControlView

-(id)initWithFrame:(CGRect)frame config:(FWItemsConfig *)config titles:(NSArray *)titles {
    
    self = [super initWithFrame:frame];
    if(self){
        
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.scrollsToTop = NO;
        
        _tapAnimation = NO;
        _titleArray = titles;
        _config = config;
        _currentIndex = 0;
        
        
        [self createButtons];
        [self createLine];
        
    }
    return self;
}

-(void)createButtons {
    
    float x = 0;
    float y = 0;
    float width = _config.itemWidth;
    float height = self.frame.size.height;
    
    for (int i=0; i<_titleArray.count; i++) {
        
        x = _config.itemWidth*i;
        
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(x, y, width, height)];
        btn.tag = baseTag+i;
        [btn setTitle:_titleArray[i] forState:UIControlStateNormal];
        [btn setTitleColor:_config.textColor forState:UIControlStateNormal];
        btn.titleLabel.font = _config.itemFont;
        [btn addTarget:self action:@selector(itemButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        
        if(i==0){
            [btn setTitleColor:_config.selectedColor forState:UIControlStateNormal];
        }
    }
    self.contentSize = CGSizeMake(width*_titleArray.count, height);
}

-(void)createLine{
    
    __block CGFloat maxContentWidth = 0;
    [_titleArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        CGRect rect = [obj boundingRectWithSize:CGSizeMake(HUGE, HUGE) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:_config.itemFont} context:nil];
        CGSize size = rect.size;
        if(maxContentWidth < size.width){
            maxContentWidth = size.width;
        }
    }];
    CGFloat minPercent = (maxContentWidth + 4)/_config.itemWidth;
    if(_config.linePercent < minPercent){
        _config.linePercent = minPercent;
    }
    
    if(_config.linePercent > 1.0){
        _config.linePercent = 1.0;
    }
    
    _line = [[UIView alloc] initWithFrame:CGRectMake(_config.itemWidth*(1-_config.linePercent)/2.0, CGRectGetHeight(self.frame) - _config.lineHieght, _config.itemWidth*_config.linePercent, _config.lineHieght)];
    _line.backgroundColor = _config.selectedColor;
    [self addSubview:_line];
}


#pragma mark - 点击事件

-(void)itemButtonClicked:(UIButton*)btn
{
    //接入外部效果
    _currentIndex = btn.tag-baseTag;
    
    if(!_tapAnimation){
        //没有动画，需要手动瞬移线条，改变颜色
        [self changeItemColor:_currentIndex];
        
        //等价于 [self changeLine:_currentIndex]; + 动画
        CGRect rect = _line.frame;
        rect.origin.x = _currentIndex*_config.itemWidth + _config.itemWidth*(1-_config.linePercent)/2.0;
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _line.frame = rect;
        } completion:^(BOOL finished) {
            
        }];
    }
    [self changeScrollOfSet:_currentIndex];
    
    if(self.tapBlock){
        self.tapBlock(_currentIndex, NO);
    }
}

-(NSInteger)getCurrentSelectedIndex {
    return _currentIndex;
}


-(void)tapAtIndex:(void(^)(NSInteger index,BOOL animation))tap {
    
    self.tapBlock = tap;
    
}


#pragma mark - Methods

//改变文字焦点
-(void)changeItemColor:(NSInteger)index
{
    for (int i=0; i<_titleArray.count; i++) {
        
        UIButton *btn = (UIButton*)[self viewWithTag:i+baseTag];
        [btn setTitleColor:_config.textColor forState:UIControlStateNormal];
        if(btn.tag == index+baseTag){
            [btn setTitleColor:_config.selectedColor forState:UIControlStateNormal];
        }
    }
}

//改变线条位置
-(void)changeLine:(float)index
{
    CGRect rect = _line.frame;
    rect.origin.x = index*_config.itemWidth + _config.itemWidth*(1-_config.linePercent)/2.0;
    _line.frame = rect;
}


//向上取整
- (NSInteger)changeProgressToInteger:(float)x
{
    
    float max = _titleArray.count;
    float min = 0;
    
    NSInteger index = 0;
    
    if(x< min+0.5){
        
        index = min;
        
    }else if(x >= max-0.5){
        
        index = max;
        
    }else{
        
        index = (x+0.5)/1;
    }
    
    return index;
}


//移动ScrollView
-(void)changeScrollOfSet:(NSInteger)index
{
    float  halfWidth = CGRectGetWidth(self.frame)/2.0;
    float  scrollWidth = self.contentSize.width;
    
    float leftSpace = _config.itemWidth*index - halfWidth + _config.itemWidth/2.0;
    
    if(leftSpace<0){
        leftSpace = 0;
    }
    if(leftSpace > scrollWidth- 2*halfWidth){
        leftSpace = scrollWidth-2*halfWidth;
    }
    [self setContentOffset:CGPointMake(leftSpace, 0) animated:YES];
}



#pragma mark - 在ScrollViewDelegate中回调
-(void)moveToIndex:(float)x
{
    [self changeLine:x];
    NSInteger tempIndex = [self changeProgressToInteger:x];
    if(tempIndex != _currentIndex){
        //保证在一个item内滑动，只执行一次
        [self changeItemColor:tempIndex];
    }
    _currentIndex = tempIndex;
}

-(void)endMoveToIndex:(float)x
{
    [self changeLine:x];
    [self changeItemColor:x];
    _currentIndex = x;
    [self changeScrollOfSet:x];
}

@end













































