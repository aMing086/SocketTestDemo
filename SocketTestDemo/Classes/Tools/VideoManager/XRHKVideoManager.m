//
//  XRHKVideoManager.m
//  SocketTestDemo
//
//  Created by 369 on 2018/5/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRHKVideoManager.h"
#import "XRHKSDKManager.h"
#import "SocketTool.h"

@interface XRHKVideoManager()<SocketToolDelegate>

@property (nonatomic, strong) XRHKSDKManager *hkSDKManager;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *playView;
@property (nonatomic, strong) SocketTool *socketTool;

@end

@implementation XRHKVideoManager

// 懒加载
- (XRHKSDKManager *)hkSDKManager
{
    if (!_hkSDKManager) {
        _hkSDKManager = [[XRHKSDKManager alloc] initWithHwnd:(__bridge void *)self.playView];
    }
    return _hkSDKManager;
}

- (SocketTool *)socketTool
{
    if (!_socketTool) {
        _socketTool = [[SocketTool alloc] initWithHost:self.getStreamIPAck.streamIP port:self.getStreamIPAck.streamPort timeOut:-1 delegate:self];
    }
    return _socketTool;
}

- (instancetype)initWithFrame:(CGRect)frame getStreamIPAck:(XRTCPProtocol_VideoGetStreamIPAck *)getStreamIPAck
{
    self = [super initWithFrame:frame];
    if (self) {
        self.getStreamIPAck = getStreamIPAck;
        [self setupUI];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(singalTapVideoManager:)]) {
        [self.delegate singalTapVideoManager:self];
    }
}

- (void)doubleTapAction:(UITapGestureRecognizer *)gesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(doubleTapVideoManager:)]) {
        [self.delegate doubleTapVideoManager:self];
    }
}

- (void)setupUI
{
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentView];
    
    self.playView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.playView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:self.playView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    [tap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:tap];
}

- (void)play
{
    self.playStatus = VideoManagerPlayStatusLoading;
    XRTCPProtocol_VideoStartPreview *videoGetPreviewStream = [[XRTCPProtocol_VideoStartPreview alloc] init];
    videoGetPreviewStream.clientGUID = self.socketTool.clientGUID;
    videoGetPreviewStream.deviceID = _getStreamIPAck.deviceID;
    videoGetPreviewStream.channelNo = _getStreamIPAck.channelNo;
    videoGetPreviewStream.streamType = _streamType;
    NSData *videoGetPreviewStreamData = [videoGetPreviewStream encodePack];
    [self.socketTool sendMessageWithData:videoGetPreviewStreamData];
}

- (void)stop
{
    self.playStatus = VideoManagerPlayStatusPause;
    XRTCPProtocol_VideoStopPreview *videoStopPreview = [[XRTCPProtocol_VideoStopPreview alloc] init];
    videoStopPreview.clientGUID = self.socketTool.clientGUID;
    videoStopPreview.deviceID = _getStreamIPAck.deviceID;
    videoStopPreview.channelNo = _getStreamIPAck.channelNo;
    videoStopPreview.sessionID = _sessionID;
    [self.socketTool sendMessageWithData:[videoStopPreview encodePack]];
    [self.hkSDKManager stopPlayStream];
}

#pragma mark -SocketToolDelegate
- (void)socketTool:(SocketTool *)tool readCompletePackData:(NSData *)packData
{
    XRTCPProtocol_Basic *basic = [XRVideoDataTool decodePackWithCompletePacketData:packData];
    if ([basic isKindOfClass:[XRTCPProtocol_VideoStartPreviewAck class]]) {
        XRTCPProtocol_VideoStartPreviewAck *startPreviewAck = (XRTCPProtocol_VideoStartPreviewAck *)basic;
        _sessionID = startPreviewAck.sessionID;
        if (startPreviewAck.ResCode == 0) {
            self.playStatus = VideoManagerPlayStatusPlaying;
        } else {
            self.playStatus = VideoManagerPlayStatusError;
        }
    } else if ([basic isKindOfClass:[XRTCPProtocol_VideoPreviewStream class]]) {
        __block XRTCPProtocol_VideoPreviewStream *blockPreviewStream = (XRTCPProtocol_VideoPreviewStream *)basic;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hkSDKManager playStreamData:blockPreviewStream.videoData dataType:blockPreviewStream.dataType  length:[blockPreviewStream.videoData length]];
        });
    } else if ([basic isKindOfClass:[XRTCPProtocol_VideoStopPreviewAck class]]) {
        if (basic.ResCode == 0) {
            self.playStatus = VideoManagerPlayStatusPause;
        } else {
            self.playStatus = VideoManagerPlayStatusError;
        }
    }
}

- (void)socketTool:(SocketTool *)tool error:(NSError *)error
{
    
}

@end
