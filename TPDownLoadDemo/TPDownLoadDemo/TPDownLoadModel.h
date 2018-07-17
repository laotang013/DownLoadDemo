//
//  TPDownLoadModel.h
//  DownLoadDemo
//
//  Created by Start on 2018/7/11.
//  Copyright © 2018年 Start. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPDownLoadModel : NSObject
/**下载URL*/
@property(nonatomic,copy)NSString *videoUrl;
/**音频URL*/
@property(nonatomic,copy)NSString *voiceUrl;
@property(nonatomic,strong)NSNumber *senceId;
- (instancetype)initWithCoreDataModel:(NSDictionary *)dict;
@end
