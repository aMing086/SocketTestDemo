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

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) NSTimer *connectTimer;


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

- (void)sendMessageWithData:(NSData *)data
{
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

- (void)addTimer
{
    // 连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前runloop中，并设置为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

- (void)longConnectToSocket
{
    XRTCPProtocol_Contact *contact = [[XRTCPProtocol_Contact alloc] init];
    contact.ProtocolValue = 0x05;
    contact.Length = 23;
    NSData *data = [contact encodePack];
    // 发送固定格式的数据，指令@“longConnect”
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
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
    }
    
}

#pragma mark -GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [self appendLogStr:[NSString stringWithFormat:@"连接成功，服务器IP：%@， 端口号：%hu\n", host, port]];
    // 连接成功开启定时器
    [self addTimer];
    // 连接后，可读取服务器端的数据
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    self.connected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // 处理从服务器端获取到的数据
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XRTCPProtocol_Basic *basic = [[XRTCPProtocol_Basic alloc] init];
    BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
    if (!flag) {
        NSLog(@"解析失败");
    }
    switch (basic.ProtocolValue) {
        case 0x05:
        {
            basic = [[XRTCPProtocol_Contact alloc] init];
            [basic decodePackWithData:data length:[data length]];
            break;
        }
        default:
            break;
    }
    // 读取到服务器端数据后，继续读取
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"%d", tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
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
