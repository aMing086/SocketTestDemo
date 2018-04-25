//
//  HKVideoManager.m
//  SocketTestDemo
//
//  Created by 369 on 2018/3/14.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "HKVideoManager.h"
#import "MobilePlaySDKInterface.h"

@interface HKVideoManager()
{
    BOOL _bSound;
}
@end

@implementation HKVideoManager

- (instancetype)initWithHwnd:(void *)hWnd
{
    self = [super init];
    if (self) {
        self.hWnd = hWnd;
        _bSound = YES;
    }
    
    return self;
}

- (BOOL)playStreamData:(NSData *)streamData dataType:(NSInteger)dataType length:(uint)length
{
    if (streamData == nil) {
        return NO;
    }
    if (1 == dataType) {
        // 获取播放库端口号
        if (!PlayM4_GetPort(&_nPort)) {
            [self stopPlayStream];
            return NO;
        }
        // 设置流模式
        if (!PlayM4_SetStreamOpenMode(_nPort, STREAME_REALTIME)) {
            [self stopPlayStream];
            return NO;
        }
        // 先打开流头文件
        if (!PlayM4_OpenStream(_nPort, (Byte *)[streamData bytes], length, 2 * 1024 * 1024/*设置缓冲区*/)) {
            [self stopPlayStream];
            return NO;
        }
        _PlayStatus = YES;
        // 开始解码播放
        if (!PlayM4_Play(_nPort, _hWnd))
        {
            [self stopPlayStream];
            return NO;
        }
    } else if (self.PlayStatus){
        if (_bSound) {
            if (!_soundStatus) {
                if (PlayM4_PlaySoundShare(_nPort)) {
                    _soundStatus = YES;
                }
            }
        } else {
            if (_soundStatus) {
                if (PlayM4_StopSoundShare(_nPort)) {
                    _soundStatus = NO;
                }
            }
        }
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

// 停止播放
- (void)stopPlayStream
{
    if (!PlayM4_Stop(_nPort)) {
        
    }
    _PlayStatus = NO;
    if (!PlayM4_StopSoundShare(_nPort)) {
        
    }
    _soundStatus = NO;
    if (!PlayM4_CloseStream(_nPort)) {
        
    }
    if (!PlayM4_FreePort(_nPort)) 
    _nPort = -1;
}

// 抓图
- (NSData *)screenshotsWithImageType:(HKVideoImageType)imageType
{
    if (!_PlayStatus) {
        return nil;
    }
    switch (imageType) {
        case HKVideoImageTypeBMP:
        {
            int BufSize = 1024 * 1024 * 3/2;
            char *imageBuf = (char *)malloc(BufSize);
            int pSize = 0;
            if (!PlayM4_GetBMP(_nPort, imageBuf, BufSize, pSize)) {
                NSData *imageData = [NSData dataWithBytes:imageBuf length:pSize];
                return imageData;
            }
            return nil;
            break;
        }
        case HKVideoImageTypeBMPEx:
        {
            int BufSize = 1024 * 1024 * 3/2;
            char *imageBuf = (char *)malloc(BufSize);
            int pSize = 0;
            if (!PlayM4_GetBMPEx(_nPort,imageBuf , BufSize, &pSize)) {
                NSData *imageData = [NSData dataWithBytes:imageBuf length:pSize];
                return imageData;
            }
            return nil;
            break;
        }
            
        default:
        {
            int BufSize = 1024 * 1024 * 3/2;
            char *imageBuf = (char *)malloc(BufSize);
            int pSize = 0;
            if (!PlayM4_GetJPEG(_nPort,imageBuf , BufSize, &pSize)) {
                NSData *imageData = [NSData dataWithBytes:imageBuf length:pSize];
                return imageData;
            }
            return nil;
            break;
        }
    }
}

- (void)playSound:(BOOL)flag
{
    _bSound = flag;
}

// 同步回放
- (BOOL)sycPlayBackWithFileNames:(NSArray *)fileNames dwGroupIndex:(int)index
{
    // 获取播放库端口号
    if (!PlayM4_GetPort(&_nPort)) {
        [self stopPlayBack];
        return NO;
    }
    for (NSString *fileName in fileNames) {
        // 打开文件
        if (!PlayM4_OpenFile(_nPort, [[fileName dataUsingEncoding:NSUTF8StringEncoding] bytes])) {
            [self stopPlayBack];
            return NO;
        }
    }
    
    // 设置同步回放
    if (!PlayM4_SetSycGroup(_nPort, index)) {
        [self stopPlayBack];
        return NO;
    }
    _PlayStatus = YES;
    // 开始解码播放
    if (!PlayM4_Play(_nPort, _hWnd))
    {
        [self stopPlayBack];
        return NO;
    }
    
    return YES;
}

// 停止回放
- (void)stopPlayBack
{
    if (!PlayM4_Stop(_nPort)) {
        
    }
    _PlayStatus = NO;
    if (!PlayM4_StopSoundShare(_nPort)) {
        
    }
    _soundStatus = NO;
    if (!PlayM4_CloseFile(_nPort)) {
        
    }
    if (!PlayM4_FreePort(_nPort))
        _nPort = -1;
}

@end
