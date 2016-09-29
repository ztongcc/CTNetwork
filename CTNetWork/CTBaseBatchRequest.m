//
//  CTBatchBaseRequest.m
//  CTNetwork
//
//  Created by ZhiTong on 16/6/4.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTBaseBatchRequest.h"
#import "CTNetworkManager.h"
#import "CTBaseRequest.h"   

@interface CTBaseBatchRequest ()

@property (nonatomic, copy)void (^successBlock)(CTBaseRequest * request, id responseObj);
@property (nonatomic, copy)void (^failureBlock)(CTBaseRequest * request, NSError * error);
@property (nonatomic, copy)void (^completBlock)(CTBaseBatchRequest * request, BOOL isFinish);

@property (nonatomic, strong) NSArray *requestArray;

@end

@implementation CTBaseBatchRequest

- (instancetype)init {
    return [self initWithRequests:nil];
}

- (instancetype)initWithRequests:(NSArray *)requestArray
{
    if(self = [super init]) {
        self.requestArray = requestArray;
        self.continueLoadWhenRequestFailure = YES;
    }
    return self;
}

- (void)startRequestSuccess:(void (^)(CTBaseRequest * request, id responseObj))successBlock
                    failure:(void (^)(CTBaseRequest * request, NSError *error))failureBlock
                 completion:(void (^)(CTBaseBatchRequest * request, BOOL isFinish))completionBlock
{
    
    NSInteger requestCount = self.requestArray.count;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.completBlock = completionBlock;
    __block NSInteger successCount = 0;
    __weak typeof (self) weakSelf = self;
    for (CTBaseRequest * request in self.requestArray)
    {
        [request startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response)
        {
            successCount++;
            if(weakSelf.successBlock)
            {
                weakSelf.successBlock(request, response);
            }
            if(successCount == requestCount)
            {
                if(weakSelf.completBlock)
                {
                    weakSelf.completBlock(weakSelf, YES);
                }
            }
        }
        failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error)
        {
            successCount++;
            if(weakSelf.failureBlock)
            {
                weakSelf.failureBlock(request, error);
            }
            if(!self.continueLoadWhenRequestFailure)
            {
                [weakSelf cancle];
                if(weakSelf.completBlock)
                {
                    weakSelf.completBlock(weakSelf, NO);
                }
            }
            if(successCount == requestCount)
            {
                if(weakSelf.completBlock)
                {
                    weakSelf.completBlock(weakSelf, YES);
                }
            }
        }];
    }
}

- (void)cancle
{
    for (CTBaseRequest * request in _requestArray)
    {
        [[CTNetworkManager sharedManager] cancelRequest:request];
    }
    [self clearBlockCallback];
}

- (void)clearBlockCallback
{
    self.successBlock = nil;
    self.failureBlock = nil;
    self.completBlock = nil;
}

@end
