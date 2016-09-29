//
//  CTNetworkConfiguration.h
//  CTNetwork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTBaseRequest.h"


typedef NS_ENUM(NSInteger, CTRequestSerializerType)
{
    CTRequestSerializerTypeJSON = 0,
    CTRequestSerializerTypeHTTP,
};

typedef NS_ENUM(NSInteger, CTResponseSerializerType)
{
    CTResponseSerializerTypeJSON = 0,
    CTResponseSerializerTypeHTTP,
};


@protocol CTNetworkConfiguration <NSObject>

@required
/**
 *  基础地址字符串
 */
@property (nonatomic, strong, readonly) NSString * _Nonnull baseURLString;


@optional
/**
 *  在请求以前，对request预处理一下，默认不处理
 *
 *  @param request 请求
 *  @note 此方法添加，为了适应多域名，可以对request.methodName设置一个绝对路径
 */
- (void)prepareProcessingRequest:(CTBaseRequest * _Nonnull)request;

/**
 *  最终请求参数
 *
 *  @param dict 原参数字典
 *
 *  @return 处理后的参数字典
 */
- (NSDictionary * _Nullable)requestParamterWithRequest:(CTBaseRequest * _Nonnull)request;
/**
 *  对request当中的HTTP Header进行处理，可以在此方法内部加入公共的请求头内容
 *
 *  @param request 请求
 *
 *  @return 返回一个处理好的请求头给AF，默认加公共的Content-Type和User-Agent
 */
- (NSDictionary * _Nonnull)requestHTTPHeaderFields:(CTBaseRequest * _Nonnull)request;

/**
 *  解密请求返回的数据，默认不解密，如果需要解密，实现此方法
 *
 *  @param responseData 返回的数据
 *  @param response     response
 *  @param request      请求
 *
 *  @return 解密后的数据
 */
- (NSData * _Nullable)decryptResponseData:(NSData * _Nonnull)responseData response:(NSURLResponse * _Nonnull)response request:(CTBaseRequest * _Nonnull)request;

/**
 *  是否应该缓存当前的数据，里面根据request.cachePolicy来进行判断。若是根据服务器返回的一个字段来判断是否应该返回数据，子类覆写此方法
 *
 *  @param responseData 请求到的数据，此数据已经经过json解析之后的数据
 *  @param task         task
 *  @param request      请求
 *
 *  @return 根据request.cachePolicy来判断
 *  @code
 if(request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheOnly || request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheLoadData) {
 return YES;
 }
 return NO;
 */
- (BOOL)shouldCacheResponseData:(id _Nullable)responseData task:(NSURLSessionDataTask * _Nonnull)task request:(CTBaseRequest * _Nonnull)request;

@end


@interface CTNetworkConfiguration : NSObject<CTNetworkConfiguration>
/**
 *  超时时间
 */
@property (nonatomic, assign) NSTimeInterval timeInterval;

/**
 *   default CTRequestSerializerTypeJSON
 */
@property (nonatomic, assign)CTRequestSerializerType requestType;
/**
 *   default CTResponseSerializerTypeJSON
 */
@property (nonatomic, assign)CTResponseSerializerType responseType;

@property (nonatomic, assign)AFSSLPinningMode SSLPinningMode;

@property (nonatomic, copy)NSSet * _Nonnull acceptableContentTypes;

+ (instancetype _Nonnull)configuration;
+ (instancetype _Nonnull)configurationWithBaseURL:(NSString * _Nonnull)baseURL;

@end
