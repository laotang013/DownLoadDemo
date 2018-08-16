//
//  TPDownLoadCache.h
//  DownLoadDemo
//
//  Created by Start on 2018/7/12.
//  Copyright © 2018年 Start. All rights reserved.
/*
 1.获取文件路径 一个模型一个文件地址
 */

#import <Foundation/Foundation.h>
#import "TPDownLoadModel.h"
@interface TPDownLoadCache : NSObject
/**获取路径*/
+(NSString *)getFilePathWithModel:(TPDownLoadModel *)downLoadModel taskUrl:(NSString *)taskUrl;
+(NSString *)getFileTempWithModel:(TPDownLoadModel *)downLoadModel;

//生成路径 通过一个TaskID 和一个taskUrl MD5加密 来生成唯一路径

//移动文件（从临时文件夹移到正式文件夹）
+ (BOOL)moveTempFileWithStepModel:(TPDownLoadModel *)downLoadModel tempFile:(NSString *)tempFile taskUrl:(NSString *)taskUrl;
//获取唯一的taskID
+ (NSString *)getTaskIdWithUrlStr:(NSString *)urlString
                          sceneId:(NSNumber *)sceneId;
//获取下载文件的大小
+(long  long )fileSizeInFilePathWithModel:(TPDownLoadModel *)model taskURL:(NSString *)taskurl;


//获取断点续传下载的临时文件地址
+(NSString *)getTempFileNameWithDownloadTask:(NSURLSessionDownloadTask *)downLoadTask;
//捆绑tmp文件与taskId进行绑定
+(void)saveTempFileName:(NSString *)tmpfile taskId:(NSString *)taskId;
//获取resumeData文件
+(NSData *)getResumeDataWithTaskId:(NSString *)taskId;
+(NSString *)saveResumeData:(NSData *)resumeData taskId:(NSString *)taskId;
/**删除恢复文件信息*/
+(void)removeResumeInfoWithTaskId:(NSString *)taskId;
//删除tmp文件
+(void)removeTempFileWithTask:(NSString *)taskId;
@end
