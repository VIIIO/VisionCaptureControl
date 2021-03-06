VisionCaptureControl
=====
* An oc barcode/QRcode recognizer based on iOS AVCaptureDevice
* 基于IOS7+自带条码识别器的自适应条码/二维码扫描控件，已自动处理相机访问权限

### Screenshots
![image](http://blog.viiio.com/wp-content/uploads/2016/04/IMG_0026.jpg)

### Contents
## Installation 安装

  * Just drag `VisionControl` folder into your project
  * 将`VisionControl`文件夹拖入你的項目

### 在你需要使用识别器的文件中导入头文件:
```objective-c
#import "VisionCaptureControl.h"
```
## Usage 使用方法
```objective-c
   VisionCaptureControl *capture = [[VisionCaptureControl alloc] init];
    [capture setMultiMode:NO];//default value is NO
    [capture setCallback:^(NSString *result) {
        //識別成功，你可以在此播放聲音及進行其他操作
        //Code recognized successfully.You could play a sound or do anything you want
    }];
    [capture show];
```

## Features 特性
* Support batch scan</br>
* Support `Barcode Only` mode which would ignore QRCode and improve the recognition rate&speed of barcode substantially
* Auto-focus to raise the recognition rate&speed</br>
* 支持进行条码/二维码的单体或批量扫描</br>
* 支持条码专扫，此模式下会忽略二维码，但会大幅提高条码的识别速度</br>
* 定时自动对焦，提高识别速度和识别率</br>

## Requirements 要求
  iOS 7 or later. Requires ARC  ,support iPhone/iPad
  
  iOS 7及以上系统可使用. 本控件纯ARC，支持iPhone/iPad横竖屏
## More 更多 

  Please create a issue if you have any questions.
  Welcome to visit my [Blog](http://blog.viiio.com/ "Vision的博客")
  
## Licenses
   All source code is licensed under the [MIT License](https://github.com/VIIIO/VisionCaptureControl/blob/master/LICENSE "License").
  
