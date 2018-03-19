//
//  XRTCPProtocol_HK.m
//  SocketTestDemo
//
//  Created by 369 on 2018/3/8.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRTCPProtocol_HK.h"
#import "YMSocketUtils.h"
#import <objc/runtime.h>

NSString * const TYPE_UINT8 = @"TC"; // char是1个字节，8位
NSString * const TYPE_UINT16 = @"TS"; // short是2个字节，16位
NSString * const TYPE_UINT32 = @"TI";
NSString * const TYPE_UINT64 = @"TQ";
NSString * const TYPE_STRING = @"T@\"NSString\"";
NSString * const TYPE_ARRAY = @"T@\"NSArray\"";

#define kContentOrignPoint 7
#define kReadContentEndPoint(DataLength) (length - 1)

// 星软客户端协议包
@implementation XRTCPProtocol_Basic

// 编码(协议值、body)
- (NSData *)encodePack
{
    NSMutableData *mutableData = [NSMutableData data];
    self.Head = XRCP_HEAD;
    self.Tail = XRCP_TAIL;
    
    [mutableData appendData:[YMSocketUtils byteFromUInt8:self.Head]];
    [mutableData appendData:[YMSocketUtils bytesFromUInt16:self.Length]];
    [mutableData appendData:[YMSocketUtils bytesFromUInt16:self.ProtocolValue]];
    [mutableData appendData:[YMSocketUtils bytesFromUInt16:self.ResCode]];
    [mutableData appendData:[self encodeBody]];
    [mutableData replaceBytesInRange:NSMakeRange(1, 2) withBytes:[[YMSocketUtils bytesFromUInt16:
                                                                   [mutableData length] + 1] bytes]];
    [mutableData appendData:[YMSocketUtils byteFromUInt8:[self calcXorWithData:mutableData startPos:1 endPos:(int)[mutableData length] - 1]]];
    [mutableData appendData:[YMSocketUtils byteFromUInt8:self.Tail]];
    
    return [self escapeWithData:mutableData dataLength:(int)[mutableData length]];
}

// 解码
- (BOOL)decodePackWithData:(NSData *)data length:(int)length;
{
    Byte *buf = (Byte *)[data bytes];
    if (buf[0] != XRCP_HEAD || buf[length - 1] != XRCP_TAIL) {
        return false;
    }
    // 1、逆转义包
    NSData *unEscapeData = [self unEscapeWithData:data dataLength:(int)[data length]];
    length = [unEscapeData length];
    // 2、判断校验和
    uint8_t bXor = [self calcXorWithData:unEscapeData startPos:1 endPos:length - 2];
    if (bXor != 0) {
        return NO;
    }
    // 3、反序列化
    self.Head = [YMSocketUtils uint8FromBytes:[unEscapeData subdataWithRange:NSMakeRange(0, 1)]];
    self.Length = [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[unEscapeData subdataWithRange:NSMakeRange(1, 2)]]];
    self.ProtocolValue = [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[unEscapeData subdataWithRange:NSMakeRange(3, 2)]]];
    self.ResCode = [YMSocketUtils uint16FromBytes:[unEscapeData subdataWithRange:NSMakeRange(5, 2)]];
    
    // 反编译消息体
    [self decodeBodyWithData:[unEscapeData subdataWithRange:NSMakeRange(7, length - 9)]];
    
    self.CheckValue = [YMSocketUtils uint8FromBytes:[unEscapeData subdataWithRange:NSMakeRange(length - 2, 1)]];
    self.Tail = [YMSocketUtils uint8FromBytes:[unEscapeData subdataWithRange:NSMakeRange(length - 1, 1)]];
    return YES;
}

- (BOOL)decodeBodyWithData:(NSData *)data
{
    return NO;
}


// 转义包
- (NSData *)escapeWithData:(NSData *)data dataLength:(int)length
{
    Byte *buf = (Byte *)[data bytes];
    NSMutableData *escapeData = [NSMutableData data];
    [escapeData appendData:[YMSocketUtils byteFromUInt8:buf[0]]];
    for (int i = 1; i < length - 1 ; i++) {
        if (buf[i] == XRCP_HEAD || buf[i] == XRCP_ESCAPE) {
            [escapeData appendData:[YMSocketUtils byteFromUInt8:XRCP_ESCAPE]];
            [escapeData appendData:[YMSocketUtils byteFromUInt8:buf[i] ^ 0x20]];
        } else {
            [escapeData appendData:[YMSocketUtils byteFromUInt8:buf[i]]];
        }
    }
    [escapeData appendData:[YMSocketUtils byteFromUInt8:buf[length - 1]]];
    return escapeData;
}

