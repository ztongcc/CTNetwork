//
//  CTBaseRequest.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTBaseRequest.h"
#import "CTNetworkManager.h"

static NSUInteger const K_CACHE_VALIDITY = 60;

static NSUInteger K_REQUEST_INDENTIFIER = 0;

@interface CTBaseRequest ()

@property (nonatomic, readwrite) NSURLSessionDataTask * _Nullable sessionTask;
@property (nonatomic, strong) NSMutableDictionary * mutableRequestHTTPHeaderFields;
@property (nonatomic, copy) NSString * requestKey;

@property (nonatomic, weak) id<CTNetworkRequestDelegate> delegate;

@end

@implementation CTBaseRequest

- (void)dealloc
{
    if ([CTNetworkManager sharedManager].configuration.isDebug)
    {
        NET_LOG(@"%@ [ - delloc - ]  requestIndentifier : %ld ", NSStringFromClass(self.class), (unsigned long)self.requestIdentifier);
    }
}

- (instancetype)init
{
    if(self = [super init]) {
        NSLock * lock = [[NSLock alloc] init];
        [lock lock];
        K_REQUEST_INDENTIFIER += 1;
        _requestIdentifier = K_REQUEST_INDENTIFIER;
        [lock unlock];
        _mutableRequestHTTPHeaderFields = [[NSMutableDictionary alloc] init];
        _isCancleSendWhenExciting = NO;
        self.cacheValidInterval = K_CACHE_VALIDITY;
        self.requestMethod = CTHTTPMethodGET;
        self.cachePolicy = CTCacheNone;
    }
    return self;
}

+ (CTBaseRequest * _Nonnull)request
{
    CTBaseRequest * req = [[CTBaseRequest alloc] init];
    return req;
}

+ (CTBaseRequest * _Nonnull)requestWithInterface:(NSString * _Nonnull)interface
{
    CTBaseRequest * req = [[CTBaseRequest alloc] initWithInterface:interface];
    return req;
}

+ (CTBaseRequest * _Nonnull)requestWithInterface:(NSString * _Nonnull)interface
                                       parameter:(id _Nonnull)parameter
{
    CTBaseRequest * req = [[CTBaseRequest alloc] initWithInterface:interface];
    req.parameterDict = parameter;
    return req;
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
                                 parameter:(NSDictionary * _Nullable)param
{
    return [self initWithInterface:interface parameter:param cachePolicy:CTCacheNone];
}

- (instancetype _Nonnull)initWithInterface:(NSString * _Nullable)interface
                                 parameter:(NSDictionary * _Nullable)param
                               cachePolicy:(CTRequestCachePolicy)policy
{
    self = [self init];
    if (self) {
        self.interface = interface;
        self.parameterDict = param;
        self.cachePolicy = policy;
    }
    return self;
}

#pragma mark - set or get method

- (NSString *)requestKey
{
    if (!_requestKey)
    {
        NSURL * baseUrl = [NSURL URLWithString:[CTNetworkManager sharedManager].configuration.baseURLString];
        _requestKey = CTKeyFromRequestAndBaseURL(self.parameterDict, baseUrl, self.interface);
    }
    return _requestKey;
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
    return request;
}

#pragma mark - description
- (NSString *)description
{
    NSString * desStr = [NSString stringWithFormat:@"\n-------------------- CTRequest completion --------------------\n-> interface: [-  %@  -]\n-> param:\n%@\n-> Unusual HTTPHeader:\n%@\n-> From cache: %@\n-> responseObj:\n%@\n-------------------------------------------------------------", self.interface, self.parameterDict, self.HTTPHeaderFieldDict,self.isFromCache?@"YES":@"NO", self.responseObj];
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
                         complectHandler:(CTNetworkDownloadBlock _Nonnull)complectBlock
{
    self.progressBlock = progressBlock;
    self.downloadBlock = complectBlock;
    [[CTNetworkManager sharedManager] sendDownloadRequest:self];
}

- (void)cancle
{
    [[CTNetworkManager sharedManager] cancelRequest:self];
}
@end


