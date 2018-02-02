#import <Foundation/Foundation.h>
#include "VideoFileParser.h"

const uint8_t KStartCode[4] = {0, 0, 0, 1};

@implementation VideoPacket
- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}
@end

@interface VideoFileParser ()
{
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
}
@property NSString *fileName;
@property NSInputStream *fileStream;
@end

@implementation VideoFileParser

-(BOOL)open:(NSString *)fileName
{
    _bufferSize = 0;
    _bufferCap = 512 * 1024;
    _buffer = malloc(_bufferCap);
    self.fileName = fileName;
    
    //NSInputStream is an abstract class representing the base functionality of a read stream.
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:fileName];
    [self.fileStream open];

    return YES;
}

-(VideoPacket*)nextPacket
{
    NSLog(@"before _bufferSize = %ld",_bufferSize);
    if(_bufferSize < _bufferCap && self.fileStream.hasBytesAvailable) {
        /*
         - (NSInteger) :(uint8_t *)buffer maxLength:(NSUInteger)len;
         从流中读取数据到 buffer 中，buffer 的长度不应少于 len，该接口返回实际读取的数据长度（该长度最大为 len）。
         
         - (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len;
         获取当前流中的数据以及大小，注意 buffer 只在下一个流操作之前有效。
         
         - (BOOL)hasBytesAvailable;
         检查流中是否还有数据。
         */
        NSInteger readBytes = [self.fileStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        _bufferSize += readBytes;
    } else {
        NSLog(@"_bufferSize > _bufferCap");
    }
    NSLog(@"next _bufferSize = %ld",_bufferSize);
//    NSLog(@"%s ,%s",KStartCode,_buffer);
//    if(memcmp(_buffer, KStartCode, 4) != 0) {
//        return nil;
//    }
    
    if(_bufferSize >= 5) {
        uint8_t *bufferBegin = _buffer + 3;
        uint8_t *bufferEnd = _buffer + _bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {  //这里要注意的是，传入的H.264数据需要Mp4风格的，就是开始的 四个字节 是数据的长度而不是“00 00 00 01”的start code，四个字节的长度是big-endian的。
                
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {  //memcmp是比较内存区域buf1和buf2的前count个字节。该函数是按字节比较的. 当buf1<buf2时，返回值-1; 当buf1==buf2时，返回值=0; 当buf1>buf2时，返回值1
                    
                    NSLog(@"%s,%s",bufferBegin - 3,KStartCode);
                    NSInteger packetSize = bufferBegin - _buffer - 3;
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _buffer, packetSize);  //void *memcpy(void *dest, const void *src, size_t n)  memcpy函数的功能是从源src所指的内存地址的起始位置开始拷贝n个字节到目标dest所指的内存地址的起始位置中。
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);  //void *memmove( void* dest, const void* src, size_t count );  memmove用于从src拷贝count个字节到dest，如果目标区域和源区域有重叠的话，memmove能够保证源串在被覆盖之前将重叠区域的字节拷贝到目标区域中。但复制后src内容会被更改。但是当目标区域与源区域没有重叠则和memcpy函数功能相同。
                    _bufferSize -= packetSize;
                    
//                    NSLog(@"return vp");
                    return vp;
                }
            }
//            NSLog(@"++bufferBegin");
            ++bufferBegin;
        }
    }

    return nil;
}

-(void)close
{
    free(_buffer);
    [self.fileStream close];
}

@end