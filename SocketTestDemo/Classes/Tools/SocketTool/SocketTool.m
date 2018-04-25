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
        [self connectedToHost];
    }
    return self;
}

// 连接服务器
- (BOOL)connectedToHost
{
    if (!self.clientSocket.isConnected) {
        NSError *error = nil;
        if (![self.clientSocket connectToHost:_host onPort:_port withTimeout:_timeOut error:&error]) {
            return NO;
        }
    }
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
    if (self.responseBlock) {
        self.responseBlock(data, tag, nil);
    }
    // 读取到服务器端数据后，继续读取
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (!err) {
        _isConnected = NO;
    } else {
        [sock disconnect];
    }
}

@end
