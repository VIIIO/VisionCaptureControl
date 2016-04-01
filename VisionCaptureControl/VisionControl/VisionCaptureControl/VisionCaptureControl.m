//
//  VisionCaptureControl.m
//  VisionControls
//
//  Created by Vision on 16/3/15.
//  Copyright © 2016年 VIIIO. All rights reserved.
//

#import "VisionCaptureControl.h"

#define SCANVIEW_EdgeTop 40.0
#define SCANVIEW_EdgeLeft 50.0

#define TINTCOLOR_ALPHA 0.2  //浅色透明度
#define DARKCOLOR_ALPHA 0.5  //深色透明度
#define VisionKeyIsPortrait (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
#define VisionKeyIsLandscape (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);
@interface VisionCaptureControl (){
    UIImageView *_QrCodeline;
    //设置扫描画面
    UIView *_scanView;
    UIButton *openButton;
    BOOL IsStopped;
    BOOL IsOnlyBarcode;
    BOOL IsInterval;//是否處於識別間隔期
    
    CGSize fixedScreenSize;
    float VIEW_WIDTH;
    float VIEW_HEIGHT;
    void(^callback)(NSString *st_result);//回调函数
    BOOL IsMulti;//是否连续识别
}
@property (strong,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;

@property (copy,nonatomic) NSString *requestAccessTitle;
@property (copy,nonatomic) NSString *requestAccessContent;
@property (copy,nonatomic) NSString *requestAccessConfirmText;
@property (copy,nonatomic) NSString *scanIntroduction;
@property (copy,nonatomic) NSString *scanBarcodeOnlyText;
@property (copy,nonatomic) NSString *scanAllCodeText;
@end

@implementation VisionCaptureControl

- (void)viewWillDisappear:(BOOL)animated
{
    [ super viewWillDisappear :animated];
    [_session stopRunning];
    [self stopMoveLine];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    IsInterval = NO;
    fixedScreenSize = [self fixedScreenSize];
    //MasterController的屏幕方向影響子頁size，強制豎屏則需要置換寬高
    VIEW_WIDTH = VisionKeyIsPortrait ? fixedScreenSize.width: fixedScreenSize.height;
    VIEW_HEIGHT = VisionKeyIsPortrait ? fixedScreenSize.height: fixedScreenSize.width;
    self.title = @"扫描二维码";
    self.requestAccessTitle = @"拍摄授权";
    self.requestAccessContent = @"您需要授予本软件使用相机的权限";
    self.requestAccessConfirmText = @"确认";
    self.scanIntroduction = @"将条码/二维码对准方框，即可自动扫描";
    self.scanBarcodeOnlyText = @"条码专扫";
    self.scanAllCodeText = @"关闭专扫";
    //初始化扫描界面
    [self setScanView];
    [self requestAccess];
}

- (void)requestAccess{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
        {
            [self setupCamera];
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted)
                {
//                    [self setupCamera];
                    //扫描线动画
                    IsStopped = NO;
                    [self moveUpAndDownLine];
                }
                else
                {
                    
                }
            }];
            break;
        }
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:{
            UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:self.requestAccessTitle message:self.requestAccessContent delegate:nil cancelButtonTitle:self.requestAccessConfirmText otherButtonTitles:nil, nil];//攝像授權  您需要授予本軟體使用相機的權限
            [alterView show];
            break;
        }
        default:{
            [self setupCamera];
            //扫描线动画
            IsStopped = NO;
            [self moveUpAndDownLine];
        }
    }
}

