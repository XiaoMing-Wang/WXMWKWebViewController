//
//  WXMWKWebViewController.m
//  ModuleDebugging
//
//  Created by edz on 2019/5/8.
//  Copyright © 2019年 wq. All rights reserved.
//
#define KBarHeight (([UIScreen mainScreen].bounds.size.height == 812.0f) ? 88.0f : 64.0f)
#define KWidth [UIScreen mainScreen].bounds.size.width
#define KHeight [UIScreen mainScreen].bounds.size.height
#define COLOR_WITH_HEX(hexValue) \
[UIColor colorWith\
Red:((float)((0x##hexValue & 0xFF0000) >> 16)) / 255.0 \
green:((float)((0x##hexValue & 0xFF00) >> 8)) / 255.0 \
blue:((float)(0x##hexValue & 0xFF)) / 255.0 alpha:1.0f]

#import "WXMWKWebViewController.h"

@interface WXMWKWebViewController ()<WKNavigationDelegate, NSURLSessionDelegate, WKUIDelegate, UIWebViewDelegate>

@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeBtn;           /** 返回按钮 */
@property (nonatomic, strong) UIProgressView *progressView; /** 进度条 */
@property (nonatomic, strong) NSDictionary *parameters;     /** 参数字典 */

@property (nonatomic, assign) CGFloat allProgressFloat; /** 总进度 */
@property (nonatomic, assign) CGFloat speed;            /**  速度 */
@property (nonatomic, assign) BOOL moreSlow;
@property (nonatomic, assign) BOOL isJump;
@property (nonatomic, strong) dispatch_source_t currentTime;
@end

@implementation WXMWKWebViewController {
    CAGradientLayer *_gradientLayer;
    NSURLSession *_session;
}
+ (WXMWKWebViewController *)wkWebViewControllerWithTitle:(NSString *)title
                                               urlString:(NSString *)urlString
                                              parameters:(NSDictionary *)parameters {
    WXMWKWebViewController *wkWebViewController = [[WXMWKWebViewController alloc] init];
    wkWebViewController.navigationItem.title = title;
    wkWebViewController.parameters = parameters;
    wkWebViewController.url = urlString;
    wkWebViewController.wkType = WXMWKWebViewTypeWebpage;
    return wkWebViewController;
}
+ (WXMWKWebViewController *)wkWebViewControllerWithTitle:(NSString *)title urlString:(NSString *)urlString {
    WXMWKWebViewController *wkWebViewController = [[WXMWKWebViewController alloc] init];
    wkWebViewController.navigationItem.title = title;
    wkWebViewController.parameters = nil;
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
    
    _speed = 0.1;
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, KBarHeight + 0.5, KWidth, KHeight - 64)];
    _webView.scrollView.backgroundColor = [UIColor whiteColor];
    _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    @try {
        UIGestureRecognizer * ges = self.navigationController.interactivePopGestureRecognizer;
        [_webView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:ges];
    } @catch (NSException *exception) {} @finally {};
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    [self.view addSubview:_webView];
    
    _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(CloseLeft, 1, 44, 43)];
    _closeBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _closeBtn.titleLabel.font = [UIFont systemFontOfSize:21];
    [_closeBtn setTitle:@"ㄨ" forState:UIControlStateNormal];
    [_closeBtn setTitleColor:CloseColor forState:UIControlStateNormal];
    _closeBtn.hidden = YES;
    
    [self.navigationController.navigationBar addSubview:_closeBtn];
    [self webViewRequestURL];
}

/** 跳转 */
- (void)webViewRequestURL {
    if (self.wkType == WXMWKWebViewTypePost) {
        
    } else if (self.wkType == WXMWKWebViewTypeWebpage) { /**  wk 不带参数网页 */
        NSURL *url = [NSURL URLWithString:_url];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [_webView loadRequest:request];
        
    } else if (self.wkType == WXMWKWebViewTypeLocalHtml) { /**  本地Html */
        NSString *path = [[NSBundle mainBundle] pathForResource:self.url ofType:nil];
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    }
    
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, KBarHeight, KWidth + 3.5, 2)];
    _progressView.transform = CGAffineTransformMakeScale(1.0f, 1.25f);
    _progressView.trackTintColor = [UIColor clearColor];
    _progressView.progressTintColor = [UIColor clearColor];
    [self.view addSubview:_progressView];
    
    _gradientLayer = [CAGradientLayer layer];
    [_progressView.layer addSublayer:_gradientLayer];
    _gradientLayer.cornerRadius = 1.3;
    _gradientLayer.masksToBounds = YES;
    _gradientLayer.frame = CGRectMake(0, 0, 0, 2.6f);
    
    //设置渐变的颜色
    _gradientLayer.colors = @[(__bridge id)[COLOR_WITH_HEX(7530FC) colorWithAlphaComponent:0.0].CGColor,
                              (__bridge id)[COLOR_WITH_HEX(7530FC) colorWithAlphaComponent:0.2].CGColor,
                              (__bridge id)[COLOR_WITH_HEX(7530FC) colorWithAlphaComponent:0.3].CGColor,
                              (__bridge id)[COLOR_WITH_HEX(7530FC) colorWithAlphaComponent:0.5].CGColor,
                              (__bridge id)[COLOR_WITH_HEX(7530FC) colorWithAlphaComponent:0.9].CGColor];
    _gradientLayer.locations = @[@0.0, @0.2, @0.3, @0.5, @0.7];
    _gradientLayer.startPoint = CGPointMake(0, 0.5);
    _gradientLayer.endPoint = CGPointMake(1, 0.5);
    
    
//    /**返回图标 */
//    self.navigationItem.leftBarButtonItem = [UIBarButtonItem barButtonItemWithImageName:@"返回按钮" title: @"" action:^{
//        if (!weakself.webView.canGoBack) [weakself.navigationController popViewControllerAnimated:YES];
//        else {
//            weakself.closeBtn.hidden = NO;
//            [weakself.webView goBack];
//        }
//    }];
}
//页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {}
//当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {}
//页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.canGoBack) self.closeBtn.hidden = NO;
}
//页面加载失败时调用(session请求数据不调用)
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
//    if (!self.autoPage) decisionHandler(WKNavigationActionPolicyAllow);
//    if (self.autoPage) {
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
//        }
//    }
}
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}

/** 倒计时 */
- (void)countdownWithFinish:(BOOL)finish {
    if (finish) [self hideProgressView];
    else {
        self.speed = 0.1;
        self.progressView.hidden = NO;
        
        /**  越来越快 */
        if (_moreSlow == NO) {
            if (self.allProgressFloat >= 0.15) _speed = 0.11;
            if (self.allProgressFloat >= 0.2) _speed = 0.15;
            if (self.allProgressFloat >= 0.3) _speed = 0.19;
            if (self.allProgressFloat >= 0.4) _speed = 0.23;
            if (self.allProgressFloat >= 0.5) _speed = 0.27;
            if (self.allProgressFloat >= 0.6) _speed = 0.31;
            if (self.allProgressFloat >= 0.7) _speed = 0.35;
            if (self.allProgressFloat >= 0.8) _speed = 0.39;
            
        /**  越来越慢(界面没有真正加载完成) */
        } else {
            if (self.allProgressFloat >= 0.15) _speed = 0.39;
            if (self.allProgressFloat >= 0.2) _speed = 0.35;
            if (self.allProgressFloat >= 0.3) _speed = 0.31;
            if (self.allProgressFloat >= 0.4) _speed = 0.27;
            if (self.allProgressFloat >= 0.5) _speed = 0.20;
            if (self.allProgressFloat >= 0.6) _speed = 0.15;
            if (self.allProgressFloat >= 0.7) _speed = 0.10;
            if (self.allProgressFloat >= 0.8) _speed = 0.05;
        }
        
        self.allProgressFloat += _speed;
        [self.progressView setProgress:self.allProgressFloat animated:YES];
        [UIView animateWithDuration:0.11f delay:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect rect = self->_gradientLayer.frame;
            rect.size.width = self.progressView.frame.size.width *self.allProgressFloat;
            self->_gradientLayer.frame = rect;
        } completion:nil];
    }
}
#pragma mark __________________________________________________________________ 观察

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat width = _gradientLayer.frame.size.width;
        
        /** 内容实际已经加载进度 */
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        
        /** 进度条已经加载进度 */
        CGFloat current = ABS(width * 1.0 / _progressView.frame.size.width * 1.0);
        
        /**  瞬间加载完成(越来越慢) */
        /** (newprogress - current)表示跳跃幅度 值太大表示跳动很大 进度条太快不好看 */
        if (newprogress== 1&&(newprogress-current<0.7)&&(newprogress-current>= 0.5)) _moreSlow = YES;
        if (newprogress != 1 && (newprogress - current >= 0.5)) _moreSlow = YES;
        
        if (newprogress >= 1.0) {
            if (current >= (_moreSlow ? 0.899f : 0.79)) [self hideProgressView];
            else {
                __weak typeof(self) weakself = self;
                self.allProgressFloat = current;
                dispatch_queue_t queue = dispatch_get_main_queue();
                self.currentTime = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                dispatch_source_set_timer(self.currentTime, dispatch_walltime(NULL, 0), 0.11f * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(self.currentTime, ^{
                    if (weakself.allProgressFloat >= 1) [weakself countdownWithFinish:YES];
                    if (weakself.allProgressFloat >= 1) dispatch_cancel(weakself.currentTime);;
                    if (weakself.allProgressFloat < 1) [weakself countdownWithFinish:NO];
                });
                dispatch_resume(self.currentTime);
            }
        } else {
            self.progressView.hidden = NO;
            [self.progressView setProgress:newprogress animated:YES];
            [UIView animateWithDuration:(0.1f) delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:^{
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
    
    [UIView animateWithDuration:0.1 delay:0.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
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
    _allProgressFloat = 1;
    [_session invalidateAndCancel];
    [_closeBtn removeFromSuperview];
    [_progressView removeFromSuperview];
    [_gradientLayer removeFromSuperlayer];
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
