//
//  CTNetworkManager.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTNetworkManager.h"
#import "CTHTTPSessionManager.h"

static CTNetworkManager *_manager = nil;

@interface CTNetworkManager ()
@property (nonatomic, strong) CTHTTPSessionManager * sessionManager;
@property (nonatomic, strong) CTNetworkCache * cache;
@property (nonatomic, strong) dispatch_queue_t dataHandleQueue;
/**
 *  临时储存请求的字典
 */
@property (nonatomic, strong) NSMutableDictionary *tempRequestDic;
/**
 *  下载任务的字典
 */
@property (nonatomic, strong) NSMutableDictionary *tempDownloadTaskDic;
/**
 *  网络配置
 */
@property (nonatomic, strong) CTNetworkConfiguration *configuration;

@property (nonatomic, strong) NSURL *baseURL;

@end


@implementation CTNetworkManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[[self class] alloc] init];
    });
    return _manager;
}

- (instancetype)init
{
    if(self = [super init]){
        //缓存
        _cache = [CTNetworkCache sharedCache];
        
        //数据处理队列
        _dataHandleQueue = dispatch_queue_create("com.CTNEtworkManager.dataHandleQueue", DISPATCH_QUEUE_CONCURRENT);
        
        self.tempRequestDic = [NSMutableDictionary dictionary];
        self.tempDownloadTaskDic = [NSMutableDictionary dictionary];
    }
    return self;
}


#pragma makr - download request
- (void)sendDownloadRequest:(CTBaseRequest *)request
                   progress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                    success:(void (^)(CTBaseRequest * _Nonnull, NSURL * _Nullable))successBlock
                    failure:(void (^)(CTBaseRequest * _Nonnull, NSError * _Nullable))failureBlock
{
    
    NSString * requestURLString = CTURLStringFromBaseURLAndInterface(self.baseURL, request.interface);
    NSString * fileName = [self downloadRequestFileName:request];
    if (request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheOnly) {
        
    }
    [self.cache queryDiskCacheForFileName:fileName expiryDate:request.cacheValidInterval completion:^(id  _Nullable object) {
        //有缓存，则直接返回
        if(object && [object isKindOfClass:[NSData class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *filePath = [NSURL fileURLWithPath:[self.cache defaultCachePathForFileName:fileName]];
                //保存文件
                if(successBlock) {
                    successBlock(request, filePath);
                }
            });
        }
        else {
            [self downloadDataWithRequest:request requestURL:requestURLString fileName:fileName progress:downloadProgressBlock success:successBlock failure:failureBlock];
        }
    }];
}

- (void)downloadDataWithRequest:(CTBaseRequest *)request
                     requestURL:(NSString *)requestURLString
                       fileName:(NSString *)fileName
                       progress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                        success:(void (^)(CTBaseRequest * _Nonnull, NSURL * _Nullable))successBlock
                        failure:(void (^)(CTBaseRequest * _Nonnull, NSError * _Nullable))failureBlock {
    
    NSString *resumeDataFileName = [NSString stringWithFormat:@"%@_resume", fileName];
    [self.cache queryDiskCacheForFileName:resumeDataFileName expiryDate:request.cacheValidInterval completion:^(id  _Nullable object) {
        //有数据，断点续传
        if(object && [object isKindOfClass:[NSData class]]) {
            NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithResumeData:object progress:downloadProgressBlock destination:^NSURL * _Nullable(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                //4xx 客户端错误
                //5xx 服务器错误
                //2xx 请求成功
                //3xx 重定向
                if(((NSHTTPURLResponse *) response).statusCode >= 400) {
                    return targetPath;
                }
                else {
                    return [NSURL fileURLWithPath:[self.cache defaultCachePathForFileName:fileName]];
                }
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                if(error == nil) {
                    //删除断点续传文件
                    [self.cache removeCacheForFileName:resumeDataFileName];
                }
                self.tempDownloadTaskDic[requestURLString] = nil;
                [self handleResultWithDownloadRequest:request filePath:filePath error:error success:successBlock failure:failureBlock];
            }];
            
            [task resume];
            //save
            self.tempDownloadTaskDic[requestURLString] = task;
            
        }else {
            //无缓存，则重新下载
            NSMutableURLRequest *httpRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURLString]];
            [self setHttpRequestHeardFieldsWithRequest:request];
            NSURLSessionDownloadTask *task = [self.sessionManager downloadTaskWithRequest:httpRequest progress:downloadProgressBlock destination:^NSURL * _Nullable(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                
                if(((NSHTTPURLResponse *) response).statusCode >= 400) {
                    return targetPath;
                }
                else {
                    return [NSURL fileURLWithPath:[self.cache defaultCachePathForFileName:fileName]];
                }

            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                //清空task
                self.tempDownloadTaskDic[requestURLString] = nil;
                [self handleResultWithDownloadRequest:request filePath:filePath error:error success:successBlock failure:failureBlock];
                
            }];
            
            [task resume];
            //save
            self.tempDownloadTaskDic[requestURLString] = task;
        }
    }];
}

