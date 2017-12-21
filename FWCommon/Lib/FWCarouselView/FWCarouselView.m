//
//  FWCarouselView.m
//  FWCarouselExample
//
//  Created by silver on 2017/9/8.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import "FWCarouselView.h"

NSString *const kReuseIdentifier = @"FWCarouseCell";

/** 
 * This value shoule be even numbers (偶数)  and  >= 4.
 */
static const int multiplier = 4;

typedef void (^ItemBlock)(NSString *url,NSInteger index);

@interface FWCarouseCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *label;

@end

@implementation FWCarouseCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UIImageView *imageView = [[UIImageView alloc] init];
        _imageView = imageView;
        [self.contentView addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        _label = label;
        [self.contentView addSubview:label];

    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _imageView.frame = self.bounds;
    _label.frame = self.bounds;
}

@end



@interface FWCarouselView()<UICollectionViewDelegate,UICollectionViewDataSource>
{
    UICollectionViewFlowLayout *_flowLayout;
    UICollectionView *_collectionView; 
    NSTimer *_scrollTimer;
    
    NSInteger _currentItemIndex;
    NSInteger _totalItemCount;
}
@property(nonatomic,copy)ItemBlock block;

@end

@implementation FWCarouselView

-(instancetype)init{
    NSAssert(false, @"Use initWithFrame .");
    self = [super init];
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if(self){
        
        _autoRollTime = 3.f;
        
        
        self.backgroundColor = [UIColor lightGrayColor];
        [self setUpCollectionView];
        
    }
    return self;
}

-(void)setUpCollectionView {
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _flowLayout = flowLayout;
    flowLayout.itemSize = self.bounds.size;
    
    UICollectionView *collection = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    collection.backgroundColor = [UIColor clearColor];
    collection.pagingEnabled = YES;
    collection.showsHorizontalScrollIndicator = NO;
    collection.showsVerticalScrollIndicator = NO;
    [collection registerClass:[FWCarouseCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    collection.dataSource = self;
    collection.delegate = self;
    collection.scrollsToTop = NO;
    
    [self addSubview:collection];
    _collectionView = collection;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _totalItemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FWCarouseCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
    
    NSInteger index = indexPath.item % self.imageUrls.count;
    NSString *imageUrl = self.imageUrls[index];
    cell.label.text = [NSString stringWithFormat:@"%@ %ld",imageUrl,indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index = indexPath.item % self.imageUrls.count;
    NSString *imageUrl = self.imageUrls[index];
    if(self.block){
        self.block(imageUrl, index);
    }
    NSLog(@"%ld : %@",indexPath.row,imageUrl);
}

-(void)clickWithItem:(void(^)(NSString *url,NSInteger index))block {
    
    self.block = block;
}

/**
 * 手动滑动完毕后，会触发此方法
 */
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    CGFloat offsetX = scrollView.contentOffset.x;
    
    CGFloat x = offsetX / scrollView.frame.size.width;
    
    float max = _totalItemCount;
    float min = 0;
    
    NSInteger index = 0;
    
    if(x< min+0.5){
        
        index = min;
        
    }else if(x >= max-0.5){
        
        index = max;
        
    }else{
        
        index = (x+0.5)/1;
    }
    
    _currentItemIndex = [self getCurrentItemIndex:index];
    [self scrollToItem:_currentItemIndex animation:NO];
}


-(NSInteger)getCurrentItemIndex:(NSInteger)index {
    
    if(_totalItemCount <= 1){
        return 0;
    }
    
    if(index == 0){
        
        return multiplier/2 * _imageUrls.count;
        
    }else if(index == _totalItemCount - 1){
        
        return index - (multiplier/2 * _imageUrls.count);
        
    }else{
        
        return index;
    }
}



-(void)scrollToItem:(NSInteger)index animation:(BOOL)animation {
    
    if(index < _totalItemCount){
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:animation];
    }
    
}


#pragma mark - set


-(void)setImageUrls:(NSArray<NSString *> *)imageUrls {
    
    _imageUrls = imageUrls;
    _totalItemCount =  (imageUrls.count > 1)? imageUrls.count*multiplier : imageUrls.count;
    [_collectionView reloadData];
    
    
    _currentItemIndex = [self getCurrentItemIndex:0];
    [self scrollToItem:_currentItemIndex animation:NO];
    
    [self addTimer];
}


-(void)addTimer {
    
    if(_autoRollTime <= 0){
        return;
    }
    if(_scrollTimer){
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:_autoRollTime target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:_scrollTimer forMode:NSRunLoopCommonModes];
}

-(void)autoScroll {
    
    if(_autoRollTime <= 0){
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
    
    if(_imageUrls.count <= 1){
        return;
    }
    
    if(_collectionView.tracking || _collectionView.isDragging ||  _collectionView.decelerating){
        NSLog(@"scrollView is busy.");
        return;
    }
    
    NSInteger index = [self getCurrentItemIndex:_currentItemIndex];
    if(index != _currentItemIndex){
        [self scrollToItem:index animation:NO];
    }
    _currentItemIndex = index + 1;
    [self scrollToItem:_currentItemIndex animation:YES];

}




@end















