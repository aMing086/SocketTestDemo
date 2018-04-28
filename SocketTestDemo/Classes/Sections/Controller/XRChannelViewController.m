//
//  XRChannelViewController.m
//  SocketTestDemo
//
//  Created by 369 on 2018/4/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRChannelViewController.h"
#import "SocketTool.h"
#import "XRTCPProtocol_HK.h"

@interface XRChannelViewController ()<UITableViewDelegate, UITableViewDataSource, SocketToolDelegate>

@property (weak, nonatomic) IBOutlet UITextField *deviceIDTF;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) SocketTool *socketTool;
@property (nonatomic, strong) XRTCPProtocol_VideoChannelAck *videoChannelAck;

@end

@implementation XRChannelViewController

- (SocketTool *)socketTool
{
    if (!_socketTool) {
        _socketTool = [[SocketTool alloc] initWithHost:@"58.215.179.52" port:8001 timeOut:-1 delegate:self];
    }
    return _socketTool;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    [self.socketTool connectedToHost];
    [self setupUI];
}

- (void)setupUI
{
    self.title = @"查询通道号";
    self.tableView.tableFooterView = [UIView new];
    self.tableView.allowsMultipleSelection = YES;
}

- (IBAction)searchChannel:(UIButton *)sender {
    [self.view endEditing:YES];
    XRTCPProtocol_VideoChannel *videoChannel = [[XRTCPProtocol_VideoChannel alloc] init];
    if (self.deviceIDTF.text.length == 0) {
        videoChannel.deviceID = @"123456";
        self.deviceIDTF.text = @"123456";
    } else {
        videoChannel.deviceID = self.deviceIDTF.text;
    }
    
    NSData *videoChannelData = [videoChannel encodePack];
    __block typeof(self) blockSelf = self;
    [self.socketTool sendMessageWithData:videoChannelData responseBlock:^(NSData *data, long tag, NSError *error) {
        XRTCPProtocol_Basic *basic = [[XRTCPProtocol_Basic alloc] init];
        BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
        if (flag) {
            if (basic.ProtocolValue == 0x40) {
                XRTCPProtocol_Video *video = [[XRTCPProtocol_Video alloc] init];
                flag = [video decodePackWithData:data length:(int)[data length]];
                if (flag && video.videoCmd == 0x01) {
                    blockSelf.videoChannelAck = [[XRTCPProtocol_VideoChannelAck alloc] init];
                    flag = [blockSelf.videoChannelAck decodePackWithData:data length:(int)[data length]];
                    if (flag) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadData];
                        });
                    }
                }
            }
        }
    }];
}

#pragma mark -UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark -UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.videoChannelAck) {
        return self.videoChannelAck.channelNum;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"defaultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:identifier];
        UIView *bgV = [[UIView alloc] init];
        bgV.backgroundColor = [UIColor colorWithRed:243 / 255.0 green:243 / 255.0 blue:243 / 255.0 alpha:1];
        cell.selectedBackgroundView = bgV;
    }
    XR_VideoChannelInfo *channelInfo = self.videoChannelAck.Channels[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"通道号：%d", channelInfo.nChannelNo];
    return cell;
}

#pragma mark -
- (void)socketTool:(SocketTool *)tool readData:(NSData *)data
{
    
}

- (void)socketTool:(SocketTool *)tool error:(NSError *)error
{
    
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
