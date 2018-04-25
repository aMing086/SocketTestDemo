//
//  SocketTool.h
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

typedef void (^ResponseBlock)(NSData *data, long tag, NSError *error);

@interface SocketTool : NSObject

// 客户端socket
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
// 链接状态
@property (nonatomic, assign, readonly) BOOL isConnected;
// 服务器地址
@property (nonatomic, strong, readonly) NSString *host;
// 服务器端口
@property (nonatomic, assign, readonly) uint16_t port;
// 链接超时时间
@property (nonatomic, assign, readonly) NSInteger timeOut;

@property (nonatomic, copy) ResponseBlock responseBlock;

- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port timeOut:(NSInteger)timeOut;

// 连接服务器
- (BOOL)connectedToHost;

// 断开链接
- (void)disconnected;

// 向服务器发送信息
- (void)sendMessageWithData:(NSData *)data responseBlock:(ResponseBlock)block;

@end
