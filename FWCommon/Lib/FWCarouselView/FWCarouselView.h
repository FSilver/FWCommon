//
//  FWCarouselView.h
//  FWCarouselExample
//
//  Created by silver on 2017/9/8.
//  Copyright © 2017年 Fsilver. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWCarouselView : UIView

/**
 * Auto roll time for each Image. 
 */
@property(nonatomic,assign) NSTimeInterval autoRollTime;

/**
 * The urls of images.
 */
@property(nonatomic,strong) NSArray<NSString*> *imageUrls;

-(instancetype)new UNAVAILABLE_ATTRIBUTE;
-(instancetype)init UNAVAILABLE_ATTRIBUTE;

-(void)clickWithItem:(void(^)(NSString *url,NSInteger index))block;

@end
