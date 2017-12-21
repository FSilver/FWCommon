//
//  FWMonitorView.m
//  LearnDemo
//
//  Created by Lizhi on 2017/12/15.
//  Copyright © 2017年 WSX. All rights reserved.
//

#import "FWMonitorView.h"
#import "FWMonitorMgr.h"


typedef enum {
    ViewStatusPanel = 1,
    ViewStatusTable = 2,
    ViewStatusText = 3
}ViewStatus;

@interface  FWMonitorView()<UITableViewDelegate,UITableViewDataSource>
{
    //Moved
    BOOL _canMove;
    CGPoint _lastPoint;
    
    //性能面板
    UILabel *_panelLabel;
    
    //卡顿tableView
    UITableView *_tableView;
    NSMutableArray *_dataArray;
    UIView *_headerView;
    
    //UITextView
    UITextView *_textView;
    
    //status
    ViewStatus _status;
}
@end

@implementation FWMonitorView

+(instancetype)monitor
{
    FWMonitorView  *view = [[FWMonitorView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-120, 100, 120, 100)];
    return view;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self)return nil;
    _status = ViewStatusPanel;
    [self createTableView];
    [self cteatTextView];
    [self createLabel];
    [self start];
    return self;
}

#pragma mark  - careteViews

-(void)createLabel
{
    _panelLabel = [[UILabel alloc]initWithFrame:self.bounds];
    _panelLabel.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.8];
    _panelLabel.numberOfLines = 0;
    _panelLabel.font = [UIFont systemFontOfSize:16];
    _panelLabel.userInteractionEnabled = YES;
    _panelLabel.textColor = [UIColor whiteColor];
    [self addSubview:_panelLabel];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClicked)];
    tap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tap];
    
}

-(void)tapClicked
{
    switch (_status) {
        case ViewStatusPanel:
        {
            _tableView.hidden = NO;
            _textView.hidden = YES;
            _status = ViewStatusTable;
        }
            break;
        case ViewStatusTable:
        {
            _tableView.hidden = YES;
            _textView.hidden = YES;
            _status = ViewStatusPanel;
        }
            break;
        case ViewStatusText:
        {
            _tableView.hidden = NO;
            _textView.hidden = YES;
            _status = ViewStatusTable;
        }
            break;
            
        default:
            break;
    }
    _tableView.frame = self.superview.bounds;
    _textView.frame = self.superview.bounds;
    [self getTableHeade];
    [self.superview addSubview:_tableView];
    [self.superview addSubview:_textView];
    [self.superview addSubview:self];
}

#pragma mark  - tableView

-(void)createTableView
{
    _dataArray = [NSMutableArray array];
    _tableView = [[UITableView alloc]init];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.hidden = YES;
    _tableView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"FWANRInfoTableCell"];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

-(void)getTableHeade
{
    if(!_headerView){
        _headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 84)];
        
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 20, _headerView.frame.size.width, 30)];
        [btn setTitle:@"清空ANRS,本地日志除外" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clearBtn) forControlEvents:UIControlEventTouchUpInside];
        [_headerView addSubview:btn];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, btn.frame.size.height + btn.frame.origin.y, _headerView.frame.size.width, _headerView.frame.size.height-(btn.frame.size.height + btn.frame.origin.y))];
        label.textColor = [UIColor blackColor];
        label.text = @"点击Cell，查看每次卡顿的详情，双击浮窗返回";
        label.textAlignment = NSTextAlignmentCenter;
        [_headerView addSubview:label];
      
    }
    _tableView.tableHeaderView = _headerView;
}

-(void)clearBtn
{
    [[FWMonitorMgr sharedInstance]cleanANRs];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FWANRInfoTableCell" forIndexPath:indexPath];
    
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.numberOfLines = 0;
    NSString *anrStr = [_dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = anrStr;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *anrStr = [_dataArray objectAtIndex:indexPath.row];
    _textView.text = anrStr;
    _textView.hidden = NO;
    _status = ViewStatusText;
}

#pragma mark  - textView
-(void)cteatTextView
{
    _textView = [[UITextView alloc]init];
    _textView.editable = NO;
    _textView.hidden = YES;
    _status = ViewStatusText;
}

#pragma mark  - 接入数据
-(void)start {
    
    FWMonitorMgr *mgr = [FWMonitorMgr sharedInstance];
    [mgr reciveInfo:^(FWPerformanceInfo *info) {
        [self updateWithInfo:info];
    }];
    [mgr reciveANR:^(NSArray *anrs) {
        [self updateANR:anrs];
    }];
    [mgr start];
}

-(void)updateWithInfo:(FWPerformanceInfo*)info
{
    _panelLabel.text = [info descriptionInMultiLines];
}

-(void)updateANR:(NSArray*)array
{
    [_dataArray removeAllObjects];
    [_dataArray addObjectsFromArray:array];
    [_tableView reloadData];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _canMove = YES;  
    _lastPoint = [[touches anyObject]locationInView:self.superview];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject]locationInView:self.superview];
    
    float x = point.x - _lastPoint.x;
    float y = point.y - _lastPoint.y;
    
    CGRect rect = self.frame;
    rect.origin.x += x;
    rect.origin.y += y;
    
    
    if(rect.origin.x <=0){
        rect.origin.x = 0;
    }
    if(rect.origin.x >= self.superview.frame.size.width - rect.size.width){
        rect.origin.x = self.superview.frame.size.width - rect.size.width;
    }
    
    if(rect.origin.y <=0){
        rect.origin.y = 0;
    }
    if(rect.origin.y >= self.superview.frame.size.height - rect.size.height){
        rect.origin.y = self.superview.frame.size.height - rect.size.height;
    }
    
    self.frame = rect;
    _lastPoint = point;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    
}



@end
