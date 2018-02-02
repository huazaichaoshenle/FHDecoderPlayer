//
//  VSDecoderPlayer.m
//  VSDecoderPlayerText
//
//  Created by none on 17/7/17.
//  Copyright © 2017年 fuhua. All rights reserved.
//

#import "VSDecoderPlayer.h"
#import <pthread/pthread.h>
#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libswscale/swscale.h"

#import <VideoToolbox/VideoToolbox.h>
#import <GLKit/GLKit.h>
#import "OpenGLFrameView.h"
#import "OpenglView.h"

pthread_mutex_t g_cs;
BOOL b_cs = NO;

@implementation VSDecoderPlayer {
    
    pthread_mutex_t m_cs;
    
    AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    AVPicture picture;
    AVPacket avpkt;
    AVCodec  *pCodec;
    struct SwsContext *img_convert_ctx;
    UIImage *rgbImage;
    
    int frameWidth;
    int frameHeight;
    
    
    OpenGLFrameView *_opengl;
    
    // 硬解码
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    H264YUV_Frame    yuvFrame;
    UIImage *toolBoxImage;
}

- (id)initDecoderPlayerWith:(CoderMode)coderMode decoderMode:(decoderMode)decoderMode {
    
    self = [super init];
    if (self) {
        
        _coderModer = coderMode;
        _decoderMode = decoderMode;
        
        if (![self adaptDecoderMode]) {
            return nil;
        }
    }
    
    return self;
}

- (BOOL)initFfmpeg {
    
    // init ffmpeg
    av_register_all();
    avcodec_register_all();
    
    if (!b_cs) {
        pthread_mutex_init(&g_cs, NULL);
        b_cs = YES;
    }
    pthread_mutex_init(&m_cs, NULL);
    
    pthread_mutex_lock(&g_cs);
    av_init_packet(&avpkt);
    
    if (_coderModer == H265Coder) {
        pCodec = avcodec_find_decoder(AV_CODEC_ID_H265);
    } else {
        pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    }
    
    if(pCodec == NULL)
    {
        pthread_mutex_unlock(&g_cs);
        return NO;
    }
    pCodecCtx = avcodec_alloc_context3(pCodec);
    // Allocate video frame
    pFrame = av_frame_alloc();
    if(pFrame == NULL)
    {
        pthread_mutex_unlock(&g_cs);
        return NO;
    }
    
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        pthread_mutex_unlock(&g_cs);
        return NO;
    }
    rgbImage = [[UIImage alloc] init];
    pthread_mutex_unlock(&g_cs);
    
    return YES;
}

- (BOOL)adaptDecoderMode {
    if (_coderModer == H265Coder) {
        _decoderMode = Ffmpeg;
    }
    
    if (_decoderMode == VideoToolBox) {
        NSString *versionStr = [[UIDevice currentDevice].systemVersion substringToIndex:2];
        if ([versionStr integerValue] < 8) {
            _decoderMode = Ffmpeg;
        }
    }
    
    if (_decoderMode == Ffmpeg) {
        if (![self initFfmpeg]) {
            return NO;
        }
    }
    return YES;
}

- (id)init {
    
    self = [super init];
    if (self) {
        
        _coderModer = H264Coder;
        _decoderMode = VideoToolBox;
        
        if (![self adaptDecoderMode]) {
            return nil;
        }
    }
    
    return self;
}

#pragma mark--外部接口
- (int)DecodeVideoData: (char *)buffer withLenth:(NSInteger)lenth withImageView:(UIImageView *)imgV {
    
    if (_decoderMode == VideoToolBox) {        // 硬 解 码
        
        if ([self videoToolDecoder:buffer withLenth:lenth withImageView:imgV] == 0) {
            return 0;
        }
        
    } else {     // 软 解 码
        
        if ([self ffmpegDecoder:buffer withLenth:lenth withImageView:imgV] == 0) {
            return 0;
        }
    }
    
    return 1;
}

- (UIImage *)captureImage {
    
    if (_decoderMode == VideoToolBox) {
        
        return toolBoxImage;
        
    } else {
        pthread_mutex_lock(&m_cs);
        UIImage *img = [_opengl snapshotPicture];
        pthread_mutex_unlock(&m_cs);
        return img;
    }
    
    return nil;
}

