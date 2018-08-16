//
//  HETDownloadUrlSession.h
//  HETDownLoad
//
//  Created by Start on 2018/7/30.
//  Copyright © 2018年 Start. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void (^Progress)(long long downloadedBytes,long long totalMBRead,long long totalMBExpectedToRead);
typedef void (^Success)();
typedef void (^Failure)(NSError *error);

@interface HETDownloadUrlSession : NSObject

+(instancetype)session;

-(void)downloadTaskWithUrl:(NSString *)url
                    taskId:(NSString *)taskId
                  filePath:(NSString *)downloadFilePath
                  progress:(Progress)progress
                   success:(Success)successBlock
                      fail:(Failure)failBlock;

- (void)removeOperationWithTaskId:(NSString *)taskID isCancelOperation:(BOOL)isCancel;
//暂停单个下载任务
- (void)removeOperationWithDownloadUrlStr:(NSString *)downloadUrlStr;
//暂停所有
- (void)removeAllOperation;
@end
