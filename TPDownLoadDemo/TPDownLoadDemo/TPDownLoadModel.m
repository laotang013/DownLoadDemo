
//
//  TPDownLoadModel.m
//  DownLoadDemo
//
//  Created by Start on 2018/7/11.
//  Copyright © 2018年 Start. All rights reserved.
//

#import "TPDownLoadModel.h"

@implementation TPDownLoadModel
- (instancetype)initWithCoreDataModel:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.videoUrl = dict[@"videoUrl"];
        self.voiceUrl = dict[@"voiceUrl"];
        self.senceId =  dict[@"senceId"];
    }
    return self;
}

@end