- (void)setupCamera
{
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // Session
    _session = [[AVCaptureSession alloc]init];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
    }else{
        [_session setSessionPreset:AVCaptureSessionPresetPhoto];//经iPhone测试比High识别速度更快
    }
    
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode,
                                   AVMetadataObjectTypeCode39Code,
                                   AVMetadataObjectTypeCode39Mod43Code,
                                   AVMetadataObjectTypeEAN13Code,
                                   AVMetadataObjectTypeEAN8Code,
                                   AVMetadataObjectTypeCode93Code,
                                   AVMetadataObjectTypeCode128Code,
                                   //AVMetadataObjectTypePDF417Code,
                                   AVMetadataObjectTypeQRCode,
                                   //AVMetadataObjectTypeAztecCode,
                                   //AVMetadataObjectTypeInterleaved2of5Code,
                                   //AVMetadataObjectTypeITF14Code,
                                   //AVMetadataObjectTypeDataMatrixCode
                                   ];
    //扫描区域
    CGRect scanMaskRect =  CGRectMake (SCANVIEW_EdgeLeft , SCANVIEW_EdgeTop , VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft , VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft );
    
    //扫描区域计算
    CGRect scanCrop =[self getScanCrop:scanMaskRect readerViewBounds:self.view.bounds];
    [_output setRectOfInterest:scanCrop];
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
    
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    [self reFocusCenter];
    // Start
    [_session startRunning];
    [self reFocusCenter];
}

