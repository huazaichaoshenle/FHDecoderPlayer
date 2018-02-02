//
//  MainVC.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/13.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "MainVC.h"

#import "FFmpegVC.h"

#import "OpenglVC.h"

#import "H264DecodeVC.h"

#import "VideoToolVC.h"

#define screenSize [UIScreen mainScreen].bounds.size

@interface MainVC ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
  
    [self createUpUI];
}


#pragma mark -  UI
-(void)createUpUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView * tableView = [[UITableView alloc]init];
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.view addSubview:tableView];
    
    tableView.frame = CGRectMake(0, 0, screenSize.width, 300);
    
    tableView.dataSource = self;
    
    tableView.delegate = self;
}


#pragma mark -  dataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"h264硬解码";
            break;
        case 1:
            cell.textLabel.text = @"h264软解码";
            break;
            
        case 2:
            cell.textLabel.text = @"H265软解码";
            break;
            
        case 3:
            cell.textLabel.text = @"播放器搭建";
            break;
        default:
            cell.textLabel.text = @"";
            break;
    }
    
    return cell;
}

#pragma mark -  delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:
        {
            VideoToolVC * vc = [[VideoToolVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
            
        }
            break;

        case 1:
        {
            OpenglVC * vc = [[OpenglVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

        case 2:
        {
            H264DecodeVC * vc = [[H264DecodeVC alloc]init];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;

//        case 3:
//        {
//            IJKPlayerVC * vc = [[IJKPlayerVC alloc]init];
//            
//            [self.navigationController pushViewController:vc animated:YES];
//        }
//            break;
            
            
            
        default:
            break;
    }
    
}
@end