- (void)handleResultWithDownloadRequest:(CTBaseRequest *)request
                         filePath:(NSURL *)filePath
                            error:(NSError *)error
                          success:(void (^)(CTBaseRequest * _Nonnull, NSURL * _Nullable))successBlock
                          failure:(void (^)(CTBaseRequest * _Nonnull, NSError * _Nullable))failureBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(error) {
            if(failureBlock)
            {
                failureBlock(request, error);
            }
        }
        else {
            if(successBlock) {
                successBlock(request, filePath);
            }
        }
    });
}

/**
 *  下载请求的文件名
 */
- (NSString *)downloadRequestFileName:(CTBaseRequest *)request
{
    NSString *requestURLString = CTURLStringFromBaseURLAndInterface(self.baseURL, request.interface);
    NSString *cacheKey = CT_MD5(requestURLString);
    NSString *pathExtension = [request.fileName pathExtension];
    NSString *fileName =  pathExtension ? [cacheKey stringByAppendingPathExtension:pathExtension] : [cacheKey stringByAppendingPathExtension:@"tmp"];
    return fileName;
}

/**
 *  断点续传的文件名，在下载文件名后面多了一个_resume
 */
- (NSString *)downloadRequestResumeDataFileName:(CTBaseRequest *)request
{
    return [NSString stringWithFormat:@"%@_resume", [self downloadRequestFileName:request]];
}

#pragma mark - upload request
- (void)sendUploadRequest:(CTBaseRequest *)request
                 progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                  success:(CTNetworkSuccessBlock)successBlock
                  failure:(CTNetworkFailureBlock)failureBlock {
    NSString * url = [self buildRequestUrl:request];
    request.sessionTask = [self.sessionManager POST:url parameters:request.parametersDic constructingBodyWithBlock:request.formData progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        [self networkSuccess:request task:task responseData:responseObject success:successBlock failure:failureBlock];
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nullable error) {
        [self failure:request error:error completion:failureBlock];
    }];
}

- (void)sendRequest:(CTBaseRequest *)request
            success:(CTNetworkSuccessBlock)successBlock
            failure:(CTNetworkFailureBlock)failureBlock
{
    //发送网络之前，先进行一下预处理
    [self.configuration prepareProcessingRequest:request];
    
    switch (request.cachePolicy)
    {
        case CTNetworkRquestCacheNone:
            //请求网络数据
            [self startNetworkDataWithRequest:request success:successBlock failure:failureBlock];
            break;
        case CTNetworkRequestCacheDataAndReadCacheOnly:
        case CTNetworkRequestCacheDataAndRefreshCacheData:
        case CTNetworkRequestCacheDataAndReadCacheLoadData:
            //读取缓存并且请求数据
            [self readCacheWithRequest:request completion:^(CTBaseRequest *request, id responseObject) {
                if(responseObject){
                    /*
                     缓存策略
                     CTBaseRequestCacheDataAndReadCacheOnly：获取缓存数据直接调回，不再请求
                     */
                    [self success:request responseObject:responseObject completion:successBlock isFromCache:YES];

                    // CTBaseRequestCacheDataAndReadCacheLoadData：缓存数据成功调回并且重新请求网络
                    if(request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheLoadData || request.cachePolicy == CTNetworkRequestCacheDataAndReadCacheLoadData){
                        [self startNetworkDataWithRequest:request success:successBlock failure:failureBlock];
                    }
                }else{
                    //无缓存数据，则还需要再请求网络
                    [self startNetworkDataWithRequest:request success:successBlock failure:failureBlock];
                }
            }];
    }
}

