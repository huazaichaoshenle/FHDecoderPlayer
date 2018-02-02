//
//  OpenglVC.m
//  SDLPlayerDemo
//
//  Created by fy on 2016/10/13.
//  Copyright © 2016年 LY. All rights reserved.
//
//这里县渲染的是一张yuv图片,如果想渲染一段yuv视频,需要对yuv视频进行分割并循环,若屏幕出现绿色或打印说参数错误,一般是视频/图片的宽高不对引起的,请仔细查看资源宽高属性,视频目前需要一些特别的参数,我目前是写死的,这样很不好,后面有空了我会将他们进行合理的优化
#import "OpenglVC.h"

//#import <OpenGLES/ES3/gl.h>

#import <GLKit/GLKit.h>
#import "OpenGLFrameView.h"
#import "OpenglView.h"
#import "VideoFileParser.h"
//文件名
//#define filePathName @"jpgimage1_image_640_480.yuv"

#define screenSize [UIScreen mainScreen].bounds.size


#warning 这里参数一定要正确!
//yuv数据宽度
#define videoW 640
//yuv数据高度
#define videoH 480

@interface OpenglVC () {
    
    UIImageView *glV;
    UIImageView *glV2;
    
    VideoFileParser *parser;
    
    OpenGLFrameView *_opengl;
    
    VSDecoderPlayer *vsPlayer;
}

@end

@implementation OpenglVC
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    glV = [[UIImageView alloc] init];
//    glV.hidden = YES;
    glV.backgroundColor = [UIColor lightGrayColor];
    glV.frame = CGRectMake(0, 100, self.view.bounds.size.width, 300);
    [self.view addSubview:glV];
    
    glV2 = [[UIImageView alloc] init];
    //    glV.hidden = YES;
    glV2.backgroundColor = [UIColor lightGrayColor];
    glV2.frame = CGRectMake(0, 400, 100, 100);
    [self.view addSubview:glV2];
    
//    _opengl=[[OpenGLFrameView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 300)];
//    _opengl.backgroundColor = [UIColor redColor];
//    [self.view addSubview:_opengl];
    
    UIButton *butt = [UIButton buttonWithType:UIButtonTypeCustom];
    butt.frame = CGRectMake(50, 500, 100, 40);
    [butt setBackgroundColor:[UIColor redColor]];
    [butt setTitle:@"播放" forState:UIControlStateNormal];
    [self.view addSubview:butt];
    [butt addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *butt2 = [UIButton buttonWithType:UIButtonTypeCustom];
    butt2.frame = CGRectMake(240, 500, 100, 40);
    [butt2 setBackgroundColor:[UIColor redColor]];
    [butt2 setTitle:@"截图" forState:UIControlStateNormal];
    [self.view addSubview:butt2];
    [butt2 addTarget:self action:@selector(captureImage:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)captureImage:(UIButton *)butt {
    UIImage *result = [vsPlayer captureImage];
    glV2.image = result;
    NSLog(@"result=%@",result);
}

- (void)playVideo:(UIButton *)butt {
    
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //
    //        VSDecoderPlayer *vsPlayer = [[VSDecoderPlayer alloc] init];
    //        [vsPlayer decodeFile:@"720p" fileExt:@"264" glView:glV];
    //    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        vsPlayer = [[VSDecoderPlayer alloc] initDecoderPlayerWith:H264Coder decoderMode:VideoToolBox];
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

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
//    [parser close];
}
- (void)updateDecodedH264FrameData: (H264YUV_Frame*)yuvFrame {
    
//    dispatch_async(dispatch_get_main_queue(), ^{
    //这个方法 运行在 iOS11以及iOS11以上的真机会奔溃
//        [_opengl render:yuvFrame];
//    });
}
@end
