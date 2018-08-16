//
//  TPDownLoadManager.m
//  DownLoadDemo
//
//  Created by Start on 2018/7/11.
//  Copyright © 2018年 Start. All rights reserved.
/*
 1.开始下载
 2.判断是否在下载列表中 在下载列表中则直接下载
 2.1 加入到等待下载列表中
 2.2 根据最大的并发任务数来进行判断 maxDownloadingTaskCount-downloadingList.count是否将等待下载列表加入到
     下载列表中
 2.3 开启并发下载(通过for 循环子线程进行下载)
 */

#import "TPDownLoadManager.h"
#import "TPDownLoadChecker.h"
#import "TPDownLoadSession.h"
#import "TPDownLoadModel.h"
#import "TPDownLoadCache.h"
#import "YYDownloadManager.h"
@interface TPDownLoadManager()
/**全部下载列表*/
@property(nonatomic,strong)NSMutableArray *allDownLoadList;
/**等待下载列表*/
@property(nonatomic,strong)NSMutableArray *waitDownLoadList;
/**下载中的列表*/
@property(nonatomic,strong)NSMutableArray *downloadingList;
/**暂停任务集合*/
@property(nonatomic,strong)NSMutableSet *pauseTaskStore;
/**并发下载任务数*/
@property(nonatomic,assign)NSUInteger maxDownloadingTaskCount;
/**下载状态*/
@property(nonatomic,assign)DownLoadState downLoadState;

@end
@implementation TPDownLoadManager
-(instancetype)init
{
    return [TPDownLoadManager shareManager];
}
-(instancetype)initPrivate
{
    self = [super init];
    if (self) {
        //初始化
        self.allDownLoadList = [NSMutableArray array];
        self.waitDownLoadList = [NSMutableArray array];
        self.downloadingList = [NSMutableArray array];
        self.pauseTaskStore = [NSMutableSet set];
        self.maxDownloadingTaskCount = 1;
    }
    return self;
}

+(instancetype)shareManager
{
    static TPDownLoadManager *downLoad = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downLoad = [[TPDownLoadManager alloc]initPrivate];
    });
    return downLoad;
}

-(void)startDownLoadTask:(TPDownLoadModel *)task
{
    [TPDownLoadChecker checkWithModel:task checkBlock:^(NSError *error) {
        if (error) {
            NSLog(@"error:%@",error);
        }else
        {
            //开始下载
            [self beginDownloadTask:task];
        }
    }];
}

-(void)beginDownloadTask:(TPDownLoadModel*)task
{
    //临时存储路径
    //NSString *tempFilePath = [TPDownLoadCache getFilePathWithModel:task];
    //1.模型中有多个文件要一起下载 使用for循环加group进行下载
    /*
     1.涉及到这个模块 1.多个文件组成下载包 计算进度 2.全部下载完成则表示下载完成
     */
    __block BOOL taskSuccess = YES;
    NSArray *validArray = @[task.videoUrl,task.voiceUrl];
//    dispatch_group_t dispatchGroup = dispatch_group_create();
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    for (NSString *taskUrl in validArray) {
//        NSInteger index = [validArray indexOfObject:taskUrl];
//        dispatch_group_enter(dispatchGroup);
//        dispatch_sync(queue, ^{
//            NSString *tempFilePath = [TPDownLoadCache getFilePathWithModel:task taskUrl:taskUrl];
//            NSString *taskId = [TPDownLoadCache getTaskIdWithUrlStr:taskUrl sceneId:task.senceId];
//            [[TPDownLoadSession session]downloadTaskWithDownloadUrl:[NSURL URLWithString:taskUrl] taskId:taskId downloadedBytes:0 tempFilePath:tempFilePath progress:^(CGFloat totoalMBExpectedToRead) {
//                self.progress = totoalMBExpectedToRead;
//                NSLog(@"self.progress: %f",self.progress);
//            } success:^{
//                NSLog(@"%@ \n支线任务%d下载成功",taskUrl,(int)index);
//                dispatch_group_leave(dispatchGroup);
//            } fail:^(NSError *error) {
//                 NSLog(@"%@ \n %@ \n支线任务%d下载失败",taskUrl,error,(int)index);
//                taskSuccess = NO;
//                dispatch_group_leave(dispatchGroup);
//            } model:task];
//        });
    
        for (NSString *taskUrl in validArray) {
            
//            dispatch_group_enter(dispatchGroup);
//            dispatch_sync(queue, ^{
                NSString *tempFilePath = [TPDownLoadCache getFilePathWithModel:task taskUrl:taskUrl];
                //唯一标识符
                NSString *taskId = [TPDownLoadCache getTaskIdWithUrlStr:taskUrl sceneId:task.senceId];
            
            NSString *dstUrl = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
            NSLog(@"\n\n%@\n\n",dstUrl);
            dstUrl = [dstUrl stringByAppendingPathComponent:taskUrl.lastPathComponent];
            __weak typeof(self) weakSelf = self;
            NSURLSessionDownloadTask *task = [YYDownloadManager downloadTaskWithUrl:taskUrl destinationUrl:dstUrl progress:^(NSProgress *progress) {
                NSLog(@"%lld %lld %f",progress.totalUnitCount, progress.completedUnitCount, progress.fractionCompleted);
                dispatch_async(dispatch_get_main_queue(), ^{
//                    weakSelf.progressView.progress = progress.fractionCompleted;
                });
            } complete:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                NSLog(@"%@",filePath);
            }];
            [task resume];
            [self.allDownLoadList addObject:task];
//               NSURLSessionDownloadTask *downlodTask =  [[TPDownLoadSession session] downLoadTaskWithDownloadUrl:[NSURL URLWithString:taskUrl] taskId:taskId filePath:tempFilePath progress:^(NSProgress *progress) {
//                    NSLog(@"%f",(1.0 * (progress.completedUnitCount)) /progress.totalUnitCount);
//                } complete:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
////                     dispatch_group_leave(dispatchGroup);
//                    if (error) {
//                        NSLog(@"error: %@",error);
//                    }
//                }];
//                NSDictionary *operationDic = @{@"taskID":taskId,@"operation":downlodTask};
//                [self.allDownLoadList addObject:operationDic];
//                [downlodTask resume];
//            });
    
    }
//    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
//        if (taskSuccess) {
//            NSLog(@"下载成功");
//        }else
//        {
//            NSLog(@"下载失败");
//        }
//    });

}

-(void)pauseDownLoadTask:(TPDownLoadModel *)task
{
    //将模型中的的下载遍历暂停
//    NSArray *taskUrl = @[task.videoUrl,task.voiceUrl];
//    for (NSString *taskurl in taskUrl) {
//       NSString *taskId = [TPDownLoadCache getTaskIdWithUrlStr:taskurl sceneId:task.senceId];
//       [[TPDownLoadSession session] suspendOperationTaskId:taskId resume:NO];
//    }
    for (NSURLSessionDownloadTask *task in self.allDownLoadList) {
        [task suspend];
    }
    
}
-(void) resumeDownLoadTask:(TPDownLoadModel *)task
{
    NSArray *taskUrl = @[task.videoUrl,task.voiceUrl];
    for (NSString *taskurl in taskUrl) {
        NSString *taskId = [TPDownLoadCache getTaskIdWithUrlStr:taskurl sceneId:task.senceId];
        [[TPDownLoadSession session] suspendOperationTaskId:taskId resume:YES];
    }
}



@end