- (void)setHttpRequestHeardFieldsWithRequest:(CTBaseRequest *)request
{
    NSDictionary * headerFieldValueDictionary = request.requestHTTPHeaderFields;
    if (headerFieldValueDictionary != nil) {
        for (id httpHeaderField in headerFieldValueDictionary.allKeys) {
            id value = headerFieldValueDictionary[httpHeaderField];
            if ([httpHeaderField isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]]) {
                [_sessionManager.requestSerializer setValue:(NSString *)value forHTTPHeaderField:(NSString *)httpHeaderField];
            } else {
                NSLog(@"Error, class of key/value in headerFieldValueDictionary should be NSString.");
            }
        }
    }
}

- (void)startNetworkDataWithRequest:(CTBaseRequest *)request
                            success:(CTNetworkSuccessBlock)successBlock
                            failure:(CTNetworkFailureBlock)failureBlock
{
    //临时保存请求
    NSString *requestKey = [[NSURL URLWithString:request.interface relativeToURL:self.baseURL] absoluteString];
    self.tempRequestDic[requestKey] = request;
    
    NSString * url = [self buildRequestUrl:request];
    NSLog(@"CTRequest url %@", url);

    [self setHttpRequestHeardFieldsWithRequest:request];
    
    //发送请求
    __weak CTNetworkManager *weakManager = self;
    switch (request.requestMethod) {
        case CTNetworkRequestHTTPGet:
        {
            request.sessionTask = [self.sessionManager GET:url parameters:request.parametersDic progress:NULL success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject success:successBlock failure:failureBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error completion:failureBlock];
            }];
        }
            break;
        case CTNetworkRequestHTTPPost:
        {
            request.sessionTask = [self.sessionManager POST:url parameters:request.parametersDic progress:NULL success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject success:successBlock failure:failureBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error completion:failureBlock];
            }];
        }
            break;
        case CTNetworkRequestHTTPDelete:
        {
            request.sessionTask = [self.sessionManager DELETE:url parameters:request.parametersDic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject success:successBlock failure:failureBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error completion:failureBlock];
            }];
        }
            break;

        case CTNetworkRequestHTTPPut:
        {
            request.sessionTask = [self.sessionManager PUT:url parameters:request.parametersDic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject success:successBlock failure:failureBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error completion:failureBlock];
            }];
        }
            break;

        default:
            break;
    }
}

- (NSString *)buildRequestUrl:(CTBaseRequest *)request
{
    NSString *detailUrl = [request interface];
    if ([detailUrl hasPrefix:@"http"]) {
        return detailUrl;
    }
    // filter url
    return [NSString stringWithFormat:@"%@%@", _configuration.baseURLString, detailUrl];
}

#pragma mark - cache method -
- (void)readCacheWithRequest:(CTBaseRequest *)request completion:(void (^)(CTBaseRequest *request, id responseObject))completionBlock
{
    __weak CTNetworkManager *weakManager = self;
    NSString *cacheKey = CTKeyFromRequestAndBaseURL(request.parametersDic, self.baseURL, request.interface);
    [self.cache queryDiskCacheForFileName:cacheKey expiryDate:request.cacheValidInterval completion:^(NSData *data) {
        dispatch_async(weakManager.dataHandleQueue, ^{
            //解析数据
            id responseObject = CTParseJsonData(data);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock) {
                    completionBlock(request, responseObject);
                }
            });
        });
    }];
}

- (void)cacheResponseData:(NSData *)responseData request:(CTBaseRequest *)request
{
    //缓存数据
    [self.cache storeData:responseData forFileName:CTKeyFromRequestAndBaseURL(request.parametersDic, self.baseURL, request.interface)];
}

