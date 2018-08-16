//
//  TPDownLoadCache.m
//  DownLoadDemo
//
//  Created by Start on 2018/7/12.
//  Copyright © 2018年 Start. All rights reserved.
//

#import <SAMCategories/NSString+SAMAdditions.h>
#import "TPDownLoadCache.h"
#import <objc/runtime.h>
#define FileManager    [NSFileManager defaultManager]
#define FileStrAppendPath(A,B) [(A) stringByAppendingPathComponent:(B)]
@implementation TPDownLoadCache
+(NSString *)getFilePathWithModel:(TPDownLoadModel *)downLoadModel taskUrl:(NSString *)taskUrl
{
    //1.判断是否有该路径 如果没有则创建一个
    NSURL *url = [NSURL URLWithString:taskUrl];
    if (!url) {
        return nil;
    }
    NSString *fileName = [[NSString stringWithFormat:@"%@",downLoadModel.senceId] stringByAppendingPathExtension:taskUrl.pathExtension];
    NSString *fileFolderPath = [FilePath() stringByAppendingPathComponent:fileName];
    return fileFolderPath;
}
+(NSString *)getFileTempWithModel:(TPDownLoadModel *)downLoadModel
{
    //1.判断是否有该路径 如果没有则创建一个
    NSURL *url = [NSURL URLWithString:downLoadModel.videoUrl];
    if (!url) {
        return nil;
    }
    NSString *fileName = [@"downLoadModel" stringByAppendingPathExtension:downLoadModel.videoUrl.pathExtension];
    NSString *fileTempFolderPath = [FileTempPath() stringByAppendingPathComponent:fileName];
    return fileTempFolderPath;
}
//移动文件（从临时文件夹移到正式文件夹）
+ (BOOL)moveTempFileWithStepModel:(TPDownLoadModel *)downLoadModel tempFile:(NSString *)tempFile taskUrl:(NSString *)taskUrl
{
//    NSString *tempFile = [self getFileTempWithModel:downLoadModel];
    NSString *filePath = [self getFilePathWithModel:downLoadModel taskUrl:taskUrl];
    NSError *error = nil;
    [FileManager moveItemAtPath:tempFile toPath:filePath error:&error];
    if (error) {
        NSLog(@"%@",error);
        return NO;
    }else
    {
        return YES;
    }
}

