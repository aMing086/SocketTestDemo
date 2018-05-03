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
#import "XRVideoViewController.h"

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
    self.navigationController.navigationBar.translucent = NO;
    [self setupUI];
}

- (void)setupUI
{
    self.title = @"查询通道号";
    self.tableView.tableFooterView = [UIView new];
    self.tableView.allowsMultipleSelection = YES;
}

#pragma mark -Action
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
    [self.socketTool sendMessageWithData:videoChannelData];
    /*
     __block typeof(self) blockSelf = self;
    [self.socketTool sendMessageWithData:videoChannelData responseBlock:^(NSData *data, long tag, NSError *error) {
        XRTCPProtocol_Basic *basic = [[XRTCPProtocol_Basic alloc] init];
        BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
        if (flag) {
            if (basic.ProtocolValue == 0x40) {
                XRTCPProtocol_Video *video = [[XRTCPProtocol_Video alloc] init];
                flag = [video decodePackWithData:data length:(int)[data length]];
                if (flag && video.videoCmd == 0x01) {
     
                    }
                }
            }
        }
    }];
     */
}

- (IBAction)previewAction:(UIButton *)sender {
    NSArray *indexPahts = self.tableView.indexPathsForSelectedRows;
    if (indexPahts.count == 0) {
        
    }
    NSMutableArray *channels = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPahts) {
        XR_VideoChannelInfo *channel = self.videoChannelAck.Channels[indexPath.row];
        [channels addObject:channel];
    }
    XRVideoViewController *videoVC = [[XRVideoViewController alloc] initWithDeviceID:self.deviceIDTF.text channels:channels workType:HKVideoWorkTypePre];
    [self.navigationController pushViewController:videoVC animated:YES];
}

- (IBAction)backPlayAction:(UIButton *)sender {
    NSArray *indexPahts = self.tableView.indexPathsForSelectedRows;
    if (indexPahts.count == 0) {
        
    }
    NSMutableArray *channels = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPahts) {
        XR_VideoChannelInfo *channel = self.videoChannelAck.Channels[indexPath.row];
        [channels addObject:channel];
    }
    XRVideoViewController *videoVC = [[XRVideoViewController alloc] initWithDeviceID:self.deviceIDTF.text channels:channels workType:HKVideoWorkTypeBackPlay];
    [self.navigationController pushViewController:videoVC animated:YES];
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

#pragma mark -SockToolDelegate
- (void)socketTool:(SocketTool *)tool readCompletePackData:(NSData *)packData
{
    XRTCPProtocol_Basic *basic = [XRVideoDataTool decodePackWithCompletePacketData:packData];
    if ([basic isKindOfClass:[XRTCPProtocol_VideoChannelAck class]]) {
        self.videoChannelAck = basic;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.videoChannelAck.channelNum == 0) {
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"未获取到通道信息！" preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alertC addAction:sureAction];
                [self.navigationController presentViewController:alertC animated:YES completion:nil];
            }
            [self.tableView reloadData];
        });
    }
    
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
