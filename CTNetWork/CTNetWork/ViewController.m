//
//  ViewController.m
//  CTNetWork
//
//  Created by ZhiTong on 16/5/29.
//  Copyright © 2016年 Excalibur-Tong. All rights reserved.
//

#import "ViewController.h"
#import "CTNetwork.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [[CTNetworkManager sharedManager] setNetworkConfiguration:[CTNetworkConfiguration configurationWithBaseURL:@"http://sunhouse.jingruigroup.com/"]];
//
//    CTBaseRequest * request = [[CTBaseRequest alloc] initWithInterface:@"Api/index/appdata.json"];
//    [request startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
//        NSLog(@" %@ %@ ", request, response);
//    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
//        NSLog(@"%@ ", error);
//    }];
//    
//    
//    CTBaseRequest * request1 = [[CTBaseRequest alloc] initWithInterface:@"api/food/lists.json"];
//    [request1 setValue:@"39.90660660044679" forParamKey:@"lat"];
//    [request1 setValue:@"116.3965963042809" forParamKey:@"lon"];
//    [request1 setValue:@"t1464703896" forParamKey:@"token"];
//    [request1 setValue:@"1" forParamKey:@"p"];
//    [request1 setValue:@"10" forParamKey:@"r"];
//    [request1 startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
//        NSLog(@"%@  %@ ", request, response);
//    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
//        NSLog(@"%@ ", error);
//    }];
    

}

- (IBAction)touchAction:(UIButton *)sender
{
    [self downloadRequestExample];
}


- (void)downloadRequestExample
{
    [[CTNetworkManager sharedManager] setNetworkConfiguration:[CTNetworkConfiguration configurationWithBaseURL:@"http://p3.v.iask.com/777/94/88271092_2.jpg"]];

    CTBaseRequest *request = [[CTBaseRequest alloc] initWithInterface:@""];
//    [request setValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
//    [request setValue:@"iPhone" forHTTPHeaderField:@"User-Agent"];
    request.fileName = @"test";
    [request startDownloadRequestWithProgress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"总: %lld  下载:%lld", downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
    } success:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
        NSLog(@"response %@", response);
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        NSLog(@"error = %@", error);

    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