//设置taskId
+ (NSString *)getTaskIdWithUrlStr:(NSString *)urlString
                          sceneId:(NSNumber *)sceneId{
    NSString *file = [NSString stringWithFormat:@"%@/%@",sceneId,[urlString stringByDeletingPathExtension]];
    NSString *md5File =file.sam_MD5Digest;//
    return [md5File stringByAppendingPathExtension:[NSURL URLWithString:urlString].pathExtension];
}
//获取下载文件的大小
+(long  long )fileSizeInFilePathWithModel:(TPDownLoadModel *)model taskURL:(NSString *)taskurl
{
    NSString *filePath = [self getFilePathWithModel:model taskUrl:taskurl];
    if ([FileManager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        NSDictionary *fileAttributeDict = [FileManager attributesOfItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"获取文件错误:%@",error);
        }
        return [fileAttributeDict fileSize];
    }
    return 0;
}
//获取断点续传下载的临时文件地址
+(NSString *)getTempFileNameWithDownloadTask:(NSURLSessionDownloadTask *)downLoadTask
{
    NSString *tempFileName = nil;
    unsigned int downloadTaskPropertyCount;
    objc_property_t *downloadTaskPropertys = class_copyPropertyList([downLoadTask class],&downloadTaskPropertyCount);
    for(int i=0;i<downloadTaskPropertyCount;i++)
    {
        objc_property_t prop = downloadTaskPropertys[i];
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
       // NSLog(@"propName:%@",propName);
        if ([propName isEqualToString:@"downloadFile"]) {
            id downloadFile = [downLoadTask valueForKey:propName];
            unsigned int downloadFilePropertyCount;
            objc_property_t *downloadFileProperty = class_copyPropertyList([downloadFile class], &downloadFilePropertyCount);
            for(int i=0;i<downloadFilePropertyCount;i++)
            {
                objc_property_t downloadFileProp = downloadFileProperty[i];
                 NSString *downloadFilePropName = [NSString stringWithUTF8String:property_getName(downloadFileProp)];
                //下载文件的临时地址
                NSLog(@"downloadFilePropName:%@",downloadFilePropName);
                if ([downloadFilePropName isEqualToString:@"path"]) {
                    id pathValue = [downloadFile valueForKey:downloadFilePropName];
                    NSString *tempPath = [NSString stringWithFormat:@"%@",pathValue];
                    NSLog(@"tempPath: %@",tempPath);
                    tempFileName = tempPath.lastPathComponent;
                    break;
                }
                
            }
            free(downloadFileProperty);
            break;
        }
    }
    free(downloadTaskPropertys);
    return tempFileName;
}
//捆绑task与tmp文件  task->tmp文件名
+(void)saveTempFileName:(NSString *)tmpfile taskId:(NSString *)taskId
{
    NSString *tempMapFile = [self FileCachePathPlist];
    NSMutableDictionary *tempMapDict = [NSMutableDictionary dictionaryWithContentsOfFile:tempMapFile];
    if ([tempMapDict[taskId]length]>0) {
        [FileManager removeItemAtPath:[self tempFilePathWithName:tempMapDict[taskId]] error:nil];
    }
    if (!tempMapDict) {
        tempMapDict = [NSMutableDictionary dictionary];
    }
    tempMapDict[taskId] = tmpfile;
    [tempMapDict writeToFile:tempMapFile atomically:YES];
}
+(NSData *)getResumeDataWithTaskId:(NSString *)taskId
{
    //本地resumeData文件 resumeDataFileMapPath -> resumeDataMap.plist
    NSMutableDictionary *resumeMapDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self resumeDataFileMapPath]];
    NSString *resumeDataName = resumeMapDict[taskId];
    NSLog(@"resumeDataName: %@",resumeDataName);
    //获取data
    NSData *resumeData = nil;
    //resumeDataPathWithName —> 传入一个文件名 从cache文件夹下获取到文件
    NSString *resumeDataFileString = [self resumeDataPathWithName:resumeDataName];
    if (resumeDataName.length>0) {
        //获取到resumeData文件路径并计算其文件
        resumeData = [NSData dataWithContentsOfFile:resumeDataFileString];
    }
    //没有则创建一个
    if (!resumeData) {
        resumeData = [self createResumeDataWithTaskId:taskId];
    }
    return resumeData;
}
+(NSData *)createResumeDataWithTaskId:(NSString *)taskId
{

    //主要做两件事情 1.创建一个本地的data文件 2.将计算tmp文件夹下的文件大小写入到data文件中
    //本地resumeData文件  --> resumeDataMap.plist
    NSMutableDictionary *resumeMapDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self resumeDataFileMapPath]];
    NSString *resumeDataFileName = resumeMapDict[taskId];
    if (resumeDataFileName.length<1) {
        //randomResumeDataName 创建路径
        if (!resumeMapDict ) {
            resumeMapDict = [NSMutableDictionary dictionary];
        }
        //randomResumeDataName生成dat文件
        resumeDataFileName = [self randomResumeDataName:taskId];
        resumeMapDict[taskId] = resumeDataFileName;
        [resumeMapDict writeToFile:[self resumeDataFileMapPath] atomically:YES];
    }
    //获取data //1.获取到tmp文件 2.获取其大小
    NSString *resumeDataPath = [self resumeDataPathWithName:resumeDataFileName];
    NSDictionary *tempFileMap = [NSDictionary dictionaryWithContentsOfFile:[self FileCachePathPlist]];
    NSString *tempFileName = tempFileMap[taskId];
    if (tempFileName.length>0) {
        //tmp文件路径
        NSString *tmpFilePath = [self tempFilePathWithName:tempFileName];
        if ([FileManager fileExistsAtPath:tmpFilePath]) {
            //获取文件大小
            NSError *error =nil;
            NSDictionary *tempFileArr = [FileManager attributesOfItemAtPath:tmpFilePath error:&error];
            NSLog(@"error:%@",error);
            unsigned long long fileSize = [tempFileArr[NSFileSize]unsignedLongLongValue];
            //手动创建一个resumeData 1.url 2.临时的下载文件名 3.已接收字节数
            NSMutableDictionary *reusesumeData = [NSMutableDictionary dictionary];
            reusesumeData[@"NSURLSessionDownloadURL"] = taskId;
            if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
                reusesumeData[@"NSURLSessionResumeInfoLocalPath"] = tempFileName;
            }else
            {
                reusesumeData[@"NSURLSessionResumeInfoLocalPath"] = tmpFilePath;
            }
            reusesumeData[@"NSURLSessionResumeBytesReceived"] = @(fileSize);
            //写入到resumeData中
            NSLog(@"----resumeDataPath: %@",resumeDataPath);
            [reusesumeData writeToFile:resumeDataPath atomically:YES];
            return [NSData dataWithContentsOfFile:resumeDataPath];
        }
    }
    return nil;
}
+(NSString *)saveResumeData:(NSData *)resumeData taskId:(NSString *)taskId
{
    if (resumeData.length<1) {
        return nil;
    }
    NSMutableDictionary *resumeMapDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self resumeDataFileMapPath]];
    NSString *resumeDataFileName = resumeMapDict[taskId];
    if (resumeDataFileName.length<1) {
        //randomResumeDataName 创建路径
        if (!resumeMapDict ) {
            resumeMapDict = [NSMutableDictionary dictionary];
        }
        resumeDataFileName = [self randomResumeDataName:taskId];
        // 删除旧的resumeData
        if (resumeMapDict[taskId]) {
            [[NSFileManager defaultManager] removeItemAtPath:[self resumeDataPathWithName:resumeMapDict[taskId]] error:nil];
        }
        //更新新的
        resumeMapDict[taskId] = resumeDataFileName;
        [resumeMapDict writeToFile:[self resumeDataFileMapPath] atomically:YES];
        // 2. 存储resumeData
        [resumeData writeToFile:resumeDataFileName atomically:YES];
    }
    return resumeDataFileName;
}
/**删除恢复文件信息*/
+(void)removeResumeInfoWithTaskId:(NSString *)taskId
{
    NSMutableDictionary *resumeMapDict = [NSMutableDictionary dictionaryWithContentsOfFile:[self resumeDataFileMapPath]];
    NSString *resumeDataName = resumeMapDict[taskId];
    if (resumeDataName) {
        [resumeMapDict removeObjectForKey:resumeDataName];
        [resumeMapDict writeToFile:[self resumeDataFileMapPath] atomically:YES];
        //删除resumeData
        NSString *resumeDataPath = [self randomResumeDataName:taskId];
        [FileManager removeItemAtPath:resumeDataPath error:nil];
    }
  
}
+(void)removeTempFileWithTask:(NSString *)taskId
{
    NSString *tmpMapPath = [self FileCachePathPlist];
    NSMutableDictionary *tempFileDict = [NSMutableDictionary dictionaryWithContentsOfFile:tmpMapPath];
    if ([tempFileDict[taskId] length]>0) {
        [FileManager removeItemAtPath:[self tempFilePathWithName:tempFileDict[taskId]] error:nil];
        [tempFileDict writeToFile:tmpMapPath atomically:YES];
    }
}

