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
    [CTNetworkManager setNetConfig:^(CTNetworkConfiguration * _Nonnull config) {
        config.baseURLString = @"http://www.weather.com.cn/";
        config.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
        config.requestSerializerType = CTRequestSerializerTypeHTTP;
        config.responseSerializerType = CTResponseSerializerTypeJSON;
        config.isDebug = YES;
    }];

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
   
    [CTNetworkManager startGET:^(CTBaseRequest * _Nonnull req) {
        req.interface = @"data/sk/101010100.html";
    } success:^(CTBaseRequest * _Nonnull request, id  _Nullable responseObj) {
        
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        
    }];
    
}

- (void)downloadRequestExample
{
    
     [CTNetworkManager startDownload:^(CTBaseRequest * _Nonnull req) {
        req.interface = @"http://dl.bizhi.sogou.com/images/2012/01/19/174522.jpg";
    } progress:^(NSProgress * _Nonnull progress) {
        NSLog(@"%lld === %lld", progress.totalUnitCount, progress.completedUnitCount);
    } complectHandler:^(CTBaseRequest * _Nonnull request, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"%@ %@", filePath, error);
    }];
}

- (void)uploadRequestExample
{
    
    UIImage *image = [UIImage imageNamed:@"test.png"];

    CTNetworkConfiguration * configuration = [CTNetworkConfiguration configurationWithBaseURL:@"https://casetree.cn/web/test/"];
    configuration.SSLPinningMode = AFSSLPinningModeNone;
    configuration.responseSerializerType = CTResponseSerializerTypeHTTP;
    configuration.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
    [[CTNetworkManager sharedManager] setNetworkConfiguration:configuration];
    
    CTBaseRequest * request = [[CTBaseRequest alloc] initWithInterface:@"upload.php"];
    request.parameterDict = @{@"test":@"hello"};
    [request setFormData:^(id <AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 1.0) name:@"fileUpload" fileName:@"IMG_20150617_105877.jpg" mimeType:@"application/octet-stream"];
    }];
    request.HTTPHeaderFieldDict = @{@"Content-Type":@"application/json; charset=UTF-8"};
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
    [CTNetworkManager startBatch:^NSArray<CTBaseRequest *> *(CTBaseBatchRequest * _Nonnull req) {
        CTBaseRequest * req1 = [CTBaseRequest requestWithInterface:@"data/sk/101010100.html"];
        CTBaseRequest * req2 = [CTBaseRequest requestWithInterface:@"data/sk/101010200.html"];
        return @[req1,req2];
    } success:^(CTBaseRequest * _Nonnull request, id  _Nullable responseObj) {
        
    } failure:^(CTBaseRequest * _Nonnull request, NSError * _Nullable error) {
        
    } completion:^(CTBaseBatchRequest * _Nonnull request, BOOL isFinish) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
