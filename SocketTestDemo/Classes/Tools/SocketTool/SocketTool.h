//
//  SocketTool.h
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
@class SocketTool;

@protocol SocketToolDelegate <NSObject>

@optional
- (void)socketTool:(SocketTool *)tool readData:(NSData *)data;

- (void)socketTool:(SocketTool *)tool error:(NSError *)error;

@end

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

@property (nonatomic, weak) id<SocketToolDelegate> delegate;

/**
 * 初始化类
 * 初始化 GCDAsyncSocket 并发起链接服务器
 */
- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port timeOut:(NSInteger)timeOut delegate:(id<SocketToolDelegate >)delegate;

// 连接服务器
- (BOOL)connectedToHost;

// 断开链接
- (void)disconnected;

/**
 * 向服务器发送信息 同时确定服务器链接
 */
- (void)sendMessageWithData:(NSData *)data responseBlock:(ResponseBlock)block;

// 

@end
