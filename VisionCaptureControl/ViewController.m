//
//  ViewController.m
//  VisionCaptureControl
//
//  Created by Vision on 16/4/1.
//  Copyright © 2016年 VIIIO. All rights reserved.
//

#import "ViewController.h"
#import "VisionCaptureControl.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showScanner:(id)sender {
    VisionCaptureControl *capture = [[VisionCaptureControl alloc] init];
    [capture setMultiMode:NO];//default value is NO
    [capture setCallback:^(NSString *result) {
        //識別成功，你可以在此播放聲音及進行其他操作
        //Code recognized successfully.You could play a sound or do anything you want
        NSLog(@"已識別：%@",result);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                        message:result
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
    [capture show];
}


- (IBAction)showMultiScanner:(id)sender {
    VisionCaptureControl *capture = [[VisionCaptureControl alloc] init];
    [capture setMultiMode:YES];
    [capture setCallback:^(NSString *result) {
        //識別成功，你可以在此播放聲音及進行其他操作
        //Code recognized successfully.You could play a sound or do anything you want
        //see console to view the results
        NSLog(@"已識別：%@",result);
    }];
    [capture show];
}
@end
