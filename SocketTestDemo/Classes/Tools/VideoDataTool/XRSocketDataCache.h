//
//  XRSocketDataCache.h
//  SocketTestDemo
//
//  Created by 369 on 2018/5/2.
//  Copyright © 2018年 XR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XRSocketDataCache : NSObject

@property (atomic, assign) BOOL isAddData; // 是否有新增数据


- (void)writeData:(NSData *)data;

- (NSMutableData *)readCacheData;

@end
