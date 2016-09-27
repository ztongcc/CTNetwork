//
//  CTBaseRequest.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTBaseRequest.h"
#import "CTNetworkManager.h"
#import "CTNetworkCache.h"
#import <objc/runtime.h>


static NSUInteger _requestIdentifier = 0;

@interface CTBaseRequest ()

@property (nonatomic, readwrite) NSURLSessionDataTask * _Nullable sessionTask;
@property (nonatomic, strong) NSMutableDictionary *mutableParametersDic;
@property (nonatomic, strong) NSMutableDictionary *mutableRequestHTTPHeaderFields;
@property (nonatomic, copy) NSString * requestKey;

/**
 *  代理
 */
@property (nonatomic, weak) id<CTNetworkRequestDelegate> delegate;

@end

@implementation CTBaseRequest

- (void)dealloc
{
        NSLog(@"%@ [ - delloc - ]   requestIndentifier : %ld ", NSStringFromClass(self.class), (unsigned long)self.requestIdentifier);
}

- (instancetype)init
{
    if(self = [super init]){
        _requestIdentifier += 1;
        _mutableRequestHTTPHeaderFields = [[NSMutableDictionary alloc] init];
        _mutableParametersDic = [[NSMutableDictionary alloc] init];
        _isCancleSendWhenExciting = NO;
        self.requestMethod = CTNetworkRequestHTTPGet;
        self.cachePolicy = CTNetworkRquestCacheNone;
    }
    return self;
}
- (instancetype)initWithInterface:(NSString * _Nullable)interface
{
    self = [self init];
    if (self) {
        self.interface = interface;
    }
    return self;
}

- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                               cachePolicy:(CTNetworkRequestCachePolicy)policy
{
    return [self initWithInterface:interface parameter:nil cachePolicy:CTNetworkRquestCacheNone];
}

- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(NSDictionary * _Nullable)param
{
    return [self initWithInterface:interface parameter:param cachePolicy:CTNetworkRquestCacheNone];
}

- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(NSDictionary * _Nullable)param
                               cachePolicy:(CTNetworkRequestCachePolicy)policy
{
    self = [self init];
    if (self) {
        self.interface = interface;
        self.parametersDic = param;
        self.cachePolicy = policy;
    }
    return self;
}

#pragma mark - set or get method
- (NSUInteger)requestIdentifier
{
    return _requestIdentifier;
}

- (NSDictionary *)parametersDic
{
    @autoreleasepool
    {
        NSMutableDictionary * paramDict = [NSMutableDictionary dictionaryWithDictionary:_mutableParametersDic];
        if (_parametersDic != nil)
        {
            [paramDict addEntriesFromDictionary:_parametersDic];
        }
        return [paramDict copy];
    }

}

- (NSDictionary *)requestHTTPHeaderFields
{
    return [_mutableRequestHTTPHeaderFields copy];
}


- (NSString *)requestKey
{
    if (!_requestKey)
    {
        NSURL * baseUrl = [NSURL URLWithString:[CTNetworkManager sharedManager].configuration.baseURLString];
        _requestKey = CTKeyFromRequestAndBaseURL(self.parametersDic, baseUrl, self.interface);
    }
    return _requestKey;
}

#pragma mark - CTNetResponseHandle method -
- (id)handleResponseObject:(id)responseObject
{
    return responseObject;
}

#pragma mark - 设置或获取请求头
- (NSString *)valueForHTTPHeaderField:(NSString *)field{
    if(!field){
        return @"";
    }
    return _mutableRequestHTTPHeaderFields[field];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    if(!field || !value){
        return;
    }
    _mutableRequestHTTPHeaderFields[field] = value;
}

#pragma mark - 设置参数
- (void)setIntegerValue:(NSInteger)value forParamKey:(NSString *)key
{
    [self setValue:[NSNumber numberWithInteger:value] forParamKey:key];
}

- (void)setDoubleValue:(double)value forParamKey:(NSString *)key
{
    [self setValue:[NSNumber numberWithDouble:value] forParamKey:key];
}

- (void)setLongLongValue:(long long)value forParamKey:(NSString *)key
{
    [self setValue:[NSNumber numberWithLongLong:value] forParamKey:key];
}

- (void)setBOOLValue:(BOOL)value forParamKey:(NSString *)key
{
    [self setValue:[NSNumber numberWithBool:value] forParamKey:key];
}

- (void)setValue:(id)value forParamKey:(NSString *)key
{
    if(!key){
        return;
    }
    if(!value){
        value = @"";
    }
    _mutableParametersDic[key] = value;
}

- (void)start
{
    [[CTNetworkManager sharedManager] sendRequest:self];
}


#pragma mark - NSCopying method
- (id)copyWithZone:(NSZone *)zone
{
    CTBaseRequest *request = [[[self class] allocWithZone:zone] init];
    request.mutableRequestHTTPHeaderFields = [self.mutableRequestHTTPHeaderFields mutableCopy];
    request.mutableParametersDic = [self.mutableParametersDic mutableCopy];
    return request;
}

#pragma mark - description
- (NSString *)description
{
    NSString *className = NSStringFromClass([self class]);
    NSString *desStr = [NSString stringWithFormat:@"%@ indentifier %ld \n interface: [-  %@  -]\n param:\n%@\n", className,self.requestIdentifier, self.interface, self.parametersDic];
    return desStr;
}
@end

@implementation CTBaseRequest (CTNetworkManager)
#pragma mark - class method

- (void)startRequestWithSuccess:(CTNetworkSuccessBlock _Nullable)successBlock
                        failure:(CTNetworkFailureBlock _Nullable)failureBlock
{
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    [[CTNetworkManager sharedManager] sendRequest:self];
}

- (void)startUploadRequestWithProgress:(CTNetworkProgressBlock _Nullable)progressBlock
                               success:(CTNetworkSuccessBlock _Nullable)successBlock
                               failure:(CTNetworkFailureBlock _Nullable)failureBlock
{
    self.successBlock = successBlock;
    self.progressBlock = progressBlock;
    self.failureBlock = failureBlock;
    [[CTNetworkManager sharedManager] sendUploadRequest:self];
}

- (void)startDownloadRequestWithProgress:(CTNetworkProgressBlock _Nullable)progressBlock
                                 success:(CTNetworkSuccessBlock _Nullable)successBlock
                                 failure:(CTNetworkFailureBlock _Nullable)failureBlock
{
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.progressBlock = progressBlock;
    [[CTNetworkManager sharedManager] sendDownloadRequest:self];
}

- (void)cancle
{
    [[CTNetworkManager sharedManager] cancelRequest:self];
}
@end
