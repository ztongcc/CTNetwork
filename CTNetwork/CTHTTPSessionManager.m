//
//  CTHTTPSessionManager.m
//  CTNetwork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "CTHTTPSessionManager.h"


@implementation CTHTTPSessionManager

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    return self;
}

- (BOOL)isHttpQueueFinished:(NSArray *)httpUrlArray
{
    if(self.tasks.count == 0){
        return YES;
    }
    
    //add filter urlString.length==0
    NSMutableArray* urlArray = [NSMutableArray array];
    for (NSString* currentUrl in httpUrlArray) {
        if (currentUrl.length != 0) {
            [urlArray addObject:currentUrl];
        }
    }
    
    //urlArray is empty
    if(urlArray.count == 0){
        return YES;
    }
    
    for (NSURLSessionTask *task in self.tasks) {
        NSString *taskUrl = task.currentRequest.URL.absoluteString;
        for (NSString *baseUrl in urlArray) {
            if([taskUrl rangeOfString:baseUrl].location != NSNotFound){
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)cancelTaskWithUrl:(NSString *)url
{
    for (NSURLSessionTask *task in self.tasks) {
        NSString *taskUrl = task.currentRequest.URL.absoluteString;
        if([taskUrl rangeOfString:url].location != NSNotFound){
            [task cancel];
        }
    }
}
@end




