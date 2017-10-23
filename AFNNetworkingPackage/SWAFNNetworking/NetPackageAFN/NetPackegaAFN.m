//
//  NetPackageAFN.m
//  ArtBean
//
//  Created by 栾士伟 on 16/12/27.
//  Copyright © 2016年 Luanshiwei. All rights reserved.
//

#import "NetPackageAFN.h"
#import "UploadParam.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "MBProgressHUD+ADD.h"

@interface NetPackageAFN()

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@property (nonatomic, copy)NSMutableArray *imageArray;

@end


@implementation NetPackageAFN

//+ (instancetype)shareHttpManager{
//    static dispatch_once_t onece = 0;
//    static NetPackageAFN *httpManager = nil;
//    dispatch_once(&onece, ^(void){
//        httpManager = [[self alloc] init];
//    });
//    return httpManager;
//}

static NetPackageAFN *_instance = nil;

+ (instancetype)shareHttpManager {
    
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (NSMutableArray *)imageArray {
    
    if (!_imageArray) {
        
        _imageArray = [[NSMutableArray array] init];
        
        for (int i = 1; i < 23; i ++ ) {
            [_imageArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading_%d",i]]];
        }
    }
    
    return _imageArray;
}

- (instancetype)init {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _instance = [super init];
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager startMonitoring];
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            switch (status) {
                    
                case AFNetworkReachabilityStatusUnknown:
                {
                    // 未知网络
                    NSLog(@"AFNetworkStatus-未知网络");
                }
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                {
                    // 无法联网
                    NSLog(@"AFNetworkStatus-无法联网");
                }
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                {
                    // WIFI
                    NSLog(@"AFNetworkStatus-当前在WIFI网络下");
                }
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                {
                    // 手机自带网络
                    NSLog(@"AFNetworkStatus-当前使用的是2G/3G/4G网络");
                }
            }
            
        }];
        
    });
    
    return _instance;
}

- (void)netWorkType:(NetWorkType)type Signature:(NSString *)signature Token:(NSString *)token URLString:(NSString *)urlstr Parameters:(id)parameters toShowView:(UIView *)showView isFullScreen:(BOOL)isFull Success:(HttpSuccess)sucess Failure:(HttpErro)failure {
    
    [MBProgressHUD showHUDWithImageArr:self.imageArray andShowView:showView isFullScreen:isFull];
    
    //开启证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //是否允许使用自签名证书
    signature == nil ? (void)(securityPolicy.allowInvalidCertificates = NO):(securityPolicy.allowInvalidCertificates = YES);
    
    //是否需要验证域名
    securityPolicy.validatesDomainName = NO;
    
    _manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:urlstr]];
//    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.securityPolicy = securityPolicy;
    [_manager.requestSerializer setValue:token forHTTPHeaderField:@"TOKENS"];
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"application/xml",@"text/xml",@"text/json",@"text/plain",@"text/javascript",@"text/html", nil];
    
    if (signature != nil) {
        
        __weak typeof(self) weakSelf = self;
        [_manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *_credential) {
            
            //获取服务器的 trust object
            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            
            //导入自签名证书
            NSString *cerPath = [[NSBundle mainBundle] pathForResource:signature ofType:@"cer"];
            NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
            
            if (!cerData) {
                
                NSLog(@"==== .cer file is nil ====");
                return 0;
            }
            
            NSArray *cerArray = @[cerData];
            weakSelf.manager.securityPolicy.pinnedCertificates = cerArray;
            SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)cerData);
            NSCAssert(caRef != nil, @"caRef is nil");
            
            NSArray *caArray = @[(__bridge id)(caRef)];
            NSCAssert(caArray != nil, @"caArray is nil");
            
            //将读取到的证书设置为serverTrust的根证书
            OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
            SecTrustSetAnchorCertificatesOnly(serverTrust, NO);
            NSCAssert(errSecSuccess == status, @"SectrustSetAnchorCertificates failed");
            
            //选择质询认证的处理方式
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            __autoreleasing NSURLCredential *credential = nil;
            
            //NSURLAuthenTicationMethodServerTrust质询认证方式
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                //基于客户端的安全策略来决定是否信任该服务器，不信任则不响应质询
                if ([weakSelf.manager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    
                    //创建质询证书
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    
                    //确认质询方式
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                        
                    } else {
                        
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                    
                } else {
                    
                    //取消挑战
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
                
            } else {
                
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            
            return disposition;
        }];
    }
    
    switch (type) {
        case NetWorkGET:
        {
            
            [_manager GET:urlstr parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [MBProgressHUD dissmissShowView:showView];
                
                if (sucess){
                    sucess(responseObject);
                }else{
                    
                    NSLog(@"链接异常或网络不存在");
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                failure(error);
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                    
                    sleep(1.0);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [MBProgressHUD dissmissShowView:showView];
                    });
                });
                
            }];
            
        }
            break;
        case NetWorkPOST:
        {
            
            [_manager POST:urlstr parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                [MBProgressHUD dissmissShowView:showView];
                
                if (sucess){
                    
                    sucess(responseObject);
                }else{
                    
                    NSLog(@"链接异常或网络不存在");
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                failure(error);
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                    
                    sleep(1.0);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [MBProgressHUD dissmissShowView:showView];
                    });
                });
                
            }];
            
        }
            break;
    }
    
}


#pragma mark - 上传文件

- (void)postUploadMultiFileWithString:(NSString *)URLString parameters:(id)parameters uploadParam:(NSArray <UploadParam *> *)uploadParams toShowView:(UIView *)showView isFullScreen:(BOOL)isFull success:(HttpSuccess)success failure:(HttpErro)failure {
    
    [MBProgressHUD showHUDWithImageArr:self.imageArray andShowView:showView isFullScreen:isFull];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (UploadParam *uploadParam in uploadParams) {
            
            [formData appendPartWithFileData:uploadParam.data name:uploadParam.name fileName:uploadParam.filename mimeType:uploadParam.mimeType];
            
        }
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        }
        [MBProgressHUD dissmissShowView:showView];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
        [MBProgressHUD dissmissShowView:showView];
        
    }];

}

#pragma mark - 下载文件

- (void)downLoadWithURLString:(NSString *)URLString parameters:(id)parameters toShowView:(UIView *)showView isFullScreen:(BOOL)isFull progerss:(DownloadProgressBlock)progress success:(HttpSuccess)success failure:(HttpErro)failure {
    
    [MBProgressHUD showHUDWithImageArr:self.imageArray andShowView:showView isFullScreen:isFull];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    NSURLSessionDownloadTask *downLoadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        NSLog(@"下载进度--%.1f",1.0 * downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
        
        //回到主线程刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return targetPath;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if (error == nil) {
            
            if (success) {
                //返回完整路径
                success([filePath path]);
            }
            
        }else {
            
            if (failure) {
                failure(error);
            }
        }
        
        [MBProgressHUD dissmissShowView:showView];
    }];
    
    [downLoadTask resume];
}

+ (BOOL) isHaveNetwork {
    
    Reachability *connect = [Reachability reachabilityForInternetConnection];
    
    if ([connect currentReachabilityStatus] == NotReachable) {
        
        return NO;
        
    }else {
        
        return YES;
    }
}

@end
