//
//  OatuController.m
//  新浪微博
//
//  Created by apple on 13-10-30.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "OauthController.h"
#import "Weibocfg.h"
#import "HttpTool.h"
#import "AccountTool.h"
#import "MBProgressHUD.h"
#import "ViewController.h"

@interface OauthController () <UIWebViewDelegate>
{
    UIWebView *_webView;
}
@end

@implementation OauthController

- (void)loadView
{
    _webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = _webView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1.加载登录页面（获取未授权的Request Token）
    // https  http
    NSString *urlStr = [kAuthorizeURL stringByAppendingFormat:@"?display=mobile&client_id=%@&redirect_uri=%@", kAppKey, kRedirectURI];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    
    // 2.设置代理
    _webView.delegate = self;
}

#pragma mark - webview代理方法
#pragma mark 当webView开始加载请求就会调用
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // 显示指示器
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"正在加载中...";
    hud.dimBackground = YES;
}

#pragma mark 当webView请求完毕就会调用
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

#pragma mark 拦截webView的所有请求
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // 1.获得全路径
    NSString *urlStr = request.URL.absoluteString;
    
    // 2.查找code=的范围
    NSRange range = [urlStr rangeOfString:@"code="];
    
    if (range.length != 0) { // 跳到“回调地址”，说明已经授权成功
        int index = range.location + range.length;
        NSString *requestToken = [urlStr substringFromIndex:index];
        
        // 3.换取accessToken
        [self getAccessToken:requestToken];
        NSLog(@"11111");
        return NO;
    }
    return YES;
}

#pragma mark 换取accessToken
- (void)getAccessToken:(NSString *)requestToken
{
    [HttpTool postWithPath:@"oauth2/access_token" params:@{
         @"client_id" : kAppKey,
         @"client_secret" : kAppSecret,
         @"grant_type" : @"authorization_code",
         @"redirect_uri" : kRedirectURI,
         @"code" : requestToken
     } success:^(id JSON) {
         // 保存账号信息
         Account *account = [[Account alloc] init];
         account.accessToken = JSON[@"access_token"];
         account.uid = JSON[@"uid"];
         [[AccountTool sharedAccountTool] saveAccount:account];
         
         // 回到主页面
         self.view.window.rootViewController = [[ViewController alloc] init];
         
         // 清除指示器
         [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
     } failure:^(NSError *error) {
         // 清除指示器
         [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
     }];
}

@end
