//
//  TPDownLoadSession.m
//  DownLoadDemo
//
//  Created by Start on 2018/7/12.
//  Copyright © 2018年 Start. All rights reserved.
/*
 1.断点续传  1.记录之前下载的字节数
 */

#import "TPDownLoadSession.h"
#import "TPDownLoadCache.h"
#import "AFNetworking.h"
@interface TPDownLoadSession()
/** 正在下载任务操作*/
@property (nonatomic,strong) NSMutableArray *operationsArray;
//@property(nonatomic,strong)AFURLSessionManager *manager;
/**已下载了多少*/
@property(nonatomic,assign)__block CGFloat  hasDownloadSize;
/**<#name#>*/
@property(nonatomic,assign)__block CGFloat  tempDownloadSize;
@end
@implementation TPDownLoadSession
+(instancetype)session
{
    static TPDownLoadSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [[TPDownLoadSession alloc]initPrivate];
    });
    return session;
}
-(instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.operationsArray = [NSMutableArray array];
//        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//        self.manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:configuration];
        //这个可以写也可以不写
//        AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
//        sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/javascript",@"text/html",@"video/mpeg",@"video/mp4",@"audio/mp3",nil];
        self.hasDownloadSize = 0.0;
        self.tempDownloadSize = 0.0;
    }
    return self;
}
//-(void)downloadTaskWithDownloadUrl:(NSURL *)downloadUrl
//                            taskId:(NSString *)taskId
//                   downloadedBytes:(long long)downloadedBytes
//                      tempFilePath:(NSString *)tempFilePath
//                          progress:(Progress)progress
//                           success:(Success)success
//                              fail:(Fail)fail
//                             model:(TPDownLoadModel *)model
//
//{
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadUrl];
//    if (downloadedBytes>0) {
//        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-",downloadedBytes];
//        [request setValue:requestRange forHTTPHeaderField:@"Range"];
//    }
//    //不使用缓存，避免断点续传出现问题
//    [[NSURLCache sharedURLCache]removeCachedResponseForRequest:request];

    
//    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
//        //计算下载进度
//        [TPDownLoadCache fileSizeInFilePathWithModel:model taskURL:downloadUrl.absoluteString];
//        if (downloadProgress.completedUnitCount == downloadProgress.totalUnitCount) {
//            self.hasDownloadSize+= downloadProgress.completedUnitCount;
//        }
//        //打印下下载进度
//        NSLog(@"%lf",(1.0 * (self.hasDownloadSize+ downloadProgress.completedUnitCount)) /(1774298+2663577));
//        long long downSize = (1.0 * (self.hasDownloadSize+ downloadProgress.completedUnitCount)) /(1774298+2663577);
////        !progress?:progress(downSize);
//
//    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//        return [NSURL fileURLWithPath:tempFilePath];
//    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//        //设置下载完成的操作 filePath就是你下载文件的位置
//        //判断如果文件夹有文件了则不下载。
//        if (error||error.code!=-999) {
//            fail(error);
//            NSLog(@"error:%@",error);
//            return;
//        }
//        NSLog(@"filePath: %@",filePath.absoluteString);
//        success();
//
//    } ];
//    //1.判断如果已经存在下载则取消本次任务
//    for (NSDictionary *operationDic in self.operationsArray) {
//        if ([operationDic[@"taskID"] isEqualToString:taskId]&&[operationDic[@"operation"] state] != NSURLSessionTaskStateSuspended) {
//            //取消当前的任务，你也可以向处于suspend状态的任务发送cancel消息，任务如果被取消便不能再恢复到之前的状态
//            [downloadTask cancel];
//            return;
//        }
//    }
//    //2.不存在相同下载任务，存储下载任务
//    NSDictionary *operationDic = @{@"taskID":taskId,@"operation":downloadTask};
//    [self.operationsArray addObject:operationDic];
//
//    [downloadTask resume];
//}

