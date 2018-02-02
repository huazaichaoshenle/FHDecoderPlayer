//
//  VSDecoderPlayer.h
//  VSDecoderPlayerText
//
//  Created by none on 17/7/17.
//  Copyright © 2017年 fuhua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OpenglView.h"
#import "AAPLEAGLLayer.h"
#import "DecodeH264Data_YUV.h"

typedef enum {
    H264Coder,
    H265Coder,
} CoderMode;

typedef enum {
    VideoToolBox,
    Ffmpeg,
} decoderMode;



@protocol H264FrameDelegate <NSObject>

@optional
- (void)updateDecodedH264FrameData: (H264YUV_Frame*)yuvFrame;
@end


@interface VSDecoderPlayer : NSObject

@property(nonatomic,assign)BOOL bReturnYuv;
@property(nonatomic,readonly,assign) NSInteger coderModer;
@property(nonatomic,readonly,assign) NSInteger decoderMode;

@property (nonatomic,weak)id<H264FrameDelegate> updateDelegate;

/**
 abstract: init VSDecoderPlayer
 @param  coderMode: set type from CoderMode
 @param  decoderMode:  set type from decoderMode
 @result  instance of VSDecoderPlayer
 */
- (id)initDecoderPlayerWith:(CoderMode)coderMode decoderMode:(decoderMode)decoderMode;

/**
 abstract: decoder videoBuffer which is start with 00 00 00 01
 @param  char *: video data
 @param  lenth:  video lenth
 @param  imgV: the view which will display video data
 @result  1 is success; 0 is failed
 */
- (int)DecodeVideoData: (char *)buffer withLenth:(NSInteger)lenth withImageView:(UIImageView *)imgV;

/**
 abstract: captureImage
 @param  char *: video data
 @param  lenth:  video lenth
 @param  imgV: the view which will display video data
 @result  1 is success; 0 is failed
 */
- (UIImage *)captureImage;

- (void)releasePlayer;

@end
