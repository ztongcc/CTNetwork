//
//  CTNetworkManager.h
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTNetworkConfiguration.h"
#import "CTBaseRequest.h"
#import "CTNetworkCache.h"


#define NET_LOG(FORMAT, ...) printf("[%s:%d行] %s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


@interface CTNetworkManager : NSObject

/**
 *  网络缓存
 */
@property (nonatomic, strong, readonly) CTNetworkCache * _Nonnull cache;

/**
 *  设置网络配置
 */
@property (nonatomic, strong, readonly) CTNetworkConfiguration * _Nonnull configuration;

/**
 *  网络请求单例类
 *
 *  @return <#return value description#>
 */
+ (instancetype _Nonnull)sharedManager;

/**
 *  设置网络配置
 *
 *  @param configuration 网络配置
 */
- (void)setNetworkConfiguration:(CTNetworkConfiguration * _Nonnull)configuration;


/**
 *  发送请求
 *
 *  @param request                请求
 */
- (void)sendRequest:(CTBaseRequest * _Nonnull)request;

/**
 *  发送下载请求
 *
 *  @param request    下载请求
 */
- (void)sendDownloadRequest:(CTBaseRequest * _Nonnull)request;

/**
 *  发送上传请求
 *
 *  @param request        <#request description#>
 */
- (void)sendUploadRequest:(CTBaseRequest * _Nonnull)request;

/**
 *  取消请求
 *
 *  @param url 取消请求的url
 */
- (void)cancelRequestWithUrl:(NSString * _Nonnull)url;

/**
 *  取消请求
 *
 *  @param request
 */
- (void)cancelRequest:(CTBaseRequest * _Nonnull)request;
/**
 *  cancel download request
 */
- (void)cancelDownloadRequest:(CTBaseRequest * _Nonnull)request;


@end


@interface CTNetworkManager (Core)

+ (void)setNetConfig:(CTNetworkConfigBlock _Nonnull)configBlock;


+ (CTBaseRequest * _Nonnull)startGET:(CTNetworkRequestBlock _Nonnull)reqBlock
                             success:(CTNetworkSuccessBlock _Nullable)successBlock
                             failure:(CTNetworkFailureBlock _Nullable)failureBlock;

+ (CTBaseRequest * _Nonnull)startPOST:(CTNetworkRequestBlock _Nonnull)reqBlock
                              success:(CTNetworkSuccessBlock _Nullable)successBlock
                              failure:(CTNetworkFailureBlock _Nullable)failureBlock;

+ (CTBaseRequest * _Nonnull)startUpload:(CTNetworkRequestBlock _Nonnull)reqBlock
                               progress:(CTNetworkProgressBlock _Nullable)progressBlock
                                success:(CTNetworkSuccessBlock _Nullable)successBlock
                                failure:(CTNetworkFailureBlock _Nullable)failureBlock;

+ (CTBaseRequest * _Nonnull)startDownload:(CTNetworkRequestBlock _Nonnull)reqBlock
                                 progress:(CTNetworkProgressBlock _Nullable)progressBlock
                          complectHandler:(CTNetworkDownloadBlock _Nonnull)complectBlock;


+ (CTBaseBatchRequest * _Nonnull)startBatch:(CTNetworkBatchReqBlock _Nonnull)batchReqBlock
                                    success:(CTNetworkBatchSuccessBlock _Nonnull)successBlock
                                    failure:(CTNetworkBatchFailureBlock _Nonnull)failureBlock
                                 completion:(CTNetworkBatchComplectBlock _Nonnull)completionBlock;

@end
