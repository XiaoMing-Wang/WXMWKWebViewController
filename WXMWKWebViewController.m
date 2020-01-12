//
//  WXMWKWebViewController.m
//  ModuleDebugging
//
//  Created by edz on 2019/5/8.
//  Copyright © 2019年 wq. All rights reserved.
//

#define KWidth [UIScreen mainScreen].bounds.size.width
#define KHeight [UIScreen mainScreen].bounds.size.height

#import "WXMWKWebViewController.h"

@interface WXMWKWebViewController () <
    WKNavigationDelegate, NSURLSessionDelegate, WKUIDelegate, UIWebViewDelegate>

@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeBtn;           /** 返回按钮 */
@property (nonatomic, strong) UIProgressView *progressView; /** 进度条 */
@property (nonatomic, strong) NSDictionary *parameters;     /** 参数字典 */
@property (nonatomic, assign) CGFloat allProgressFloat;     /** 总进度 */
@property (nonatomic, assign) CGFloat speed;                /**  速度 */
@property (nonatomic, assign) BOOL moreSlow;
@property (nonatomic, assign) BOOL isJump;
@property (nonatomic, strong) dispatch_source_t currentTime;
@end

@implementation WXMWKWebViewController {
    CAGradientLayer *_gradientLayer;
    NSURLSession *_session;
}

+ (WXMWKWebViewController *)wkWebViewController:(NSString *)title urlString:(NSString *)urlString {
    return [self wkWebViewController:title urlString:urlString parameters:nil];
}

+ (WXMWKWebViewController *)wkWebViewController:(NSString *)title
                                      urlString:(NSString *)urlString
                                     parameters:(NSDictionary *)parameters {
    WXMWKWebViewController *wkWebViewController = [[WXMWKWebViewController alloc] init];
    wkWebViewController.navigationItem.title = title;
    wkWebViewController.parameters = parameters;
    wkWebViewController.url = urlString;
    wkWebViewController.wkType = WXMWKWebViewTypeWebpage;
    return wkWebViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    
    self.speed = 0.1;
    CGRect webRect = CGRectMake(0, kNBarHeight + 0.5, KWidth, KHeight - kNBarHeight);
    self.webView = [[WKWebView alloc] initWithFrame:webRect];
    self.webView.scrollView.backgroundColor = [UIColor whiteColor];
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    
    @try {
        UIGestureRecognizer * ges = self.navigationController.interactivePopGestureRecognizer;
        [self.webView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:ges];
    } @catch (NSException *exception) {} @finally {};
        
    
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    [self.view addSubview:self.webView];
    
    
    self.closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(WXMCloseLeft, 1, 44, 43)];
    self.closeBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.closeBtn.titleLabel.font = [UIFont systemFontOfSize:21];
    [self.closeBtn setTitle:@"ㄨ" forState:UIControlStateNormal];
    [self.closeBtn setTitleColor:WXMCloseColor forState:UIControlStateNormal];
    self.closeBtn.hidden = YES;
    [self.navigationController.navigationBar addSubview:self.closeBtn];
    [self webViewRequestURL];
}

/** 跳转 */
- (void)webViewRequestURL {
    if (self.wkType == WXMWKWebViewTypePost) {
        
    /**  wk 不带参数网页 */
    } else if (self.wkType == WXMWKWebViewTypeWebpage) {
        
        NSURL *url = [NSURL URLWithString:self.url];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
        
    /**  本地Html */
    } else if (self.wkType == WXMWKWebViewTypeLocalHtml) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:self.url ofType:nil];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    }
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress"
                      options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title"
                      options:NSKeyValueObservingOptionNew context:nil];
    
    CGRect proRect = CGRectMake(0, kNBarHeight, KWidth + 3.5, 2);
    self.progressView = [[UIProgressView alloc] initWithFrame:proRect];
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.25f);
    self.progressView.trackTintColor = [UIColor clearColor];
    self.progressView.progressTintColor = [UIColor clearColor];
    [self.view addSubview:_progressView];
    
    self->_gradientLayer = [CAGradientLayer layer];
    self->_gradientLayer.cornerRadius = 1.3;
    self->_gradientLayer.masksToBounds = YES;
    self->_gradientLayer.frame = CGRectMake(0, 0, 0, 2.6f);
    [self->_progressView.layer addSublayer:self->_gradientLayer];
    
    /** 设置渐变的颜色 */
    self->_gradientLayer.colors =
    @[(__bridge id)[WXMPregressColor colorWithAlphaComponent:0.0].CGColor,
      (__bridge id)[WXMPregressColor colorWithAlphaComponent:0.2].CGColor,
      (__bridge id)[WXMPregressColor colorWithAlphaComponent:0.3].CGColor,
      (__bridge id)[WXMPregressColor colorWithAlphaComponent:0.5].CGColor,
      (__bridge id)[WXMPregressColor colorWithAlphaComponent:0.9].CGColor];
    self->_gradientLayer.locations = @[@0.0, @0.2, @0.3, @0.5, @0.7];
    self->_gradientLayer.startPoint = CGPointMake(0, 0.5);
    self->_gradientLayer.endPoint = CGPointMake(1, 0.5);
    
    
