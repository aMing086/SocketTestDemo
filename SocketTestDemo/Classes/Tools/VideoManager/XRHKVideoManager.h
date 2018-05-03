//
//  XRHKVideoManager.h
//  SocketTestDemo
//
//  Created by 369 on 2018/5/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XRTCPProtocol_HK.h"

typedef enum
{
    VideoManagerPlayStatusLoading, // 正在加载
    VideoManagerPlayStatusPlaying, // 正在播放
    VideoManagerPlayStatusPause, // 暂停
    VideoManagerPlayStatusError, // 播放错误
}VideoManagerPlayStatus;

@class XRHKVideoManager;

@protocol XRHKVideoManagerDelegate<NSObject>

@optional
- (void)singalTapVideoManager:(XRHKVideoManager *)videoManager;
- (void)doubleTapVideoManager:(XRHKVideoManager *)videoManager;

- (void)videoManager:(XRHKVideoManager *)videoManager playStatusChanged:(VideoManagerPlayStatus)playStatus;

@end

@interface XRHKVideoManager : UIView

@property (nonatomic, assign) NSInteger videoMangerTag;
@property (nonatomic, assign) int streamType;
@property (nonatomic, assign) NSInteger sessionID;
@property (nonatomic, strong) XRTCPProtocol_VideoGetStreamIPAck *getStreamIPAck;
@property (nonatomic, weak) id<XRHKVideoManagerDelegate> delegate;
@property (nonatomic, assign) VideoManagerPlayStatus playStatus; // 播放状态

- (instancetype)initWithFrame:(CGRect)frame getStreamIPAck:(XRTCPProtocol_VideoGetStreamIPAck *)getStreamIPAck;

- (void)play;

- (void)stop;

@end
