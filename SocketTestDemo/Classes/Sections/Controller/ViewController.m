//
//  ViewController.m
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "ViewController.h"
#import "XRTCPProtocol_HK.h"
#import "XRHKSDKManager.h"
#import "XRVideoDataTool.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
{
    XRTCPProtocol_Basic *basic;
    XRTCPProtocol_Video *video;
    XRTCPProtocol_VideoChannelAck *videoChannelAck;
    XRTCPProtocol_VideoDeviceAck *deviceAck;
    XRTCPProtocol_VideoGetStreamIPAck *getStreamIPAck;
    XRTCPProtocol_VideoStartPreviewAck *startPreviewAck;
    XRTCPProtocol_VideoPreviewStream *previewStream;
    XRTCPProtocol_VideoStopPreviewAck *stopPreviewAck;
    XRTCPProtocol_VideoQueryFileAck *queryFileAck;
    XRTCPProtocol_VideoStartPlayBackAck *startPlayBackAck;
    NSMutableData *_videoData;
    NSMutableData *_playData;
    NSMutableDictionary *_videoDic;
    NSInteger  _index;
    BOOL _isEmpty;
    BOOL _isPlay;
    BOOL _isStream;
}

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL connectedTwo;
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) NSTimer *connectTimerTwo;
@property (nonatomic, strong) XRHKSDKManager *hkSDKManager;


@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (nonatomic, strong) NSMutableString *logStr;

@end

@implementation ViewController

// 懒加载
- (GCDAsyncSocket *)clientSocket
{
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clientSocket;
}

