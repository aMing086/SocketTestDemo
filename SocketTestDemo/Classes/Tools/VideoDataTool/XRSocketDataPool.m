//
//  XRSocketDataPool.m
//  SocketTestDemo
//
//  Created by 369 on 2018/4/28.
//  Copyright © 2018年 XR. All rights reserved.
//

#import "XRSocketDataPool.h"

@interface XRSocketDataPool()

@property (nonatomic, strong) NSMutableData *data;

@end

@implementation XRSocketDataPool

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
    }
    return  self;
}



@end
