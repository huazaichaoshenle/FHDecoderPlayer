#include <objc/NSObject.h>

@interface VideoPacket : NSObject

@property uint8_t* buffer;
@property NSInteger size;

@end

@interface VideoFileParser : NSObject

-(BOOL)open:(NSString*)fileName;
-(VideoPacket *)nextPacket;
-(void)close;

/*
 
 libz.tbd
 libbz2.tbd
 libiconv.tbd
 libbz2.1.0.tbd
 libxml2.tbd
 libiconv.2.4.0.tbd 
 ibz.1.2.5.tbd
 */

@end
