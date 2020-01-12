//
//  WXMWKWebViewController.h
//  ModuleDebugging
//
//  Created by edz on 2019/5/8.
//  Copyright © 2019年 wq. All rights reserved.
//

/** iphoneX */
#define kIPhoneX \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);\
})

#define kNBarHeight ((kIPhoneX) ? 88.0f : 64.0f)
#define COLOR_WITH_HEX(hexValue) \
[UIColor colorWith\
Red:((float)((0x##hexValue & 0xFF0000) >> 16)) / 255.0 \
green:((float)((0x##hexValue & 0xFF00) >> 8)) / 255.0 \
blue:((float)(0x##hexValue & 0xFF)) / 255.0 alpha:1.0f]

/** 进度条颜色 */
#define WXMPregressColor COLOR_WITH_HEX(00BFFF)

/** 关闭颜色 */
#define WXMCloseColor [UIColor blueColor]

/** 左边距离 */
#define WXMCloseLeft 100

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, WXMWKWebViewType) {

    /** 网页 默认 */
    WXMWKWebViewTypeWebpage = 0,

    /** 请求 */
    WXMWKWebViewTypePost,

    /** 本地Html */
    WXMWKWebViewTypeLocalHtml,
};

@interface WXMWKWebViewController : UIViewController
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) WXMWKWebViewType wkType;

/** 自动获取标题 */
@property (nonatomic, assign) BOOL autoGetTitle;

/** 自动翻页 不在当页加载 */
@property (nonatomic, assign) BOOL autoPage;

+ (WXMWKWebViewController *)wkWebViewController:(NSString *)title urlString:(NSString *)urlString;
+ (WXMWKWebViewController *)wkWebViewController:(NSString *)title
                                      urlString:(NSString *)urlString
                                     parameters:(NSDictionary *)parameters;
@end
