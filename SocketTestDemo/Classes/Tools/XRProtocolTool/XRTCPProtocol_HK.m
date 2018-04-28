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

// 定义时间结构类(只用于心跳包）
@implementation XRTCPProtocol_SystemTime

- (instancetype)initWithDate:(NSDate *)date
{
    self = [super init];
    if (self) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitWeekday|NSCalendarUnitNanosecond fromDate:date];
        self.wYear = [components year];
        self.wMonth = [components month];
        self.wDayOfWeek = [components weekday];
        self.wDay = [components day];
        self.wHour = [components hour];
        self.wMinute = [components minute];
        self.wSecond = [components second];
        self.wMilliseconds = [components nanosecond] / 1000000;
    }
    return self;
}

- (NSData *)encodeSystemTime
{
    NSMutableData *buf = [NSMutableData data];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wYear]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wMonth]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wDayOfWeek]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wDay]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wHour]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wMinute]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wSecond]];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wMilliseconds]];
    return buf;
}

+ (instancetype)decodeTimeWithData:(NSData *)timeData
{
    XRTCPProtocol_SystemTime *time = [[XRTCPProtocol_SystemTime alloc] init];
    if (timeData.length < 16) {
        return time;
    }
    time.wYear = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(0, 2)]];
    time.wMonth = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(2, 2)]];
    time.wDayOfWeek = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(4, 2)]];
    time.wDay = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(6, 2)]];
    time.wHour = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(8, 2)]];
    time.wMinute = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(10, 2)]];
    time.wSecond = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(12, 2)]];
    time.wMilliseconds = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(14, 2)]];
    
    return time;

}

@end

// 定义时间类
@implementation XRTCPProtocol_Time

- (instancetype)initWithDate:(NSDate *)date
{
    self = [super init];
    if (self) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
        self.wYear = [components year];
        self.wMonth = [components month];
        self.wDay = [components day];
        self.wHour = [components hour];
        self.wMinute = [components minute];
        self.wSecond = [components second];
    }
    return self;
}

- (NSData *)encodeTime
{
    NSMutableData *buf = [NSMutableData data];
    [buf appendData:[YMSocketUtils bytesFromUInt16:self.wYear]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.wMonth]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.wDay]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.wHour]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.wMinute]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.wSecond]];
    return buf;
}

+ (instancetype)decodeTimeWithData:(NSData *)timeData
{
    XRTCPProtocol_Time *time = [[XRTCPProtocol_Time alloc] init];
    if (timeData.length < 7) {
        return time;
    }
    time.wYear = [YMSocketUtils uint16FromBytes:[timeData subdataWithRange:NSMakeRange(0, 2)]];
    time.wMonth = [YMSocketUtils uint8FromBytes:[timeData subdataWithRange:NSMakeRange(2, 2)]];
    time.wDay = [YMSocketUtils uint8FromBytes:[timeData subdataWithRange:NSMakeRange(6, 2)]];
    time.wHour = [YMSocketUtils uint8FromBytes:[timeData subdataWithRange:NSMakeRange(8, 2)]];
    time.wMinute = [YMSocketUtils uint8FromBytes:[timeData subdataWithRange:NSMakeRange(10, 2)]];
    time.wSecond = [YMSocketUtils uint8FromBytes:[timeData subdataWithRange:NSMakeRange(12, 2)]];
    
    return time;
    
}

@end

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
                                                                   [mutableData length]] bytes]];
    [mutableData appendData:[YMSocketUtils byteFromUInt8:[self calcXorWithData:mutableData startPos:1 endPos:(int)[mutableData length] - 1]]];
    [mutableData appendData:[YMSocketUtils byteFromUInt8:self.Tail]];
    
    return [self escapeWithData:mutableData dataLength:(int)[mutableData length]];
}

