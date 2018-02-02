//
//  VideoToolVC.m
//  VSDecoderPlayerText
//
//  Created by none on 17/9/29.
//  Copyright © 2017年 fuhua. All rights reserved.
//

#import "VideoToolVC.h"
#import "AAPLEAGLLayer.h"
#import "VideoFileParser.h"
#import "OpenGLFrameView.h"

@interface VideoToolVC () {
    
    UIImageView *glV;
    
    VideoFileParser *parser;
    
    AAPLEAGLLayer *_opengl;
    
    UIImageView *imgV;
}

@end

@implementation VideoToolVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    glV = [[UIImageView alloc] init];
    glV.frame = CGRectMake(0, 100, self.view.bounds.size.width, 300);
    [self.view addSubview:glV];
    

    UIButton *butt = [UIButton buttonWithType:UIButtonTypeCustom];
    butt.frame = CGRectMake(50, 500, 100, 40);
    [butt setBackgroundColor:[UIColor redColor]];
    [butt setTitle:@"播放" forState:UIControlStateNormal];
    [self.view addSubview:butt];
    [butt addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)playVideo:(UIButton *)butt {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        VSDecoderPlayer *vsPlayer = [[VSDecoderPlayer alloc] init];
        vsPlayer.updateDelegate = self;
        vsPlayer.bReturnYuv = YES;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"720p" ofType:@"264"];
        
        parser = [VideoFileParser alloc];
        [parser open:path];
        
        VideoPacket *vp = nil;
        while(true) {
            vp = [parser nextPacket];
            if(vp == nil) {
                break;
            }
            
            [vsPlayer DecodeVideoData:vp.buffer withLenth:vp.size withImageView:glV];
        }
        [parser close];
    });
}


- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
//    [parser close];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateDecodedH264FrameData: (H264YUV_Frame*)yuvFrame {
    
//    [_opengl render:yuvFrame];
    
}

@end