//    /**返回图标 */
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem barButtonItemWithImageName:@"返回按钮" title: @"" action:^{
//        if (!weakself.webView.canGoBack) [weakself.navigationController popViewControllerAnimated:YES];
//        else {
//            weakself.closeBtn.hidden = NO;
//            [weakself.webView goBack];
//        }
//    }];
}

/** 页面开始加载时调用 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {}

/** 当内容开始返回时调用 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {}

/** 页面加载完成之后调用 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.canGoBack) self.closeBtn.hidden = NO;
}

/** 页面加载失败时调用(session请求数据不调用) */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
//    if (!self.autoPage) {
//        decisionHandler(WKNavigationActionPolicyAllow);
//    } else {
//        NSString *url = [navigationAction.request.URL.absoluteString stringByRemovingPercentEncoding];
//        if (self.isJump || [self.url isEqualToString:url] || !self.loadFinash) {
//            decisionHandler(WKNavigationActionPolicyAllow);
//        } else {
//            self.isJump = YES;
//            WKWebViewController * wk = [WKWebViewController wkWebViewControllerWithTitle:@"" urlString:url];
//            wk.wkType = WKWebViewTypeWebpage;
//            wk.autoGetTitle = YES;
//            wk.autoPaging = self.autoPaging;
//            KPushController(wk);
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                self.isJump = NO;
//            });
//            decisionHandler(WKNavigationActionPolicyCancel);
//            decisionHandler(WKNavigationActionPolicyAllow);
//        }
//    }
}

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                            NSURLCredential *credential))completionHandler{
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        NSURLCredential *card =
        [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}

/** 倒计时 */
- (void)countdownWithFinish:(BOOL)finish {
    if (finish) {
        [self hideProgressView];
    } else {
        self.speed = 0.1;
        self.progressView.hidden = NO;
        
        /**  越来越快 */
        if (self.moreSlow == NO) {
            if (self.allProgressFloat >= 0.15) self.speed = 0.11;
            if (self.allProgressFloat >= 0.2) self.speed = 0.15;
            if (self.allProgressFloat >= 0.3) self.speed = 0.19;
            if (self.allProgressFloat >= 0.4) self.speed = 0.23;
            if (self.allProgressFloat >= 0.5) self.speed = 0.27;
            if (self.allProgressFloat >= 0.6) self.speed = 0.31;
            if (self.allProgressFloat >= 0.7) self.speed = 0.35;
            if (self.allProgressFloat >= 0.8) self.speed = 0.39;
            
        /**  越来越慢(界面没有真正加载完成) */
        } else {
            if (self.allProgressFloat >= 0.15) self.speed = 0.39;
            if (self.allProgressFloat >= 0.2) self.speed = 0.35;
            if (self.allProgressFloat >= 0.3) self.speed = 0.31;
            if (self.allProgressFloat >= 0.4) self.speed = 0.27;
            if (self.allProgressFloat >= 0.5) self.speed = 0.20;
            if (self.allProgressFloat >= 0.6) self.speed = 0.15;
            if (self.allProgressFloat >= 0.7) self.speed = 0.10;
            if (self.allProgressFloat >= 0.8) self.speed = 0.05;
        }
        
        self.allProgressFloat += self.speed;
        [self.progressView setProgress:self.allProgressFloat animated:YES];
        [UIView animateWithDuration:0.11f delay:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect rect = self->_gradientLayer.frame;
            rect.size.width = self.progressView.frame.size.width *self.allProgressFloat;
            self->_gradientLayer.frame = rect;
        } completion:nil];
    }
}