// 编码消息体
- (NSData *)encodeBody
{
    NSMutableData *data = [NSMutableData data];
    return data;
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
    if (length > 2) {
        uint8_t bXor = [self calcXorWithData:unEscapeData startPos:1 endPos:length - 2];
        if (bXor != 0) {
            return NO;
        }
    } else {
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
- (uint8_t)calcXorWithData:(NSData *)data startPos:(NSInteger)startPos endPos:(NSInteger)endPos
{
    uint8_t bXor = 0;
    Byte *buf = (Byte *)[data bytes];
    for (NSInteger i = startPos; i <= endPos; i++) {
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
        self.sysTime = [[XRTCPProtocol_SystemTime alloc] init];
    }
    return self;
}

// 编码消息体
- (NSData *)encodeBody
{
    self.sysTime = [[XRTCPProtocol_SystemTime alloc] initWithDate:[NSDate date]];
    self.sysTime.wYear = 2018;
    self.sysTime.wMonth = 4;
    self.sysTime.wDayOfWeek = 6;
    self.sysTime.wDay = 28;
    self.sysTime.wHour = 14;
    self.sysTime.wMinute = 36;
    self.sysTime.wSecond = 34;
    self.sysTime.wMilliseconds = 74;
    NSData *buf = [self.sysTime encodeSystemTime];
    
    return buf;
}


// 解码消息体
- (BOOL)decodeBodyWithData:(NSData *)bodydata
{
    if (bodydata.length < 16) {
        return NO;
    }
    self.sysTime = [XRTCPProtocol_SystemTime decodeTimeWithData:bodydata];
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
    if (data.length < 10) {
        return NO;
    }
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

// 查询设备信息 videoCmd = 0x02 中心
@implementation XRTCPProtocol_VideoDevice

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x02;
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

// 查询设备信息 videoCmd = 0x02 中心
@implementation XRTCPProtocol_VideoDeviceAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x02;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 13) {
        return NO;
    }
    int index = 0;
    self.seqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    ushort deviceIDLenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 13 + deviceIDLenght) {
        return NO;
    }
    index += 2;
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, deviceIDLenght)] encoding:GBKEncoding];
    index += deviceIDLenght;
    self.bOnline = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    ushort snLength = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 13 + deviceIDLenght + snLength) {
        return NO;
    }
    index += 2;
    self.deviceSN = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, snLength)] encoding:GBKEncoding];
    index += snLength;
    ushort verLength = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 13 + deviceIDLenght + snLength + verLength) {
        return NO;
    }
    index += 2;
    self.deviceVer = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, verLength)] encoding:GBKEncoding];
    index += verLength;
    ushort simLength = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 13 + deviceIDLenght + snLength + verLength + simLength) {
        return NO;
    }
    index += 2;
    self.SIMSN = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, simLength)] encoding:GBKEncoding];
    
    return YES;
}

@end

// 获取流服务器地址 videoCmd = 0x10 中心
@implementation XRTCPProtocol_VideoGetStreamIP

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x10;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.workType]];
    
    return buf;
}

@end

// 获取流服务器地址 videoCmd = 0x10 中心
@implementation XRTCPProtocol_VideoGetStreamIPAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x10;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 14) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    ushort deviceIDLenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 14 + deviceIDLenght) {
        return NO;
    }
    index += 2;
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, deviceIDLenght)] encoding:GBKEncoding];
    index += deviceIDLenght;
    self.channelNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    
    ushort streamIPLength = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 14 + deviceIDLenght + streamIPLength) {
        return NO;
    }
    index += 2;
    self.streamIP = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, streamIPLength)] encoding:GBKEncoding];
    index += streamIPLength;
    self.streamPort =  [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    return YES;
}

@end

/*
// 停止预览 videoCmd = 0x11 中心
@implementation XRTCPProtocol_VideoStopPreview

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x11;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    
    return buf;
}

@end

// 停止预览应答 videoCmd = 0x11 中心
@implementation XRTCPProtocol_VideoStopPreviewAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x11;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 4) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    return YES;
}

@end
*/

// 开始预览 0x12 (流服务器)
@implementation XRTCPProtocol_VideoStartPreview

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x12;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
//    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.streamType]];
    
    return buf;
}

@end

// 开始预览应答 0x12 (流服务器)
@implementation XRTCPProtocol_VideoStartPreviewAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x12;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 8) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.sessionID = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
    return YES;
}

@end

// 预览视频流 0x13 (流服务器)
@implementation XRTCPProtocol_VideoPreviewStream

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x13;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.streamType]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.dataType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:(uint)[self.videoData length]]];
    [buf appendData:self.videoData];
    return buf;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 16) {
        return NO;
    }
    int index = 0;
    ushort deviceIDLenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    index += 2;
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, deviceIDLenght)] encoding:GBKEncoding];
    index += deviceIDLenght;
    if (data.length < 16 + deviceIDLenght) {
        return NO;
    }
    self.channelNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.sessionID = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.streamType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    self.dataType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    uint videoDataLength = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    if (data.length < 16 + deviceIDLenght + videoDataLength) {
        return NO;
    }
    self.videoData = [data subdataWithRange:NSMakeRange(index, videoDataLength)];
    return YES;
}

@end

// 停止预览 0x14 (流服务器)
@implementation XRTCPProtocol_VideoStopPreview

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x14;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    return buf;
}

