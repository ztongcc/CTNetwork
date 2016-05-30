//
//  CTNetworkCache.h
//  CTNetWork
//
//  Created by Admin on 16/5/30.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTNetworkCache : NSObject

+ (instancetype _Nonnull)sharedCache;

- (void)removeCacheForKey:(NSString * _Nonnull)key;

@end