-(NSURLSessionDownloadTask *)downLoadTaskWithDownloadUrl:(NSURL *)downloadUrl
                            taskId:(NSString *)taskId
                          filePath:(NSString *)filePath
                          progress:(void (^)(NSProgress *))progressHandler
                          complete:(MISDownloadManagerCompletion)completionHandler
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadUrl];
    //不使用缓存，避免断点续传出现问题
    [[NSURLCache sharedURLCache]removeCachedResponseForRequest:request];
    //目标path
    NSURL *(^destination)(NSURL *, NSURLResponse *) =
    ^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:filePath];
    };
    MISDownloadManagerCompletion completeBlock =
    ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"%@",error);
        // 任务完成或暂停下载
        if (!error || error.code == -999) {
            // 调用cancle的时候，任务也会结束，并返回-999错误，此时由于系统已返回resumeData，不另行处理了
            if (!error) {
                // 任务完成
                [TPDownLoadCache removeResumeInfoWithTaskId:taskId];
                [TPDownLoadCache removeTempFileWithTask:taskId];
            }
            
            if (completionHandler) {
                completionHandler(response,filePath,error);
            }
        } else  {
            // 部分网络出错，会返回resumeData
            NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            [TPDownLoadCache saveResumeData:resumeData taskId:taskId];
            
            if (completionHandler) {
                completionHandler(response,filePath,error);
            }
        }
    };
    
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    /*
     1. 下载url
     2. 临时文件：即未完成的文件，断点下载开始后，需要继续将剩余文件流导入到临时文件尾部
     3. 文件开始位置：即临时文件大小，用于告诉服务器从哪块开始继续下载
     
     
     1.创建断点下载任务时，根据resumeDataMap找到resumeData,
     2.若没有发现resumeData,则根据tempFileMap的信息找到临时文件，获取其大小
       ，然后尝试手动建一个resumeData，并加载到内存中
     3.若没有发现临时文件,则不创建resumeData，建立普通下载任务。
     */
    
   
    //获取resumeData 计算resumeData  实现断点续传
    NSData *resumeData = [TPDownLoadCache getResumeDataWithTaskId:taskId];
    NSURLSessionDownloadTask *downloadTask = nil;
    if (resumeData) {
       
        downloadTask =
        [manager downloadTaskWithResumeData:resumeData
                                   progress:progressHandler
                                destination:destination
                          completionHandler:completeBlock];

        [TPDownLoadCache removeResumeInfoWithTaskId:taskId];
       
//        [TPDownLoadCache removeTempFileWithTask:taskId];
    }else
    {
        NSLog(@"新建下载任务");
       
        //首次进来的时候则普通下载任务
        downloadTask = [manager downloadTaskWithRequest:request
                                                progress:progressHandler
                                             destination:destination
                                       completionHandler:completeBlock];
        //获取临时文件并进行保存 临时文件与taskID通过一个本地字典进行捆绑
        NSString *tempFileName = [TPDownLoadCache getTempFileNameWithDownloadTask:downloadTask];
        [TPDownLoadCache saveTempFileName:tempFileName taskId:taskId];
    }
    

    //2.不存在相同下载任务，存储下载任务
    NSDictionary *operationDic = @{@"taskID":taskId,@"operation":downloadTask};
    [self.operationsArray addObject:operationDic];
    return downloadTask;
}





/**删除单个下载*/
-(void)removeOperationWithDownloadUrlStr:(NSString *)downloadUrlStr
{
    [self removeOperationWithTaskId:downloadUrlStr isCancelOperation:NO];
}
/**删除全部下载*/
-(void)removeAllOperation
{
    [self removeOperationWithTaskId:nil isCancelOperation:YES];
    [self.operationsArray removeAllObjects];
}
//增加条件判断
-(void)removeOperationWithTaskId:(NSString *)taskID isCancelOperation:(BOOL)isCancel
{
    //1.如果数组为空则直接返回
    if (!self.operationsArray||self.operationsArray.count==0) {
        return;
    }
    //2 判断是否取消 取消则直接取消 不是则删除
    for (NSDictionary *operationDic in self.operationsArray) {
        if (taskID) {
            if (operationDic[@"taskID"]&&[operationDic[@"taskID"] isEqualToString:taskID]) {
                if (isCancel) {
                    NSURLSessionDownloadTask *operation = operationDic[@"operation"];
                    [operation cancel];
                }
                
                [self.operationsArray removeObject:operationDic];
                break;
            }
        }else
        {
            if (operationDic[@"operation"]) {
                NSURLSessionDownloadTask *operation = operationDic[@"operation"];
                [operation cancel];
            }
        }
    }
}




-(void)suspendOperationTaskId:(NSString *)taskID resume:(BOOL)resume
{
    //1.如果数组为空则直接返回
    if (!self.operationsArray||self.operationsArray.count==0) {
        return;
    }
    //2 判断是否取消 取消则直接取消 不是则删除
    for (NSDictionary *operationDic in self.operationsArray) {
        if (taskID) {
            if (operationDic[@"taskID"]&&[operationDic[@"taskID"] isEqualToString:taskID]) {
                if (resume) {
                    NSURLSessionDownloadTask *operation = operationDic[@"operation"];
                    
                    [operation cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                        [TPDownLoadCache saveResumeData:resumeData taskId:taskID];
                    }];
                }else
                {
                    NSURLSessionDownloadTask *operation = operationDic[@"operation"];
                    [operation suspend];
                }
                break;
            }
        }else
        {
            if (operationDic[@"operation"]) {
                NSURLSessionDownloadTask *operation = operationDic[@"operation"];
                [operation cancel];
            }
        }
    }
}


@end
