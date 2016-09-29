//
//  CTNetworkConfiguration.m
//  CTNetwork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTNetworkConfiguration.h"


@interface CTNetworkConfiguration ()

@property(nonatomic, strong) NSString *baseURLString;

@end

@implementation CTNetworkConfiguration

+ (instancetype)configuration
{
    return [self configurationWithBaseURL: @""];
}

+ (instancetype _Nonnull)configurationWithBaseURL:(NSString *)baseURL
{
    CTNetworkConfiguration *configuration = [[self alloc] init];
    configuration.baseURLString = baseURL;
    configuration.SSLPinningMode = AFSSLPinningModeNone;
    return configuration;
}

#pragma mark - BGNetworkConfiguration
- (NSString *)baseURLString {
    return _baseURLString;
}

- (void)prepareProcessingRequest:(CTBaseRequest *)request
{
    
}

- (NSDictionary * _Nullable)requestParamterWithRequest:(CTBaseRequest * _Nonnull)request
{
    return request.parametersDic;
}

- (NSDictionary *)requestHTTPHeaderFields:(CTBaseRequest *)request {
    NSMutableDictionary *allHTTPHeaderFileds = [@{
                                                  @"Content-Type":@"application/x-www-form-urlencoded;charset=utf-8",
                                                  @"User-Agent":@"iPhone"
                                                  } mutableCopy];
    [request.requestHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        allHTTPHeaderFileds[key] = obj;
    }];
    return allHTTPHeaderFileds;
}

- (NSData *)decryptResponseData:(NSData *)responseData response:(NSURLResponse *)response request:(CTBaseRequest *)request
{
    return responseData;
}

- (BOOL)shouldCacheResponseData:(id)responseData task:(NSURLSessionDataTask *)task request:(CTBaseRequest *)request
{
    if(request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheOnly || request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheLoadData) {
        return YES;
    }
    return NO;
}

@end