/** 观察 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat width = self->_gradientLayer.frame.size.width;
        
        /** 真实进度 */
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        
        /** 进度条进度 */
        CGFloat current = ABS(width * 1.0 / self->_progressView.frame.size.width * 1.0);
        
        /**  瞬间加载完成(越来越慢) */
        /** (newprogress - current)表示跳跃幅度 值太大表示跳动很大 进度条太快不好看 */
        if (newprogress == 1 && (newprogress - current < 0.7) && (newprogress - current >= 0.5))  {
            self.moreSlow = YES;
        } else if (newprogress != 1 && (newprogress - current >= 0.5))  {
            self.moreSlow = YES;
        }
        
        if (newprogress >= 1.0) {
            if (current >= (self.moreSlow ? 0.899f : 0.79)) {
                [self hideProgressView];
            } else {
                __weak typeof(self) self_weak = self;
                dispatch_time_t start = dispatch_walltime(NULL, 0);
                dispatch_queue_t queue = dispatch_get_main_queue();
                self.allProgressFloat = current;
                self.currentTime = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                dispatch_source_set_timer(self.currentTime, start , 0.11f * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(self.currentTime, ^{
                    if (self_weak.allProgressFloat >= 1) [self_weak countdownWithFinish:YES];
                    if (self_weak.allProgressFloat >= 1) dispatch_cancel(self_weak.currentTime);;
                    if (self_weak.allProgressFloat < 1) [self_weak countdownWithFinish:NO];
                });
                dispatch_resume(self.currentTime);
            }
        } else {
            
            self.progressView.hidden = NO;
            [self.progressView setProgress:newprogress animated:YES];
            UIViewAnimationOptions option = UIViewAnimationOptionCurveEaseOut;
            [UIView animateWithDuration:(0.1f) delay:0.1f options:option animations:^{
                CGRect rect = self->_gradientLayer.frame;
                rect.size.width = self.progressView.frame.size.width *newprogress;
                self->_gradientLayer.frame = rect;
            } completion:nil];
        }
    }
    
   /** 标题 */
    if ([keyPath isEqualToString:@"title"] && _autoGetTitle) {
        NSString *title = change[NSKeyValueChangeNewKey];
        BOOL isLeng = title.length >= 15;
        if (isLeng) title = [title substringToIndex:15];
        self.navigationItem.title = title;
        if (title && isLeng) self.navigationItem.title = [title stringByAppendingString:@"..."];
        if (!title) self.navigationItem.title = @"";
    }
}

/** 隐藏进度条 */
- (void)hideProgressView {
    self.moreSlow = NO;
    [_progressView setProgress:1.0 animated:YES];
    CGRect rect = self->_gradientLayer.frame;
    rect.size.width = _progressView.frame.size.width;
    self->_gradientLayer.frame = rect;
    
    UIViewAnimationOptions option = UIViewAnimationOptionCurveEaseOut;
    [UIView animateWithDuration:0.1 delay:0.35 options:option animations:^{
        self->_progressView.alpha = 0;
    } completion:^(BOOL finished) {
        CGRect rect = self->_gradientLayer.frame;
        rect.size.width = 0;
        self->_gradientLayer.frame = rect;
        [self->_progressView setProgress:0 animated:NO];
        self->_progressView.hidden = YES;
        self->_progressView.alpha = 1;
    }];
}

- (void)removeProgressView {
    self.allProgressFloat = 1;
    [self.closeBtn removeFromSuperview];
    [self.progressView removeFromSuperview];
    [self->_session invalidateAndCancel];
    [self->_gradientLayer removeFromSuperlayer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
     self.closeBtn.alpha = 0;
    [UIApplication sharedApplication].statusBarStyle = self.statusBarStyle;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.closeBtn.alpha = 1;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeProgressView];
}

- (void)dealloc {
    @try {
        [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
        [_webView removeObserver:self forKeyPath:@"title"];
    }@catch (NSException *exception) {} @finally {};
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