- (void)releasePlayer {
    
    if (_decoderMode == VideoToolBox) {
        
        
        
    } else {
        if (img_convert_ctx) {
            sws_freeContext(img_convert_ctx);
            img_convert_ctx = NULL;
        }
        
        if (pFrame) {
            av_free(pFrame);
            pFrame = NULL;
        }
        if (pCodecCtx){
            avcodec_close(pCodecCtx);
            pCodec = NULL;
        }
    }
}



void copyDecodedFrame(unsigned char *src, unsigned char *dist,int linesize, int width, int height)
{
    
    width = MIN(linesize, width);
    
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dist, src, width);
        dist += width;
        src += linesize;
    }
}

- (void)updateYUVFrameOnMainThread:(H264YUV_Frame*)yuvFrame
{
    if(yuvFrame!=NULL){
        if([self.updateDelegate respondsToSelector:@selector(updateDecodedH264FrameData: )]){
            
            [self.updateDelegate updateDecodedH264FrameData:yuvFrame];
            
        }
    }
}

#pragma mark--软解码
- (int)ffmpegDecoder: (char *)buffer withLenth:(NSInteger)lenth withImageView:(UIImageView *)imgV {
    
    pthread_mutex_lock(&m_cs);
    
    avpkt.size = (int)lenth;
    avpkt.data = (void *)buffer;
    
    while (avpkt.size) {

        int frameFinished,len;
        len = avcodec_send_packet(pCodecCtx, &avpkt);
        frameFinished = avcodec_receive_frame(pCodecCtx, pFrame);
//        len =  avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &avpkt);
//        if (len!= avpkt.size) {
//            NSLog(@"^^^^^^^^^^^^^^_________^^^^^^^^^^ len=%d,finished=%d",len,frameFinished);
//        }
        if (frameFinished != 0) {
            pthread_mutex_unlock(&m_cs);
            return 0;
        }

        //创建并 给 H264YUV_Frame 赋值
        unsigned int lumaLength= (pCodecCtx->height)*(MIN(pFrame->linesize[0], pCodecCtx->width));
        unsigned int chromBLength=((pCodecCtx->height)/2)*(MIN(pFrame->linesize[1], (pCodecCtx->width)/2));
        unsigned int chromRLength=((pCodecCtx->height)/2)*(MIN(pFrame->linesize[2], (pCodecCtx->width)/2));
        
        memset(&yuvFrame, 0, sizeof(H264YUV_Frame));
        
        yuvFrame.luma.length = lumaLength;
        yuvFrame.chromaB.length = chromBLength;
        yuvFrame.chromaR.length =chromRLength;
        
        yuvFrame.luma.dataBuffer=(unsigned char*)malloc(lumaLength);
        yuvFrame.chromaB.dataBuffer=(unsigned char*)malloc(chromBLength);
        yuvFrame.chromaR.dataBuffer=(unsigned char*)malloc(chromRLength);
        
        copyDecodedFrame(pFrame->data[0],yuvFrame.luma.dataBuffer,pFrame->linesize[0],
                         pCodecCtx->width,pCodecCtx->height);
        copyDecodedFrame(pFrame->data[1], yuvFrame.chromaB.dataBuffer,pFrame->linesize[1],
                         pCodecCtx->width / 2,pCodecCtx->height / 2);
        copyDecodedFrame(pFrame->data[2], yuvFrame.chromaR.dataBuffer,pFrame->linesize[2],
                         pCodecCtx->width / 2,pCodecCtx->height / 2);
        
        yuvFrame.width=pCodecCtx->width;
        yuvFrame.height=pCodecCtx->height;
        yuvFrame.dataLenth = lenth;
        
        // 回传yuvFrame给应用层
        if (_bReturnYuv) {
            
            [self updateYUVFrameOnMainThread:(H264YUV_Frame*)&yuvFrame];
        }
        
        //渲染显示
        if (pFrame->width != 0) {
        
            if (_opengl == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    _opengl = [[OpenGLFrameView alloc] initWithFrame:imgV.bounds];
                    [imgV addSubview:_opengl];
                });
            }
            
            [_opengl render:(H264YUV_Frame*)&yuvFrame];
            
            free(yuvFrame.luma.dataBuffer);
            free(yuvFrame.chromaB.dataBuffer);
            free(yuvFrame.chromaR.dataBuffer);
            pthread_mutex_unlock(&m_cs);
            
//            avpicture_free(&picture);
//            sws_freeContext(img_convert_ctx);
//            avpicture_alloc(&picture, AV_PIX_FMT_RGB24,frameWidth, frameHeight);
//
//            img_convert_ctx = sws_getContext(frameWidth,
//                                             frameHeight,
//                                             AV_PIX_FMT_YUV420P,
//                                             frameWidth,
//                                             frameHeight,
//                                             AV_PIX_FMT_RGB24,
//                                             SWS_FAST_BILINEAR, NULL, NULL, NULL);
//            pthread_mutex_unlock(&m_cs);
            
            return 1;
        }
        
        free(yuvFrame.luma.dataBuffer);
        free(yuvFrame.chromaB.dataBuffer);
        free(yuvFrame.chromaR.dataBuffer);
    }
    return 0;
}


