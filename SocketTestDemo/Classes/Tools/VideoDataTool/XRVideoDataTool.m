//
//  XRVideoDataTool.m
//  SocketTestDemo
//
//  Created by 369 on 2018/3/29.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRVideoDataTool.h"
@implementation XRVideoDataTool

+ (XRTCPProtocol_VideoPreviewStream *)decodePreViewStreamFromData:(NSMutableData *)data
{
    if (data.length < XRCP_MINPACK_LEN) {
        return nil;
    }
    int i, nStart = -1;
    Byte *buf = data.bytes;
    for (i = 0; i < data.length - 1; i++) {
        if (buf[i] == XRCP_HEAD) {
            if (buf[i + 1] == XRCP_HEAD) {
                nStart = i + 1;
            } else {
                nStart = i;
            }
            break;
        }
    }
    if (nStart == -1) {
        [data replaceBytesInRange:NSMakeRange(0, data.length) withBytes:NULL length:0];
        return nil;
    } else if (nStart > 0) {
        [data replaceBytesInRange:NSMakeRange(0, nStart) withBytes:NULL length:0];

    }
    Byte *tempBuf = data.bytes;
    for (i = 1; i < data.length; i++) {
        if (tempBuf[i] == XRCP_TAIL) {
            XRTCPProtocol_VideoPreviewStream *previewStream = [[XRTCPProtocol_VideoPreviewStream alloc] init];
            [previewStream decodePackWithData:[data subdataWithRange:NSMakeRange(0, i+1)] length:i+ 1];
            [data replaceBytesInRange:NSMakeRange(0, i+1) withBytes:NULL length:0];
            return previewStream;
        }
    }
    return nil;
}

+ (NSData *)getCompletePacketFromData:(NSMutableData *)data
{
    if (data.length < XRCP_MINPACK_LEN) {
        return nil;
    }
    int i, nStart = -1;
    Byte *buf = data.bytes;
    for (i = 0; i < data.length - 1; i++) {
        if (buf[i] == XRCP_HEAD) {
            if (buf[i + 1] == XRCP_HEAD) {
                nStart = i + 1;
            } else {
                nStart = i;
            }
            break;
        }
    }
    if (nStart == -1) {
        [data replaceBytesInRange:NSMakeRange(0, data.length) withBytes:NULL length:0];
        return nil;
    } else if (nStart > 0) {
        [data replaceBytesInRange:NSMakeRange(0, nStart) withBytes:NULL length:0];
        
    }
    Byte *tempBuf = (Byte *)data.bytes;
    for (i = 1; i < data.length; i++) {
        if (tempBuf[i] == XRCP_TAIL) {
            NSData *tempData = [NSData dataWithData:[data subdataWithRange:NSMakeRange(0, i+1)]];
            [data replaceBytesInRange:NSMakeRange(0, i+1) withBytes:NULL length:0];
            return tempData;
        }
    }
    return nil;
}

@end
