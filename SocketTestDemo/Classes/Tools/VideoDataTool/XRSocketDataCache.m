//
//  XRSocketDataCache.m
//  SocketTestDemo
//
//  Created by 369 on 2018/5/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRSocketDataCache.h"

@interface XRSocketDataCache()

@property (atomic, strong) NSMutableData *data;

@end

@implementation XRSocketDataCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
    }
    return  self;
}

- (void)writeData:(NSData *)data
{
    _isAddData = YES;
    [self.data appendData:data];
}

- (NSData *)readData
{
    _isAddData = NO;
    NSData *data = [NSData dataWithData:self.data];
    [self.data replaceBytesInRange:NSMakeRange(0, data.length) withBytes:NULL length:0];
    return data;
}

@end
