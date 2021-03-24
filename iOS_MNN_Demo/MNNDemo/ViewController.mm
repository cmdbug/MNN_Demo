//
//  ViewController.m
//  MNNDemo
//
//  Created by WZTENG on 2021/1/11.
//  Copyright © 2021 TENG. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>
#include <algorithm>
#include <functional>
#include <vector>

#include "NanoDet.h"

#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVMediaFormat.h>
#import "ELCameraControlCapture.h"


@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *resultLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UISlider *nmsSlider;
@property (strong, nonatomic) IBOutlet UISlider *thresholdSlider;
@property (strong, nonatomic) IBOutlet UILabel *valueShowLabel;
@property (strong, nonatomic) IBOutlet UIView *preView;

@property (assign, nonatomic) float threshold;
@property (assign, nonatomic) float nms_threshold;

@property (assign, atomic) double total_fps;
@property (assign, atomic) double fps_count;

// 相机部分
@property (strong, nonatomic) ELCameraControlCapture *cameraCapture;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preLayer;

@property NanoDet *nanodet;

@property (assign, atomic) Boolean isDetecting;
@property (assign, atomic) Boolean isPhoto;

@property (nonatomic) dispatch_queue_t queue;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        // 没有权限
        NSLog(@"没有权限");
    } else {
        // 有权限
    }
    self.queue = dispatch_queue_create("ncnn", DISPATCH_QUEUE_CONCURRENT);
    [self initTitleName];
    self.isDetecting = NO;
    self.isPhoto = NO;
    [self initView];
    [self setCameraUI];
}

#pragma mark 显示标题
- (void)initTitleName {
    self.title = [[[self getModelName] stringByReplacingOccurrencesOfString:@"[CPU] " withString:@""] stringByReplacingOccurrencesOfString:@"[GPU] " withString:@""];
}

- (CGFloat)degreesToRadians:(CGFloat)degrees {
    return M_PI * (degrees / 180.0);
}

- (UIImage *)rotatedByDegrees:(CGFloat)degrees image:(UIImage *)image {
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation([self degreesToRadians:degrees]);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    // Rotate the image context
    CGContextRotateCTM(bitmap, [self degreesToRadians:degrees]);
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark 设置相机并回调
- (void)setCameraUI {
    [self setVideoPreview];
    __weak typeof(self) weakSelf = self;
    self.cameraCapture.imageBlock = ^(UIImage *image) {
//        NSLog(@"%f", image.size.height);
        if (weakSelf.isDetecting || weakSelf.isPhoto) {
            return;
        }
        weakSelf.isDetecting = YES;
        // 根据方向旋转图片
        __block float degrees = 0.0f;
        __block UIImage *temp = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait) {
                degrees = 90.0f;
            } else {
                degrees = -90.0f;
            }
            temp = [weakSelf rotatedByDegrees:degrees image:image];
        });
        dispatch_sync(weakSelf.queue, ^{
            [weakSelf detectImage:temp];
            weakSelf.isDetecting = NO;
        });
    };
    [self.cameraCapture startSession];
}

- (ELCameraControlCapture *)cameraCapture {
    if (!_cameraCapture) {
        _cameraCapture = [[ELCameraControlCapture alloc] init];
    }
    return _cameraCapture;
}

#pragma mark 相机预览画面位置
- (void)setVideoPreview {
    self.preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.cameraCapture.captureSession];
    self.preLayer.backgroundColor = [[UIColor redColor] CGColor];
    UIEdgeInsets insets = self.view.safeAreaInsets;
    CGRect screen = [[UIScreen mainScreen] bounds];
    self.preLayer.frame = CGRectMake(5, screen.size.height - 145 - insets.bottom - 5, 110, 145);
    self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.preLayer];
}

- (void)tapImageViewRecognizer {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick)];
    tap.numberOfTapsRequired = 1;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:tap];
}

- (void)tapClick {
    self.isPhoto = NO;
    self.isDetecting = NO;
    [self.cameraCapture startSession];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isPhoto) {
        [self.cameraCapture startSession];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraCapture stopSession];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.isPhoto) {
        dispatch_barrier_async(self.queue, ^{
            [self releaseModel];
        });
    }
}


- (void)initView {
    self.threshold = 0.3f;
    self.nms_threshold = 0.7f;
    if (self.USE_MODEL == W_NANODET) {
        self.threshold = 0.4f;
        self.nms_threshold = 0.6f;
    }
    [self.thresholdSlider setValue:self.threshold];
    [self.nmsSlider setValue:self.nms_threshold];
    NSString *value = [NSString stringWithFormat:@"Threshold:%.2f NMS:%.2f", self.threshold, self.nms_threshold];
    self.valueShowLabel.text = value;
    
    [self.nmsSlider addTarget:self action:@selector(nmsChange:forEvent:) forControlEvents:UIControlEventValueChanged];
    [self.thresholdSlider addTarget:self action:@selector(nmsChange:forEvent:) forControlEvents:UIControlEventValueChanged];
    if (self.USE_MODEL != W_NANODET) {
        self.nmsSlider.enabled = NO;
        self.thresholdSlider.enabled = NO;
    }
    
    [self tapImageViewRecognizer];
}

