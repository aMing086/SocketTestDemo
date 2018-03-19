//
//  HKVideoManager.h
//  SocketTestDemo
//
//  Created by 369 on 2018/3/14.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HKVideoManager : NSObject

@property (nonatomic, assign, readonly) int nPort;
@property (nonatomic, assign) void *hWnd;

- (instancetype)initWithHWnd:(void *)hWnd;

- (BOOL)playStreamData:(NSData *)streamData dataType:(NSInteger)dataType length:(uint)length;

- (void)stopPlay;

@end