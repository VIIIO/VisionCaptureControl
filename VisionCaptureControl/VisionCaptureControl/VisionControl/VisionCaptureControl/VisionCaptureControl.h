//
//  VisionCaptureControl.h
//  VisionControls
//
//  Created by Vision on 16/3/15.
//  Copyright © 2016年 VIIIO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
/**
 基于IOS7+自带条码识别器的自适应条码/二维码扫描控件
 */
@interface VisionCaptureControl : UIViewController<AVCaptureMetadataOutputObjectsDelegate>
- (void)show;
/**
 回调函数，定义识别完成后的动作 st_result为已识别的内容
 */
- (void)setCallback:(void(^)(NSString *result)) cb;
/**
 设定是否为连续识别模式，默认NO
 */
- (void)setMultiMode:(BOOL)isMultiMode;
@end