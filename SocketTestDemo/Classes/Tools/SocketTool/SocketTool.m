//
//  SocketTool.m
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "SocketTool.h"
#import "XRTCPProtocol_HK.h"
#import "XRSocketDataCache.h"

#define kSocket_TimeOut 5

@interface SocketTool ()<GCDAsyncSocketDelegate>
{
    dispatch_queue_t _serialDataQueue;
    dispatch_queue_t _serialSelfQueue;
    dispatch_queue_t _callbackQueue;
}

@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) XRSocketDataCache *dataCache;


@end

@implementation SocketTool

- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port timeOut:(NSInteger)timeOut delegate:(id<SocketToolDelegate >)delegate
{
    self = [super init];
    if (self) {
        _host = host;
        _port = port;
        _timeOut = timeOut;
        self.delegate = delegate;
        _serialDataQueue = dispatch_queue_create("com.XRHKVideo.socketTool.serialData", DISPATCH_QUEUE_SERIAL);
        _serialSelfQueue = dispatch_queue_create("com.XRHKVideo.socketTool.serialSelf", DISPATCH_QUEUE_SERIAL);
        
        _callbackQueue = dispatch_get_main_queue();
        // 初始化数据缓冲区
        self.dataCache = [[XRSocketDataCache alloc] init];
        // 初始化socket
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        // 连接服务器
        [self connectedToHost];
    }
    return self;
}

// 连接服务器
- (BOOL)connectedToHost
{
    if (!_isConnected) {
        NSError *error = nil;
        if (![self.clientSocket connectToHost:_host onPort:_port withTimeout:_timeOut error:&error]) {
            return NO;
        }
    }
    _isConnected = YES;
    return YES;
}

// 断开链接
- (void)disconnected
{
    [self.clientSocket disconnect];
}

// 向服务器发送信息
- (void)sendMessageWithData:(NSData *)data responseBlock:(ResponseBlock)block
{
    if ([self connectedToHost]) {
        self.responseBlock = block;
        [self.clientSocket writeData:data withTimeout:-1 tag:0];
    }
    
}

