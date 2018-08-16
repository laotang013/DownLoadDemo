//
//  HETDownloadUrlSession.m
//  HETDownLoad
//
//  Created by Start on 2018/7/30.
//  Copyright © 2018年 Start. All rights reserved.

#import "HETDownloadUrlSession.h"
#import "NSURLSession+CorrectedResumeData.h"
@interface HETDownloadUrlSession()<NSURLSessionDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic,strong) NSMutableArray *operationsArray;//正在下载任务操作
@property (nonatomic, assign) BOOL allowsCellularAccess; // 是否允许蜂窝网络下载
@property (nonatomic,strong) NSMutableDictionary *downloadResumeDataDict; //下载历史记录 taskId -> resumeData关联起来
@property (nonatomic, strong) NSURLSession *session;// NSURLSession
@property(nonatomic,copy)NSString *resumeDataFilePath;//resumeData存储地址
@property(nonatomic,strong)NSString *filePath;
/** 文件管理*/
@property (nonatomic,strong) NSFileManager *fileMgr;
@property(nonatomic,strong)NSString *downloadFilePath;
@property(nonatomic,copy) Progress downloadSessionProgress;
@property(nonatomic,copy)Success sessionSuccessBlock;
@property(nonatomic,copy)Failure failBlock;
@end
@implementation HETDownloadUrlSession
+(instancetype)session
{
    static HETDownloadUrlSession *_shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareManager =  [[HETDownloadUrlSession alloc] initPrivate];
    });
    return _shareManager;
}
-(instancetype)initPrivate{
    self = [super init];
    if (self) {
        self.operationsArray = [NSMutableArray array];
        //单线程代理队列
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        self.fileMgr = [NSFileManager defaultManager];
        //本地文件
        self.downloadResumeDataDict = [NSMutableDictionary dictionary];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
        self.resumeDataFilePath = [path stringByAppendingPathComponent:@"resumeDataFilePath.plist"];
        //判断是否有本地文件没有则创建一个
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.resumeDataFilePath]) {
             self.downloadResumeDataDict =[NSMutableDictionary dictionaryWithContentsOfFile:self.resumeDataFilePath];
        }else{
             self.downloadResumeDataDict =[NSMutableDictionary dictionary];
            [ self.downloadResumeDataDict writeToFile:self.resumeDataFilePath atomically:YES];
        }
        
        // 后台下载标识
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"HETDownloadBackgroundSessionIdentifier"];
        // 允许蜂窝网络下载，默认为YES，这里开启，我们添加了一个变量去控制用户切换选择
        configuration.allowsCellularAccess = YES;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
        // 是否允许蜂窝网络下载改变通知
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllowsCellularAccessChange:) name:@"HWDownloadAllowsCellularAccessChangeNotification" object:nil];
        // 网路改变通知
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkingReachabilityDidChange:) name:@"HWDownloadAllowsCellularAccessChangeNotification" object:nil];
        
    }
    return self;
}
#pragma mark - 开始下载
-(void)downloadTaskWithUrl:(NSString *)url
                    taskId:(NSString *)taskId
                  filePath:(NSString *)downloadFilePath
                  progress:(Progress)progress
                   success:(Success)successBlock
                      fail:(Failure)failBlock
{
    self.downloadFilePath  = downloadFilePath;
    //判断是否存在文件
    if ([self.fileMgr fileExistsAtPath:downloadFilePath]) {
        successBlock();
        return;
    }
    //1.判断是否有resumeData 有则断点续传 2.没有则新建下载
    NSURLSessionDownloadTask *downloadTask = nil;
    NSData *resumeData = self.downloadResumeDataDict[taskId];
    self.downloadSessionProgress = progress;
    self.sessionSuccessBlock = successBlock;
    self.failBlock = failBlock;
    if (resumeData.length>0) {
        NSLog(@"2.恢复任务");
        CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (version >= 10.0 && version < 10.2) {
            downloadTask = [_session downloadTaskWithCorrectResumeData:resumeData];
        }else {
            downloadTask = [_session downloadTaskWithResumeData:resumeData];
        }
    }else
    {
        NSLog(@"1.创建新任务");
        downloadTask = [_session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
    //添加描述标签
    downloadTask.taskDescription = taskId;
    //如果已经存在operation就取消本次任务
    for (NSDictionary *operationDic in self.operationsArray) {
        if ([operationDic[@"taskID"] isEqualToString:taskId] && ![operationDic[@"operation"] isPaused]) {
            [downloadTask cancel];
            return;
        }
    }
    //不存在相同下载任务，存储下载任务 taskId -> downloadTask
    NSDictionary *operationDic = @{@"taskId":taskId,@"operation":downloadTask};
    [self.operationsArray addObject:operationDic];
    //启动(继续下载)
    [downloadTask resume];
}
#pragma mark - 取消下载
- (void)removeOperationWithTaskId:(NSString *)taskID isCancelOperation:(BOOL)isCancel{
    if(!self.operationsArray || self.operationsArray.count == 0){
        return;
    }
    for (NSDictionary *operationDic in self.operationsArray) {
        if (taskID) {
            if (operationDic[@"taskId"] && [operationDic[@"taskId"] isEqualToString:taskID]) {
                if (isCancel) {
                    // 获取NSURLSessionDownloadTask
                    NSURLSessionDownloadTask *downloadTask = [operationDic valueForKey:@"operation"];
                    //取消任务
                    [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                        //存储resumeData
                        [self downloadSaveResumeData:taskID resumeData:resumeData];
                    }];
                }
                //移除字典存储的对象
                [self.operationsArray removeObject:operationDic];
                break;
            }
        }else{
            if (operationDic[@"operation"]) {
                NSURLSessionDownloadTask *operation = operationDic[@"operation"];
                [operation cancel];
            }
        }
    }
}
- (void)removeOperationWithDownloadUrlStr:(NSString *)downloadUrlStr{
    [self removeOperationWithTaskId:downloadUrlStr isCancelOperation:NO];
}
- (void)removeAllOperation{
    [self removeOperationWithTaskId:nil isCancelOperation:YES];
    [self.operationsArray removeAllObjects];
}
#pragma mark - 存储resumeData
-(void)downloadSaveResumeData:(NSString *)taskId resumeData:(NSData *)resumeData
{
    if (!resumeData) {
        NSString *emptyData = [NSString stringWithFormat:@""];
        [self.downloadResumeDataDict setObject:emptyData forKey:taskId];
    }else{
        [self.downloadResumeDataDict setObject:resumeData forKey:taskId];
    }
    [self.downloadResumeDataDict writeToFile:self.resumeDataFilePath atomically:NO];
}
#pragma mark - NSURLSessionDownloadDelegate
//接收服务器返回的数据，会调用多次
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"3.接收数据");
   //获取到下载任务 通过downloadTask.taskDescription获取到下载任务。
    if (self.downloadSessionProgress) {
        self.downloadSessionProgress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}
