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

@interface XRChannelViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *deviceIDTF;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) SocketTool *socketTool;
@property (nonatomic, strong) XRTCPProtocol_VideoChannelAck *videoChannelAck;

@end

@implementation XRChannelViewController

- (SocketTool *)socketTool
{
    if (!_socketTool) {
        _socketTool = [[SocketTool alloc] initWithHost:@"58.215.179.52" port:8001 timeOut:30];
    }
    return _socketTool;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)searchChannel:(UIButton *)sender {
    XRTCPProtocol_VideoChannel *videoChannel = [[XRTCPProtocol_VideoChannel alloc] init];
    videoChannel.deviceID = self.deviceIDTF.text;
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
                        [self.tableView reloadData];
                    }
                }
            }
        }
    }];
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
    }
    XR_VideoChannelInfo *channelInfo = self.videoChannelAck.Channels[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"通道号：%d", channelInfo.nChannelNo];
    return cell;
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