- (CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    CGFloat x,y,width,height;
    if (VisionKeyIsLandscape) {
        //橫屏掃描區域計算公式
        x = rect.origin.x / readerViewBounds.size.width;
        y = rect.origin.y / readerViewBounds.size.height;
        width = rect.size.width / readerViewBounds.size.width;
        height = rect.size.height / readerViewBounds.size.height;
    }else if(VisionKeyIsPortrait){
        //豎屏掃描區域計算公式
        x = rect.origin.y / readerViewBounds.size.height;
        y = 1 - (rect.origin.x + rect.size.width) / readerViewBounds.size.width;
        width = (rect.origin.x + rect.size.height) / readerViewBounds.size.height;
        height = 1 - rect.origin.x / readerViewBounds.size.width;
    }
    return CGRectMake(x, y, width, height);
}
#pragma mark - ReaderViewDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (!IsInterval) {
        IsInterval = YES;
        NSString *stringValue;
        if ([metadataObjects count] >0)
        {
            AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
            stringValue = metadataObject.stringValue;
        }
        if (stringValue == nil) {//|| [stringValue isEqualToString: self.st_currRecognised] 需要解决识别间隔过高问题
            return;
        }
        if (stringValue.length > 0) {
            //执行回调
            if (callback != nil) {
                callback(stringValue);
            }
            //不是连续识别模式则直接退出
            if (!IsMulti) {
                [_session stopRunning];
                [self dismissViewControllerAnimated:YES completion:nil];
            }else{
                double delayInSeconds = 1.0;//一秒后再次啟動識別
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    IsInterval = NO;
                });
            }
        }
    }
}
- (void)setScanView
{
    _scanView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    _scanView.backgroundColor = [UIColor clearColor];
    
    //最上部view
    UIView * upView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, VIEW_WIDTH, SCANVIEW_EdgeTop)];
    upView.alpha = TINTCOLOR_ALPHA;
    upView.backgroundColor = [UIColor blackColor];
    [_scanView addSubview: upView];
    
    //左侧的view
    UIView * leftView = [[UIView alloc] initWithFrame: CGRectMake(0, SCANVIEW_EdgeTop, SCANVIEW_EdgeLeft, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft)];
    leftView.alpha = TINTCOLOR_ALPHA;
    leftView.backgroundColor = [UIColor blackColor];
    [_scanView addSubview: leftView];
    
    /******************中间扫描区域****************************/
    UIImageView * scanCropView = [[UIImageView alloc] initWithFrame: CGRectMake(SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft)];
    scanCropView.image = [UIImage imageNamed: @"VisionCaptureBackground"];
    scanCropView.backgroundColor = [UIColor clearColor];
    [_scanView addSubview: scanCropView];
    
    //右侧的view
    UIView * rightView = [[UIView alloc] initWithFrame: CGRectMake(VIEW_WIDTH - SCANVIEW_EdgeLeft, SCANVIEW_EdgeTop, SCANVIEW_EdgeLeft, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft)];
    rightView.alpha = TINTCOLOR_ALPHA;
    rightView.backgroundColor = [UIColor blackColor];
    [_scanView addSubview: rightView];
    
    //底部view
    UIView * downView = [[UIView alloc] initWithFrame: CGRectMake(0, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop, VIEW_WIDTH, VIEW_HEIGHT - (VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft + SCANVIEW_EdgeTop))];
    //downView.alpha = TINTCOLOR_ALPHA;
    downView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: TINTCOLOR_ALPHA]; [_scanView addSubview: downView];
    
    //用于说明的label
    UILabel * labIntroudction = [[UILabel alloc] init];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.frame = CGRectMake(0, 30, VIEW_WIDTH, 20);
    labIntroudction.numberOfLines = 1;
    labIntroudction.font = [UIFont systemFontOfSize: 15.0];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.textColor = [UIColor whiteColor];
    labIntroudction.text = self.scanIntroduction;//"將條碼/二維碼對準方框，即可自動掃描";
    [downView addSubview: labIntroudction];
    
    //按鈕區
    UIView * darkView = [[UIView alloc] initWithFrame: CGRectMake(0, downView.frame.size.height - 60.0, VIEW_WIDTH, 60.0)];
    darkView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent: DARKCOLOR_ALPHA]; [downView addSubview: darkView];
    
    //用于开关灯操作的button
    openButton = [[UIButton alloc] initWithFrame: CGRectMake(VIEW_WIDTH / 2 - 15, 15, 30.0, 30.0)];
    [openButton setImage: [UIImage imageNamed: @"Lightning Bolt-50white"] forState: UIControlStateNormal];
    [openButton setImage: [UIImage imageNamed: @"Lightning Bolt Filled-50white"] forState: UIControlStateSelected];
    [openButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    openButton.tintColor = [UIColor whiteColor];
    openButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    openButton.backgroundColor = [UIColor clearColor];
    openButton.titleLabel.font = [UIFont systemFontOfSize: 22.0]; [openButton addTarget: self action: @selector(openLight) forControlEvents: UIControlEventTouchUpInside];
    [darkView addSubview: openButton];
    
    //離開按鈕
    UIButton * btn_leave = [[UIButton alloc] initWithFrame: CGRectMake(15, 15, 30.0, 30.0)];
    [btn_leave setImage: [UIImage imageNamed: @"Back-50white"] forState: UIControlStateNormal];
    [btn_leave addTarget: self action: @selector(btn_leave_click) forControlEvents: UIControlEventTouchUpInside];
    [darkView addSubview: btn_leave];
    
    //专扫条码按鈕
    UIButton * btn_barcode = [[UIButton alloc] initWithFrame: CGRectMake(VIEW_WIDTH - 115, 15, 100.0, 30.0)];
    [btn_barcode setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn_barcode setTitle:self.scanBarcodeOnlyText forState:UIControlStateNormal];//條碼專掃
    [btn_barcode setTitle:self.scanAllCodeText forState:UIControlStateSelected];//關閉專掃
    [btn_barcode addTarget: self action: @selector(btn_barcode_click:) forControlEvents: UIControlEventTouchUpInside];
    [darkView addSubview: btn_barcode];
    
    //画中间的基准线
    _QrCodeline = [[UIImageView alloc] initWithFrame: CGRectMake(SCANVIEW_EdgeLeft + 15, SCANVIEW_EdgeTop + 20, VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft - 30, 2)];
    _QrCodeline.backgroundColor = [UIColor clearColor];
    _QrCodeline.image = [UIImage imageNamed: @"VisionCaptureLine"];
    [_scanView addSubview: _QrCodeline];
    [self.view addSubview : _scanView ];
}
- (void)openLight
{
    if([_device hasTorch]){
        [_device lockForConfiguration:nil];
        if (_device.torchMode == AVCaptureTorchModeOn) {
            [openButton setSelected:NO];
            [_device setTorchMode:AVCaptureTorchModeOff];
        }else if (_device.torchMode == AVCaptureTorchModeOff) {
            [openButton setSelected:YES];
            [_device setTorchMode:AVCaptureTorchModeOn];
        }
        [_device unlockForConfiguration];
    }
}

