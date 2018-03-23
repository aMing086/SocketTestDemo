//
//  ViewController.h
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"

@interface ViewController : UIViewController

// 客户端socket
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket_two;

@end