#pragma mark - set method
- (void)setNetworkConfiguration:(CTNetworkConfiguration *)configuration
{
    NSParameterAssert(configuration);
    NSParameterAssert(configuration.baseURLString);
    
    
    // CTHTTPSessionManager
    _sessionManager = [[CTHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:configuration.baseURLString]];
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    //是否允许CA不信任的证书通过
    policy.allowInvalidCertificates = YES;
    //是否验证主机名
    policy.validatesDomainName = YES;
    _sessionManager.securityPolicy = policy;
    
    //设置
    if (configuration.requestType == CTRequestSerializerTypeJSON) {
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }else {
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    
    if (configuration.responseType == CTResponseSerializerTypeJSON) {
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    }else {
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }

    NSMutableSet * sets = [NSMutableSet setWithSet:_sessionManager.responseSerializer.acceptableContentTypes];
    [sets unionSet:configuration.acceptableContentTypes];
    _sessionManager.responseSerializer.acceptableContentTypes = sets;
    _sessionManager.requestSerializer.timeoutInterval = configuration.timeInterval;
    
    
    self.baseURL = [NSURL URLWithString:configuration.baseURLString];
    _configuration = configuration;
}

#pragma mark - 网络请求回来调用的方法
- (void)networkSuccess:(CTBaseRequest *)request
                  task:(NSURLSessionDataTask *)task
          responseData:(id)responseData
               success:(CTNetworkSuccessBlock)successBlock
               failure:(CTNetworkFailureBlock)failureBlock
{
    
    dispatch_async(self.dataHandleQueue, ^{
        //对数据进行解密
        id responseObject = CTDataFromJsonObj(responseData);
        NSData *decryptData = [self.configuration decryptResponseData:responseObject response:task.response request:request];
        //解析数据
        dispatch_async(dispatch_get_main_queue(), ^{
            if(responseObject) {
                if([self.configuration shouldCacheResponseData:responseObject task:task request:request]) {
                    //缓存解密之后的数据
                    [self cacheResponseData:decryptData request:request];
                }
                if (request.cachePolicy != CTNetworkRequestCacheDataAndRefreshCacheData) {
                    //成功回调
                    [self success:request responseObject:responseData completion:successBlock isFromCache:NO];
                }
            }else {
                if (request.cachePolicy != CTNetworkRequestCacheDataAndRefreshCacheData) {
                    NSError * error = [NSError errorWithDomain:@"CTNetwork error" code:1000 userInfo:nil];
                    [self failure:request error:error completion:failureBlock];
                }
            }
        });
    });
    
    //remove temp request
    [self removeTempRequest:request];
}

- (void)success:(CTBaseRequest *)request
 responseObject:(id)responseObject
     completion:(CTNetworkSuccessBlock)successCompletionBlock
    isFromCache:(BOOL)isFromCache
{
    dispatch_async(self.dataHandleQueue, ^{
        id resultObject = nil;
        @try {
            //调用request方法中的数据处理，将数据处理成想要的model
            resultObject = [request handleResponseObject:responseObject];
        }
        @catch (NSException *exception) {
            //崩溃则删除对应的缓存数据
            [self.cache removeCacheForKey:CTKeyFromRequestAndBaseURL(request.parametersDic, self.baseURL, request.interface)];
        }
        @finally {
            
        }
        request.isFromCache = isFromCache;
        //成功回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if(successCompletionBlock) {
                successCompletionBlock(request, resultObject);
            }
        });
    });
}

/**
 *  网络失败
 */
- (void)failure:(CTBaseRequest *)request error:(NSError *)error completion:(CTNetworkFailureBlock)failureBlock
{
    //remove temp request
    [self removeTempRequest:request];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(failureBlock) {
            failureBlock(request, error);
        }
    });
}

#pragma mark - private method
/**
 *  删除临时存储的请求
 */
- (void)removeTempRequest:(CTBaseRequest *)request
{
    NSString *requestKey = [[NSURL URLWithString:request.interface relativeToURL:self.baseURL] absoluteString];
    [self.tempRequestDic removeObjectForKey:requestKey];
}

#pragma mark - cancel request
- (void)cancelRequestWithUrl:(NSString *)url
{
    [self.sessionManager cancelTaskWithUrl:url];
}

- (void)cancelRequest:(CTBaseRequest * _Nonnull)request
{
    @synchronized (self)
    {
        NSString * detailUrl = request.interface;
        if (![detailUrl hasPrefix:@"http"])
        {
            detailUrl = [NSString stringWithFormat:@"%@%@", _configuration.baseURLString, detailUrl];
        }
        [self.sessionManager cancelTaskWithUrl:detailUrl];
        request.successBlock = nil;
        request.failureBlock = nil;
    }
}


- (void)cancelDownloadRequest:(CTBaseRequest *)request
{
    NSString *requestURLString = [[NSURL URLWithString:request.interface relativeToURL:self.baseURL] absoluteString];
    NSURLSessionDownloadTask *task = self.tempDownloadTaskDic[requestURLString];
    [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        NSString *resumeDataFileName = [self downloadRequestResumeDataFileName:request];
        //缓存，以用来断点续传
        [self.cache storeData:resumeData forFileName:resumeDataFileName];
        //不保存
        self.tempDownloadTaskDic[requestURLString] = nil;
    }];
}
@end