- (CGSize)fixedScreenSize {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && VisionKeyIsLandscape) {
        return CGSizeMake(screenSize.height, screenSize.width);
    } else {
        return screenSize;
    }
}

- (void)btn_leave_click{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btn_barcode_click:(UIButton *)sender{
    [_device lockForConfiguration:nil];
    if (!IsOnlyBarcode) {
        _output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode,
                                       AVMetadataObjectTypeCode39Code,
                                       AVMetadataObjectTypeCode39Mod43Code,
                                       AVMetadataObjectTypeEAN13Code,
                                       AVMetadataObjectTypeEAN8Code,
                                       AVMetadataObjectTypeCode93Code,
                                       AVMetadataObjectTypeCode128Code,
                                       ];
        [sender setSelected:YES];
    }else{
        _output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode,
                                       AVMetadataObjectTypeCode39Code,
                                       AVMetadataObjectTypeCode39Mod43Code,
                                       AVMetadataObjectTypeEAN13Code,
                                       AVMetadataObjectTypeEAN8Code,
                                       AVMetadataObjectTypeCode93Code,
                                       AVMetadataObjectTypeCode128Code,
                                       AVMetadataObjectTypeQRCode
                                       ];
        [sender setSelected:NO];
    }
    IsOnlyBarcode = !IsOnlyBarcode;
    [_device unlockForConfiguration];
}

//二维码的横线移动
- (void)moveUpAndDownLine
{
    [self reFocusCenter];
    CGFloat Y= _QrCodeline.frame.origin.y ;
    float moveTo = 0.0f;
    if (VIEW_WIDTH- 2 *SCANVIEW_EdgeLeft+SCANVIEW_EdgeTop-20 ==Y) {
        moveTo = SCANVIEW_EdgeTop +20;
    }else{
        moveTo = VIEW_WIDTH- 2 *SCANVIEW_EdgeLeft+SCANVIEW_EdgeTop-20;
    }
    [UIView animateWithDuration:1.3 delay:0 options:UIViewAnimationOptionCurveLinear| UIViewAnimationOptionAllowUserInteraction animations:^{
        _QrCodeline.frame=CGRectMake(SCANVIEW_EdgeLeft + 15, moveTo, VIEW_WIDTH- 2 *SCANVIEW_EdgeLeft -30, 2 );
    } completion:^(BOOL finished) {
        if (!IsStopped) {//必要，否则引起死循环
            [self moveUpAndDownLine];//无限循环
        }
    }];
}

- (void) stopMoveLine{
    IsStopped = YES;
}

// 是否支持转屏
- (BOOL)shouldAutorotate
{
    return YES;
}

// 支持的屏幕方向，此处可直接返回 UIInterfaceOrientationMask 类型
// 也可以返回多个 UIInterfaceOrientationMask 取或运算后的值
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//重聚焦
- (void)reFocusCenter{
    CGPoint cameraPoint= [_preview captureDevicePointOfInterestForPoint:CGPointMake(VIEW_WIDTH/2,SCANVIEW_EdgeTop + (VIEW_WIDTH - 2 * SCANVIEW_EdgeLeft)/2)];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}
/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= _device;
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

- (UIViewController*)topMostController{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}
#pragma mark 外部調用方法
- (void)show{
    [[self topMostController] presentViewController:self animated:YES completion:nil];
}

- (void)setCallback:(void(^)(NSString *result)) cb{
    callback = cb;
}

- (void)setMultiMode:(BOOL)isMultiMode{
    IsMulti = isMultiMode;
}

@end
