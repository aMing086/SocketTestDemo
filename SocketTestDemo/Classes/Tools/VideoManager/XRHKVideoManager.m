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

- (instancetype)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentView];
    
    self.playView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.playView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:self.playView];
}

- (void)play
{
    
}

@end
