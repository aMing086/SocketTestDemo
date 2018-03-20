//
//  XRTCPProtocol_HK.h
//  SocketTestDemo
//
//  Created by 369 on 2018/3/8.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XRCP_HEAD 0xAA
#define XRCP_TAIL 0xAA
#define XRCP_ESCAPE 0xAB
#define XRCP_MINPACK_LEN 9
#define XRCP_MAXPACK_LEN 20480 // 20k

typedef struct _SYSTEMTIME
{
    ushort wYear;
    ushort wMonth;
    ushort wDayOfWeek;
    ushort wDay;
    ushort wHour;
    ushort wMinute;
    ushort wSecond;
    ushort wMilliseconds;
}   SYSTEMTIME;

//SYSTEMTIME SYSTEMTIMEMake(ushort wYear, ushort wMonth, ushort wDayOfWeek, ushort wDay, ushort wHour, ushort wMinute, ushort wSecond, ushort wMilliseconds) {
//    SYSTEMTIME systemtime;
//    systemtime.wYear = wYear;
//    systemtime.wMonth = wMonth;
//    systemtime.wDayOfWeek = wDayOfWeek;
//    systemtime.wDay = wDay;
//    systemtime.wHour = wHour;
//    systemtime.wMinute = wMinute;
//    systemtime.wSecond = wSecond;
//    systemtime.wMilliseconds = wMilliseconds;
//    return systemtime;
//}


extern NSString * const TYPE_UINT8;
extern NSString * const TYPE_UINT16;
extern NSString * const TYPE_UINT32;
extern NSString * const TYPE_UINT64;
extern NSString * const TYPE_STRING;
extern NSString * const TYPE_ARRAY;

// 星软客户端协议包
@interface XRTCPProtocol_Basic : NSObject

@property (nonatomic, assign) uint8_t Head; // 数据头
@property (nonatomic, assign) uint16_t Length; // 数据长度（不包括头尾）
@property (nonatomic, assign) uint16_t ProtocolValue; // 协议值
@property (nonatomic, assign) uint16_t ResCode; // 反馈值
@property (nonatomic, assign) uint8_t CheckValue; // 校验值（异或和,不包括头尾）
@property (nonatomic, assign) uint8_t Tail; // 数据尾

// 编码
- (NSData *)encodePack;
// 解码
- (BOOL)decodePackWithData:(NSData *)data length:(int)length;
// 编码消息体
- (NSData *)encodeBody;
// 解码消息体
- (BOOL)decodeBodyWithData:(NSData *)bodydata;


@end

// 身份验证 ProtocolValue = 0x35
@interface XRTCPProtocol_Login : XRTCPProtocol_Basic

@property (nonatomic, strong) NSString *GUID; // 客户端会话ID
@property (nonatomic, assign) uint8_t nameLen; // 用户名长度
@property (nonatomic, strong) NSString *UserName; // 用户名
@property (nonatomic, assign) uint8_t passwordLen; // 密码长度
@property (nonatomic, strong) NSString *Password; // 密码

@end

// 身份验证应答 ProtocolValue = 0x35
@interface XRTCPProtocol_LoginAck : XRTCPProtocol_Basic

@property (nonatomic, assign) uint8_t bResult; // 验证结果

@end

// 心跳包 ProtocolValue = 0x05
@interface XRTCPProtocol_Contact : XRTCPProtocol_Basic

@property (nonatomic, assign) SYSTEMTIME sysTime;

// 编码消息体
- (NSData *)encodeBody;
// 解码消息体
- (BOOL)decodeBodyWithData:(NSData *)data;

@end

/**    视频 ProtocolValue = 0x40   **/

// 视频相关协议
@interface XRTCPProtocol_Video :XRTCPProtocol_Basic

@property (nonatomic, assign) uint8_t version; // 版本
@property (nonatomic, assign) uint8_t senderType; // 发送者类型 1-服务器 2-pc 3-apple app 4- android app
@property (nonatomic, assign) uint8_t videoCmd; // 视频命令
@property (nonatomic, assign) uint seqNo; // 序列号

- (NSData *)encodeVideo;
- (BOOL)decodeVideoWithData:(NSData *)data;

@end

// 查询通道信息 videoCmd = 0x01 中心
@interface XRTCPProtocol_VideoChannel : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID

@end

// class 通道信息
@interface XR_VideoChannelInfo : NSObject

@property (nonatomic, assign) uint nChannelNo;    //通道号
@property (nonatomic, assign) uint8_t bChannelType;    //通道类型

@end

// 查询通道信息应答 videoCmd = 0x01 中心
@interface XRTCPProtocol_VideoChannelAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNum; // 通道数
@property (nonatomic, strong) NSArray<XR_VideoChannelInfo *> *Channels; // 通道信息列表

@end

// 查询设备信息 videoCmd = 0x02 中心
@interface XRTCPProtocol_VideoDevice : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID

@end

// 查询设备信息应答 videoCmd = 0x02 中心
@interface XRTCPProtocol_VideoDeviceAck : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, assign) Byte bOnline; // 是否在线
@property (nonatomic, strong) NSString *deviceSN; // 设备序列号
@property (nonatomic, strong) NSString *deviceVer; // 固件版本
@property (nonatomic, strong) NSString *SIMSN; // SIM卡序列号

@end

// 开始预览 videoCmd = 0x10 中心
@interface XRTCPProtocol_VideoStartPreview : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) Byte streamType; // 流类型 0-主码流 1-子码流

@end

// 开始预览应答 videoCmd = 0x10 中心
@interface XRTCPProtocol_VideoStartPreviewAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint result; // 结果
@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, strong) NSString *streamIP; // 流服务器IP
@property (nonatomic, assign) ushort streamPort; // 流服务器端口

@end

// 停止预览 videoCmd = 0x11 中心
@interface XRTCPProtocol_VideoStopPreview : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) Byte streamType; // 流类型 0-主码流 1-子码流

@end

// 停止预览应答 videoCmd = 0x11 中心
@interface XRTCPProtocol_VideoStopPreviewAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, assign) uint result; // 结果

@end

// 获取预览视频流 0x12 (流服务器)
@interface XRTCPProtocol_VideoGetPreviewStream : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 获取预览视频流应答 0x12 (流服务器)
@interface XRTCPProtocol_VideoGetPreviewStreamAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, assign) uint result; // 结果

@end

// 预览视频流 0x13 (流服务器)
@interface XRTCPProtocol_VideoPreviewStream : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, assign) uint8_t streamType; // 流类型
@property (nonatomic, assign) uint8_t dataType; // 数据类型
@property (nonatomic, strong) NSData *videoData; // 视频数据

@end

// 停止接收预览视频流 0x14 (流服务器)
@interface XRTCPProtocol_VideoStopPreviewStream : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end
