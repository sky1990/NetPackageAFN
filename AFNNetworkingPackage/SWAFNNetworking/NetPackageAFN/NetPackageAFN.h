//
//  NetPackageAFN.h
//  ArtBean
//
//  Created by 栾士伟 on 16/12/27.
//  Copyright © 2016年 Luanshiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Reachability.h"

@class UploadParam;

/**
 *  网络请求类型
 */
//typedef enum{
//    
//    NetWorkGET ,   /**< GET请求 */
//    NetWorkPOST = 1 /**< POST请求 */
//    
//}NetWorkType;

typedef NS_ENUM(NSUInteger,NetWorkType) {
    /**
     *  get请求
     */
    NetWorkGET = 0,
    /**
     *  post请求
     */
    NetWorkPOST
};


typedef void(^ProssBlock)(NSProgress *pross);
typedef void (^HttpSuccess)(id json);
typedef void (^HttpErro)(NSError *error);

typedef void (^DownloadProgressBlock)(int64_t bytesProgress,
                                     int64_t totalBytesProgress);


@interface NetPackageAFN : NSObject

+ (instancetype)shareHttpManager;

/*******************************************************************
 *  @param netWorkType  请求方式 GET 或 POST                         *
 *  @param signature    是否使用签名证书,是的话直接写入证书名字,否的话填nil *
 *  @param token       请求头部添加的token                            *
 *  @param urlstr      请求的URL接口                                 *
 *  @param parameters   请求参数                                     *
 *  @param showView HUD 展示view                                    *
 *  @param isFull 是否覆盖全屏                                        *
 *  @param sucess   请求成功时的返回值                                 *
 *  @param failure 请求失败时的返回值                                  *
 *******************************************************************/

- (void)netWorkType:(NetWorkType)netWorkType Signature:(NSString *)signature Token:(NSString *)token URLString:(NSString *)urlstr Parameters:(id)parameters toShowView:(UIView *)showView isFullScreen:(BOOL)isFull Success:(HttpSuccess)sucess Failure:(HttpErro)failure;

/********************************************
 *  上传图片                                  *
 *                                          *
 *  @param URLString   上传图片的网址字符串     *
 *  @param parameters  上传图片的参数          *
 *  @param uploadParams 上传图片的信息         *
 *  @param success     上传成功的回调          *
 *  @param failure     上传失败的回调          *
 ********************************************/

- (void)postUploadMultiFileWithString:(NSString *)URLString parameters:(id)parameters uploadParam:(NSArray <UploadParam *> *)uploadParams toShowView:(UIView *)showView isFullScreen:(BOOL)isFull success:(HttpSuccess)success failure:(HttpErro)failure;

/********************************************
 *  下载数据                                  *
 *                                          *
 *  @param URLString   下载数据的网址          *
 *  @param parameters  下载数据的参数          *
 *  @param success     下载成功的回调          *
 *  @param failure     下载失败的回调          *
 ********************************************/

- (void)downLoadWithURLString:(NSString *)URLString parameters:(id)parameters toShowView:(UIView *)showView isFullScreen:(BOOL)isFull progerss:(DownloadProgressBlock)progress success:(HttpSuccess)success failure:(HttpErro)failure;

@end
