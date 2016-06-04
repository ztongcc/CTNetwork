//
//  CTNetworkCache.h
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CTQueryCacheCompletionBlock)(id _Nullable object);
typedef void(^CTCacheCompletionBlock)(void);



@interface CTNetworkCache : NSObject
/**
 *  返回一个单例对象
 */
+ (instancetype _Nonnull)sharedCache;

/**
 *  初始化对象
 *
 *  @param nameSpace 设置缓存空间
 *
 */
- (instancetype _Nonnull)initWithNamespace:(NSString * _Nonnull)nameSpace;

/**
 *  默认缓存路径
 *
 *  @param fileName 文件名
 *
 *  @return 返回文件路径
 */
- (NSString * _Nonnull)defaultCachePathForFileName:(NSString * _Nonnull)fileName;

#pragma mark - cache file with key
/**
 *  缓存数据
 *
 *  @param data 缓存的数据
 *  @param key  缓存的Key值，内部会以此值md5一下成为文件名
 */
- (void)storeData:(NSData * _Nonnull)data forKey:(NSString * _Nonnull)key;


/**
 *  查询缓存数据
 *
 *  @param key 查询缓存数据的key
 *
 *  @return 返回查询到的缓存数据
 */
- (NSData * _Nullable)queryCacheForKey:(NSString * _Nonnull)key;

/**
 */
- (void)queryCacheForKey:(NSString * _Nonnull)key completion:(CTQueryCacheCompletionBlock _Nonnull)block;
/**
 *  查询缓存数据
 *
 *  @param key   查询缓存数据的key
 *  @param effectTime 缓存有效期
 *  @param block 查询完之后的回调block
 */
- (void)queryCacheForKey:(NSString * _Nonnull)key expiryDate:(NSUInteger)effectTime completion:(CTQueryCacheCompletionBlock _Nonnull)block;
/**
 *  删除数据
 *
 *  @param key 缓存数据对应的key
 */
- (void)removeCacheForKey:(NSString * _Nonnull)key;

#pragma mark - 存储对象
/**
 *  归档存储对象
 *
 *  @param object 对象
 *  @param key    key值
 */
- (void)storeObject:(id<NSCoding> _Nonnull)object forKey:(NSString * _Nonnull)key;
/**
 *  查询对象
 *
 *  @param key key值
 *
 *  @return 返回一个查询的对象
 */
- (id _Nullable)queryObjectForKey:(NSString * _Nonnull)key;
/**
 *  查询对象
 *
 *  @param key   key值
 *  @param block 回调一个查询好的对象
 */
- (void)queryObjectForKey:(NSString * _Nonnull)key completion:(CTQueryCacheCompletionBlock _Nonnull)block;

#pragma mark - cache file with fileName
/**
 *  缓存数据 fileName 由 key MD5 生成
 */
- (void)storeData:(NSData * _Nonnull)data forFileName:(NSString * _Nonnull)fileName;

/**
 *  缓存数据 fileName 由 key MD5 生成
 */
- (void)storeData:(NSData * _Nonnull)data forFileName:(NSString * _Nonnull)fileName completion:(CTCacheCompletionBlock _Nullable)comletionBlock;

/**
 *  查询缓存数据 fileName 由 key MD5 生成
 *  @return 返回查询到的缓存数据
 */
- (NSData * _Nullable)queryCacheForFileName:(NSString * _Nonnull)fileName;

/**
 *  查询缓存数据
 *
 *  @param fileName       文件名 （由 key MD5 生成缓存到本地的文件名）
 *  @param effectTime     缓存有限时间 0 是无限 以秒为单位
 *  @param comletionBlock 完成block
 */
- (void)queryDiskCacheForFileName:(NSString * _Nonnull)fileName expiryDate:(NSUInteger)effectTime completion:(CTQueryCacheCompletionBlock _Nonnull)comletionBlock;

/**
 *  删除数据 （由 key MD5 生成缓存到本地的文件名）
 */
- (void)removeCacheForFileName:(NSString * _Nonnull)fileName;

@end






/**
 *  生成MD5
 */
FOUNDATION_EXPORT NSString * const _Nonnull CT_MD5(NSString * _Nonnull value);

/**
 *  由参数、方法名、URL生成一个唯一的key
 */
FOUNDATION_EXPORT NSString * const _Nonnull CTKeyFromParamsAndURLString(NSDictionary * _Nullable paramDic, NSString * _Nonnull URLString);


FOUNDATION_EXPORT NSString * const _Nonnull CTURLStringFromBaseURLAndInterface(NSURL * _Nullable baseURL, NSString * _Nullable interface);


FOUNDATION_EXPORT NSString * const _Nonnull CTKeyFromRequestAndBaseURL(NSDictionary * _Nullable paramDic, NSURL * _Nonnull baseURL, NSString * _Nonnull interface);
/**
 *  解析数据
 *
 *  @param jsonData 原数据
 *
 *  @return 解析后的数据
 */
FOUNDATION_EXPORT id _Nonnull CTParseJsonData(id _Nonnull jsonData);


FOUNDATION_EXPORT NSData * _Nonnull CTDataFromJsonObj(id _Nonnull jsonObj);
