//
//  TPDownLoadChecker.m
//  DownLoadDemo
//
//  Created by Start on 2018/7/11.
//  Copyright © 2018年 Start. All rights reserved.
//

#import "TPDownLoadChecker.h"
static  NSString *DownLoadError = @"DownLoadError";
@implementation TPDownLoadChecker
+(void)checkWithModel:(TPDownLoadModel *)model checkBlock:(CheckBlock)checkBlock
{
    //url 校验 如果有一个有问题则不下载
    NSArray *array = @[model.videoUrl,model.voiceUrl];
    for (NSString *modelUrl in array) {
        BOOL validStr = [self checkUrlStr:modelUrl];
        if (!validStr) {
            NSError *error = [NSError errorWithDomain:DownLoadError code:DownLoadCheckerErrorCoderUrlErrorCode userInfo:@{@"NSLocalizedDescription":@(DownLoadCheckerErrorCoderUrlErrorCode)}];
            !checkBlock?:checkBlock(error);
            break;
            return;
        }
    }
    !checkBlock?:checkBlock(nil);
}
+(BOOL)checkUrlStr:(NSString *)urlStr
{
    //1.判断是否为空
    if (!urlStr||[urlStr isEqual:[NSNull null]]||[urlStr isEqualToString:@""]) {
        return NO;
    }
    //2.判断不是http开头
    if (![[urlStr substringToIndex:4]isEqualToString:@"http"]) {
        return NO;
    }
    //3.判断尾缀是否是符合的格式
    //指明扩展名pathExtension 比如txt mp4
    NSString *downLoadExt = [NSURL URLWithString:urlStr].pathExtension;
    static dispatch_once_t onceToken;
    static NSArray *fileTypesByFileExtensions;
    dispatch_once(&onceToken, ^{
        fileTypesByFileExtensions = @[@"mp4",@"mp3",@"acc"];
    });
    if (downLoadExt&&![fileTypesByFileExtensions containsObject:downLoadExt]) {
        return NO;
    }
    return YES;
}
@end
