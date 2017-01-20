//
//  CTNetworkManager.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTNetworkManager.h"
#import "CTBaseBatchRequest.h"



static CTNetworkManager *_manager = nil;

@interface CTNetworkManager ()
{
    dispatch_semaphore_t _lock;
}

@property (nonatomic, strong) AFHTTPSessionManager * sessionManager;
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
        
        _lock = dispatch_semaphore_create(1);
        
        //数据处理队列
        _dataHandleQueue = dispatch_queue_create("com.CTNEtworkManager.dataHandleQueue", DISPATCH_QUEUE_CONCURRENT);
        
        self.tempRequestDic = [NSMutableDictionary dictionary];
        self.tempDownloadTaskDic = [NSMutableDictionary dictionary];
    }
    return self;
}


- (NSString *)buildRequestUrl:(CTBaseRequest *)request
{
    NSAssert(_configuration, @"请先使用CTNetworkConfiguration 设置BaseUrl");
    NSString *detailUrl = [request interface];
    if ([detailUrl hasPrefix:@"http"]) {
        return detailUrl;
    }
    // filter url
    return [NSString stringWithFormat:@"%@%@", _configuration.baseURLString, detailUrl];
}


#pragma mark - download request -
- (void)sendDownloadRequest:(CTBaseRequest *)request
{
    NSAssert(self.baseURL, @"请先使用CTNetworkConfiguration 设置BaseUrl");
    NSString * requestURLString = CTURLStringFromBaseURLAndInterface(self.baseURL, request.interface);
    NSString * fileName = [self downloadRequestFileName:request];
    if (request.cachePolicy == CTCacheNone)
    {
        [self downloadDataWithRequest:request requestURL:requestURLString fileName:fileName];
    }
    else
    {
        [self.cache queryDiskCacheForFileName:fileName expiryDate:request.cacheValidInterval completion:^(id  _Nullable object)
         {
             //有缓存，则直接返回
             if(object && [object isKindOfClass:[NSData class]])
             {
                NSURL *filePath = [NSURL fileURLWithPath:[self.cache defaultCachePathForFileName:fileName]];
                 request.isFromCache = YES;
                 [self handleResultWithDownloadRequest:request filePath:filePath error:nil];
             }
            
             if (request.cachePolicy != CTCacheReadCacheOnly)
             {
                 [self downloadDataWithRequest:request requestURL:requestURLString fileName:fileName];
             }
         }];
    }
}

