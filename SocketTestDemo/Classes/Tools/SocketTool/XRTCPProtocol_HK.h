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

@property (nonatomic, strong) NSString *GUID; // 客户端会话ID(36字节)
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

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint8_t bOnline; // 是否在线
@property (nonatomic, strong) NSString *deviceSN; // 设备序列号
@property (nonatomic, strong) NSString *deviceVer; // 固件版本
@property (nonatomic, strong) NSString *SIMSN; // SIM卡序列号

@end

// 获取流服务器地址 videoCmd = 0x10 中心
@interface XRTCPProtocol_VideoGetStreamIP : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
//@property (nonatomic, assign) uint8_t streamType; // 流类型 0-主码流 1-子码流
@property (nonatomic, assign) uint8_t workType; // 业务类型 1-预览 2-回放

@end

// 获取流服务器地址 videoCmd = 0x10 中心
@interface XRTCPProtocol_VideoGetStreamIPAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
//@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, strong) NSString *streamIP; // 流服务器IP
@property (nonatomic, assign) ushort streamPort; // 流服务器端口

@end

/*
// 停止预览 videoCmd = 0x11 中心
@interface XRTCPProtocol_VideoStopPreview : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 停止预览应答 videoCmd = 0x11 中心
@interface XRTCPProtocol_VideoStopPreviewAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号

@end
*/

// 开始预览 0x12 (流服务器)
@interface XRTCPProtocol_VideoStartPreview : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
//@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, assign) uint8_t streamType; // 流类型 0-主码流 1-子码流

@end

// 开始预览应答 0x12 (流服务器)
@interface XRTCPProtocol_VideoStartPreviewAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 预览视频流 0x13 (流服务器)
@interface XRTCPProtocol_VideoPreviewStream : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, assign) uint8_t streamType; // 流类型 1-HK
@property (nonatomic, assign) uint8_t dataType; // 数据类型 HK: 1-码流头 2-码流数据
@property (nonatomic, strong) NSData *videoData; // 视频数据

@end

// 停止预览 0x14 (流服务器)
@interface XRTCPProtocol_VideoStopPreview : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 停止预览应答 0x14 (流服务器)
@interface XRTCPProtocol_VideoStopPreviewAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号

@end

// 文件信息
@interface XR_VideoFileInfo : NSObject

@property (nonatomic, strong) NSString *fileName; // 文件名
@property (nonatomic, assign) SYSTEMTIME startTime; // 开始时间
@property (nonatomic, assign) SYSTEMTIME endTime; // 结束时间
@property (nonatomic, assign) uint fileSize; // 文件大小
@property (nonatomic, assign) uint fileMainType; // 文件主类型
@property (nonatomic, assign) uint fileChildType; // 文件次类型
@property (nonatomic, assign) uint fileIndex; // 文件索引
@property (nonatomic, assign) Byte timeLagHour; // 时差小时 与UTC时差
@property (nonatomic, assign) Byte timeLagMinute; // 时差分钟 与UTC时差

@end

// 查询录像文件（0x15）(中心)
@interface XRTCPProtocol_VideoQueryFile : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint videoType; // 录像类型：0xFF-全部 0-定时录像
@property (nonatomic, assign) SYSTEMTIME startTime; // 开始时间
@property (nonatomic, assign) SYSTEMTIME endTime; // 结束时间
@property (nonatomic, assign) uint index; // 起始索引 从0开始
@property (nonatomic, assign) uint OnceQueryNum; // 单次查询个数 建议最大个数 8
@property (nonatomic, assign) Byte dateType; // 时间类型：0-北京时间 1-UTC 时间

@end

// 查询录像文件应答（0x15）(中心)
@interface XRTCPProtocol_VideoQueryFileAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint fileNum; // 文件数
@property (nonatomic, strong) NSArray<XR_VideoFileInfo *> *fileInfos; // 文件信息数组

@end

// 开始回放 （0x16） (流服务器)
@interface XRTCPProtocol_VideoStartPlayBack : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint playBackType; // 回放模式 0-按文件名 1-按时间(暂不支持)
@property (nonatomic, strong) NSString *fileName; // 回放文件名
@property (nonatomic, assign) Byte calculationType; // 计算类型 0-按字节长度计算 1-按秒数计算
@property (nonatomic, assign) uint fileOffset; // 文件偏移量 按字节或秒。
@property (nonatomic, assign) uint fileSize; // 回放文件大小 0-回放到该文件结束，按字节或秒。
@property (nonatomic, assign) SYSTEMTIME startTime; // 开始时间 按时间模式有效
@property (nonatomic, assign) SYSTEMTIME endTime; // 结束时间 按时间模式有效

@end

// 开始回放应答 （0x16） (流服务器)
@interface XRTCPProtocol_VideoStartPlayBackAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 回放视频流 0x17（流服务器）
@interface XRTCPProtocol_VideoPlayBackStream : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, assign) uint8_t streamType; // 流类型 1-HK
@property (nonatomic, assign) uint8_t dataType; // 数据类型 HK: 1-码流头 2-码流数据
@property (nonatomic, strong) NSData *videoData; // 视频数据

@end

// 停止回放 0x18 (流服务器)
@interface XRTCPProtocol_VideoStopPlayBack : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint channelNo; // 通道号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 停止回放应答 0x18 (流服务器)
@interface XRTCPProtocol_VideoStopPlayBackAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号

@end

// 开始语音对讲 0x19 (流服务器)
@interface XRTCPProtocol_VideoStartVoice : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint voiceChannelNo; // 语音通道号

@end

// 开始语音对讲应答 0x19 (流服务器)
@interface XRTCPProtocol_VideoStartVoiceAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 对讲语音数据 0x20 (流服务器)
@interface XRTCPProtocol_VideoVoiceData : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint voiceChannelNo; // 语音通道号
@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, assign) uint8_t streamType; // 流类型 1-HK
@property (nonatomic, assign) uint8_t dataType; // 数据类型 HK: 1-码流头 2-码流数据
@property (nonatomic, strong) NSData *voiceData; // 语音数据

@end

// 下发语音数据 0x21 (流服务器)
@interface XRTCPProtocol_VideoSendVoiceData : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint voiceChannelNo; // 语音通道号
@property (nonatomic, assign) uint sessionID; // 会话ID
@property (nonatomic, assign) uint8_t streamType; // 流类型 1-HK
@property (nonatomic, assign) uint8_t dataType; // 数据类型 HK: 1-码流头 2-码流数据
@property (nonatomic, strong) NSData *voiceData; // 语音数据 最大语音长度限制在 60k

@end

// 下发语音数据应答 0x21 (流服务器)
@interface XRTCPProtocol_VideoSendVoiceDataAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号

@end

// 停止语音对讲 0x22 (流服务器)
@interface XRTCPProtocol_VideoStopVoice : XRTCPProtocol_Video

@property (nonatomic, strong) NSString *clientGUID; // 客户端GUID
@property (nonatomic, strong) NSString *deviceID; // 设备ID
@property (nonatomic, assign) uint voiceChannelNo; // 语音通道号
@property (nonatomic, assign) uint sessionID; // 会话ID

@end

// 停止语音对讲应答 0x22 (流服务器)
@interface XRTCPProtocol_VideoStopVoiceAck : XRTCPProtocol_Video

@property (nonatomic, assign) uint respSeqNo; // 应答序列号

@end
