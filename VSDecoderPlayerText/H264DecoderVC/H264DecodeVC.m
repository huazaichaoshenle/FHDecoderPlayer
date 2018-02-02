//
//  H264DecodeVC.m
//  FFmpegAndSDLDemo
//
//  Created by fy on 2016/10/20.
//
//

#import "H264DecodeVC.h"
#import "VSDecoderPlayer.h"
#import "H264DecodeTool.h"
#import "VideoFileParser.h"

@interface H264DecodeVC () {
    
    UIImageView *glV;
    
    VideoFileParser *parser;
}


@end

@implementation H264DecodeVC
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    glV = [[UIImageView alloc] init];
    glV.backgroundColor = [UIColor lightGrayColor];
    glV.frame = CGRectMake(0, 100, self.view.bounds.size.width, 400);
    [self.view addSubview:glV];
    
    
    UIButton *butt = [UIButton buttonWithType:UIButtonTypeCustom];
    butt.frame = CGRectMake(50, 540, 100, 40);
    [butt setBackgroundColor:[UIColor redColor]];
    [butt setTitle:@"播放" forState:UIControlStateNormal];
    [self.view addSubview:butt];
    [butt addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)playVideo:(UIButton *)butt {
    
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //
    //        VSDecoderPlayer *vsPlayer = [[VSDecoderPlayer alloc] init];
    //        [vsPlayer decodeFile:@"720p" fileExt:@"264" glView:glV];
    //    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        VSDecoderPlayer *vsPlayer = [[VSDecoderPlayer alloc] initDecoderPlayerWith:H265Coder decoderMode:Ffmpeg];
//        vsPlayer.bReturnYuv = YES;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"3mp" ofType:@"265"];
        
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




@end
