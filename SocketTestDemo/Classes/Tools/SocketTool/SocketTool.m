//
//  SocketTool.m
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "SocketTool.h"

@interface SocketTool ()<GCDAsyncSocketDelegate>

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) NSTimer *connectTimer;

@end

@implementation SocketTool

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

// 向服务器发送信息
- (void)sendMessageAction
{
    NSString *text = @"测试发给服务端的文本";
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

- (void)addTimer
{
    // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前RunLoop中共，并调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

- (void)longConnectToSocket
{
    // 发送固定格式的数据，指令@“longConnect”
    [self.clientSocket writeData:[NSData data] withTimeout:-1 tag:0];
}

#pragma mark -GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接成功，服务器IP：%@， 端口号：%@", host, port);
    // 连接成功开启定时器
    [self addTimer];
    // 连接后，可读取服务器端的数据
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    self.connected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // 处理从服务器端获取到的数据
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // 读取到服务器端数据后，继续读取
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}


@end