- (GCDAsyncSocket *)clientSocket_two
{
    if (!_clientSocket_two) {
        _clientSocket_two = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clientSocket_two;
}

- (XRHKSDKManager *)hkSDKManager
{
    if (!_hkSDKManager) {
        _hkSDKManager = [[XRHKSDKManager alloc] initWithHwnd:(__bridge void *)self.playView];
    }
    return _hkSDKManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.logStr = [NSMutableString string];
    [self appendLogStr:@"Log:\n"];
    _videoData = [NSMutableData data];
    _playData = [NSMutableData data];
    dispatch_queue_t queue = dispatch_queue_create("com.video", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        while (1) {
            if (_playData.length == 0) {
                _isEmpty = YES;
                [NSThread sleepForTimeInterval:0.1];
                continue;
            }
            @synchronized(self) {
                XRTCPProtocol_VideoPreviewStream *tempPreviewStream = [XRVideoDataTool decodePreViewStreamFromData:_playData];
                if (tempPreviewStream == nil) {
                    _isEmpty = YES;
                    [NSThread sleepForTimeInterval:0.1];
                    continue;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.hkSDKManager playStreamData:tempPreviewStream.videoData dataType:tempPreviewStream.dataType  length:[tempPreviewStream.videoData length]];
//                    NSLog(@"%d", tempPreviewStream.dataType);
                });

            }
            
            
        }
        
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopPreview:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (void)sendMessageWithData:(NSData *)data
{
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

- (void)addTimer
{
    // 连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前runloop中，并设置为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

- (void)longConnectToSocket
{
    XRTCPProtocol_Contact *contact = [[XRTCPProtocol_Contact alloc] init];
    NSData *data = [contact encodePack];
    // 发送固定格式的数据，指令@“longConnect”
    [self.clientSocket writeData:data withTimeout:-1 tag:contact.ProtocolValue];
}

- (void)addTimerTwo
{
    // 连接定时器
    self.connectTimerTwo = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(longConnectToSocketTwo) userInfo:nil repeats:YES];
    // 把定时器添加到当前runloop中，并设置为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimerTwo forMode:NSRunLoopCommonModes];
}

- (void)longConnectToSocketTwo
{
    XRTCPProtocol_Contact *contact = [[XRTCPProtocol_Contact alloc] init];
    NSData *data = [contact encodePack];
    // 发送固定格式的数据，指令@“longConnect”
    [self.clientSocket_two writeData:data withTimeout:-1 tag:contact.ProtocolValue];
}

// 添加操作日志
- (void)appendLogStr:(NSString *)str
{
    [self.logStr appendString:str];
    self.textView.text = self.logStr;
}

#pragma mark -Action
// 连接服务器
- (IBAction)linkServiceAction:(UIButton *)sender {
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"123456-1-51184" ofType:@"mp4"];
//    NSData *data = [NSData dataWithContentsOfFile:path];
//    NSInteger index = 0;
//    for (int i = 0; i < 1000; i++) {
//        if (i == 0) {
//            [self.videoManager playStreamData:[data subdataWithRange:NSMakeRange(index, 40)] dataType:1 length:40];
//            index += 40;
//        } else {
//            if (data.length >= index + 1400) {
//                if (i > 5) {
//                    NSLog(@"%d", i);
//                    [self.videoManager playStreamData:[data subdataWithRange:NSMakeRange(index, 1400)] dataType:2 length:1400];
//                    index += 1400;
//                }
//
//            } else {
//                index = 40;
//                [self.videoManager playStreamData:[data subdataWithRange:NSMakeRange(index, 1400)] dataType:2 length:1400];
//            }
//
//        }
//    }
    
    if (self.connected) {
        [self.clientSocket disconnect];
    } else {
        BOOL flag = [self.clientSocket connectToHost:@"58.215.179.52" onPort:[self.portTextField.text intValue] withTimeout:5.0 error:nil];
        if (!flag) {
            NSLog(@"连接失败");
        }
    }
    
}

// 身份认证
- (IBAction)loginAction:(UIButton *)sender {
    
    XRTCPProtocol_Login *login = [[XRTCPProtocol_Login alloc] init];
    login.GUID = @"GUID123456";
    login.UserName = @"video";
    login.Password = @"123456";
    NSData *loginData = [login encodePack];
    [self.clientSocket writeData:loginData withTimeout:-1 tag:login.ProtocolValue];
}

// 获取通道号
- (IBAction)getVideoChannel:(UIButton *)sender {
    XRTCPProtocol_VideoChannel *videoChannel = [[XRTCPProtocol_VideoChannel alloc] init];
    videoChannel.deviceID = @"123456";
    NSData *videoChannelData = [videoChannel encodePack];
    [self.clientSocket writeData:videoChannelData withTimeout:-1 tag:videoChannel.ProtocolValue];
}

// 获取设备信息
- (IBAction)getDeviceInfoAction:(UIButton *)sender {
    XRTCPProtocol_VideoDevice *videoDevice = [[XRTCPProtocol_VideoDevice alloc] init];
    videoDevice.deviceID = @"123456";
    NSData *videoDeviceData = [videoDevice encodePack];
    [self.clientSocket writeData:videoDeviceData withTimeout:-1 tag:videoDevice.ProtocolValue];
}

// 获取流服务器地址
- (IBAction)getStreamIP:(UIButton *)sender {
    XRTCPProtocol_VideoGetStreamIP *getStreamIP = [[XRTCPProtocol_VideoGetStreamIP alloc] init];
    getStreamIP.deviceID = @"123456";
    getStreamIP.channelNo = 4;
    getStreamIP.workType = 2;
    [self.clientSocket writeData:[getStreamIP encodePack] withTimeout:-1 tag:getStreamIP.ProtocolValue];
}

// 开始预览
- (IBAction)startPreview:(UIButton *)sender {
    
    if (!self.clientSocket_two.isConnected) {
        [self.clientSocket_two connectToHost:getStreamIPAck.streamIP onPort:getStreamIPAck.streamPort withTimeout:5.0 error:nil];
    }
    
    if (self.clientSocket_two.isConnected) {
        XRTCPProtocol_VideoStartPreview *videoGetPreviewStream = [[XRTCPProtocol_VideoStartPreview alloc] init];
        videoGetPreviewStream.clientGUID = @"GUID123456";
        videoGetPreviewStream.deviceID = getStreamIPAck.deviceID;
        videoGetPreviewStream.channelNo = getStreamIPAck.channelNo;
        videoGetPreviewStream.streamType = 0;
        [self.clientSocket_two writeData:[videoGetPreviewStream encodePack] withTimeout:-1 tag:2];
    }
    
}

// 停止接收预览视频流
- (IBAction)stopPreview:(UIButton *)sender {
    XRTCPProtocol_VideoStopPreview *videoStopPreview = [[XRTCPProtocol_VideoStopPreview alloc] init];
    videoStopPreview.clientGUID = @"GUID123456";
    videoStopPreview.deviceID = getStreamIPAck.deviceID;
    videoStopPreview.channelNo = getStreamIPAck.channelNo;
    videoStopPreview.sessionID = startPreviewAck.sessionID;
    [self.clientSocket_two writeData:[videoStopPreview encodePack] withTimeout:-1 tag:2];
    
    [self.hkSDKManager stopPlayStream];
}

- (IBAction)queryVideoFile:(UIButton *)sender
{
    XRTCPProtocol_VideoQueryFile *queryFile = [[XRTCPProtocol_VideoQueryFile alloc] init];
    queryFile.clientGUID = @"GUID123456";
    queryFile.deviceID = getStreamIPAck.deviceID;
    queryFile.channelNo = getStreamIPAck.channelNo;
    queryFile.videoType = 0xff;
    NSString *timeStr = @"2018-04-26 15:00:00";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *startDate = [formatter dateFromString:timeStr];
    queryFile.startTime = [[XRTCPProtocol_Time alloc] initWithDate:startDate];
    NSString *endTimeStr = @"2018-04-26 16:10:00";
    queryFile.endTime = [[XRTCPProtocol_Time alloc] initWithDate:[formatter dateFromString:endTimeStr]];
    queryFile.index = 0;
    queryFile.OnceQueryNum = 1;
    queryFile.dateType = 0;
    [self.clientSocket writeData:[queryFile encodePack] withTimeout:-1 tag:2];
}

// 开始回放
- (IBAction)startPalyBackAction:(UIButton *)sender
{
    if (!self.clientSocket_two.isConnected) {
        [self.clientSocket_two connectToHost:getStreamIPAck.streamIP onPort:getStreamIPAck.streamPort withTimeout:5.0 error:nil];
    }
    
    if (self.clientSocket_two.isConnected) {
    XRTCPProtocol_VideoStartPlayBack *startPlayBack = [[XRTCPProtocol_VideoStartPlayBack alloc] init];
    startPlayBack.clientGUID = @"guid123456";
    startPlayBack.deviceID = queryFileAck.deviceID;
    startPlayBack.channelNo = queryFileAck.channelNo;
    startPlayBack.playBackType = 0;
    XR_VideoFileInfo *file = queryFileAck.fileInfos[0];
    startPlayBack.fileName = file.fileName;
    startPlayBack.calculationType = 0;
    startPlayBack.fileOffset = 0;
    startPlayBack.fileSize = file.fileSize;
    NSString *timeStr = @"2018-04-26 15:00:00";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *startDate = [formatter dateFromString:timeStr];
    startPlayBack.startTime = [[XRTCPProtocol_Time alloc] initWithDate:startDate];
    NSString *endTimeStr = @"2018-04-26 16:10:00";
    startPlayBack.endTime = [[XRTCPProtocol_Time alloc] initWithDate:[formatter dateFromString:endTimeStr]];
    NSData *data = [startPlayBack encodePack];
    [self.clientSocket_two writeData:data withTimeout:-1 tag:2];
    }
}

- (IBAction)stopPlayBackAction:(UIButton *)sender {
    XRTCPProtocol_VideoStopPlayBack *stopPlayBack = [[XRTCPProtocol_VideoStopPlayBack alloc] init];
    stopPlayBack.clientGUID = @"guid123456";
    stopPlayBack.deviceID = queryFileAck.deviceID;
    stopPlayBack.channelNo = queryFileAck.channelNo;
    stopPlayBack.sessionID = startPlayBackAck.sessionID;
    NSData *data = [stopPlayBack encodePack];
    [self.clientSocket_two writeData:data withTimeout:-1 tag:2];
}


#pragma mark -GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendLogStr:[NSString stringWithFormat:@"连接成功，服务器IP：%@， 端口号：%hu\n", host, port]];
    });
    if (port == 8002) {
        // 连接成功开启定时器
        [self addTimerTwo];
        // 连接后，可读取服务器端的数据
        [self.clientSocket_two readDataWithTimeout:-1 tag:2];
        self.connectedTwo = YES;
    }
    // 连接成功开启定时器