// 下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    //下载地址
    NSString *downloadFilePath = [self.filePath stringByAppendingPathComponent:downloadTask.taskDescription];
    if ([self.fileMgr fileExistsAtPath:downloadFilePath]) {
        return;
    }
    NSLog(@"downLoadFilePath: %@",self.downloadFilePath);
    //获取到文件路径 进行移动文件
    NSLog(@"4.下载完成移动文件");
    NSError *error = nil;
//     [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:downloadFilePath error:&error];
    
    if ([self.fileMgr moveItemAtPath:[location path] toPath:downloadFilePath error:&error]) {
        if (error) {
            NSLog(@"下载完成，移动文件发生错误: %@",error);
            return;
        }
        
        if (self.sessionSuccessBlock) {
            ntThread]);
            self.sessionSuccessBlock();
        }
    }
}
#pragma mark - NSURLSessionTaskDelegate
//请求完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSString *downloadFilePath = [self.filePath stringByAppendingPathComponent:task.taskDescription];
    // 调用cancel方法直接返回，在相应操作是直接进行处理
    if (error && [error.localizedDescription isEqualToString:@"cancelled"]) return;
    // 下载时，进程杀死，重新启动，回调错误
    if (error && [error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey]) {
        #pragma mark - **************** 更新为等待状态
        self.downloadResumeDataDict[task.taskDescription] = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        return;
    }
    // 更新下载数据、任务状态
    if (error) {
        self.downloadResumeDataDict[task.taskDescription]= [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        #pragma mark - **************** 更新为错误状态
        if (self.failBlock) {
            self.failBlock(error);
        }
    }
    [self removeOperationWithTaskId:task.taskDescription isCancelOperation:NO];
   
    NSLog(@"\n    文件：%@，下载完成 \n    本地路径：%@ \n    错误：%@ \n",  task.taskDescription,self.filePath, error);
}
#pragma mark  - NSURLSessionDelegate
// 应用处于后台，所有下载任务完成及NSURLSession协议调用之后调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler) {
        void (^completionHandler)(void) = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        // 执行block，系统后台生成快照，释放阻止应用挂起的断言
        completionHandler();
    }
}
#pragma mark - 文件位置
//文件保存地址
-(NSString *)filePath{
    if (!_filePath) {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        //下载完成文件保存地址
        NSString *scenesDir = [NSString stringWithFormat:@"%@/HETSleepScene",docPath];
        BOOL isDir;
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        //缓存文件夹路径是否存在
        BOOL existed = [fileMgr fileExistsAtPath:scenesDir isDirectory:&isDir];
        //如果不是文件夹或不存在 则创建
        if (!(isDir && existed)) {
            [fileMgr createDirectoryAtPath:scenesDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _filePath = scenesDir;
    }
    return _filePath;
}
- (void)dealloc
{
    NSLog(@"dealloc");
    [_session invalidateAndCancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