@end

// 停止预览应答 0x14 (流服务器)
@implementation XRTCPProtocol_VideoStopPreviewAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x14;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 4) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
    return YES;
}

@end

@implementation XR_VideoFileInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.startTime = [[XRTCPProtocol_Time alloc] init];
        self.endTime = [[XRTCPProtocol_Time alloc] init];
    }
    return self;
}

- (NSData *)encodeFileInfo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *fileNameData = [self.fileName dataUsingEncoding:GBKEncoding];
    
    [buf appendData:[YMSocketUtils bytesFromUInt16:fileNameData.length]];
    [buf appendData:fileNameData];
    [buf appendData:[self.startTime encodeTime]];
    [buf appendData:[self.endTime encodeTime]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.fileSize]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.fileMainType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.fileChildType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.fileIndex]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.timeLagHour]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.timeLagMinute]];
    return buf;
}

+ (instancetype)decodeFileInfoWithData:(NSData *)data
{
    XR_VideoFileInfo *fileInfo = [[XR_VideoFileInfo alloc] init];
    if (data.length < 34) {
        return fileInfo;
    }
    NSInteger index = 0;
    int fileNameLength = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    index += 2;
    if (data.length < 34 + fileNameLength) {
        return fileInfo;
    }
    fileInfo.fileName = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, fileNameLength)] encoding:GBKEncoding];
    index += fileNameLength;
    fileInfo.startTime = [XRTCPProtocol_Time decodeTimeWithData:[data subdataWithRange:NSMakeRange(index, 7)]];
    index += 7;
    fileInfo.endTime = [XRTCPProtocol_Time decodeTimeWithData:[data subdataWithRange:NSMakeRange(index, 7)]];
    index += 7;
    fileInfo.fileSize = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    fileInfo.fileMainType = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    fileInfo.fileChildType = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    fileInfo.fileIndex = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    fileInfo.timeLagHour = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    fileInfo.timeLagMinute = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    return fileInfo;
}

@end

// 查询录像文件（0x15）(中心)
@implementation XRTCPProtocol_VideoQueryFile

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x15;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.videoType]];
    [buf appendData:[self.startTime encodeTime]];
    [buf appendData:[self.endTime encodeTime]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.index]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.OnceQueryNum]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.dateType]];
    return buf;
}

@end

// 查询录像文件应答（0x15）(中心)
@implementation XRTCPProtocol_VideoQueryFileAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x15;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 14) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    ushort deviceIDLenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    if (data.length < 14 + deviceIDLenght) {
        return NO;
    }
    index += 2;
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, deviceIDLenght)] encoding:GBKEncoding];
    index += deviceIDLenght;
    self.channelNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.fileNum = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    NSMutableArray *tempArray = [NSMutableArray array];
#warning 注意下面的操作越界崩溃
    for (int i = 0; i < self.fileNum; i++) {
        XR_VideoFileInfo *videoInfo = [[XR_VideoFileInfo alloc] init];
        short fileNameLength = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
        index += 2;
        videoInfo.fileName = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, fileNameLength)] encoding:GBKEncoding];
        index += fileNameLength;
        videoInfo.startTime = [XRTCPProtocol_Time decodeTimeWithData:[data subdataWithRange:NSMakeRange(index, 7)]];
        index += 7;
        videoInfo.startTime = [XRTCPProtocol_Time decodeTimeWithData:[data subdataWithRange:NSMakeRange(index, 7)]];
        index += 7;
        videoInfo.fileSize = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
        index += 4;
        videoInfo.fileMainType = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
        index += 4;
        videoInfo.fileChildType = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
        index += 4;
        videoInfo.fileIndex = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
        index += 4;
        videoInfo.timeLagHour = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
        index += 1;
        videoInfo.timeLagMinute = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
        index += 1;
        [tempArray addObject:videoInfo];
    }
    self.fileInfos = tempArray;
    return YES;
}

@end

// 开始回放 （0x16） (流服务器)
@implementation XRTCPProtocol_VideoStartPlayBack

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x16;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.playBackType]];
    NSData *fileNameData = [self.fileName dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[fileNameData length]]];
    [buf appendData:fileNameData];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.calculationType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.fileOffset]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.fileSize]];
    [buf appendData:[self.startTime encodeTime]];
    [buf appendData:[self.endTime encodeTime]];
    return buf;
}

@end

// 开始回放应答 （0x16） (流服务器)
@implementation XRTCPProtocol_VideoStartPlayBackAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x16;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 8) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.sessionID = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
    return YES;
}

