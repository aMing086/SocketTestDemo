//
//  XRVideoDataTool.h
//  SocketTestDemo
//
//  Created by 369 on 2018/3/29.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XRTCPProtocol_HK.h"

@interface XRVideoDataTool : NSObject

+ (XRTCPProtocol_VideoPreviewStream *)decodePreViewStreamFromData:(NSMutableData *)data;

+ (NSData *)getCompletePacketFromData:(NSMutableData *)data;

@end
