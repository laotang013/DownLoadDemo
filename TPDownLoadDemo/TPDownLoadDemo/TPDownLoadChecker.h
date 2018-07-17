//
//  TPDownLoadChecker.h
//  DownLoadDemo
//
//  Created by Start on 2018/7/11.
//  Copyright © 2018年 Start. All rights reserved.
/*
 容错处理
 1.版本检验
    检查版本号，版本号升级下载
 2. 文件校验
    本地已存在,不下载
 3. 下载地址校验
    前缀http
    后缀zip
 4. 网络环境校验
    非wifi环境下提示用户
 5. 内存不足提示
 */

#import <Foundation/Foundation.h>
#import "TPDownLoadModel.h"
/**错误提示*/
typedef void (^CheckBlock)(NSError *error);
typedef NS_ENUM(NSInteger,DownLoadCheckerErrorCoder)
{
    DownLoadCheckerErrorCoderUrlErrorCode = 1000,//连接错误
    DownLoadCheckerErrorCoderVersionErrorCode,//版本错误
    DownLoadCheckerErrorCoderOldVersionErrorCode,//版本错误
    DownLoadCheckerErrorCoderMemoryErrorCode,//内存不足
    DownLoadCheckerErrorCoderExistErrorCode, //已经存在
    DownLoadCheckerErrorCoderNoNetErrorCode, //无网络
    DownLoadCheckerErrorCoderNoWIFIErrorCode, //非wifi
};
@interface TPDownLoadChecker : NSObject
+(void)checkWithModel:(TPDownLoadModel *)model checkBlock:(CheckBlock)checkBlock;
@end
