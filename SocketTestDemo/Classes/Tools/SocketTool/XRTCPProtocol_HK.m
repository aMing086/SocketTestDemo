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

#define GBKEncoding CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)

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
    self.Length = [YMSocketUtils uint16FromBytes:[unEscapeData subdataWithRange:NSMakeRange(1, 2)]];
    self.ProtocolValue = [YMSocketUtils uint16FromBytes:[unEscapeData subdataWithRange:NSMakeRange(3, 2)]];
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

- (NSString *)description
{
    unsigned int numIvars; // 成员变量个数
    id obj = self;
    objc_property_t *propertys = class_copyPropertyList(NSClassFromString([NSString stringWithUTF8String:object_getClassName(obj)]), &numIvars);
    
    NSString *type = nil;
    NSString *name = nil;
    
    NSMutableString *tempStr = [NSMutableString string];
    for (int i = 0; i < numIvars ; i++) {
        objc_property_t thisProperty = propertys[i];
        name = [NSString stringWithUTF8String:property_getName(thisProperty)];
        type = [[[NSString stringWithUTF8String:property_getAttributes(thisProperty)] componentsSeparatedByString:@","] objectAtIndex:0]; // 变量类型 字符串
        id propertyValue = [obj objectForKey:[name substringFromIndex:0]];
        [tempStr appendFormat:@"%@:%@\t", name, propertyValue];
    }
    free(propertys);
    return tempStr;
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
    
    // GUID
    NSData *data = [self.GUID dataUsingEncoding:GBKEncoding];
    if ([data length] > 36) {
        data = [data subdataWithRange:NSMakeRange(0, 36)];
    } else {
        NSMutableData *mutableData = [NSMutableData dataWithData:data];
        for (int i = 0; i < 36 - [data length]; i++) {
            [mutableData appendData:[@"0" dataUsingEncoding:GBKEncoding]];
        }
        data = mutableData;
    }
    [buf appendData:data];
    // 用户名
    NSData *userNameData = [self.UserName dataUsingEncoding:GBKEncoding];
    //  用户名长度
    self.nameLen = [userNameData length];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.nameLen]];
    [buf appendData:userNameData];
    
    // 密码
    NSData *passwordData = [self.Password dataUsingEncoding:GBKEncoding];
    // 密码长度
    self.passwordLen = [self.Password length];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.passwordLen]];
    [buf appendData:passwordData];
    
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

- (BOOL)decodeBodyWithData:(NSData *)bodydata
{
    if (bodydata.length != 1) {
        return NO;
    }
    self.bResult = [YMSocketUtils uint8FromBytes:bodydata];
    return YES;
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
- (BOOL)decodeBodyWithData:(NSData *)bodydata
{
    SYSTEMTIME time  = {[YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(0, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(2, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(4, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(6, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(8, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(10, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(12, 2)]],
        [YMSocketUtils uint16FromBytes:[bodydata subdataWithRange:NSMakeRange(14, 2)]]};
    self.sysTime = time;
   
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
        self.senderType = 3; // ios
        self.version = 1;
#warning 序列号 自增 版本？？
        self.seqNo = 1;
    }
    return self;
}

// 编码消息体
- (NSData *)encodeBody
{
    NSMutableData *buf = [NSMutableData data];
    
    [buf appendData:[YMSocketUtils byteFromUInt8:self.version]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.senderType]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.videoCmd]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.seqNo]];
    [buf appendData:[self encodeVideo]];
    return buf;
}

// 解码消息体
- (BOOL)decodeBodyWithData:(NSData *)bodydata
{
    if (bodydata.length < 7) {
        return NO;
    }
    self.version = [YMSocketUtils uint8FromBytes:[bodydata subdataWithRange:NSMakeRange(0, 1)]];
    self.senderType = [YMSocketUtils uint8FromBytes:[bodydata subdataWithRange:NSMakeRange(1, 1)]];
    self.videoCmd = [YMSocketUtils uint8FromBytes:[bodydata subdataWithRange:NSMakeRange(2, 1)]];
    self.seqNo = [YMSocketUtils uint32FromBytes:[bodydata subdataWithRange:NSMakeRange(3, 4)]];
    [self decodeVideoWithData:[bodydata subdataWithRange:NSMakeRange(7, [bodydata length] - 7)]];
    return YES;
}

- (NSData *)encodeVideo
{
    return [NSData data];
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    return NO;
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

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    
    return buf;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 2) {
        return NO;
    }
    ushort lenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(0, 2)]];
    if (data.length != 2 + lenght) {
        return NO;
    }
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(2, lenght)] encoding:GBKEncoding];
    return YES;
}

@end

// class 通道信息
@implementation XR_VideoChannelInfo

@end

// 查询通道信息应答 videoCmd = 0x01 中心
@implementation XRTCPProtocol_VideoChannelAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x01;
        self.senderType = 3;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.respSeqNo]];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNum]];
    for (XR_VideoChannelInfo *channelInfo in self.Channels) {
        [buf appendData:[YMSocketUtils bytesFromUInt32:channelInfo.nChannelNo]];
        [buf appendData:[YMSocketUtils byteFromUInt8:channelInfo.bChannelType]];
    }
    return buf;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    self.seqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(0, 4)]];
    ushort lenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(4, 2)]];
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(6, lenght)] encoding:GBKEncoding];
    self.channelNum = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(lenght + 6, 4)]];
    NSMutableArray *tempArray = [NSMutableArray array];
    int index = lenght + 10;
    for (int i = 0; i < self.channelNum; i++) {
        XR_VideoChannelInfo *channelInfo = [[XR_VideoChannelInfo alloc] init];
        channelInfo.nChannelNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
        index += 4;
        channelInfo.bChannelType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
        index += 1;
        [tempArray addObject:channelInfo];
    }
    self.Channels = tempArray;
    
    return YES;
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
