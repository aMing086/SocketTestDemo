//
//  ViewController.m
//  SocketTestDemo
//
//  Created by 369 on 2018/2/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "ViewController.h"
#import "XRTCPProtocol_HK.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
{
    XRTCPProtocol_VideoChannelAck *videoChannelAck;
    XRTCPProtocol_VideoDeviceAck *deviceAck;
    XRTCPProtocol_VideoStartPreviewAck *startPreviewAck;
    XRTCPProtocol_VideoStopPreviewAck *stopPreviewAck;
    XRTCPProtocol_VideoGetPreviewStreamAck *getPreviewStreamAck;
    XRTCPProtocol_VideoPreviewStream *previewStream;
    
}

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL connectedTwo;
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) NSTimer *connectTimerTwo;


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

//- (void)setLogStr:(NSMutableString *)logStr
//{
//    _logStr = logStr;
//    self.textView.text = logStr;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.logStr = [NSMutableString stringWithString:@"Log:\n"];
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
    
    if (self.connected) {
        [self.clientSocket disconnect];
    } else {
        BOOL flag = [self.clientSocket connectToHost:@"58.215.179.52" onPort:[self.portTextField.text intValue] error:nil];
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

// 开始预览
- (IBAction)startPreview:(UIButton *)sender {
    XRTCPProtocol_VideoStartPreview *startPreview = [[XRTCPProtocol_VideoStartPreview alloc] init];
    startPreview.deviceID = @"123456";
    startPreview.channelNo = 3;
    startPreview.streamType = 0;
    [self.clientSocket writeData:[startPreview encodePack] withTimeout:-1 tag:startPreview.ProtocolValue];
}

// 停止预览
- (IBAction)stopPreview:(UIButton *)sender {
    XRTCPProtocol_VideoStopPreview *videoStopPreview = [[XRTCPProtocol_VideoStopPreview alloc] init];
    videoStopPreview.deviceID = startPreviewAck.deviceID;
    videoStopPreview.channelNo = startPreviewAck.channelNo;
    videoStopPreview.sessionID = startPreviewAck.sessionID;
    [self.clientSocket writeData:[videoStopPreview encodePack] withTimeout:-1 tag:videoStopPreview.ProtocolValue];
}

// 获取预览视频流
- (IBAction)getPreviewStream:(UIButton *)sender {
    
    if (!_connectedTwo) {
        BOOL flag = [self.clientSocket_two connectToHost:startPreviewAck.streamIP onPort:startPreviewAck.streamPort error:nil];
    }
    
    if (_connectedTwo) {
        XRTCPProtocol_VideoGetPreviewStream *videoGetPreviewStream = [[XRTCPProtocol_VideoGetPreviewStream alloc] init];
        videoGetPreviewStream.clientGUID = @"GUID123456";
        videoGetPreviewStream.deviceID = startPreviewAck.deviceID;
        videoGetPreviewStream.channelNo = startPreviewAck.channelNo;
        videoGetPreviewStream.sessionID = startPreviewAck.sessionID;
        
        [self.clientSocket_two writeData:[videoGetPreviewStream encodePack] withTimeout:-1 tag:2];
    }
    
}

// 停止接收预览视频流
- (IBAction)stopGetPreviewVideoStream:(UIButton *)sender {
    XRTCPProtocol_VideoStopPreviewStream *videoStopPreviewStream = [[XRTCPProtocol_VideoStopPreviewStream alloc] init];
    videoStopPreviewStream.clientGUID = @"GUID123456";
    videoStopPreviewStream.deviceID = startPreviewAck.deviceID;
    videoStopPreviewStream.channelNo = startPreviewAck.channelNo;
    videoStopPreviewStream.sessionID = startPreviewAck.sessionID;
    [self.clientSocket_two writeData:[videoStopPreviewStream encodePack] withTimeout:-1 tag:2];
}

#pragma mark -GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [self appendLogStr:[NSString stringWithFormat:@"连接成功，服务器IP：%@， 端口号：%hu\n", host, port]];
    if (port == 8002) {
        // 连接成功开启定时器
        [self addTimerTwo];
        // 连接后，可读取服务器端的数据
        [self.clientSocket_two readDataWithTimeout:-1 tag:2];
        self.connectedTwo = YES;
    }
    // 连接成功开启定时器
    [self addTimer];
    // 连接后，可读取服务器端的数据
    [self.clientSocket readDataWithTimeout:-1 tag:1];
    self.connected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // 处理从服务器端获取到的数据
    XRTCPProtocol_Basic *basic = [[XRTCPProtocol_Basic alloc] init];
    BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
    if (!flag) {
        NSLog(@"解析失败");
    }
//    XRTCPProtocol_Basic *basic;
//    BOOL flag;
    if (basic.ProtocolValue == 0x05) {
        basic = [[XRTCPProtocol_Contact alloc] init];
        flag = [basic decodePackWithData:data length:(int)[data length]];
    } else if (basic.ProtocolValue == 0x35) {
        basic = [[XRTCPProtocol_LoginAck alloc] init];
        flag = [basic decodePackWithData:data length:(int)[data length]];

    } else if (basic.ProtocolValue == 0x40) {
        XRTCPProtocol_Video * video = [[XRTCPProtocol_Video alloc] init];
        flag = [video decodePackWithData:data length:(int)[data length]];
        
        switch (video.videoCmd) {
            case 0x01:
            {
                videoChannelAck = [[XRTCPProtocol_VideoChannelAck alloc] init];
                flag = [videoChannelAck decodePackWithData:data length:(int)[data length]];
                video = videoChannelAck;
                break;
            }
            case 0x02:
            {
                deviceAck = [[XRTCPProtocol_VideoDeviceAck alloc] init];
                flag = [deviceAck decodePackWithData:data length:(int)[data length]];
                video = deviceAck;
                break;
            }
            case 0x10:
            {
                startPreviewAck = [[XRTCPProtocol_VideoStartPreviewAck alloc] init];
                flag = [startPreviewAck decodePackWithData:data length:(int)data.length];
                video = startPreviewAck;
                break;
            }
            case 0x11:
            {
                stopPreviewAck = [[XRTCPProtocol_VideoStopPreviewAck alloc] init];
                flag = [stopPreviewAck decodePackWithData:data length:(int)data.length];
                video = stopPreviewAck;
                break;
            }
            case 0x12:
            {
                getPreviewStreamAck = [[XRTCPProtocol_VideoGetPreviewStreamAck alloc] init];
                flag = [getPreviewStreamAck decodePackWithData:data length:(int)data.length];
                video = getPreviewStreamAck;
                break;
            }
            case 0x13:
            {
                previewStream = [[XRTCPProtocol_VideoPreviewStream alloc] init];
                flag = [previewStream decodePackWithData:data length:(int)data.length];
                video = previewStream;
                break;
            }
            
            default:
                break;
        }
        
        basic = video;
    }
    // 读取到服务器端数据后，继续读取
    [sock readDataWithTimeout:-1 tag:0];
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"%ld", tag);
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
        [self appendLogStr:@"断开连接\n"];
    } else {
        [self appendLogStr:[NSString stringWithFormat:@"%@\n",[err description]]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