- (void)downloadDataWithRequest:(CTBaseRequest *)request
                     requestURL:(NSString *)requestURLString
                       fileName:(NSString *)fileName
{
    
    NSString *resumeDataFileName = [self downloadRequestResumeDataFileName:request];
    __weak CTNetworkManager * weakSelf = self;
    __weak CTBaseRequest * req = request;
    [self.cache queryDiskCacheForFileName:resumeDataFileName expiryDate:request.cacheValidInterval completion:^(id  _Nullable object)
    {
        //有数据，断点续传
        if(object && [object isKindOfClass:[NSData class]])
        {
            request.sessionTask = [self.sessionManager downloadTaskWithResumeData:object progress:request.progressBlock destination:^NSURL * _Nullable(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response)
            {
                return [weakSelf fileDestinationPathWithRequest:req targetPath:targetPath response:response];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
            {
                if (error)
                {
                    NSDictionary *userInfo = error.userInfo;
                    NSData * resumeData = [userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
                    [self cacheResumeData:resumeData request:req];
                }
                else
                {
                    //删除断点续传文件
                    [self.cache removeCacheForFileName:resumeDataFileName];
                }
                CTLock();
                self.tempDownloadTaskDic[requestURLString] = nil;
                CTUnlock();
                if (request.cachePolicy == CTCacheRefreshCacheAndLoadData)
                {
                    [self handleResultWithDownloadRequest:request filePath:filePath error:error];
                }
            }];
        }
        else
        {
            //无缓存，则重新下载
            NSMutableURLRequest *httpRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURLString]];
            [self setHttpRequestHeardFieldsWithRequest:request];
            request.sessionTask = [self.sessionManager downloadTaskWithRequest:httpRequest progress:request.progressBlock destination:^NSURL * _Nullable(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response)
            {
                return [weakSelf fileDestinationPathWithRequest:req targetPath:targetPath response:response];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                if (error)
                {
                    NSDictionary *userInfo = error.userInfo;
                    NSData * resumeData = [userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
                    [self cacheResumeData:resumeData request:req];
                }
                //清空task
                CTLock();
                self.tempDownloadTaskDic[requestURLString] = nil;
                CTUnlock();
                if (request.cachePolicy == CTCacheRefreshCacheAndLoadData)
                {
                    [self handleResultWithDownloadRequest:request filePath:filePath error:error];
                }
            }];
        }
        [request.sessionTask resume];
        //save
        CTLock();
        self.tempDownloadTaskDic[requestURLString] = request.sessionTask;
        CTUnlock();
    }];
}

- (void)cacheResumeData:(NSData *)data request:(CTBaseRequest *)req
{
    NSString * resumeDataFileName = [self downloadRequestResumeDataFileName:req];
    [self.cache storeData:data forFileName:resumeDataFileName];
}


- (NSURL * _Nullable)fileDestinationPathWithRequest:(CTBaseRequest *)req
                                         targetPath:(NSURL * _Nonnull)targetPath
                                           response:(NSURLResponse * _Nonnull)response
{
    if(((NSHTTPURLResponse *)response).statusCode >= 400)
    {
        return targetPath;
    }
    else
    {
        NSString * fileName = req.fileName;
        if (!fileName)
        {
            fileName = [response suggestedFilename];
            req.fileName = fileName;
        }
        return [NSURL fileURLWithPath:[self.cache defaultCachePathForFileName:fileName]];
    }
}

- (void)handleResultWithDownloadRequest:(CTBaseRequest *)request
                         filePath:(NSURL *)filePath
                            error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
    NSString * desStr = [NSString stringWithFormat:@"\n--------------- CTRequest download completion ---------------\n-> interface: [-  %@  -]\n-> param:\n%@\n-> Unusual HTTPHeader:\n%@\n-> fileName:\n%@\n-> filePath:\n%@\n-> error:\n%@\n-------------------------------------------------------------", request.interface, request.parameterDict, request.HTTPHeaderFieldDict,request.fileName,filePath.absoluteString,error.localizedDescription];
        NET_LOG(@"%@",desStr);
        if(request.downloadBlock)
        {
            request.downloadBlock(request, filePath, error);
        }
        request.isExciting = NO;
    });
}

/**
 *  下载请求的文件名
 */
- (NSString *)downloadRequestFileName:(CTBaseRequest *)request
{
    NSString * fileName = [request.fileName lastPathComponent];
    if (!fileName) {
        fileName = [request.interface lastPathComponent];
    }
    return fileName;
}

/**
 *  断点续传的文件名，在下载文件名后面多了一个_resume
 */
- (NSString *)downloadRequestResumeDataFileName:(CTBaseRequest *)request
{
    return [NSString stringWithFormat:@"%@_resume", [self downloadRequestFileName:request]];
}

#pragma mark - upload request -
- (void)sendUploadRequest:(CTBaseRequest *)request
{
    [self setHttpRequestHeardFieldsWithRequest:request];
    NSString * url = [self buildRequestUrl:request];
    NSDictionary * param = [self.configuration requestParamterWithRequest:request];
    request.sessionTask = [self.sessionManager POST:url
                                         parameters:param
                          constructingBodyWithBlock:request.formData
                                           progress:request.progressBlock
                                            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
    {
        [self networkSuccess:request task:task responseData:responseObject];
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nullable error) {
        [self failure:request error:error];
    }];
    request.isExciting = YES;
}

- (void)sendRequest:(CTBaseRequest *)request
{
    //发送网络之前，先进行一下预处理
    [self.configuration prepareProcessingRequest:request];
    
    switch (request.cachePolicy)
    {
        case CTCacheNone:
            //请求网络数据
            [self startNetworkDataWithRequest:request];
            break;
        case CTCacheReadCacheOnly:
        case CTCacheRefreshCacheData:
        case CTCacheRefreshCacheAndLoadData:
            //读取缓存并且请求数据
            [self readCacheWithRequest:request completion:^(CTBaseRequest *request, id responseObject)
            {
                if(responseObject){
                    /*
                     缓存策略
                     CTBaseRequestCacheDataAndReadCacheOnly：获取缓存数据直接调回，不再请求
                     */
                    [self success:request responseObject:responseObject isFromCache:YES];

                    // CTBaseRequestCacheDataAndReadCacheLoadData：缓存数据成功调回并且重新请求网络
                    if(request.cachePolicy == CTCacheRefreshCacheData ||
                       request.cachePolicy == CTCacheRefreshCacheAndLoadData)
                    {
                        [self startNetworkDataWithRequest:request];
                    }
                }else{
                    //无缓存数据，则还需要再请求网络
                    [self startNetworkDataWithRequest:request];
                }
            }];
    }
}

