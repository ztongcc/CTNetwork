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

//#import "BGDownloadRequest.h"
//#import "BGUploadRequest.h"


@interface CTNetworkManager : NSObject
/**
 *  网络请求单例类
 *
 *  @return <#return value description#>
 */
+ (instancetype _Nonnull)sharedManager;
/**
 *  网络缓存
 */
@property (nonatomic, strong, readonly) CTNetworkCache * _Nonnull cache;

/**
 *  设置网络配置
 */
@property (nonatomic, strong, readonly) CTNetworkConfiguration * _Nonnull configuration;

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
 *  @param successCompletionBlock 成功调回
 *  @param businessFailureBlock   业务失败调回
 *  @param networkFailureBlock    网络失败调回
 */
- (void)sendRequest:(CTBaseRequest * _Nonnull)request
            success:(CTSuccessCompletionBlock _Nullable)successCompletionBlock
            failure:(CTNetworkFailureBlock    _Nullable)networkFailureBlock;

/**
 *  发送下载请求
 *
 *  @param request                下载请求
 *  @param downloadProgressBlock  下载的进度条
 *  @param successCompletionBlock 下载成功
 *  @param failureCompletionBlock 下载失败
 */
//- (void)sendDownloadRequest:(BGDownloadRequest * _Nonnull)request
//                   progress:(nullable void (^)(NSProgress * _Nonnull downloadProgress)) downloadProgressBlock
//                    success:(nullable void (^)(BGDownloadRequest * _Nonnull request, NSURL * _Nullable filePath))successCompletionBlock
//                    failure:(nullable void (^)(BGDownloadRequest * _Nonnull request, NSError * _Nullable error))failureCompletionBlock;
//
//
//- (void)sendUploadRequest:(BGUploadRequest * _Nonnull)request
//                 progress:(nullable void (^)(NSProgress * _Nonnull uploadProgress)) uploadProgress
//                  success:(BGSuccessCompletionBlock _Nullable)successCompletionBlock
//          businessFailure:(BGBusinessFailureBlock _Nullable)businessFailureBlock
//           networkFailure:(BGNetworkFailureBlock _Nullable)networkFailureBlock;
//

/**
 *  取消请求
 *
 *  @param url 取消请求的url
 */
- (void)cancelRequestWithUrl:(NSString * _Nonnull)url;

/**
 *  cancel download request
 */
//- (void)cancelDownloadRequest:(CTDownloadRequest * _Nonnull)request;


@end