//    [self addTimer];
    // 连接后，可读取服务器端的数据
    [sock readDataWithTimeout:-1 tag:1];
    self.connected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    // 处理从服务器端获取到的数据
    if (!basic) {
        basic = [[XRTCPProtocol_Basic alloc] init];
    }
    BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
    if (flag) {
        if (basic.ProtocolValue == 0x05) {
            flag = [[[XRTCPProtocol_Contact alloc] init] decodePackWithData:data length:(int)[data length]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendLogStr:[NSString stringWithFormat:@"Protocol：%d decode:%d ResCode：%d\n", basic.ProtocolValue, flag, basic.ResCode]];
            });
        } else if (basic.ProtocolValue == 0x35) {
            flag = [[[XRTCPProtocol_LoginAck alloc] init] decodePackWithData:data length:(int)[data length]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendLogStr:[NSString stringWithFormat:@"Protocol：%d decode:%d ResCode：%d\n", basic.ProtocolValue, flag, basic.ResCode]];
            });
        } else if (basic.ProtocolValue == 0x40) {
            if (!video) {
                video = [[XRTCPProtocol_Video alloc] init];
            }
            flag = [video decodePackWithData:data length:(int)[data length]];
            
            switch (video.videoCmd) {
                case 0x01:
                {
                    videoChannelAck = [[XRTCPProtocol_VideoChannelAck alloc] init];
                    flag = [videoChannelAck decodePackWithData:data length:(int)[data length]];
                    break;
                }
                case 0x02:
                {
                    deviceAck = [[XRTCPProtocol_VideoDeviceAck alloc] init];
                    flag = [deviceAck decodePackWithData:data length:(int)[data length]];
                    break;
                }
                case 0x10:
                {
                    getStreamIPAck = [[XRTCPProtocol_VideoGetStreamIPAck alloc] init];
                    flag = [getStreamIPAck decodePackWithData:data length:(int)data.length];
                    break;
                }
                    
                case 0x12:
                {
                    startPreviewAck = [[XRTCPProtocol_VideoStartPreviewAck alloc] init];
                    flag = [startPreviewAck decodePackWithData:data length:(int)data.length];
                    [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
                    [_playData replaceBytesInRange:NSMakeRange(0, _playData.length) withBytes:NULL length:0];
                    NSLog(@"开会预览：%@", data);
                    _isStream = NO;
                    _isPlay = YES;
                    break;
                }
                case 0x13:
                {
                    [_videoData appendData:data];
                    if (_isEmpty) {
                        _isEmpty = NO;
                        [_playData appendData:_videoData];
                        [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
                    }
                    //                    dispatch_queue_t queue = dispatch_queue_create("com.video", DISPATCH_QUEUE_CONCURRENT);
                    //                    dispatch_async(queue, ^{
                    //                        XRTCPProtocol_VideoPreviewStream *tempPreviewStream = [[XRTCPProtocol_VideoPreviewStream alloc] init];
                    //                        BOOL f = [tempPreviewStream decodePackWithData:data length:(int)data.length];
                    //                        if (f) {
                    //                            [self.videoManager playStreamData:tempPreviewStream.videoData dataType:tempPreviewStream.dataType  length:[tempPreviewStream.videoData length]];
                    //                        }
                    //                    });
                    //                    if (!_isStream) {
                    //                        _isStream = YES;
                    //                        dispatch_queue_t queue = dispatch_queue_create("com.video", NULL);
                    //                        dispatch_async(dispatch_get_main_queue(), ^{
                    //                            if (_videoDataArray.count == 0) {
                    //                                _isStream = NO;
                    //                                return ;
                    //                            }
                    //                            for (int i = 0; i < _videoDataArray.count; i++) {
                    //                                NSData *tempData = _videoDataArray.firstObject;
                    //                                XRTCPProtocol_VideoPreviewStream *tempPreviewStream = [[XRTCPProtocol_VideoPreviewStream alloc] init];
                    //                                BOOL f = [tempPreviewStream decodePackWithData:tempData length:(int)tempData.length];
                    //                                if (f) {
                    //                                    [self.videoManager playStreamData:tempPreviewStream.videoData dataType:tempPreviewStream.dataType  length:[tempPreviewStream.videoData length]];
                    //                                }
                    //                                [_videoDataArray removeObjectAtIndex:0];
                    //                                i = 0;
                    //                            }
                    //                            if (_videoDataArray.count == 0) {
                    //                                _isStream = NO;
                    //                                return ;
                    //                            }
                    //                        });
                    //                    }
                    
                    /*
                     if (flag) {
                     NSThread *thread = [NSThread currentThread];
                     NSLog(@"%@", thread.name);
                     dispatch_async(dispatch_get_global_queue(0, 0), ^{
                     dispatch_async(dispatch_get_main_queue(), ^{
                     [self.videoManager playStreamData:previewStream.videoData dataType:previewStream.dataType length:[previewStream.videoData length]];
                     //                            if (!self.videoManager.PlayStatus) {
                     //                                NSString *path = [[NSBundle mainBundle] pathForResource:@"123456-1-51184" ofType:@"mp4"];
                     //                                NSData *data = [NSData dataWithContentsOfFile:path];
                     //                                [self.videoManager playStreamData:[data subdataWithRange:NSMakeRange(0, 40)] dataType:1 length:40];
                     //                            } else {
                     //                                _index++;
                     //                                if (_index > 1000) {
                     //                                    return ;
                     //                                }
                     //
                     //                            }
                     });
                     });
                     }
                     */
                    
                    break;
                }
                case 0x14:
                {
                    _isPlay = NO;
                    stopPreviewAck = [[XRTCPProtocol_VideoStopPreviewAck alloc] init];
                    flag = [stopPreviewAck decodePackWithData:data length:[data length]];
                    break;
                }
                case 0x15:
                {
                    queryFileAck = [[XRTCPProtocol_VideoQueryFileAck  alloc] init];
                    flag = [queryFileAck decodePackWithData:data length:[data length]];
                    break;
                }
                case 0x16:
                {
                    startPlayBackAck = [[XRTCPProtocol_VideoStartPlayBackAck alloc] init];
                    flag = [startPlayBackAck decodePackWithData:data length:data.length];
                    break;
                }
                case 0x17:
                {
                    [_videoData appendData:data];
                    if (_isEmpty) {
                        _isEmpty = NO;
                        [_playData appendData:_videoData];
                        [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
                    }
                    break;
                }
                default:
                    break;
            }
            
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                [self appendLogStr:[NSString stringWithFormat:@"Protocol：%d_%d decode:%d ResCode：%d\n", video.ProtocolValue, video.videoCmd, flag, basic.ResCode]];
            //            });
        }
    } else {
        if (_isPlay) {
            [_videoData appendData:data];
            if (_isEmpty) {
                _isEmpty = NO;
                [_playData appendData:_videoData];
                [_videoData replaceBytesInRange:NSMakeRange(0, _videoData.length) withBytes:NULL length:0];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendLogStr:[NSString stringWithFormat:@"解析失败！\n"]];
            });
        }
    }
    
   
    // 读取到服务器端数据后，继续读取
    [sock readDataWithTimeout:-1 tag:0];
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
//    NSLog(@"%ld", tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    
//    if(self.reconnection_time >=0 && self.reconnection_time <= kMaxReconnection_time) {
//
//        [self.timer invalidate];
//
//        self.timer=nil;
//
//        int time =pow(2,self.reconnection_time);
//
//        self.timer= [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(reconnection) userInfo:nil repeats:NO];
//
//        self.reconnection_time++;
//
//        NSLog(@"socket did reconnection,after %ds try again",time);
//
//    } else {
//
//        self.reconnection_time=0;
//
//        NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
//    }
    if (!err) {
        self.connected = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self appendLogStr:@"断开连接\n"];
        });
    } else {
        [sock disconnect];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self appendLogStr:[NSString stringWithFormat:@"%@\n",[err description]]];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
