//
//  CTNetworkCache.m
//  CTNetwork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTNetworkCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface CTNetworkCache ()

@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, strong) NSString *diskCachePath;
@property (nonatomic, strong) NSFileManager *fileManager;

@end

@implementation CTNetworkCache

+ (instancetype)sharedCache{
    static CTNetworkCache *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class] alloc] init];
    });
    return _instance;
}

- (instancetype)init{
    
    return [self initWithNamespace:@"com.CTNetworkCache"];
}

- (instancetype)initWithNamespace:(NSString *)nameSpace{
    if(self = [super init]){
        //创建工作队列
        _workQueue = dispatch_queue_create("com.CTNetworkCache.workQueue", DISPATCH_QUEUE_SERIAL);
        
        //缓存路径
        _diskCachePath = [self makeDiskCachePath:nameSpace];
        
        //文件管理
        dispatch_async(self.workQueue, ^{
            _fileManager = [NSFileManager defaultManager];
            if (![_fileManager fileExistsAtPath:_diskCachePath]) {
                [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
        });
    }
    return self;
}

#pragma mark - cache data for key
- (void)storeData:(NSData *)data forKey:(NSString *)key
{
    [self storeData:data forFileName:CT_MD5(key)];
}

- (NSData *)queryCacheForKey:(NSString *)key
{
    return [self queryCacheForFileName:CT_MD5(key)];
}

- (void)queryCacheForKey:(NSString *)key completion:(CTQueryCacheCompletionBlock _Nonnull)block
{
    [self queryDiskCacheForFileName:CT_MD5(key) expiryDate:-1 completion:block];
}

- (void)queryCacheForKey:(NSString * _Nonnull)key expiryDate:(NSUInteger)effectTime completion:(CTQueryCacheCompletionBlock _Nonnull)block
{
    [self queryDiskCacheForFileName:CT_MD5(key) expiryDate:effectTime completion:block];
}

- (void)removeCacheForKey:(NSString *)key
{
    [self removeCacheForFileName:CT_MD5(key)];
}

#pragma mark - cache data for fileName
- (void)storeData:(NSData *)data forFileName:(NSString *)fileName completion:(CTCacheCompletionBlock _Nullable)comletionBlock
{
    if(!data | !fileName){
        return;
    }
    //缓存到本地
    dispatch_async(self.workQueue, ^{
        // get cache Path for data key
        NSString *cachePathForKey = [self defaultCachePathForFileName:fileName];
        if([_fileManager fileExistsAtPath:cachePathForKey isDirectory:nil]) {
            [_fileManager removeItemAtPath:cachePathForKey error:nil];
        }
        BOOL success = [_fileManager createFileAtPath:cachePathForKey contents:data attributes:nil];
        NSLog(@"-- cache %@ \n%@", success?@"成功":@"失败", cachePathForKey);
        if(comletionBlock) {
            comletionBlock();
        }
    });
}

- (void)storeData:(NSData *)data forFileName:(NSString *)fileName
{
    [self storeData:data forFileName:fileName completion:NULL];
}

- (NSData *)queryCacheForFileName:(NSString *)fileName
{
    if(!fileName){
        return nil;
    }
    NSString *cachePathForKey = [self defaultCachePathForFileName:fileName];
    NSData * data = [[NSData alloc] initWithContentsOfFile:cachePathForKey];
    return data;
}


- (void)queryDiskCacheForFileName:(NSString *)fileName expiryDate:(NSUInteger)effectTime completion:(CTQueryCacheCompletionBlock)comletionBlock {
    if(!fileName){
        return;
    }
    dispatch_async(self.workQueue, ^{
        NSString *cachePath = [self defaultCachePathForFileName:fileName];
        NSLog(@"-- 读取缓存 %@", cachePath);
        long long seconds = [self cacheFileDuration:cachePath];
        if (seconds < 0 || seconds > effectTime) {
            [self removeCacheForFileName:fileName];
            comletionBlock(nil);
            return;
        }
        
        NSData *diskData = [[NSData alloc] initWithContentsOfFile:cachePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            comletionBlock(diskData);
        });
    });
}

- (int)cacheFileDuration:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // get file attribute
    NSError *attributesRetrievalError = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path
                                                             error:&attributesRetrievalError];
    if (!attributes) {
        return -1;
    }
    int seconds = - [[attributes fileModificationDate] timeIntervalSinceNow];
    return seconds;
}


- (void)removeCacheForFileName:(NSString *)fileName
{
    //remove disk data
    dispatch_async(self.workQueue, ^{
        NSString *cachePathForKey = [self defaultCachePathForFileName:fileName];
        [_fileManager removeItemAtPath:cachePathForKey error:nil];
    });
}