- (void)setHttpRequestHeardFieldsWithRequest:(CTBaseRequest *)request
{
    NSDictionary * headerFieldValueDictionary = [self.configuration requestHTTPHeaderFields:request];
    if (headerFieldValueDictionary != nil)
    {
        for (id httpHeaderField in headerFieldValueDictionary.allKeys)
        {
            id value = headerFieldValueDictionary[httpHeaderField];
            if ([httpHeaderField isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]])
            {
                [_sessionManager.requestSerializer setValue:(NSString *)value forHTTPHeaderField:(NSString *)httpHeaderField];
            } else {
                NSLog(@"Error, class of key/value in headerFieldValueDictionary should be NSString.");
            }
        }
    }
}

- (void)startNetworkDataWithRequest:(CTBaseRequest *)request
{
    //临时保存请求
    NSString *requestKey = request.requestKey;
    if (request.isCancleSendWhenExciting)
    {
        if ([[_tempRequestDic allKeys] containsObject:requestKey])
        {   // 取消发送请求
            return;
        }
    }
    CTLock();
    self.tempRequestDic[requestKey] = request;
    CTUnlock();
    
    NSString * url = [self buildRequestUrl:request];
    
    [self setHttpRequestHeardFieldsWithRequest:request];
    // 生成请求参数
    NSDictionary * param = [self.configuration requestParamterWithRequest:request];
    //发送请求
    __weak CTNetworkManager * weakManager = self;
    switch (request.requestMethod) {
        case CTNetworkRequestHTTPGet:
        {
            request.sessionTask = [self.sessionManager GET:url parameters:param progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error];
            }];
        }
            break;
        case CTNetworkRequestHTTPPost:
        {
            request.sessionTask = [self.sessionManager POST:url parameters:param progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error];
            }];
        }
            break;
        case CTNetworkRequestHTTPDelete:
        {
            request.sessionTask = [self.sessionManager DELETE:url parameters:param success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error];
            }];
        }
            break;

        case CTNetworkRequestHTTPPut:
        {
            request.sessionTask = [self.sessionManager PUT:url parameters:param success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakManager networkSuccess:request task:task responseData:responseObject ];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakManager failure:request error:error];
            }];
        }
            break;

        default:
            break;
    }
    
    if ([request.sessionTask respondsToSelector:@selector(priority)])
    {
        switch (request.requestPriority)
        {
            case CTRequestPriorityHigh:
                request.sessionTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case CTRequestPriorityLow:
                request.sessionTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case CTRequestPriorityDefault:
                /*!!fall through*/
            default:
                request.sessionTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    request.isExciting = YES;
}


#pragma mark - cache method -
- (void)readCacheWithRequest:(CTBaseRequest *)request completion:(void (^)(CTBaseRequest *request, id responseObject))completionBlock
{
    __weak CTNetworkManager *weakManager = self;
    NSString *cacheKey = CTKeyFromRequestAndBaseURL(request.parameterDict, self.baseURL, request.interface);
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
    [self.cache storeData:responseData forFileName:CTKeyFromRequestAndBaseURL(request.parameterDict, self.baseURL, request.interface)];
}

#pragma mark - set method -
- (void)setNetworkConfiguration:(CTNetworkConfiguration *)configuration
{
    NSParameterAssert(configuration);
    NSParameterAssert(configuration.baseURLString);
    
    // AFHTTPSessionManager
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:configuration.baseURLString]];
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:configuration.SSLPinningMode];
    //是否允许CA不信任的证书通过
    policy.allowInvalidCertificates = configuration.allowInvalidCertificates;
    //是否验证主机名
    policy.validatesDomainName = configuration.validatesDomainName;
    _sessionManager.securityPolicy = policy;
    
    AFHTTPRequestSerializer * reqSerializer;
    AFHTTPResponseSerializer * resSerializer;

    //设置
    if (configuration.requestSerializerType == CTRequestSerializerTypeJSON) {
        reqSerializer = [AFJSONRequestSerializer serializer];
    }else {
        reqSerializer = [AFHTTPRequestSerializer serializer];
    }
    
    if (configuration.responseSerializerType == CTResponseSerializerTypeJSON) {
        resSerializer = [AFJSONResponseSerializer serializer];
    }else {
        resSerializer = [AFHTTPResponseSerializer serializer];
    }

    reqSerializer.timeoutInterval = configuration.timeInterval;
    NSMutableSet * sets = [NSMutableSet setWithSet:resSerializer.acceptableContentTypes];
    [sets unionSet:configuration.acceptableContentTypes];
    
    resSerializer.acceptableContentTypes = sets;
    _sessionManager.requestSerializer = reqSerializer;
    _sessionManager.responseSerializer = resSerializer;
    
    self.baseURL = [NSURL URLWithString:configuration.baseURLString];
    _configuration = configuration;
}

