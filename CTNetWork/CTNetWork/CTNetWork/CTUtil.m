//
//  CTUtil.m
//  CTNetWork
//
//  Created by ZhiTong on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTUtil.h"
#import <CommonCrypto/CommonDigest.h>

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

