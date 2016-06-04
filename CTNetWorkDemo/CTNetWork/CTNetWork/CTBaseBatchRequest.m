//
//  CTBatchBaseRequest.m
//  CTNetWork
//
//  Created by ZhiTong on 16/6/4.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTBaseBatchRequest.h"
#import "CTBaseRequest.h"   

@interface CTBaseBatchRequest ()

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
    __block NSInteger successCount = 0;
    
    for (CTBaseRequest * request in self.requestArray) {
        
        [request startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
            successCount++;
            if(successBlock) {
                successBlock(request, response);
            }
            if(successCount == requestCount) {
                if(completionBlock) {
                    completionBlock(self, YES);
                }
            }
        } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
            successCount++;
            if(failureBlock) {
                failureBlock(request, error);
            }
            if(!self.continueLoadWhenRequestFailure) {
                if(completionBlock) {
                    completionBlock(self, NO);
                }
            }
            if(successCount == requestCount) {
                if(completionBlock) {
                    completionBlock(self, YES);
                }
            }
        }];
    }
}

- (void)cancle
{
    for (CTBaseRequest * request in _requestArray) {
        [request.sessionTask cancel];
    }
}

@end
