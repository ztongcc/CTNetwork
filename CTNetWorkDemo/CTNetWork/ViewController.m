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


}


- (IBAction)requestAction:(UIButton *)sender
{
    [self requestData];
}

- (IBAction)downloadAction:(UIButton *)sender
{
    [self downloadRequestExample];
}

- (IBAction)uploadAction:(id)sender
{
    [self uploadRequestExample];
}

- (IBAction)batchAction:(id)sender
{
    [self batchRequestExample];
}

- (void)requestData
{
    [[CTNetworkManager sharedManager] setNetworkConfiguration:[CTNetworkConfiguration configurationWithBaseURL:@"http://sunhouse.jingruigroup.com/"]];
    
    // 1
    //    CTBaseRequest * request = [[CTBaseRequest alloc] initWithInterface:@"Api/index/appdata.json"];
    //    [request startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
    //        NSLog(@" %@ %@ ", request, response);
    //    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
    //        NSLog(@"%@ ", error);
    //    }];
    
    // 2
    CTBaseRequest * request1 = [[CTBaseRequest alloc] initWithInterface:@"api/food/lists.json"];
    request1.cachePolicy = CTNetworkRequestCacheDataAndReadCacheLoadData;
    request1.cacheValidInterval = 10*60;
    [request1 setValue:@"39.90660660044679" forParamKey:@"lat"];
    [request1 setValue:@"116.3965963042809" forParamKey:@"lon"];
    [request1 setValue:@"t1464703896" forParamKey:@"token"];
    [request1 setValue:@"1" forParamKey:@"p"];
    [request1 setValue:@"10" forParamKey:@"r"];
    [request1 startRequestWithSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
        NSLog(@"请求成功 cache %@" ,request.isFromCache?@"YES":@"No");
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        NSLog(@"%@ ", error);
    }];
    
    [CTNetworkManager startGET:^(CTBaseRequest * _Nonnull req) {
        req.interface = @"dewdewde";
    } success:^(CTBaseRequest * _Nonnull request, id  _Nullable responseObj) {
        
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        
    }];
    
    [CTNetworkManager setNetConfig:^(CTNetworkConfiguration * _Nonnull config) {
        config.baseURLString = @"fefew";
    }];
}

- (void)downloadRequestExample
{
    [[CTNetworkManager sharedManager] setNetworkConfiguration:[CTNetworkConfiguration configurationWithBaseURL:@"http://p3.v.iask.com/777/94/88271092_2.jpg"]];
    CTBaseRequest *request = [[CTBaseRequest alloc] initWithInterface:@""];
    request.fileName = @"test";
    [request startDownloadRequestWithProgress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"总: %lld  下载:%lld", downloadProgress.totalUnitCount, downloadProgress.completedUnitCount);
    } success:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
        NSLog(@"response %@", response);
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        NSLog(@"error = %@", error);
    }];
}

- (void)uploadRequestExample
{
    
    UIImage *image = [UIImage imageNamed:@"test.png"];

    CTNetworkConfiguration * configuration = [CTNetworkConfiguration configurationWithBaseURL:@"https://casetree.cn/web/test/"];
    configuration.SSLPinningMode = AFSSLPinningModeNone;
    configuration.responseType = CTResponseSerializerTypeHTTP;
    configuration.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
    [[CTNetworkManager sharedManager] setNetworkConfiguration:configuration];
    
    CTBaseRequest * request = [[CTBaseRequest alloc] initWithInterface:@"upload.php"];
    [request setValue:@"hello" forParamKey:@"test"];
    [request setFormData:^(id <AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 1.0) name:@"fileUpload" fileName:@"IMG_20150617_105877.jpg" mimeType:@"application/octet-stream"];
    }];
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request startUploadRequestWithProgress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传进度 %lld  %lld", uploadProgress.totalUnitCount, uploadProgress.completedUnitCount);
    } success:^(CTBaseRequest * _Nonnull request, id  _Nullable response) {
        NSLog(@"response = %@", response);
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        NSLog(@"error = %@", error);
    }];
}

- (void)batchRequestExample
{
    [[CTNetworkManager sharedManager] setNetworkConfiguration:[CTNetworkConfiguration configurationWithBaseURL:@"http://sunhouse.jingruigroup.com/"]];
    
    // 1
    CTBaseRequest * request = [[CTBaseRequest alloc] initWithInterface:@"Api/index/appdata.json"];;

    // 2
    CTBaseRequest * request1 = [[CTBaseRequest alloc] initWithInterface:@"api/food/lists.json"];
    [request1 setValue:@"39.90660660044679" forParamKey:@"lat"];
    [request1 setValue:@"116.3965963042809" forParamKey:@"lon"];
    [request1 setValue:@"t1464703896" forParamKey:@"token"];
    [request1 setValue:@"1" forParamKey:@"p"];
    [request1 setValue:@"10" forParamKey:@"r"];

    
    CTBaseBatchRequest * batch = [[CTBaseBatchRequest alloc] initWithRequests:@[request,request1]];
    [batch startRequestSuccess:^(CTBaseRequest * _Nonnull request, id  _Nullable responseObj) {
        NSLog(@"%@ %@", request.interface, responseObj);
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        NSLog(@"%@ %@", request.interface, error);
    } completion:^(CTBaseBatchRequest * _Nonnull request, BOOL isFinish) {
        NSLog(@"finish %@", isFinish?@"YES":@"NO");
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
