# FWCommon
#
## FWItemsControlView 
适用于UIScrollView，精准控制多页内容切换。与UIScrollView联动。另外还提供了Swift版本
##使用方法
配置+创建+关联
### FWItemsConfig--配置
    FWItemsConfig *config = [[WJItemsConfig alloc]init];
    config.itemWidth = widht/4.0;   //item宽度
### FWItemsControlView--创建
    NSArray *array = @[@"新闻",@"房产",@"体育",@"美女",@"文化"];
    WJItemsControlView *itemControlView = [[FWItemsControlView alloc]initWithFrame:CGRectMake(0, 100-44, widht, 44) config:config titles:array];
    [_itemControlView tapAtIndex:^(NSInteger index, BOOL animation) {
        //关联的UIScrollView scrollRectToVisible 到响应的区域
    }];
    [self.view addSubview:_itemControlView];
### UIScrollView--联动
    - (void)scrollViewDidScroll:(UIScrollView *)scrollView
    {
        float offset = scrollView.contentOffset.x;
        offset = offset/CGRectGetWidth(scrollView.frame);
        [_itemControlView moveToIndex:offset];
    }

    - (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
    {
        float offset = scrollView.contentOffset.x;
        offset = offset/CGRectGetWidth(scrollView.frame);
        [_itemControlView endMoveToIndex:offset];
    }
### 使用场景效果图
![FWItemsControlView](https://github.com/FSilver/WJItemControlView/raw/master/demo.png)
#
# FWMonitor
实时性能监控，指标CPU、FPS、Memory、卡顿堆栈显示
## 使用方法
```
FWMonitorView *view = [FWMonitorView monitor];
[[UIApplication sharedApplication].keyWindow addSubView:view];
```
##### 仅仅上面两行代码即可。实时显示:
###### 1 FPS : 程序的当前帧率 0~60
###### 2 CPU : 程序当前cpu使用情况
###### 3 Memory: 程序当前占用内存。注意不是Xcode中直接看到的内存数据，而是和Profile中Activity Monitor检测到的内存数据一致。
###### 4 ANR: 监控程序在使用的过程中卡顿现象，并记录堆栈日志，保存到沙盒。 或者直接双击面板查看。
#
## FWProgressHUD
### Indicator only.
    FWProgressHUD *hud = [FWProgressHUD showHUDAddedTo:self.view];
    [hud hideAfterDelay:2.f];
### Indicator and text.
    FWProgressHUD *hud = [FWProgressHUD showHUDAddedTo:self.view];
    hud.label.text = @"do something";
    [hud hideAfterDelay:2.f];
### Text only
    FWProgressHUD *hud = [FWProgressHUD showHUDAddedTo:self.view];
    hud.mode = FWProgressHUDModeText;
    hud.label.text = @"do something";
    [hud hideAfterDelay:2.f];
### CustomView
    UIView *customView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 150, 50)];
    customView.backgroundColor = [UIColor purpleColor];
            
    FWProgressHUD *hud = [FWProgressHUD showHUDAddedTo:self.view];
    hud.mode = FWProgressHUDModeCustomView;
    hud.customView = customView;
    hud.label.text = @"do something";
    [hud hideAfterDelay:2.f];    
#
# FWDrawView
富文本解析，包括表情，链接，电话号码，自定义链接。折行处理，边距处理等
## 使用方法
三步，使用FWDrawConfig来进行配置，FWDrawParser提供解析方法，FWDrawView绘制富文本
### FWDrawConfig--配置
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280; //文本最大宽度
    config.text = text; //文本内容
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10); //文本上下左右边距
    config.textColor = [UIColor grayColor]; //文本字体颜色
    config.numberOfLines = 0; //文本最大显示行数
    config.linkColor = [UIColor blueColor]; //链接字体颜色
### FWDrawParser--解析
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    [parser parseEmoji];  //解析表情
    [parser parseUrl];    //解析链接
    [parser parsePhone];  //解析电话号码
    [parser addLinkWithValue:@"life" range:NSMakeRange(2, 3)];  //自定义添加，链接文字
### FWDrawView--绘制
    FWDrawInfo *data = parser.data;
    FWDrawView *draw = [[FWDrawView alloc]initWithFrame:CGRectMake(10, 60, data.width, data.height)];
    draw.data = data;
    draw.delegate = self;
    draw.allowTapGesture = YES;
    draw.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    [self.view addSubview:draw];
#### 代理方法
    -(void)didClickFWDraw:(FWDrawView *)draw byLink:(FWDrawLinkInfo *)link
    {
        switch (link.type) {
            case FWLinkURL:
            {
                NSLog(@"点击的是 url   value:%@  text:%@",link.value,link.text);
            }
                break;
            case FWLinkPhoneNumber:
            {
           
                NSLog(@"点击的是 phone   value:%@  text:%@",link.value,link.text);
            }
                break;
            case FWLinkCustom:
            {
            
                NSLog(@"点击的是 自定义链接   value:%@  text:%@",link.value,link.text);
            }
                break;
                
            default:
                break;
        }
    }

    -(void)didClickFWDraw:(FWDrawView *)draw
    {
        NSLog(@"单击");
    }
    #
    # FWCache
FWcache is used to storage key-pairs in memory and disk.
## Disk
FWKDStorage is the base util for disk . When the data is more than 20kb, it saves the data in file. Else it saves the data in sqlite.
FWDiskCache is a thread-safe cache that saved key-value paires by sqlite or file system. It based on FWKDStorage.
## Memory
FWMemoryCahe is a thread-safe cache that saved key-value paires by NSDictionay.

### Create
  FWCache *_cache;
  _cache = [[FWCache alloc]initWithName:@"FWCache2017"];
### Save
  [_cache setObject:@"Object" forKey:@"A" withBlock:^{
                NSLog(@"Object set finished : %d",i);
            }];
### Select
  id object = [_cache objectForKey:@"A"];
### Delete
  [_cache removeObjectForKey:@"A" withBlock:^(NSString *key) {
            NSLog(@"key : %@ is removed",key);
        }];
#