@end

// 回放视频流 0x17（流服务器）
@implementation XRTCPProtocol_VideoPlayBackStream

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x17;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.streamType]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.dataType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:(uint)[self.videoData length]]];
    [buf appendData:self.videoData];
    return buf;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 16) {
        return NO;
    }
    int index = 0;
    ushort deviceIDLenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    index += 2;
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, deviceIDLenght)] encoding:GBKEncoding];
    index += deviceIDLenght;
    if (data.length < 16 + deviceIDLenght) {
        return NO;
    }
    self.channelNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.sessionID = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.streamType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    self.dataType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    uint videoDataLength = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    if (data.length < 16 + deviceIDLenght + videoDataLength) {
        return NO;
    }
    self.videoData = [data subdataWithRange:NSMakeRange(index, videoDataLength)];
    return YES;
}

@end

// 停止回放 0x18 (流服务器)
@implementation XRTCPProtocol_VideoStopPlayBack

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x18;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.channelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    return buf;
}

@end

// 停止回放应答 0x18 (流服务器)
@implementation XRTCPProtocol_VideoStopPlayBackAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x18;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 4) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
    return YES;
}

@end

// 开始语音对讲 0x19 (流服务器)
@implementation XRTCPProtocol_VideoStartVoice

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x19;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.voiceChannelNo]];
    return buf;
}

@end

// 开始语音对讲应答 0x19 (流服务器)
@implementation XRTCPProtocol_VideoStartVoiceAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x19;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 8) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.sessionID = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
    return YES;
}

@end

// 对讲语音数据 0x20 (流服务器)
@implementation XRTCPProtocol_VideoVoiceData

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x20;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.voiceChannelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.streamType]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.dataType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:(uint)[self.voiceData length]]];
    [buf appendData:self.voiceData];
    return buf;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 16) {
        return NO;
    }
    int index = 0;
    ushort deviceIDLenght = [YMSocketUtils uint16FromBytes:[data subdataWithRange:NSMakeRange(index, 2)]];
    index += 2;
    self.deviceID = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(index, deviceIDLenght)] encoding:GBKEncoding];
    index += deviceIDLenght;
    if (data.length < 16 + deviceIDLenght) {
        return NO;
    }
    self.voiceChannelNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.sessionID = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    self.streamType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    self.dataType = [YMSocketUtils uint8FromBytes:[data subdataWithRange:NSMakeRange(index, 1)]];
    index += 1;
    uint voiceDataLength = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    index += 4;
    if (data.length < 16 + deviceIDLenght + voiceDataLength) {
        return NO;
    }
    self.voiceData = [data subdataWithRange:NSMakeRange(index, voiceDataLength)];
    return YES;
}

@end

// 下发语音数据 0x21 (流服务器)
@implementation XRTCPProtocol_VideoSendVoiceData

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x21;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.voiceChannelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.streamType]];
    [buf appendData:[YMSocketUtils byteFromUInt8:self.dataType]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:(uint)[self.voiceData length]]];
    [buf appendData:self.voiceData];
#warning 最大语音长度限制在 60k
    return buf;
}

@end

// 下发语音数据应答 0x21 (流服务器)
@implementation XRTCPProtocol_VideoSendVoiceDataAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x21;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 4) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
    return YES;
}

@end

// 停止语音对讲 0x22 (流服务器)
@implementation XRTCPProtocol_VideoStopVoice

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x22;
    }
    return self;
}

- (NSData *)encodeVideo
{
    NSMutableData *buf = [NSMutableData data];
    NSData *clientGUIDData = [self.clientGUID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[clientGUIDData length]]];
    [buf appendData:clientGUIDData];
    NSData *deviceIDData = [self.deviceID dataUsingEncoding:GBKEncoding];
    [buf appendData:[YMSocketUtils bytesFromUInt16:[deviceIDData length]]];
    [buf appendData:deviceIDData];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.voiceChannelNo]];
    [buf appendData:[YMSocketUtils bytesFromUInt32:self.sessionID]];
    
    return buf;
}

@end

// 停止语音对讲应答 0x22 (流服务器)
@implementation XRTCPProtocol_VideoStopVoiceAck

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.videoCmd = 0x22;
    }
    return self;
}

- (BOOL)decodeVideoWithData:(NSData *)data
{
    if (data.length < 4) {
        return NO;
    }
    int index = 0;
    self.respSeqNo = [YMSocketUtils uint32FromBytes:[data subdataWithRange:NSMakeRange(index, 4)]];
    
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
