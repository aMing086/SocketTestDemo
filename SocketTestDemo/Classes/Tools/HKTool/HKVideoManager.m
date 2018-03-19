//
//  HKVideoManager.m
//  SocketTestDemo
//
//  Created by 369 on 2018/3/14.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "HKVideoManager.h"
#import "MobilePlaySDKInterface.h"

@implementation HKVideoManager

- (instancetype)initWithHwnd:(void *)hWnd
{
    self = [super init];
    if (self) {
        self.hWnd = hWnd;
    }
    
    return self;
}

- (BOOL)playStreamData:(NSData *)streamData dataType:(NSInteger)dataType length:(uint)length
{
    if (1 == dataType) {
        // 获取播放库端口号
        if (!PlayM4_GetPort(&_nPort)) {
            [self stopPlay];
            return NO;
        }
        // 设置流模式
        if (!PlayM4_SetStreamOpenMode(_nPort, STREAME_REALTIME)) {
            [self stopPlay];
            return NO;
        }
        // 先打开流头文件
        if (!PlayM4_OpenStream(_nPort, (Byte *)[streamData bytes], length, 2 * 1024 * 1024/*设置缓冲区*/)) {
            [self stopPlay];
            return NO;
        }
        // 开始解码播放
        if (!PlayM4_Play(_nPort, _hWnd))
        {
            [self stopPlay];
            return NO;
        }
        
    } else {
        int time = 1000;
        while (time > 0) {
            // 播放数据流
            int inputRef = PlayM4_InputData(_nPort, (Byte *)[streamData bytes], length);
            if (!inputRef) {
                sleep(5);
                time--;
                continue;
            }
            break;
        }
        
    }
    return YES;
}

- (void)stopPlay
{
    
}

@end
