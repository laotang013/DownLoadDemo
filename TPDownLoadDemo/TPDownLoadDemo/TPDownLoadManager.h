//
//  TPDownLoadManager.h
//  DownLoadDemo
//
//  Created by Start on 2018/7/11.
//  Copyright © 2018年 Start. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPDownLoadModel.h"
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,DownLoadState)
{
    DownLoadStateLoaded = 1<<1,//已下载
    DownLoadStateLoading = 1<<2,//下载中
    DownLoadStatePause = 1<<3,//下载暂停
    DownLoadStateUnDownLoad = 1<<4,//未下载
    DownLoadStateDownLoadFail = 1<<5,//下载失败
    DownLoadStateLoadWait = 1<<6,//下载等待
    DownLoadStateStateNew = 1<<7,
};
@interface TPDownLoadManager : NSObject
+(instancetype)shareManager;
//单个下载
-(void)startDownLoadTask:(TPDownLoadModel *)task;
-(void)pauseDownLoadTask:(TPDownLoadModel *)task;
-(void)resumeDownLoadTask:(TPDownLoadModel *)task;
//-(void)pauseAllTask;
//-(void)startAllTask;

/**progress*/
@property(nonatomic,assign) CGFloat progress;

//批量下载
/**开启下载*/
-(void)startDownLoadTasks:(NSArray *)tasks;
/**停止下载*/
-(void)pauseAllTask;
/**恢复下载*/
-(void)resumeAllTask;
/**清除下载*/
-(void)clearAllTask;
@end
