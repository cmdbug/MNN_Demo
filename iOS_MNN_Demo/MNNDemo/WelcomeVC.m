//
//  WelcomeVC.m
//  MNNDemo
//
//  Created by WZTENG on 2020/9/2.
//  Copyright © 2020 TENG. All rights reserved.
//

#import "WelcomeVC.h"
#import "ViewController.h"

@interface WelcomeVC ()

@property (strong, nonatomic) IBOutlet UIButton *btnNanoDet;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *boxView;

@property (strong, nonatomic) UIButton *btnRight;

@property (assign, nonatomic) Boolean useGPU;

@end

@implementation WelcomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    
    self.title = @"WZTENG";
}

- (void)changeMode {
    self.useGPU = NO;

    self.btnRight = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btnRight.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.btnRight setImage:[UIImage imageNamed:@"mode_cpu"] forState:UIControlStateNormal];
    [self.btnRight addTarget:self action:@selector(changeNcnnMode) forControlEvents:UIControlEventTouchUpInside];
    [self.btnRight.widthAnchor constraintEqualToConstant:45].active = YES;
    [self.btnRight.heightAnchor constraintEqualToConstant:30].active = YES;
    UIBarButtonItem *barRight = [[UIBarButtonItem alloc] initWithCustomView:self.btnRight];
    self.navigationItem.rightBarButtonItem = barRight;
}

- (void)changeNcnnMode {
    self.useGPU = self.useGPU ? NO : YES;
    NSString *title = @"Warning";
    NSString *message = @"ohhhhh";
    if (self.useGPU) {
        [self.btnRight setImage:[UIImage imageNamed:@"mode_gpu"] forState:UIControlStateNormal];
        title = @"Warning";
        message = @"If the GPU is too old, it may not work well in GPU mode.";
    } else {
        [self.btnRight setImage:[UIImage imageNamed:@"mode_cpu"] forState:UIControlStateNormal];
        title = @"Warning";
        message = @"Run on CPU mode.";
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:sure];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)initView {
    [self changeMode];
    
    int btnWidth = self.view.bounds.size.width;
    int offsetY = self.view.bounds.size.width * 0.6f;
    int btnHeight = 35;
    int btnY = 35;
    int btnCount = 1;
    int i = 0;
    
    self.boxView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, offsetY + btnHeight * btnCount)];
//    self.boxView.backgroundColor = [UIColor redColor];

    UIImageView *tipImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, btnWidth, offsetY)];
    tipImageView.image = [UIImage imageNamed:@"ohhh"];
    tipImageView.contentMode = UIViewContentModeScaleToFill;
    [self.boxView addSubview:tipImageView];
        
    _btnNanoDet = [[UIButton alloc] initWithFrame:CGRectMake(0, offsetY + btnY * i++, btnWidth, btnHeight)];
    [_btnNanoDet setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_btnNanoDet setTitle:@"NanoDet" forState:UIControlStateNormal];
    [_btnNanoDet addTarget:self action:@selector(pressNanoDet:) forControlEvents:UIControlEventTouchUpInside];
    [self.boxView addSubview:_btnNanoDet];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.contentSize = self.boxView.frame.size;
    [self.scrollView addSubview:self.boxView];
    [self.view addSubview:self.scrollView];
    
}

- (void)pressNanoDet:(UIButton *)btn {
    ViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    vc.USE_MODEL = W_NANODET;
    vc.USE_GPU = self.useGPU;
    [self.navigationController pushViewController:vc animated:NO];
}


@end
