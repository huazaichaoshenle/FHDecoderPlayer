//
//  ViewController.m
//  VSDecoderPlayerText
//
//  Created by none on 17/7/17.
//  Copyright © 2017年 fuhua. All rights reserved.
//

#import "ViewController.h"
#import "OpenglView.h"
#import "VSDecoderPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
//    OpenglView *glV = [[OpenglView alloc] init];
//    glV.backgroundColor = [UIColor lightGrayColor];
//    glV.frame = CGRectMake(50, 200, 200, 200);
//    [self.view addSubview:glV];
    
    UIImageView *glV = [[UIImageView alloc] init];
    glV.backgroundColor = [UIColor lightGrayColor];
    glV.frame = CGRectMake(50, 200, 200, 200);
    [self.view addSubview:glV];
    
    
    VSDecoderPlayer *vsPlayer = [[VSDecoderPlayer alloc] init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"720p" ofType:@"264"];
//    [vsPlayer decoderVideoFile:path withView:glV];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
