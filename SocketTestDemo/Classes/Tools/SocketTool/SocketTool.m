//
//  SocketTool.m
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "SocketTool.h"
#import "XRTCPProtocol_HK.h"

@interface SocketTool ()<GCDAsyncSocketDelegate>
{
    dispatch_semaphore_t _semaphore;
}
@property (nonatomic, strong) NSTimer *connectTimer;

@end

@implementation SocketTool

- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port timeOut:(NSInteger)timeOut
{
    self = [super init];
    if (self) {
        _host = host;
        _port = port;
        _timeOut = timeOut;
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _semaphore =  dispatch_semaphore_create(1);
        [self connectedToHost];
    }
    return self;
}

- (BOOL)connectedToHost
{
    if (!_isConnected) {
        NSError *error = nil;
        if (![self.clientSocket connectToHost:_host onPort:_port withTimeout:_timeOut error:&error]) {
            return NO;
        }
    }
    return YES;
}

// 向服务器发送信息
- (void)sendMessageWithData:(NSData *)data
{
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
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
    // 发送固定格式的数据，指令@“longConnect”
    [self.clientSocket writeData:data withTimeout:-1 tag:contact.ProtocolValue];
}

#pragma mark -GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    // 连接成功开启定时器
    [self addConnectTimer];
    // 连接后，可读取服务器端的数据
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    _isConnected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    /*
    dispatch_semaphore_wait(_semaphore, 10);
    // 处理从服务器端获取到的数据
    XRTCPProtocol_Basic *basic = [[XRTCPProtocol_Basic alloc] init];
    
    BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
    if (flag) {
        if (basic.ProtocolValue == 0x05) {
            flag = [[[XRTCPProtocol_Contact alloc] init] decodePackWithData:data length:(int)[data length]];
            
        } else if (basic.ProtocolValue == 0x35) {
            flag = [[[XRTCPProtocol_LoginAck alloc] init] decodePackWithData:data length:(int)[data length]];
            
        } else if (basic.ProtocolValue == 0x40) {
            
            XRTCPProtocol_Video *video = [[XRTCPProtocol_Video alloc] init];
            
            flag = [video decodePackWithData:data length:(int)[data length]];
            
            switch (video.videoCmd) {
                case 0x01:
                {
                    XRTCPProtocol_VideoChannelAck *videoChannelAck = [[XRTCPProtocol_VideoChannelAck alloc] init];
                    flag = [videoChannelAck decodePackWithData:data length:(int)[data length]];
                    break;
                }
                case 0x02:
                {
                    XRTCPProtocol_VideoDeviceAck *deviceAck = [[XRTCPProtocol_VideoDeviceAck alloc] init];
                    flag = [deviceAck decodePackWithData:data length:(int)[data length]];
                    break;
                }
                case 0x10:
                {
                    XRTCPProtocol_VideoGetStreamIPAck *getStreamIPAck = [[XRTCPProtocol_VideoGetStreamIPAck alloc] init];
                    flag = [getStreamIPAck decodePackWithData:data length:(int)data.length];
                    break;
                }
                    
                case 0x12:
                {
                    XRTCPProtocol_VideoStartPreviewAck *startPreviewAck = [[XRTCPProtocol_VideoStartPreviewAck alloc] init];
                    flag = [startPreviewAck decodePackWithData:data length:(int)data.length];
                    [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
                    [_playData replaceBytesInRange:NSMakeRange(0, _playData.length) withBytes:NULL length:0];
                    _isStream = NO;
                    _isPlay = YES;
                    break;
                }
                case 0x13:
                {
                    [_videoData appendData:data];
                    if (_isEmpty) {
                        _isEmpty = NO;
                        [_playData appendData:_videoData];
                        [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
                    }
                    
                    break;
                }
                case 14:
                {
                    _isPlay = NO;
                    stopPreviewAck = [[XRTCPProtocol_VideoStopPreviewAck alloc] init];
                    flag = [stopPreviewAck decodePackWithData:data length:[data length]];
                    break;
                }
                    
                default:
                    break;
            }
            
            
        }
    } else {
        if (_isPlay) {
            [_videoData appendData:data];
            if (_isEmpty) {
                _isEmpty = NO;
                [_playData appendData:_videoData];
                [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
            }
        } else {
            
        }
    }
    dispatch_semaphore_signal(_semaphore);
    // 读取到服务器端数据后，继续读取
    [self.clientSocket readDataWithTimeout:-1 tag:0];
     */
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    _isConnected = NO;
}

@end
