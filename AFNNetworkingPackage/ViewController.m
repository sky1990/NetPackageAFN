//
//  ViewController.m
//  AFNNetworkingPackage
//
//  Created by 栾士伟 on 2017/10/23.
//  Copyright © 2017年 Luanshiwei. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD+ADD.h"
#import "NetPackageAFN.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    [self loadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadData {
    
    //生成接口地址
    NSString *UrlStr = @"";
    
    //参数
    NSDictionary *parameters = [[NSDictionary alloc] init];
    
    NetPackageAFN *afn = [NetPackageAFN shareHttpManager];
    
    [afn netWorkType:NetWorkPOST Signature:nil Token:nil URLString:UrlStr Parameters:parameters toShowView:self.view.window isFullScreen:YES Success:^(id json) {
        NSLog(@"json=%@",json);
    } Failure:^(NSError *error) {
        NSLog(@"%@",error);
    }];
    
}

@end