-(void)decoderYUVtoRGB:(UIImageView *)imgV
{
    if (img_convert_ctx) {
        if (pFrame->width != pCodecCtx->width) {
            
            NSLog(@"sws_scale function error!!!!!!!!");
            return;
        }
        sws_scale (img_convert_ctx, pFrame->data, pFrame->linesize,
                   0, pCodecCtx->height,
                   picture.data, picture.linesize);
        
        @try {
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
            //CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, picture.data[0], picture.linesize[0]*frameHeight,kCFAllocatorNull);
            CFDataRef data = CFDataCreate(kCFAllocatorDefault, picture.data[0], picture.linesize[0]*frameHeight);
            CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGImageRef cgImage = CGImageCreate(frameWidth,
                                               frameHeight,
                                               8,
                                               24,
                                               frameWidth*3,
                                               colorSpace,
                                               bitmapInfo,
                                               provider,
                                               NULL,
                                               NO,
                                               kCGRenderingIntentDefault);
            
            CGColorSpaceRelease(colorSpace);
            
            UIImage *image = [[UIImage alloc]initWithCGImage:cgImage];
            rgbImage = image;
            
            CGImageRelease(cgImage);
            CGDataProviderRelease(provider);
            CFRelease(data);
        }
        @catch (NSException *exception) {
            NSLog(@"exception !!!!!");
        }
        @finally {
            //        NSLog(@"finally");
        }

        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                pthread_mutex_lock(&m_cs);
                imgV.image = rgbImage;
                pthread_mutex_unlock(&m_cs);
            }
            @catch (NSException *exception) {
                NSLog(@"updateimage exception !!!!!");
            }
            @finally {
                
            }
        });
    }
}