// 逆转义包
- (NSData *)unEscapeWithData:(NSData *)data dataLength:(int)length
{
    Byte *buf = (Byte *)[data bytes];
    NSMutableData *unEscapeData = [NSMutableData data];
    [unEscapeData appendData:[YMSocketUtils byteFromUInt8:buf[0]]];
    for (int i = 1; i < length - 1; i++) {
        if (buf[i] == XRCP_ESCAPE) {
            i++;
            [unEscapeData appendData:[YMSocketUtils byteFromUInt8:buf[i] ^ 0x20]];
        } else {
            [unEscapeData appendData:[YMSocketUtils byteFromUInt8:buf[i]]];
        }
    }
    [unEscapeData appendData:[YMSocketUtils byteFromUInt8:buf[length - 1]]];
    return unEscapeData;
}

// 计算校验和
- (uint8_t)calcXorWithData:(NSData *)data startPos:(int)startPos endPos:(int)endPos
{
    uint8_t bXor = 0;
    Byte *buf = (Byte *)[data bytes];
    for (int i = startPos; i <= endPos; i++) {
        bXor = bXor ^ buf[i];
    }
    return bXor;
}

@end

// 身份验证 ProtocolValue = 0x35
@implementation XRTCPProtocol_Login

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ProtocolValue = 0x35;
    }
    return self;
}

// 编码消息体
- (NSData *)encodeBody
{
    NSMutableData *buf = [NSMutableData data];
    
    NSString *string = @"123456";
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *data = [string dataUsingEncoding:encoding];
    if ([data length] > 36) {
        data = [data subdataWithRange:NSMakeRange(0, 36)];
    } else {
        NSMutableData *mutableData = [NSMutableData dataWithData:data];
        for (int i = 0; i < 36 - [data length]; i++) {
            [mutableData appendData:[@"0" dataUsingEncoding:encoding]];
        }
    }
    [buf appendData:data];
    
    return buf;
}

@end

// 身份验证应答 ProtocolValue = 0x35
@implementation XRTCPProtocol_LoginAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ProtocolValue = 0x35;
    }
    return self;
}

@end

// 心跳包 ProtocolValue = 0x05
@implementation XRTCPProtocol_Contact

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ProtocolValue = 0x05;
    }
    return self;
}

// 编码消息体
- (NSData *)encodeBody
{
    NSMutableData *buf = [NSMutableData data];
    
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitWeekday|NSCalendarUnitNanosecond fromDate:currentDate];
//    self.sysTime = {[components year],[components month],[components ] };
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components year]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components month]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components weekday]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components day]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components hour]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components minute]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components second]]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[components nanosecond] / 1000000]];
    return buf;
}


// 解码消息体
- (BOOL)decodeBodyWithData:(NSData *)data
{
    SYSTEMTIME time  = {[YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(0, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(2, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(4, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(6, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(8, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(10, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(12, 2)]]],
        [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[data subdataWithRange:NSMakeRange(14, 2)]]]};
    self.sysTime = time;
    /*
    self.sysTime = SYSTEMTIMEMake([YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(0, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(2, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(4, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(6, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(8, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(10, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(12, 2)]]],
                                  [YMSocketUtils uint16FromBytes:[YMSocketUtils dataWithReverse:[self.BodyData subdataWithRange:NSMakeRange(14, 2)]]]);
     */
    return YES;
}


@end

/**    视频 ProtocolValue = 0x40   **/

// 视频相关协议
@implementation XRTCPProtocol_Video

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ProtocolValue = 0x40;
    }
    return self;
}

@end

// 查询通道信息 videoCmd = 0x01 中心
@implementation XRTCPProtocol_VideoChannel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x01;
        self.senderType = 3;
    }
    return self;
}

@end

/*
 
 // 封装数据
 - (NSMutableData*)RequestSpliceAttribute:(id)obj
 {
 unsigned int numIvars; // 成员变量个数
 
 objc_property_t *propertys = class_copyPropertyList(NSClassFromString([NSString stringWithUTF8String:object_getClassName(obj)]), &numIvars);
 
 NSString *type = nil;
 NSString *name = nil;
 
 NSMutableData *mutableData = [NSMutableData data];
 
 for (int i = 0; i < numIvars ; i++) {
 objc_property_t thisProperty = propertys[i];
 name = [NSString stringWithUTF8String:property_getName(thisProperty)];
 NSLog(@"%d.name:%@",i, name);
 type = [[[NSString stringWithUTF8String:property_getAttributes(thisProperty)] componentsSeparatedByString:@","] objectAtIndex:0]; // 变量类型 字符串
 
 id propertyValue = [obj objectForKey:[name substringFromIndex:0]];
 NSLog(@"%d.propertyValue:%@", i, propertyValue);
 
 NSLog(@"\n");
 
 if ([type isEqualToString:TYPE_UINT8]) {
 
 }
 }
 
 return mutableData;
 }
 */
