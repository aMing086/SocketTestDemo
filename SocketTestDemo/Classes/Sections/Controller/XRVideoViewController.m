//
//  XRVideoViewController.m
//  SocketTestDemo
//
//  Created by 369 on 2018/4/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRVideoViewController.h"
#import "SocketTool.h"

@interface XRVideoViewController ()<SocketToolDelegate, XRHKVideoManagerDelegate>
{
    NSString *_deviceID;
    NSArray<XR_VideoChannelInfo *> *_channels;
    HKVideoWorkType _workType;
    NSInteger   _selectedIndex;
}

@property (nonatomic, strong) NSMutableArray<XRHKVideoManager *> *videoManagers;
@property (nonatomic, strong) SocketTool *socketTool;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *playPauseBtn;

@end

@implementation XRVideoViewController

// 懒加载
- (SocketTool *)socketTool
{
    if (!_socketTool) {
        _socketTool = [[SocketTool alloc] initWithHost:@"58.215.179.52" port:8001 timeOut:-1 delegate:self];
    }
    return _socketTool;
}

- (instancetype)initWithDeviceID:(NSString *)deviceID channels:(NSArray *)channels workType:(HKVideoWorkType)workType
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle mainBundle]];
    if (self) {
        _deviceID = deviceID;
        _channels = channels;
        _workType = workType;
        _videoManagers = [NSMutableArray array];
        _selectedIndex = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self initData];
    [self initUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    for (XRHKVideoManager *videoManager in _videoManagers) {
        [videoManager stop];
    }
}

- (void)initUI
{
    self.title = @"视频播放";
}

- (void)initData
{
    for (XR_VideoChannelInfo *channelInfo in _channels) {
        
        XRTCPProtocol_VideoGetStreamIP *getStreamIP = [[XRTCPProtocol_VideoGetStreamIP alloc] init];
        getStreamIP.deviceID = _deviceID;
        getStreamIP.channelNo = channelInfo.nChannelNo;
        getStreamIP.workType = _workType;
        NSData *getStreamIPData = [getStreamIP encodePack];
        [self.socketTool sendMessageWithData:getStreamIPData];
    }
}

#pragma mark -Action
// 切换播放状态
- (IBAction)pauseOrPlayAction:(UIButton *)sender {
    if (_videoManagers.count > _selectedIndex) {
        XRHKVideoManager *videoManger = _videoManagers[_selectedIndex];
        switch (videoManger.playStatus) {
            case VideoManagerPlayStatusLoading:
            case VideoManagerPlayStatusPlaying:
            {
                [videoManger stop];
                [sender setTitle:@"播  放" forState:(UIControlStateNormal)];
                break;
            }
            case VideoManagerPlayStatusPause:
            {
                [videoManger play];
                [sender setTitle:@"暂  停" forState:(UIControlStateNormal)];
                break;
            }
                
            default:
                break;
        }
    }
    
}

// 开关声音
- (IBAction)openOrCloseSoundAction:(UIButton *)sender {
    
}

// 截屏
- (IBAction)screenCaptureAction:(UIButton *)sender {
    
}


#pragma mark -SocketToolDelegate
- (void)socketTool:(SocketTool *)tool readCompletePackData:(NSData *)packData
{
    XRTCPProtocol_Basic *basic = [XRVideoDataTool decodePackWithCompletePacketData:packData];
    if ([basic isKindOfClass:[XRTCPProtocol_VideoGetStreamIPAck class]]) {
        switch (_workType) {
            case HKVideoWorkTypePre:
            {
                XRTCPProtocol_VideoGetStreamIPAck *getStreamIPAck = (XRTCPProtocol_VideoGetStreamIPAck *)basic;
                NSInteger width = [UIScreen mainScreen].bounds.size.width;
                CGRect frame = CGRectMake((width / 2) * (_videoManagers.count % 2), 200 * (_videoManagers.count / 2), width / 2, 200);
                XRHKVideoManager *videoManager = [[XRHKVideoManager alloc] initWithFrame:frame getStreamIPAck:getStreamIPAck];
                videoManager.delegate = self;
                videoManager.videoMangerTag = _videoManagers.count;
                [_videoManagers addObject:videoManager];
                [self.contentView addSubview:videoManager];
                [videoManager play];
                break;
            }
            case HKVideoWorkTypeBackPlay:
            {
                
                break;
            }
                
            default:
                break;
        }
        
    }
}

- (void)socketTool:(SocketTool *)tool error:(NSError *)error
{
    
}

#pragma mark -XRHKVideoManagerDelegate
- (void)singalTapVideoManager:(XRHKVideoManager *)videoManager
{
    _selectedIndex = videoManager.videoMangerTag;
    switch (videoManager.playStatus) {
        case VideoManagerPlayStatusLoading:
        case VideoManagerPlayStatusPlaying:
        {
            [self.playPauseBtn setTitle:@"播  放" forState:(UIControlStateNormal)];
            break;
        }
        case VideoManagerPlayStatusPause:
        {
            [self.playPauseBtn setTitle:@"暂  停" forState:(UIControlStateNormal)];
            break;
        }
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