#pragma mark --  硬解码
//http://www.jianshu.com/p/dac9857b34d0     http://www.jianshu.com/p/58920f8b8879    http://www.jianshu.com/p/dac9857b34d0
- (int)videoToolDecoder: (char *)buffer withLenth:(NSInteger)lenth withImageView:(UIImageView *)imgV {
    
    if(buffer == NULL) {
        return 0;
    }
    uint32_t nalSize = (uint32_t)(lenth - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    buffer[0] = *(pNalSize + 3);
    buffer[1] = *(pNalSize + 2);
    buffer[2] = *(pNalSize + 1);
    buffer[3] = *(pNalSize);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = buffer[4] & 0x1F;
    switch (nalType) {
        case 0x05:
            //                NSLog(@"Nal type is IDR frame");  //IDR图像的编码条带
            if([self initH264Decoder]) {
                pixelBuffer = [self decode:buffer withLenth:lenth];
            }
            break;
        case 0x07:
            //                NSLog(@"Nal type is SPS");  //序列参数集
            _spsSize = lenth - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, buffer + 4, _spsSize);
            break;
        case 0x08:
            //                NSLog(@"Nal type is PPS");   //图像参数集
            _ppsSize = lenth - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, buffer + 4, _ppsSize);
            break;
            
        default:
            NSLog(@"Nal type is B/P frame");
            pixelBuffer = [self decode:buffer withLenth:lenth];
            break;
    }
    
    // http://www.jianshu.com/p/dac9857b34d0   
    //可得到像素的存储方式是Planar或Chunky
    if (pixelBuffer && _bReturnYuv) {
    
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        BOOL isPlanear = CVPixelBufferIsPlanar(pixelBuffer);
        if (isPlanear) {
            //通过 CVPixelBufferGetPlaneCount获取YUV Plane 数量
            /*
             通常是两个Plane，Y为一个Plane，UV 由 VTDecompressionSessionCreate 创建解码会话时通过destinationImageBufferAttributes指定需要的像素格式（可不同于视频源像素格式）决定是否同属一个Plane，每个Plane可当作表格按行列处理，像素是行顺序填充的。下面以Planar Buffer存储方式作说明。
             */
            NSInteger num = CVPixelBufferGetPlaneCount(pixelBuffer);
            NSLog(@"%ld",num);
            
            
            unsigned int frameW = (unsigned int)CVPixelBufferGetWidth(pixelBuffer);
            unsigned int frameH = (unsigned int)CVPixelBufferGetHeight(pixelBuffer);
            
            //而CVPixelBufferGetBaseAddress返回的Planar  Buffer则是指向PlanarComponentInfo结构体的指针
            CVPlanarComponentInfo *planarComponInfoY = NULL,*planarComponInfoU = NULL,*planarComponInfoV = NULL;
            if (num == 2) {
                planarComponInfoY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
                planarComponInfoU = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
                planarComponInfoV = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
            } else if (num == 3) {
                planarComponInfoY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
                planarComponInfoU = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
                planarComponInfoV = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
            }
            
            unsigned int lumaLength= frameH*(MIN(planarComponInfoY->rowBytes, frameW));
            unsigned int chromBLength=(frameH/2)*(MIN(planarComponInfoU->rowBytes, frameW/2));
            unsigned int chromRLength=(frameH/2)*(MIN(planarComponInfoV->rowBytes, frameW/2));
            
            if (planarComponInfoY) {
                
                memset(&yuvFrame, 0, sizeof(H264YUV_Frame));
                
                yuvFrame.luma.length = lumaLength;
                yuvFrame.chromaB.length = chromBLength;
                yuvFrame.chromaR.length =chromRLength;
                
                yuvFrame.luma.dataBuffer=(unsigned char*)malloc(lumaLength);
                yuvFrame.chromaB.dataBuffer=(unsigned char*)malloc(chromBLength);
                yuvFrame.chromaR.dataBuffer=(unsigned char*)malloc(chromRLength);
                
                
                memcpy(yuvFrame.luma.dataBuffer, planarComponInfoY, lumaLength);
                memcpy(yuvFrame.chromaB.dataBuffer, planarComponInfoU, chromBLength);
                memcpy(yuvFrame.chromaR.dataBuffer, planarComponInfoV, chromRLength);
                
                yuvFrame.width=frameW;
                yuvFrame.height=frameH;
                yuvFrame.dataLenth = lenth;
//                dispatch_sync(dispatch_get_main_queue(), ^{
                
                    [self updateYUVFrameOnMainThread:(H264YUV_Frame*)&yuvFrame];
//                });
                
                free(yuvFrame.luma.dataBuffer);
                free(yuvFrame.chromaB.dataBuffer);
                free(yuvFrame.chromaR.dataBuffer);
            }
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
    
    //渲染
    if(pixelBuffer) {
        
        
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                                 createCGImage:ciImage
                                 fromRect:CGRectMake(0, 0,
                                                     CVPixelBufferGetWidth(pixelBuffer),
                                                     CVPixelBufferGetHeight(pixelBuffer))];
        
        toolBoxImage = [[UIImage alloc] initWithCGImage:videoImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            imgV.image = toolBoxImage;
        });
        CGImageRelease(videoImage);
        CVPixelBufferRelease(pixelBuffer);
    }

    return 1;
}

    
-(CVPixelBufferRef)decode:(char *)buffer withLenth:(NSInteger)lenth {
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)buffer, lenth,
                                                          kCFAllocatorNull,
                                                          NULL, 0, lenth,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {lenth};
        //根据上述得到CMVideoFormatDescriptionRef、CMBlockBufferRef和可选的时间信息，使用CMSampleBufferCreate接口得到CMSampleBuffer数据这个待解码的原始的数据
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            //解码得到 CMSampleBufferRef
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}



-(BOOL)initH264Decoder {
    if(_deocderSession) {
        return YES;
    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    
    if(status == noErr) {
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        //kCVPixelBufferPixelFormatTypeKey，指定解码后的图像格式，必须指定成NV12，苹果的硬解码器 只支持 NV12。
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_deocderSession);
        CFRelease(attrs);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
    }
    
    return YES;
}


static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@end
