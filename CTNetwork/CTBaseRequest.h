//
//  CTBaseRequest.h
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@class CTBaseRequest, CTNetworkConfiguration, CTBaseBatchRequest;

typedef NS_ENUM(NSInteger, CTNetworkRequestHTTPMethod){
    /**
     *  GET请求
     */
    CTNetworkRequestHTTPGet,
    /**
     *  POST请求
     */
    CTNetworkRequestHTTPPost,
    /**
     *  DELETE请求
     */
    CTNetworkRequestHTTPDelete,
    
    /**
     *  PUT请求
     */
    CTNetworkRequestHTTPPut,
};


/**
 *  网络请求缓存策略
 */
typedef NS_ENUM(NSInteger, CTRequestCachePolicy){
    /**
     *  不进行缓存
     */
    CTRequestCacheNone,
    /**
     *  如果有缓存则仅仅读取缓存，不再请求网络, 无缓存则请求网络，请求到数据后缓存数据
     */
    CTRequestCacheDataAndReadCacheOnly,
    /**
     *  如果有缓存则读取缓存，读取到缓存后请求网络，请求到数据后缓存数据 (此情况只会走一次成功block, 即读取缓存成功调用一次)
     */
    CTRequestCacheDataAndRefreshCacheData,
    /**
     *  如果有缓存则读取缓存，读取到缓存后请求网络，请求到数据后缓存数据 （此情况会走两次成功的block，即读取缓存成功调用一次，请求网络成功再调用一次）
     */
    CTRequestCacheDataAndReadCacheLoadData,
};

///  Request priority
typedef NS_ENUM(NSInteger, CTRequestPriority) {
    CTRequestPriorityLow = -4L,
    CTRequestPriorityDefault = 0,
    CTRequestPriorityHigh = 4,
};


#pragma mark -  block

typedef void(^CTMultipartFormData) (id <AFMultipartFormData>  _Nonnull formData);

typedef void(^CTNetworkConfigBlock)(CTNetworkConfiguration * _Nonnull config);
typedef void(^CTNetworkRequestBlock)(CTBaseRequest  * _Nonnull req);
typedef NSArray <CTBaseRequest*>* _Nonnull(^CTNetworkBatchReqBlock)(CTBaseBatchRequest * _Nonnull req);
typedef void(^CTNetworkProgressBlock)(NSProgress    * _Nonnull progress);
typedef void(^CTNetworkSuccessBlock)(CTBaseRequest  * _Nonnull request, id  _Nullable responseObj);
typedef void(^CTNetworkFailureBlock)(CTBaseRequest  * _Nonnull request, NSError *_Nullable error);
typedef void(^CTNetworkDownloadBlock)(CTBaseRequest * _Nonnull request, NSURL * _Nullable filePath, NSError * _Nullable error);

typedef NSURL * _Nonnull (^CTNetworkDestinationBlock)(CTBaseRequest * _Nonnull request,NSURL * _Nullable targetPath, NSURLResponse * _Nullable response);

typedef void (^CTNetworkBatchSuccessBlock)(CTBaseRequest * _Nonnull request, id _Nullable responseObj);
typedef void (^CTNetworkBatchFailureBlock)(CTBaseRequest * _Nonnull request, NSError * _Nullable error);
typedef void (^CTNetworkBatchComplectBlock)(CTBaseBatchRequest * _Nonnull request, BOOL isFinish);
@protocol CTNetworkRequestDelegate;

#pragma mark - CTNetworkRequest


@interface CTBaseRequest : NSObject <NSCopying>


@property (nonatomic, assign)NSUInteger tag;
/**
 *  请求标识码，每个请求都拥有唯一的标示
 */
@property (nonatomic, assign, readonly) NSUInteger requestIdentifier;
/**
 *  缓存有效期 以秒为单位 (默认一小时)
 */
@property (nonatomic, assign) NSTimeInterval cacheValidInterval;
/**
 *  方法名
 */
@property (nonatomic, copy) NSString * _Nonnull interface;
/**
 *  是否来源于缓存
 */
@property (nonatomic, assign) BOOL isFromCache;

/**
 *  请求是否活跃
 */