#pragma mark 顶部控件
- (void)nmsChange:(UISlider *)slider forEvent:(UIEvent *)event {
    UITouch *torchEvent = [[event allTouches] anyObject];
    switch (torchEvent.phase) {
        case UITouchPhaseBegan: {
            break;
        }
        case UITouchPhaseMoved: {
            NSString *value = [NSString stringWithFormat:@"Threshold:%.2f NMS:%.2f", self.thresholdSlider.value, self.nmsSlider.value];
            self.valueShowLabel.text = value;
            self.threshold = self.thresholdSlider.value;
            self.nms_threshold = self.nmsSlider.value;
            break;
        }
        case UITouchPhaseEnded: {
            NSString *value = [NSString stringWithFormat:@"Threshold:%.2f NMS:%.2f", self.thresholdSlider.value, self.nmsSlider.value];
            self.valueShowLabel.text = value;
            self.threshold = self.thresholdSlider.value;
            self.nms_threshold = self.nmsSlider.value;
            break;
        }
        default: {
            break;
        }
    }
    if (self.threshold <= 0) {
        self.threshold = 0.01;
        NSString *value = [NSString stringWithFormat:@"Threshold:%.2f NMS:%.2f", self.threshold, self.nmsSlider.value];
        self.valueShowLabel.text = value;
    }
}

#pragma mark 照片
- (IBAction)predict:(id)sender {
    self.isPhoto = YES;
    UIImagePickerController *picVC = [[UIImagePickerController alloc] init];
    picVC.delegate = self;
    picVC.allowsEditing = NO;
    [self presentViewController:picVC animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSLog(@"did pick image");
    self.isDetecting = YES;
    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
    self.imageView.image = image;
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.queue, ^{
        [weakSelf detectImage:image];
    });
    
    [self dismissViewControllerAnimated:YES completion:^{
        self.isPhoto = NO;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"did cancel image");
    self.isPhoto = NO;
    [self dismissViewControllerAnimated:YES completion:^{
        self.isPhoto = NO;
        self.isDetecting = NO;
    }];
}

#pragma mark 相机回调图片
- (void)detectImage:(UIImage *)image {
    // create model
    [self createModel];
    
    NSDate *start = [NSDate date];
    std::vector<BoxInfo> result;
    if (self.USE_MODEL == W_NANODET) {
        result = self.nanodet->detect(image, self.threshold, self.nms_threshold);
    }
    __weak typeof(self) weakSelf = self;
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (weakSelf.USE_MODEL == W_NANODET) {
            weakSelf.imageView.image = [weakSelf drawBox:weakSelf.imageView image:image boxs:result];
        }
        
        // include draw
        long dur = [[NSDate date] timeIntervalSince1970]*1000 - start.timeIntervalSince1970*1000;
        float fps = 1.0 / (dur / 1000.0);
        weakSelf.total_fps = (weakSelf.total_fps == 0) ? fps : (weakSelf.total_fps + fps);
        weakSelf.fps_count++;
        NSString *info = [NSString stringWithFormat:@"%@\nSize:%dx%d\nTime:%.3fs\nFPS:%.2f\nAVG_FPS:%.2f", [self getModelName], int(image.size.width), int(image.size.height), dur / 1000.0, fps, (float)weakSelf.total_fps / weakSelf.fps_count];
        weakSelf.resultLabel.text = info;
        
    });
    
}

#pragma mark 创建模型
- (void)createModel {
    if (!self.nanodet && self.USE_MODEL == W_NANODET) {
        NSLog(@"new NanoDet");
        self.nanodet = new NanoDet(self.USE_GPU);
    }
}

- (void)releaseModel {
    NSLog(@"release model");
    delete self.nanodet;
}

#pragma mark 获取模型名称
- (NSString *)getModelName {
    NSString *name = @"ohhhhh";
    if (self.USE_MODEL == W_NANODET) {
        name = @"NanoDet";
    }
    NSString *modelName = self.USE_GPU ? [NSString stringWithFormat:@"[GPU] %@", name] : [NSString stringWithFormat:@"[CPU] %@", name];
    return modelName;
}

#pragma mark 绘制目标检测结果
- (UIImage *)drawBox:(UIImageView *)imageView image:(UIImage *)image boxs:(std::vector<BoxInfo>)boxs {
    UIGraphicsBeginImageContext(image.size);

    [image drawAtPoint:CGPointMake(0,0)];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, fmax(image.size.width/200, 1));
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    for (int i = 0; i < boxs.size(); i++) {
        BoxInfo box = boxs[i];
        srand(box.label + 2020);
        UIColor *color = [UIColor colorWithRed:rand()%256/255.0f green:rand()%256/255.0f blue:rand()%255/255.0f alpha:1.0f];
        CGContextAddRect(context, CGRectMake(box.x1, box.y1, box.x2 - box.x1, box.y2 - box.y1));
        NSString *label = nil;
        if (self.USE_MODEL == W_NANODET) {
            label = [NSString stringWithFormat:@"%s %.3f", self.nanodet->labels[box.label].c_str(), box.score];
        }
        [label drawAtPoint:CGPointMake(box.x1 + 2, box.y1 - 3) withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20], NSParagraphStyleAttributeName:style, NSForegroundColorAttributeName:color}];
        
        CGContextSetStrokeColorWithColor(context, [color CGColor]);
        CGContextStrokePath(context);
    }
//    CGContextSetStrokeColorWithColor(context, [lineColor CGColor]);
//    CGContextStrokePath(context);
    //创建新图像
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    return newImage;
}


@end


