//
//  CTUtil.h
//  CTNetWork
//
//  Created by ZhiTong on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  生成MD5
 */
FOUNDATION_EXPORT NSString * const _Nonnull CT_MD5(NSString * _Nonnull value);

/**
 *  生成queryString
 */
FOUNDATION_EXPORT NSString * const _Nonnull CTQueryStringFromParamDictionary(NSDictionary * _Nonnull paramDic);

/**
 *  由参数、方法名、URL生成一个唯一的key
 */
FOUNDATION_EXPORT NSString * const _Nonnull CTKeyFromParamsAndURLString(NSDictionary * _Nullable paramDic, NSString * _Nonnull URLString);


FOUNDATION_EXPORT NSString * const _Nonnull CTKeyFromRequestAndBaseURL(NSDictionary * _Nullable paramDic, NSURL * _Nonnull baseURL, NSString * _Nonnull interface);
/**
 *  解析数据
 *
 *  @param jsonData 原数据
 *
 *  @return 解析后的数据
 */
FOUNDATION_EXPORT id _Nonnull CTParseJsonData(id _Nonnull jsonData);