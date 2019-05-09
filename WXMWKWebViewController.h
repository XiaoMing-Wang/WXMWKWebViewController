//
//  WXMWKWebViewController.h
//  ModuleDebugging
//
//  Created by edz on 2019/5/8.
//  Copyright © 2019年 wq. All rights reserved.
//
#define CloseColor [UIColor blueColor]
#define CloseLeft 100
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, WXMWKWebViewType) {
    WXMWKWebViewTypePost = 0,  /** 请求 */
    WXMWKWebViewTypeWebpage,   /** 网页 默认 */
    WXMWKWebViewTypeLocalHtml, /** 本地Html */
};

@interface WXMWKWebViewController : UIViewController
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) WXMWKWebViewType wkType;
@property (nonatomic, assign) BOOL autoGetTitle;
@property (nonatomic, assign) BOOL autoPage;

+ (WXMWKWebViewController *)wkWebViewControllerWithTitle:(NSString *)title urlString:(NSString *)urlString;
+ (WXMWKWebViewController *)wkWebViewControllerWithTitle:(NSString *)title
                                               urlString:(NSString *)urlString
                                              parameters:(NSDictionary *)parameters;
@end