#pragma mark - filePath
//沙盒文件
NSString *FilePath()
{
    NSString *sanboxPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"downLoadModel"];
    if (![FileManager fileExistsAtPath:sanboxPath]) {
        [FileManager createDirectoryAtPath:sanboxPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return sanboxPath;
}

//临时文件
NSString *FileTempPath()
{
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downLoadModel"];
    if (![FileManager fileExistsAtPath:tempPath]) {
        [FileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return tempPath;
}

//Cache文件
NSString *FileCachePath()
{
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    cachePath = [cachePath stringByAppendingPathComponent:@"downLoadCacheModel"];
    if (![FileManager fileExistsAtPath:cachePath]) {
        [FileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cachePath;
}
/// 临时文件路径 通过传入参数将临时文件全路径获取出来
+ (NSString *)tempFilePathWithName:(NSString *)fileName {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

//临时文件的字典存储 tmp文件存储地址 taskId -> tmp 一个taskId对应一个tmp文件
+(NSString *)FileCachePathPlist
{
    return [FileCachePath() stringByAppendingPathComponent:@"tempMapPlist.plist"];
}
/**保存resumeData的Map文件地址  通过taskId -> .dat文件*/
+(NSString *)resumeDataFileMapPath
{
    return [FileCachePath() stringByAppendingPathComponent:@"resumeDataMap.plist"];
}
//存放cache文件夹全路径通过传入的参数返回全路径
+(NSString *)resumeDataPathWithName:(NSString *)fileName
{
    return [FileCachePath() stringByAppendingPathComponent:fileName];
}
+(NSString *)randomResumeDataName:(NSString *)taskId
{
    
     NSRange range = [taskId rangeOfString:[NSURL URLWithString:taskId].pathExtension];
    taskId = [taskId substringToIndex:range.location-1];
    return [NSString stringWithFormat:@"resumeData_%@.dat",taskId];
}
@end
