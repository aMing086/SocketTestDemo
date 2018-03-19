//
//  SocketTool.h
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface SocketTool : NSObject

// 客户端socket
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@end
