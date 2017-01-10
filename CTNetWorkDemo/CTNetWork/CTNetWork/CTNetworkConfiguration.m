//
//  CTNetworkConfiguration.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTNetworkConfiguration.h"

@implementation CTNetworkConfiguration

+ (instancetype)configuration
{
    return [self configurationWithBaseURL:@""];
}

+ (instancetype _Nonnull)configurationWithBaseURL:(NSString *)baseURL
{
    CTNetworkConfiguration *configuration = [[self alloc] init];
    configuration.baseURLString = baseURL;
    configuration.SSLPinningMode = AFSSLPinningModeNone;
    configuration.allowInvalidCertificates = YES;
    configuration.validatesDomainName = NO;
    return configuration;
}

#pragma mark - BGNetworkConfiguration

- (void)prepareProcessingRequest:(CTBaseRequest *)request
{
    
}

- (NSDictionary * _Nullable)requestParamterWithRequest:(CTBaseRequest * _Nonnull)request
{
    return request.parameterDict;
}

- (NSDictionary *)requestHTTPHeaderFields:(CTBaseRequest *)request
{
    return request.HTTPHeaderFieldDict;
}

- (NSData *)decryptResponseData:(NSData *)responseData response:(NSURLResponse *)response request:(CTBaseRequest *)request
{
    return responseData;
}

- (BOOL)shouldCacheResponseData:(id)responseData task:(NSURLSessionDataTask *)task request:(CTBaseRequest *)request
{
    if(request.cachePolicy == CTRequestCacheDataAndReadCacheOnly ||
       request.cachePolicy == CTRequestCacheDataAndReadCacheLoadData ||
       request.cachePolicy == CTRequestCacheDataAndRefreshCacheData)
    {
        return YES;
    }
    return NO;
}

@end
