//
//  CTNetworkConfiguration.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTNetworkConfiguration.h"

@interface CTNetworkConfiguration ()

@property(nonatomic, strong) NSString *baseURLString;

@end

@implementation CTNetworkConfiguration

+ (instancetype)configuration{
    return [self configurationWithBaseURL: @""];
}

+ (instancetype _Nonnull)configurationWithBaseURL:(NSString *)baseURL
{
    CTNetworkConfiguration *configuration = [[self alloc] init];
    configuration.baseURLString = baseURL;
    return configuration;
}

#pragma mark - BGNetworkConfiguration
- (NSString *)baseURLString {
    return _baseURLString;
}

- (void)preProcessingRequest:(CTBaseRequest *)request {
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

//- (NSString *)queryStringForURLWithRequest:(CTBaseRequest *)request{
//    if(request.httpMethod == BGNetworkRequestHTTPGet){
//        return CTQueryStringFromParamDictionary(request.parametersDic);
//    }
//    else{
//        return nil;
//    }
//}

- (NSData *)httpBodyDataWithRequest:(CTBaseRequest *)request
{
    if(!request.parametersDic.count){
        return nil;
    }
    NSError *error = nil;
    NSData *httpBody = [NSJSONSerialization dataWithJSONObject:request.parametersDic options: (NSJSONWritingOptions)0 error:&error];
    if(error){
        return nil;
    }
    return httpBody;
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

- (BOOL)shouldBusinessSuccessWithResponseData:(id)responseData task:(NSURLSessionDataTask *)task request:(CTBaseRequest *)request
{
    return YES;
}


@end
