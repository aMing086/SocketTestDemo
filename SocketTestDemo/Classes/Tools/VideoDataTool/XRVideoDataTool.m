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
    Byte *buf = (Byte *)data.bytes;
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
    Byte *buf = (Byte *)data.bytes;
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

+ (XRTCPProtocol_Basic *)decodePackWithCompletePacketData:(NSData *)data
{
    XRTCPProtocol_Basic *basic = [[XRTCPProtocol_Basic alloc] init];
    if (data) {
        BOOL flag = [basic decodePackWithData:data length:(int)[data length]];
        if (flag) {
            if (basic.ProtocolValue == 0x05) {
                basic = [[XRTCPProtocol_Contact alloc] init];
                flag = [basic decodePackWithData:data length:(int)[data length]];
                
            } else if (basic.ProtocolValue == 0x35) {
                basic = [[XRTCPProtocol_LoginAck alloc] init];
                flag = [basic decodePackWithData:data length:(int)[data length]];
                
            } else if (basic.ProtocolValue == 0x40) {
                XRTCPProtocol_Video *video = [[XRTCPProtocol_Video alloc] init];
                flag = [video decodePackWithData:data length:(int)[data length]];
                
                switch (video.videoCmd) {
                    case 0x01:
                    {
                        video = [[XRTCPProtocol_VideoChannelAck alloc] init];
                        flag = [video decodePackWithData:data length:(int)[data length]];
                        break;
                    }
                    case 0x02:
                    {
                        video = [[XRTCPProtocol_VideoDeviceAck alloc] init];
                        flag = [video decodePackWithData:data length:(int)[data length]];
                        break;
                    }
                    case 0x10:
                    {
                        video = [[XRTCPProtocol_VideoGetStreamIPAck alloc] init];
                        flag = [video decodePackWithData:data length:(int)data.length];
                        break;
                    }
                        
                    case 0x12:
                    {
                        video = [[XRTCPProtocol_VideoStartPreviewAck alloc] init];
                        flag = [video decodePackWithData:data length:(int)data.length];
                        
                        break;
                    }
                    case 0x13:
                    {
                        video = [[XRTCPProtocol_VideoPreviewStream alloc] init];
                        flag = [video decodePackWithData:data length:(int)data.length];
                        break;
                    }
                    case 0x14:
                    {
                        video = [[XRTCPProtocol_VideoStopPreviewAck alloc] init];
                        flag = [video decodePackWithData:data length:[data length]];
                        break;
                    }
                    case 0x15:
                    {
                        video = [[XRTCPProtocol_VideoQueryFileAck  alloc] init];
                        flag = [video decodePackWithData:data length:[data length]];
                        break;
                    }
                    case 0x16:
                    {
                        video = [[XRTCPProtocol_VideoStartPlayBackAck alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    case 0x17:
                    {
                        video = [[XRTCPProtocol_VideoPlayBackStream alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    case 0x18:
                    {
                        video = [[XRTCPProtocol_VideoStopPlayBackAck alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    case 0x19:
                    {
                        video = [[XRTCPProtocol_VideoStartVoiceAck alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    case 0x20:
                    {
                        video = [[XRTCPProtocol_VideoVoiceData alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    case 0x21:
                    {
                        video = [[XRTCPProtocol_VideoSendVoiceDataAck alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    case 0x22:
                    {
                        video = [[XRTCPProtocol_VideoStopVoiceAck alloc] init];
                        flag = [video decodePackWithData:data length:data.length];
                        break;
                    }
                    default:
                        break;
                }
                basic = video;
            }
        }
    }
   
    return basic;
}

@end