#pragma mark - 网络请求回来调用的方法
- (void)networkSuccess:(CTBaseRequest *)request
                  task:(NSURLSessionDataTask *)task
          responseData:(id)responseData
{
    
    dispatch_async(self.dataHandleQueue, ^{
        //对数据进行解密
        id decryptData = [self.configuration decryptResponseData:responseData response:task.response request:request];
        //解析数据
        dispatch_async(dispatch_get_main_queue(), ^{
            if(decryptData)
            {
                if (request.cachePolicy != CTCacheNone)
                {   //缓存解密之后的数据
                    if([self.configuration shouldCacheResponseData:decryptData task:task request:request])
                    {   //缓存解密之后的数据
                        id objData = CTDataFromJsonObj(responseData);
                        [self cacheResponseData:objData request:request];
                    }
                }
                
                if (request.cachePolicy != CTCacheRefreshCacheData)
                {   //成功回调
                    [self success:request responseObject:decryptData isFromCache:NO];
                }
            }
            else
            {
                if (request.cachePolicy != CTCacheRefreshCacheData)
                {
                    NSDictionary * userInfo = @{@"interface":request.interface,
                                                @"paramter":request.parameterDict?request.parameterDict:@""};
                    NSError * error = [NSError errorWithDomain:@"解密出错, 无数据返回" code:1000 userInfo:userInfo];
                    [self failure:request error:error];
                }
            }
            request.isExciting = NO;
        });
    });
    //remove temp request
    [self removeTempRequest:request];
}

- (void)success:(CTBaseRequest *)request
 responseObject:(id)responseObject
    isFromCache:(BOOL)isFromCache
{
    dispatch_async(self.dataHandleQueue, ^{
        request.responseObj = responseObject;
        request.isFromCache = isFromCache;
        //成功回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.configuration.isDebug)
            {
                NET_LOG(@"%@", request);
            }
            if(request.successBlock) {
                request.successBlock(request, responseObject);
            }
        });
    });
}

/**
 *  网络失败
 */
- (void)failure:(CTBaseRequest *)request error:(NSError *)error
{
    //remove temp request
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.configuration.isDebug)
        {
            NSString * desStr = [NSString stringWithFormat:@"\n--------------- Request error --------------------\n-> interface: [-  %@  -]\n-> param:\n%@\n-> Unusual HTTPHeader:\n%@\n-> error:\n%@", request.interface, request.parameterDict, request.HTTPHeaderFieldDict, error.localizedDescription];
            NET_LOG(@"%@", desStr);
        }
        if(request.failureBlock) {
            request.failureBlock(request, error);
        }
        [self removeTempRequest:request];
    });
}

#pragma mark - private method
/**
 *  删除临时存储的请求
 */
- (void)removeTempRequest:(CTBaseRequest *)request
{
    CTLock();
    [self.tempRequestDic removeObjectForKey:request.requestKey];
    CTUnlock();
}

#pragma mark - cancel request
- (void)cancelRequestWithUrl:(NSString *)url
{
    [self cancelTaskWithUrl:url];
}

- (void)cancelRequest:(CTBaseRequest * _Nonnull)request
{
    NSString * detailUrl = request.interface;
    if (![detailUrl hasPrefix:@"http"])
    {
        detailUrl = [NSString stringWithFormat:@"%@%@", _configuration.baseURLString, detailUrl];
    }
    [self cancelTaskWithUrl:detailUrl];
    request.successBlock = nil;
    request.failureBlock = nil;
}

- (void)cancelDownloadRequest:(CTBaseRequest *)request
{
    NSString *requestURLString = [[NSURL URLWithString:request.interface relativeToURL:self.baseURL] absoluteString];
    NSURLSessionDownloadTask *task = self.tempDownloadTaskDic[requestURLString];
    [task cancelByProducingResumeData:^(NSData * _Nullable resumeData)
    {
        NSString *resumeDataFileName = [self downloadRequestResumeDataFileName:request];
        //缓存，以用来断点续传
        [self.cache storeData:resumeData forFileName:resumeDataFileName];
        //不保存
        self.tempDownloadTaskDic[requestURLString] = nil;
    }];
}

