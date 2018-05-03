//
//  XRVideoViewController.h
//  SocketTestDemo
//
//  Created by 369 on 2018/4/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XRHKVideoManager.h"

@interface XRVideoViewController : UIViewController

- (instancetype)initWithDeviceID:(NSString *)deviceID channels:(NSArray *)channels workType:(HKVideoWorkType)workType;

@end