@property (nonatomic, assign) BOOL isExciting;

/**
 *  返回数据
 */
@property (nonatomic, copy) id _Nullable responseObj;

/**
 *  当该请求处于活跃状态的时候再次发送是否需要过滤掉
 */
@property (nonatomic, assign) BOOL isCancleSendWhenExciting;

/**
 *  请求Session Task
 */
@property (nonatomic, readonly, nullable) NSURLSessionDataTask * sessionTask;

/**
 *  The priority of the request. Effective only on iOS 8+. Default is `CTRequestPriorityDefault`.
 */
@property (nonatomic) CTRequestPriority requestPriority;

/**
 *  请求成功Block
 */
@property (nonatomic, copy, nullable)CTNetworkSuccessBlock successBlock;

/**
 *  请求失败Block
 */
@property (nonatomic, copy, nullable)CTNetworkFailureBlock failureBlock;

/**
 *  上传/下载进度Block
 */
@property (nonatomic, copy, nullable)CTNetworkProgressBlock progressBlock;

/**
 *  下载完成Block
 */
@property (nonatomic, copy, nullable)CTNetworkDownloadBlock downloadBlock;

/**
 *  HTTP请求的方法，默认GET，现支持GET和POST, DELETE , PUT
 */
@property (nonatomic, assign) CTNetworkRequestHTTPMethod requestMethod;

/**
 *  缓存策略，默认为CTNetworkRquestCacheNone
 */
@property (nonatomic, assign) CTRequestCachePolicy cachePolicy;

/**
 *  上传文件时使用
 */
@property (nonatomic, copy)CTMultipartFormData _Nonnull formData;

/**
 *  下载文件时使用
 */
@property (nonatomic, copy) NSString * _Nonnull fileName;

/**
 *  请求时用到的临时缓存Key
 */
@property (nonatomic, readonly, nonnull) NSString * requestKey;

/**
 *  参数字典
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> * parameterDict;

/**
 *  请求头
 */
@property (nonatomic, strong, nullable) NSDictionary <NSString *, NSString *> * HTTPHeaderFieldDict;



- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface;


- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(id _Nullable)param;


- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(NSDictionary * _Nullable)param
                               cachePolicy:(CTRequestCachePolicy)policy;

+ (CTBaseRequest * _Nonnull)request;


+ (CTBaseRequest * _Nonnull)requestWithInterface:(NSString * _Nonnull)interface;


+ (CTBaseRequest * _Nonnull)requestWithInterface:(NSString * _Nonnull)interface
                                       parameter:(id _Nonnull)parameter;

/**
 *  开始请求数据 (需设置successBlock 和 failureBlock)
 */
- (void)start;

@end

#pragma mark - CTNetworkRequest(CTNetworkManager)
@interface CTBaseRequest (CTNetworkManager)


@property (nonatomic,strong, readwrite) NSURLSessionTask * _Nullable sessionTask;
/**
 *  发送网络请求
 *
 *  @param successBlock 成功回调
 *  @param failureBlock 网络失败回调
 */
- (void)startRequestWithSuccess:(CTNetworkSuccessBlock _Nullable)successBlock
                        failure:(CTNetworkFailureBlock _Nullable)failureBlock;

/**
 *  发送上传数据网络请求
 *
 *  @param progressBlock  上传进度回调
 *  @param successBlock   成功回调
 *  @param failureBlock   网络失败回调
 */
- (void)startUploadRequestWithProgress:(CTNetworkProgressBlock _Nullable)progressBlock
                               success:(CTNetworkSuccessBlock _Nullable)successBlock
                               failure:(CTNetworkFailureBlock _Nullable)failureBlock;

/**
 *  发送下载文件网络请求
 *
 *  @param progressBlock  下载进度回调
 *  @param successBlock   成功回调
 *  @param failureBlock   网络失败回调
 */
- (void)startDownloadRequestWithProgress:(CTNetworkProgressBlock _Nullable)progressBlock
                         complectHandler:(CTNetworkDownloadBlock _Nonnull)complectBlock;
/**
 *  取消网络请求
 */
- (void)cancle;

@end