- (void)cancelTaskWithUrl:(NSString *)url
{
    CTLock();
    [self.sessionManager.tasks enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop)
    {
        NSString *taskUrl = obj.currentRequest.URL.absoluteString;
        if([taskUrl rangeOfString:url].location != NSNotFound)
        {
            [obj cancel];
            * stop = YES;
        }
    }];
    CTUnlock();
}

@end


@implementation CTNetworkManager (Core)

+ (void)setNetConfig:(CTNetworkConfigBlock _Nonnull)configBlock
{
    CTNetworkConfiguration * config = [CTNetworkConfiguration configuration];
    configBlock(config);
    [[CTNetworkManager sharedManager] setNetworkConfiguration:config];
}


+ (CTBaseRequest * _Nonnull)startGET:(CTNetworkRequestBlock _Nonnull)reqBlock
                             success:(CTNetworkSuccessBlock _Nullable)successBlock
                             failure:(CTNetworkFailureBlock _Nullable)failureBlock
{
    CTBaseRequest * req = [[CTBaseRequest alloc] init];
    req.requestMethod = CTNetworkRequestHTTPGet;
    req.successBlock = successBlock;
    req.failureBlock = failureBlock;
    NSAssert(reqBlock, @"请设置请求接口 (interface)");
    reqBlock(req);
    [[CTNetworkManager sharedManager] sendRequest:req];
    return req;
}

+ (CTBaseRequest * _Nonnull)startPOST:(CTNetworkRequestBlock _Nonnull)reqBlock
                              success:(CTNetworkSuccessBlock _Nullable)successBlock
                              failure:(CTNetworkFailureBlock _Nullable)failureBlock
{
    CTBaseRequest * req = [[CTBaseRequest alloc] init];
    req.requestMethod = CTNetworkRequestHTTPPost;
    req.successBlock = successBlock;
    req.failureBlock = failureBlock;
    NSAssert(reqBlock, @"请设置请求接口 (interface)");
    reqBlock(req);
    [[CTNetworkManager sharedManager] sendRequest:req];
    return req;
}

+ (CTBaseRequest * _Nonnull)startUpload:(CTNetworkRequestBlock _Nonnull)reqBlock
                               progress:(CTNetworkProgressBlock _Nullable)progressBlock
                                success:(CTNetworkSuccessBlock _Nullable)successBlock
                                failure:(CTNetworkFailureBlock _Nullable)failureBlock
{
    CTBaseRequest * req = [[CTBaseRequest alloc] init];
    req.requestMethod = CTNetworkRequestHTTPPost;
    req.progressBlock = progressBlock;
    req.successBlock = successBlock;
    req.failureBlock = failureBlock;
    NSAssert(reqBlock, @"请设置请求接口 (interface)");
    reqBlock(req);
    [[CTNetworkManager sharedManager] sendUploadRequest:req];
    return req;
}


+ (CTBaseRequest * _Nonnull)startDownload:(CTNetworkRequestBlock _Nonnull)reqBlock
                                 progress:(CTNetworkProgressBlock _Nullable)progressBlock
                          complectHandler:(CTNetworkDownloadBlock _Nonnull)complectBlock
{
    CTBaseRequest * req = [[CTBaseRequest alloc] init];
    req.requestMethod = CTNetworkRequestHTTPPost;
    req.progressBlock = progressBlock;
    req.downloadBlock = complectBlock;
    NSAssert(reqBlock, @"请设置请求接口 (interface)");
    reqBlock(req);
    [[CTNetworkManager sharedManager] sendDownloadRequest:req];
    return req;
}

+ (CTBaseBatchRequest * _Nonnull)startBatch:(CTNetworkBatchReqBlock )batchReqBlock
                                    success:(CTNetworkBatchSuccessBlock _Nonnull)successBlock
                                    failure:(CTNetworkBatchFailureBlock _Nonnull)failureBlock
                                 completion:(CTNetworkBatchComplectBlock _Nonnull)completionBlock
{
    CTBaseBatchRequest * req = [[CTBaseBatchRequest alloc] init];
    NSAssert(batchReqBlock, @"请先设置组请求的request");
    req.requestArray = batchReqBlock(req);
    [req startRequestSuccess:successBlock failure:failureBlock completion:completionBlock];
    return req;
}

@end