#pragma mark - cache object method
- (void)storeObject:(id<NSCoding>)object forKey:(NSString *)key
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [self storeData:data forKey:key];
}

- (id)queryObjectForKey:(NSString *)key
{
    NSData *data = [self queryCacheForKey:key];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)queryObjectForKey:(NSString *)key completion:(CTQueryCacheCompletionBlock _Nonnull)block{
    if(!key || !block)
    {
        return;
    }
    [self queryCacheForKey:key completion:^(NSData *data) {
        id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        block(object);
    }];
}

// Init the disk cache
-(NSString *)makeDiskCachePath:(NSString*)fullNamespace
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

- (NSString *)cachePathForFileName:(NSString *)fileName inPath:(NSString *)path
{
    return [path stringByAppendingPathComponent:fileName];
}

- (NSString *)defaultCachePathForFileName:(NSString *)fileName
{
    return [self cachePathForFileName:fileName inPath:self.diskCachePath];
}
@end




inline NSString * const CT_MD5(NSString *value) {
    const char *str = [value UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *md5Str = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return md5Str;
}

inline NSArray * CTQueryStringFromKeyAndValue(NSString *key, id value)
{
    NSMutableArray *array = [NSMutableArray array];
    if([value isKindOfClass:[NSDictionary class]]){
        [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(NSString *dicKey, id obj, BOOL *stop) {
            NSString *resultKey = [NSString stringWithFormat:@"%@[%@]", key, dicKey];
            [array addObjectsFromArray:CTQueryStringFromKeyAndValue(resultKey, obj)];
        }];
    }
    else if([value isKindOfClass:[NSArray class]]){
        [(NSArray *)value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *resultKey = [NSString stringWithFormat:@"%@[]", key];
            [array addObjectsFromArray:CTQueryStringFromKeyAndValue(resultKey, obj)];
        }];
    }
    else if([value isKindOfClass:[NSSet class]]){
        [(NSSet *)value enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSString *resultKey = [NSString stringWithFormat:@"%@[]", key];
            [array addObjectsFromArray:CTQueryStringFromKeyAndValue(resultKey, obj)];
        }];
    }
    else{
        [array addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
    return array;
}

inline NSString * const CTQueryStringFromParamDictionary(NSDictionary *paramDic)
{
    NSMutableArray *array = [NSMutableArray array];
    [paramDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [array addObjectsFromArray:CTQueryStringFromKeyAndValue(key, obj)];
    }];
    return [array componentsJoinedByString:@"&"];
}

inline NSString * const CTKeyFromParamsAndURLString(NSDictionary *paramDic, NSString * URLString)
{
    //先进行排序
    NSArray *keys = [paramDic allKeys];
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    //组装字符串
    NSMutableString *keyMutableString = [NSMutableString string];
    for (NSInteger index = 0; index < sortedArray.count; index++) {
        NSString *key = [sortedArray objectAtIndex:index];
        NSString *value = [paramDic objectForKey:key];
        if (index == 0) {
            [keyMutableString appendFormat:@"%@=%@",key,value];
        } else {
            [keyMutableString appendFormat:@"|%@=%@",key,value];
        }
    }
    [keyMutableString appendString:URLString];
    
    return CT_MD5(keyMutableString);
}

inline NSString * const CTURLStringFromBaseURLAndInterface(NSURL *baseURL, NSString * interface)
{
    return [[NSURL URLWithString:interface relativeToURL:baseURL] absoluteString];
}

inline NSString * const CTKeyFromRequestAndBaseURL(NSDictionary *paramDic, NSURL *baseURL, NSString * interface)
{
    return CTKeyFromParamsAndURLString(paramDic, CTURLStringFromBaseURLAndInterface(baseURL, interface));
}


inline id CTParseJsonData(id jsonData)
{
    /**
     *  解析json对象
     */
    NSError *error;
    id jsonResult = nil;
    if([NSJSONSerialization isValidJSONObject:jsonData]){
        return jsonData;
    }
    //NSData
    if (jsonData && [jsonData isKindOfClass:[NSData class]]){
        jsonResult = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    }
    if (jsonResult != nil && error == nil){
        return jsonResult;
    }
    else{
        // 解析错误
        return nil;
    }
}

inline NSData * CTDataFromJsonObj(id jsonObj)
{
    /**
     *  解析json对象
     */
    NSError *error;
    id data = nil;
    //JSON obj
    if (jsonObj && [NSJSONSerialization isValidJSONObject:jsonObj]){
        data = [NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:&error];
    }
    if (data != nil && error == nil){
        return data;
    }else{
        // 解析错误
        return nil;
    }
}