// 定时器维持链接
- (void)addConnectTimer
{
    // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前RunLoop中共，并调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

- (void)longConnectToSocket
{
    XRTCPProtocol_Contact *contact = [[XRTCPProtocol_Contact alloc] init];
    NSData *data = [contact encodePack];
    // 发送固定格式的数据
    [self.clientSocket writeData:data withTimeout:-1 tag:contact.ProtocolValue];
}

// 关闭定时发送心跳包
- (void)stopTimer
{
    if (self.connectTimer) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
}

// 查询通道号
- (void)getChannelWithDeviceID:(NSString *)deviceID block:(void (^) (XRTCPProtocol_VideoChannelAck *ack, long tag, NSError *error))block
{
    XRTCPProtocol_VideoChannel *videoChannel = [[XRTCPProtocol_VideoChannel alloc] init];
    videoChannel.deviceID = deviceID;
    NSData *videoChannelData = [videoChannel encodePack];
    [self sendMessageWithData:videoChannelData responseBlock:^(NSData *data, long tag, NSError *error) {
        XRTCPProtocol_VideoChannelAck *videoChannelAck = [[XRTCPProtocol_VideoChannelAck alloc] init];
        BOOL flag = [videoChannelAck decodePackWithData:data length:(int)[data length]];
        if (flag && videoChannelAck.ProtocolValue == 0x40 && videoChannelAck.videoCmd == 0x01) {
            block(videoChannelAck, tag, nil);
        } else {
            block(nil, tag, error);
        }
    }];
}

// 查询设备信息
- (void)getDeviceInfoWithDeviceID:(NSString *)deviceID block:(void (^) (XRTCPProtocol_VideoDeviceAck *ack, long tag, NSError *error))block
{
    XRTCPProtocol_VideoDevice *videoDevice = [[XRTCPProtocol_VideoDevice alloc] init];
    videoDevice.deviceID = deviceID;
    NSData *videoDeviceData = [videoDevice encodePack];
    [self sendMessageWithData:videoDeviceData responseBlock:^(NSData *data, long tag, NSError *error) {
        XRTCPProtocol_VideoDeviceAck *deviceAck = [[XRTCPProtocol_VideoDeviceAck alloc] init];
        BOOL flag = [deviceAck decodePackWithData:data length:(int)[data length]];
        if (flag && deviceAck.ProtocolValue == 0x40 && deviceAck.videoCmd == 0x02) {
            block(deviceAck, tag, nil);
        } else {
            block(nil, tag, error);
        }
    }];
}

// 获取流服务器地址
- (void)getStreamIPWithDeviceID:(NSString *)deviceID channelNO:(int)channelNO workType:(NSInteger)workType block:(void (^) (XRTCPProtocol_VideoGetStreamIPAck *ack, long tag, NSError *error))block
{
    XRTCPProtocol_VideoGetStreamIP *getStreamIP = [[XRTCPProtocol_VideoGetStreamIP alloc] init];
    getStreamIP.deviceID = deviceID;
    getStreamIP.channelNo = channelNO;
    getStreamIP.workType = workType;
    NSData *getStreamIPData = [getStreamIP encodePack];
    [self sendMessageWithData:getStreamIPData responseBlock:^(NSData *data, long tag, NSError *error) {
        XRTCPProtocol_VideoGetStreamIPAck *getStreamIPAck = [[XRTCPProtocol_VideoGetStreamIPAck alloc] init];
        BOOL flag = [getStreamIPAck decodePackWithData:data length:(int)data.length];
        if (flag && getStreamIPAck.ProtocolValue == 0x40 && getStreamIPAck.videoCmd == 0x10) {
            block(getStreamIPAck, tag, nil);
        } else {
            block(nil, tag, error);
        }
    }];
}

// 开始预览
- (void)startPreviewWithClientGUID:(NSString *)clientGUID deviceID:(NSString *)deviceID channelNO:(int)channelNO streamType:(int)streamType
{
    XRTCPProtocol_VideoStartPreview *videoGetPreviewStream = [[XRTCPProtocol_VideoStartPreview alloc] init];
    videoGetPreviewStream.clientGUID = clientGUID;
    videoGetPreviewStream.deviceID = deviceID;
    videoGetPreviewStream.channelNo = channelNO;
    videoGetPreviewStream.streamType = streamType;
    NSData *videoGetPreviewStreamData = [videoGetPreviewStream encodePack];
    [self sendMessageWithData:videoGetPreviewStreamData responseBlock:^(NSData *data, long tag, NSError *error) {
        
    }];
}

// 停止接收预览视频流
- (void)stopPreviewWithClientGUID:(NSString *)clientGUID deviceID:(NSString *)deviceID channelNO:(int)channelNO sessionID:(int)sessionID
{
    XRTCPProtocol_VideoStopPreview *videoStopPreview = [[XRTCPProtocol_VideoStopPreview alloc] init];
    videoStopPreview.clientGUID = clientGUID;
    videoStopPreview.deviceID = deviceID;
    videoStopPreview.channelNo = channelNO;
    videoStopPreview.sessionID = sessionID;
    NSData *videoStopPreviewData = [videoStopPreview encodePack];
    [self sendMessageWithData:videoStopPreviewData responseBlock:^(NSData *data, long tag, NSError *error) {
        
    }];
}

// 查询录像文件
- (void)searchVideoFileWithClientGUID:(NSString *)clientGUID deviceID:(NSString *)deviceID channelNO:(int)channelNo startTimeStr:(NSString *)startTime endTimeStr:(NSString *)endTime
{
    XRTCPProtocol_VideoQueryFile *queryFile = [[XRTCPProtocol_VideoQueryFile alloc] init];
    queryFile.clientGUID = clientGUID;
    queryFile.deviceID = deviceID;
    queryFile.channelNo = channelNo;
    queryFile.videoType = 0xff;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *startDate = [formatter dateFromString:startTime];
    queryFile.startTime = [[XRTCPProtocol_SystemTime alloc] initWithDate:startDate];
    queryFile.endTime = [[XRTCPProtocol_SystemTime alloc] initWithDate:[formatter dateFromString:endTime]];
    queryFile.index = 0;
    queryFile.OnceQueryNum = 1;
    queryFile.dateType = 0;
}

- (void)dealCacheData
{
    dispatch_async(_serialDataQueue, ^{
        while (1) {
            if (_playData.length == 0) {
                _isEmpty = YES;
                [NSThread sleepForTimeInterval:0.1];
                continue;
            }
            @synchronized(self) {
                XRTCPProtocol_VideoPreviewStream *tempPreviewStream = [XRVideoDataTool decodePreViewStreamFromData:_playData];
                if (tempPreviewStream == nil) {
                    _isEmpty = YES;
                    [NSThread sleepForTimeInterval:0.1];
                    continue;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.hkSDKManager playStreamData:tempPreviewStream.videoData dataType:tempPreviewStream.dataType  length:[tempPreviewStream.videoData length]];
                    //                    NSLog(@"%d", tempPreviewStream.dataType);
                });
                
            }
            
            
        }
        
    });
}

#pragma mark -GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    // 连接成功开启定时器
    [self addConnectTimer];
    // 连接后，可读取服务器端的数据
    [sock readDataWithTimeout:-1 tag:0];
    _isConnected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self.dataCache writeData:data];
//    if (self.responseBlock) {
//        self.responseBlock(data, tag, nil);
//    }
//    if (self.delegate && [self.delegate respondsToSelector:@selector(socketTool:readData:)]) {
//        [self.delegate socketTool:self readData:data];
//    }
    // 读取到服务器端数据后，继续读取
    [sock readDataWithTimeout:-1 tag:0];
}

// 当过了超时时间服务器还未响应，说明网络拥堵或异常，你可以选择重新发送、提醒用户网络不稳定等操作。 -1代表没有超时时间。
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    return elapsed;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    return elapsed;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketTool:error:)]) {
        [self.delegate socketTool:self error:err];
    }
    [self stopTimer];
    if (!err) {
        _isConnected = NO;
    } else {
        [sock disconnect];
    }
}

- (void)dealloc
{
    [self disconnected];
    _clientSocket = nil;
    if (_connectTimer) {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }
}

@end
