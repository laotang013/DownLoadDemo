//
//  ViewController.m
//  TPDownLoadDemo
//
//  Created by Start on 2018/7/12.
//  Copyright © 2018年 Start. All rights reserved.
//

#import "ViewController.h"
#import "TPDownLoadModel.h"
#import "TPDownLoadSession.h"
#import "TPDownLoadCache.h"
#import "TPDownLoadManager.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property(nonatomic,strong)NSDictionary *dict;
@property(nonatomic,strong)TPDownLoadModel *model;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.model = [[TPDownLoadModel alloc]initWithCoreDataModel:self.dict];
    self.progressView.progress = [TPDownLoadManager shareManager].progress;

}
- (IBAction)StartBtn:(id)sender {
   
   
    [[TPDownLoadManager shareManager]startDownLoadTask:self.model];
}

- (IBAction)StopBtn:(id)sender {
  
    [[TPDownLoadManager shareManager]pauseDownLoadTask:self.model];
    
}
- (IBAction)ResumeBtn:(id)sender {
  
    [[TPDownLoadManager shareManager]resumeDownLoadTask:self.model];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(NSDictionary *)dict
{
    if (!_dict) {
        _dict = @{@"videoUrl":@"http://htsleep.hetyj.com/03b78be45e40b19530e87ea42020ac1f.1531206873998.mp4",@"voiceUrl":@"http://htsleep.hetyj.com/%E5%86%A5%E6%83%B3%E5%BC%95%E5%AF%BC%E8%AF%8D-%E6%9B%BC%E5%A6%99%E6%9E%81%E5%85%89.mp3",@"senceId":@(1)};
    }
    return _dict;
}

@end
