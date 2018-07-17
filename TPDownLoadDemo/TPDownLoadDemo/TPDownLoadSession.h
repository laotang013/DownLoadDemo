//
//  TPDownLoadSession.h
//  DownLoadDemo
//
//  Created by Start on 2018/7/12.
//  Copyright © 2018年 Start. All rights reserved.
/*
 1.下载/恢复下载(断点续传)
    判断下载任务是否存在
    判断临时文件夹是否已下载部分文件
 2.暂停
    移除任务
 3.取消
    移除任务
    取消临时文件夹该文件
 */

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import "TPDownLoadModel.h"
//#import <AFURLSessionManager.h>
typedef void(^MISDownloadManagerCompletion)(NSURLResponse *response, NSURL *filePath, NSError *error);
typedef void (^Progress)(CGFloat totoalMBExpectedToRead);
typedef void (^Success)(void);
typedef void (^Fail)(NSError *error);
@interface TPDownLoadSession : NSObject
+(instancetype)session;
/**下载*/
-(void)downloadTaskWithDownloadUrl:(NSURL *)downloadUrl
                            taskId:(NSString *)taskId
                   downloadedBytes:(long long)downloadedBytes
                      tempFilePath:(NSString *)tempFilePath
                          progress:(Progress)progress
                           success:(Success)success
                              fail:(Fail)fail
                             model:(TPDownLoadModel *)model;



-(NSURLSessionDownloadTask *)downLoadTaskWithDownloadUrl:(NSURL *)downloadUrl
                            taskId:(NSString *)taskId
                          filePath:(NSString *)filePath
                          progress:(void (^)(NSProgress *))progressHandler
                          complete:(MISDownloadManagerCompletion)completionHandler;

/**删除单个下载*/
-(void)removeOperationWithDownloadUrlStr:(NSString *)downloadUrlStr;
/**删除全部下载*/
-(void)removeAllOperation;


-(void)removeOperationWithTaskId:(NSString *)taskID isCancelOperation:(BOOL)isCancel;
-(void)suspendOperationTaskId:(NSString *)taskID resume:(BOOL)resume;
@end
