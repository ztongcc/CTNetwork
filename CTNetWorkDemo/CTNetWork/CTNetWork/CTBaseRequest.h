//
//  CTBaseRequest.h
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@class CTBaseRequest;

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
typedef NS_ENUM(NSInteger, CTNetworkRequestCachePolicy){
    /**
     *  不进行缓存
     */
    CTNetworkRquestCacheNone,
    /**
     *  如果有缓存则仅仅读取缓存，不再请求网络, 无缓存则请求网络，请求到数据后缓存数据
     */
    CTNetworkRequestCacheDataAndReadCacheOnly,
    /**
     *  如果有缓存则读取缓存，读取到缓存后请求网络，请求到数据后缓存数据 (此情况只会走一次成功block, 即读取缓存成功调用一次)
     */
    CTNetworkRequestCacheDataAndRefreshCacheData,
    /**
     *  如果有缓存则读取缓存，读取到缓存后请求网络，请求到数据后缓存数据 （此情况会走两次成功的block，即读取缓存成功调用一次，请求网络成功再调用一次）
     */
    CTNetworkRequestCacheDataAndReadCacheLoadData,
};

#pragma mark -  block

typedef void(^CTMultipartFormData) (id <AFMultipartFormData>  _Nonnull formData);
typedef void(^CTNetworkSuccessBlock)(CTBaseRequest  * _Nonnull request, id  _Nullable responseObj);
typedef void(^CTNetworkDownloadBlock)(CTBaseRequest  * _Nonnull request, NSURL * _Nullable filePath);
typedef void(^CTNetworkFailureBlock)(CTBaseRequest  * _Nonnull request, NSError *_Nullable error);
typedef void(^CTNetworkProgressBlock)(NSProgress * _Nonnull uploadProgress);

@protocol CTNetworkRequestDelegate;
@protocol CTNetResponseHandle <NSObject>
/**
 *  处理请求到的数据，父类默认不处理直接返回，子类覆写此方法进行处理
 *
 *  @param responseObject 请求到的数据
 *
 *  @return 处理之后的数据
 */
- (id _Nullable)handleResponseObject:(id _Nonnull)responseObject;

@end

#pragma mark - CTNetworkRequest


@interface CTBaseRequest : NSObject <NSCopying, CTNetResponseHandle>
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
 *  当该请求处于活跃状态的时候再次发送是否需要过滤掉
 */
@property (nonatomic, assign) BOOL isCancleSendWhenExciting;
/**
 *  请求Session Task
 */
@property (nonatomic, readonly, nullable) NSURLSessionDataTask * sessionTask;

/**
 *  请求成功Block
 */
@property (nonatomic, copy, nullable)CTNetworkSuccessBlock successBlock;

/**
 *  请求失败Block
 */
@property (nonatomic, copy, nullable)CTNetworkFailureBlock failureBlock;

/**
 *  上传/下载进度
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
@property (nonatomic, assign) CTNetworkRequestCachePolicy cachePolicy;

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
@property (nonatomic, copy, nonnull) NSDictionary *  parametersDic;
/**
 *  请求头
 */
@property (nonatomic, readonly, nonnull) NSDictionary * requestHTTPHeaderFields;

/**
 *  初始化方法
 *
 *  @param interface 接口名
 *
 *  @return return value description
 */
- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface;
/**
 *  初始化方法
 *
 *  @param interface 接口名
 *  @param param     参数字典(可为nil)
 *
 *  @return
 */
- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(NSDictionary * _Nullable)param;
/**
 *  初始化方法
 *
 *  @param interface 接口名
 *  @param policy    缓存策略
 *
 *  @return
 */
- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                               cachePolicy:(CTNetworkRequestCachePolicy)policy;
/**
 *  初始化方法
 *
 *  @param interface 接口名
 *  @param param     参数(可为nil)
 *  @param policy    缓存策略
 *
 *  @return
 */
- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(NSDictionary * _Nullable)param
                               cachePolicy:(CTNetworkRequestCachePolicy)policy;

#pragma mark - 设置或获取请求头的内容
- (void)setValue:(NSString * _Nonnull)value forHTTPHeaderField:(NSString * _Nonnull)field;
- (NSString * _Nonnull)valueForHTTPHeaderField:(NSString * _Nonnull)field;

#pragma mark - 设置参数
- (void)setIntegerValue:(NSInteger)value forParamKey:(NSString * _Nonnull)key;
- (void)setDoubleValue:(double)value forParamKey:(NSString * _Nonnull)key;
- (void)setLongLongValue:(long long)value forParamKey:(NSString * _Nonnull)key;
- (void)setBOOLValue:(BOOL)value forParamKey:(NSString * _Nonnull)key;
- (void)setValue:(id _Nonnull)value forParamKey:(NSString * _Nonnull)key;

/**
 *  开始请求数据 (需设置successBlock 和 failureBlock)
 */
- (void)start;

@end

#pragma mark - CTNetworkRequest(CTNetworkManager)
@interface CTBaseRequest (CTNetworkManager)

@property (nonatomic,strong, readwrite) NSURLSessionDataTask * _Nullable sessionTask;

/**
 *  发送网络请求
 *
 *  @param successCompletionBlock 成功回调
 *  @param businessFailureBlock   业务失败回调
 *  @param networkFailureBlock    网络失败回调
 */
- (void)startRequestWithSuccess:(CTNetworkSuccessBlock _Nullable)successBlock
                        failure:(CTNetworkFailureBlock _Nullable)failureBlock;

/**
 *  发送上传数据网络请求
 *
 *  @param successCompletionBlock 成功回调
 *  @param businessFailureBlock   业务失败回调
 *  @param networkFailureBlock    网络失败回调
 */
- (void)startUploadRequestWithProgress:(CTNetworkProgressBlock _Nullable)progressBlock
                               success:(CTNetworkSuccessBlock _Nullable)successBlock
                               failure:(CTNetworkFailureBlock _Nullable)failureBlock;

/**
 *  发送下载文件网络请求
 *
 *  @param successCompletionBlock 成功回调
 *  @param businessFailureBlock   业务失败回调
 *  @param networkFailureBlock    网络失败回调
 */
- (void)startDownloadRequestWithProgress:(CTNetworkProgressBlock _Nullable)progressBlock
                                 success:(CTNetworkSuccessBlock _Nullable)successBlock
                                 failure:(CTNetworkFailureBlock _Nullable)failureBlock;
/**
 *  取消网络请求
 */
- (void)cancle;

@end
