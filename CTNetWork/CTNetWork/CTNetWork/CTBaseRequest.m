//
//  CTBaseRequest.m
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTBaseRequest.h"
#import "CTNetworkManager.h"
#import <objc/runtime.h>


static NSUInteger _requestIdentifier = 0;

@interface CTBaseRequest ()
{
    NSString *_methodName;
}
@property (nonatomic, strong) NSMutableDictionary *mutableParametersDic;
@property (nonatomic, strong) NSMutableDictionary *mutableRequestHTTPHeaderFields;
/**
 *  代理
 */
@property (nonatomic, weak) id<CTNetworkRequestDelegate> delegate;

@end

@implementation CTBaseRequest

- (void)dealloc
{
        NSLog(@"%@ [-%ld-] delloc, ", NSStringFromClass(self.class), (unsigned long)self.requestIdentifier);
}

- (instancetype)init{
    if(self = [super init]){
        _requestIdentifier += 1;
        _mutableRequestHTTPHeaderFields = [[NSMutableDictionary alloc] init];
        _mutableParametersDic = [[NSMutableDictionary alloc] init];
        self.requestMethod = CTNetworkRequestHTTPGet;
        self.cachePolicy = CTNetworkRquestCacheNone;
    }
    return self;
}

#pragma mark - set or get method
- (NSUInteger)requestIdentifier {
    return _requestIdentifier;
}

- (NSDictionary *)parametersDic
{
    return [_mutableParametersDic copy];
}

- (NSDictionary *)requestHTTPHeaderFields
{
    return [_mutableRequestHTTPHeaderFields copy];
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
- (void)setIntegerValue:(NSInteger)value forParamKey:(NSString *)key{
    [self setValue:[NSNumber numberWithInteger:value] forParamKey:key];
}

- (void)setDoubleValue:(double)value forParamKey:(NSString *)key{
    [self setValue:[NSNumber numberWithDouble:value] forParamKey:key];
}

- (void)setLongLongValue:(long long)value forParamKey:(NSString *)key{
    [self setValue:[NSNumber numberWithLongLong:value] forParamKey:key];
}

- (void)setBOOLValue:(BOOL)value forParamKey:(NSString *)key{
    [self setValue:[NSNumber numberWithBool:value] forParamKey:key];
}

- (void)setValue:(id)value forParamKey:(NSString *)key{
    if(!key){
        return;
    }
    if(!value){
        value = @"";
    }
    _mutableParametersDic[key] = value;
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
    NSString *desStr = [NSString stringWithFormat:@"%@\n interface: [-%@-]\n param:\n%@", className, self.interface, self.parametersDic];
    return desStr;
}
@end

@implementation CTBaseRequest (CTNetworkManager)
#pragma mark - class method
//+ (void)cancelRequest
//{
//    [[CTNetworkManager sharedManager] cancelRequestWithUrl:[self getRequestMethodName]];
//}
//
//- (void)sendRequestWithSuccess:(BGSuccessCompletionBlock)successCompletionBlock businessFailure:(BGBusinessFailureBlock)businessFailureBlock networkFailure:(BGNetworkFailureBlock)networkFailureBlock {
//    [[BGNetworkManager sharedManager] sendRequest:self success:successCompletionBlock businessFailure:businessFailureBlock networkFailure:networkFailureBlock];
//}

@end
