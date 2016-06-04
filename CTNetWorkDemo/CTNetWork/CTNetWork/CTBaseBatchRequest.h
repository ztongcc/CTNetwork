//
//  CTBatchBaseRequest.h
//  CTNetWork
//
//  Created by ZhiTong on 16/6/4.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CTBaseRequest;

@interface CTBaseBatchRequest : NSObject

/**
 *  init method
 *  @param requestArray 一组CTBaseRequest
 */
- (instancetype _Nonnull)initWithRequests:(NSArray * _Nullable)requestArray;

@property (nonatomic, readonly) NSArray * _Nonnull requestArray;

/**
 *  当某个请求失败后，是否还继续加载其它请求，默认YES
 */
@property (nonatomic, assign) BOOL continueLoadWhenRequestFailure;


/**
 *  开始请求数据
 *
 *  @param successBlock    请求成功
 *  @param failureBlock    请求失败
 *  @param completionBlock 请求完成
 */
- (void)startRequestSuccess:(void (^_Nullable)(CTBaseRequest * _Nonnull request, id _Nullable responseObj))successBlock
                    failure:(void (^_Nullable)(CTBaseRequest * _Nonnull request, NSError * _Nullable error))failureBlock
                 completion:(void (^_Nullable)(CTBaseBatchRequest * _Nonnull request, BOOL isFinish))completionBlock;

/**
 *  取消网络请求
 */
- (void)cancle;
@end
