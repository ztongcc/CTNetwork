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
     *  请求到数据后缓存数据，读取缓存时如果有缓存则仅仅读取缓存，不再请求网络
     */
    CTNetworkRequestCacheDataAndReadCacheOnly,
    /**
     *  请求到数据后缓存数据，读取到缓存后请求网络
     */
    CTNetworkRequestCacheDataAndReadCacheLoadData,
};

typedef void(^CTMultipartFormData) (id<AFMultipartFormData>  _Nonnull formData);
#pragma mark - completion block
typedef void(^CTNetworkSuccessBlock)(CTBaseRequest  * _Nonnull request, id  _Nullable response);
typedef void(^CTNetworkFailureBlock)(CTBaseRequest  * _Nonnull request, NSError *_Nullable error);

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
/**
 *  请求类，覆写父类的方法请参照BGNetworkRequest协议进行覆写
 *  @code
 *  BGNetworkRequest *request = [[BGNetworkRequest alloc] init];
 *  [request sendRequestWithDelegate:self];
 */
@interface CTBaseRequest : NSObject <NSCopying, CTNetResponseHandle>

/**
 *  请求标识码，每个请求都拥有唯一的标示
 */
@property (nonatomic, assign, readonly) NSUInteger requestIdentifier;
/**
 *  缓存有效期
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
 *  请求Session Task
 */
@property (nonatomic, assign) NSURLSessionDataTask * _Nullable sessionTask;

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
 *  参数字典
 */
@property (nonatomic, copy, readonly) NSDictionary * _Nonnull parametersDic;

/**
 *  请求头
 */
@property (nonatomic, copy, readonly) NSDictionary * _Nonnull requestHTTPHeaderFields;

#pragma mark - 设置或获取请求头的内容
- (void)setValue:(NSString * _Nonnull)value forHTTPHeaderField:(NSString * _Nonnull)field;
- (NSString * _Nonnull)valueForHTTPHeaderField:(NSString * _Nonnull)field;

#pragma mark - 设置参数
- (void)setIntegerValue:(NSInteger)value forParamKey:(NSString * _Nonnull)key;
- (void)setDoubleValue:(double)value forParamKey:(NSString * _Nonnull)key;
- (void)setLongLongValue:(long long)value forParamKey:(NSString * _Nonnull)key;
- (void)setBOOLValue:(BOOL)value forParamKey:(NSString * _Nonnull)key;
- (void)setValue:(id _Nonnull)value forParamKey:(NSString * _Nonnull)key;
@end

#pragma mark - CTNetworkRequest(BGNetworkManager)
@interface CTBaseRequest (BGNetworkManager)
/**
 *  取消请求
 */
+ (void)cancelRequest;

/**
 *  发送网络请求
 *
 *  @param successCompletionBlock 成功回调
 *  @param businessFailureBlock   业务失败回调
 *  @param networkFailureBlock    网络失败回调
 */
- (void)sendRequestWithSuccess:(CTNetworkSuccessBlock _Nullable)successCompletionBlock
                networkFailure:(CTNetworkFailureBlock _Nullable)networkFailureBlock;
@end
