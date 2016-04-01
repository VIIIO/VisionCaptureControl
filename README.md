VisionCaptureControl
=====
* An oc barcode/QRcode recognizer based on iOS AVCaptureDevice
* 基于IOS7+自带条码识别器的自适应条码/二维码扫描控件

## Screenshots
![image](http://blog.viiio.com/wp-content/uploads/2016/04/IMG_0024.jpg)
![image](http://blog.viiio.com/wp-content/uploads/2016/04/IMG_0026.jpg)

## Contents
## 1. Installation 安装

  * Just drag VisionControl folder into your project
  * 将VisionControl文件夹拖入你的項目

    在你需要使用识别器的文件中导入头文件:
```objective-c
#import "VisionCaptureControl.h"
```
## 2. Usage 使用方法
```objective-c
   VisionCaptureControl *capture = [[VisionCaptureControl alloc] init];
    [capture setMultiMode:NO];//default value is NO
    [capture setCallback:^(NSString *result) {
        //識別成功，你可以在此播放聲音及進行其他操作
        //Code recognized successfully.You could play a sound or do anything you want
    }];
    [capture show];
```
  
## 3. Requirements 要求
   iOS 7 or later. Requires ARC  
   iOS 7及以上系统可使用. 本控件纯ARC，支持iPhone/iPad横竖屏
   
## 4. More 更多 

  Please issue me 
  If you find a bug, please create a issue.  
  Welcome to pull requests.  
  More infomation please view code.  
  如果你发现了bug，请提一个issue。  
  欢迎给我提pull requests。  
  更多信息详见代码，也可查看我的博客: [我的博客](http://www.cnblogs.com/tanzhenblog/ "半尺尘 - 博客园")
  
## 5. Licenses
   All source code is licensed under the MIT License.
  
