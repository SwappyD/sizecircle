//
//  NoticeViewController.m
//  DXQ
//
//  Created by 黄修勇 on 12-12-11.
//  Copyright (c) 2012年 http://www.heyuan110.com. All rights reserved.
//

#import "NoticeViewController.h"
#import "UerLoadNoticeList.h"
#import "LoadMoreView.h"
#import "DXQNoticeCenter.h"
#import "UIScrollView+AH3DPullRefresh.h"
#import "NoticeCell.h"
#import "UIImageView+WebCache.h"

@interface NoticeViewController ()<UITableViewDataSource,UITableViewDelegate,BusessRequestDelegate>{

    UerLoadNoticeList *userLoadNoticeRequest;
    LoadMoreView *loadMoreView;
    UIImageView *nodataImageView;
    BOOL isRefrush;
}

@end

@implementation NoticeViewController

-(void)dealloc{

    [self cancelAllRequest];
    [_tableView release];
    [_noticeArray release];
    [loadMoreView release];
    [nodataImageView release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title=AppLocalizedString(@"通知中心");
        self.noticeArray=[[DXQNoticeCenter defaultNoticeCenter]allNotice];
    }
    return self;
}

-(void)loadView{

    [super loadView];
    
    UITableView *tableView=[[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.backgroundColor=[UIColor clearColor];
    tableView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    tableView.delegate=self;
    tableView.dataSource=self;
    self.tableView=tableView;
    [tableView release];
    
    if (!nodataImageView) {
        nodataImageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"nodata"]];
    }
    if (!loadMoreView) {
        loadMoreView=[[LoadMoreView alloc]initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 60.f)];
        [loadMoreView setLoadMoreBlock:^{
            [self requestNoticeListByPage:_noticeArray.count/20+1];
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidDisappear:(BOOL)animated{

    [super viewDidDisappear:animated];
    [self cancelAllRequest];
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    if (!_noticeArray) {
        [self.tableView pullToRefresh];
    }
}

#pragma mark Set

-(void)setTableView:(UITableView *)tableView{

    if ([tableView isEqual:_tableView]) {
        return;
    }
    [_tableView removeFromSuperview];
    [_tableView release];
    _tableView=[tableView retain];
    [self.view addSubview:_tableView];
    
    [_tableView setPullToRefreshHandler:^{
    
        [self requestNoticeListByPage:1];
    }];
}

-(void)setNoticeArray:(NSArray *)noticeArray{

    if ([noticeArray isEqualToArray:_noticeArray]) {
        return;
    }
    [_noticeArray release];
    _noticeArray=[noticeArray retain];
    [self.tableView reloadData];
}

#pragma mark -UITableViewDataSource And Delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    return 75.f;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return _noticeArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *ident=@"notice";
    NoticeCell *cell=[tableView dequeueReusableCellWithIdentifier:ident];
    if (!cell) {
        cell=[[[NoticeCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident] autorelease];
    }
    NSDictionary *dic=[_noticeArray objectAtIndex:indexPath.row];
    [cell.productImageView setImageWithURL:[NSURL URLWithString:[[dic objectForKey:@"PictureUrl"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] success:^(UIImage *image,BOOL isSucces){
        [Tool setImageView:cell.productImageView toImage:image];
    } failure:nil];
    cell.productNameLabel.text=[dic objectForKey:@"Title"];
    cell.exdateLabel.text=[dic objectForKey:@"Content"];
    NSDate *date=[NSDate dateWithTimeIntervalSince1970:[[dic objectForKey:@"OpTime"] floatValue]];
    NSInteger time=-[date timeIntervalSinceNow];
    if (time<60) {
        cell.dateLabel.text=AppLocalizedString(@"刚刚  ");
    }else if (time<60*60&&time>60){
        
        NSString *tempText=[NSString stringWithFormat:@"%d分钟前  ",time/60];
        cell.dateLabel.text=tempText;
    }else if (time<60*60*60&&time>60*60){
        NSString *tempText=[NSString stringWithFormat:@"%d小时前  ",time/60/60];
         cell.dateLabel.text=tempText;
    }else if (time<60*60*60*24&&time>60*60*60){
        NSString *tempText=[NSString stringWithFormat:@"%d天前  ",time/60/60/24];
         cell.dateLabel.text=tempText;
    }else
         cell.dateLabel.text=@"未知";
    return cell;
}

#pragma mark -Request

-(void)cancelAllRequest{

    [self cancelGetNoticeList];
}

-(void)cancelGetNoticeList{

    if (userLoadNoticeRequest) {
        [userLoadNoticeRequest cancel];
        [userLoadNoticeRequest release];
        userLoadNoticeRequest=nil;
    }
}

-(void)requestNoticeListByPage:(NSInteger)page{

    [self cancelGetNoticeList];
    if (page==1) {
        isRefrush=YES;
    }else
        isRefrush=NO;
    
    NSDictionary *pager=[NSDictionary dictionaryWithObjectsAndKeys:
                         [NSString stringWithFormat:@"%d",page],@"PageIndex",
                         [NSString stringWithFormat:@"%d",20],@"ReturnCount", nil];
    NSString *accountID=[[SettingManager sharedSettingManager]loggedInAccount];
    NSDictionary *dic=[NSDictionary dictionaryWithObjectsAndKeys:
                       pager,@"Pager",
                       accountID,@"AccountId",nil];

    loadMoreView.state=LoadMoreStateRequesting;
    userLoadNoticeRequest=[[UerLoadNoticeList alloc]initWithRequestWithDic:dic];
    userLoadNoticeRequest.delegate=self;
    [userLoadNoticeRequest startAsynchronous];
}


-(void)busessRequest:(DXQBusessBaseRequest *)request didFailedWithErrorMsg:(NSString *)msg{

    [[ProgressHUD sharedProgressHUD]showInView:self.view];
    [[ProgressHUD sharedProgressHUD]setText:msg];
    [[ProgressHUD sharedProgressHUD]done:YES];
    if (request==userLoadNoticeRequest) {
        loadMoreView.state=LoadMoreStateNormal;
        [self.tableView refreshFinished];
    }
}

-(void)busessRequest:(DXQBusessBaseRequest *)request didFinishWithData:(id)data{
    
    if (request==userLoadNoticeRequest) {
        if (isRefrush) {
            self.noticeArray=data;
        }else
        {
            NSMutableArray *array=[NSMutableArray arrayWithArray:self.noticeArray];
            [array addObjectsFromArray:data];
            self.noticeArray=array;
        }
        
        if ([data count]==20) {
            self.tableView.tableFooterView=loadMoreView;
        }else
            self.tableView.tableFooterView=nodataImageView;
        
        loadMoreView.state=LoadMoreStateNormal;
        [self.tableView refreshFinished];
    }
}
@end