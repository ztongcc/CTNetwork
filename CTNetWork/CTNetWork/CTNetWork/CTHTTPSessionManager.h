//
//  CTHTTPSessionManager.h
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface CTHTTPSessionManager : AFHTTPSessionManager

/** 判断一组请求是否已经请求完成 */
- (BOOL)isHttpQueueFinished:( NSArray * _Nonnull )httpUrlArray;

/** 取消请求 */
- (void)cancelTaskWithUrl:( NSString * _Nonnull )url;

@end
