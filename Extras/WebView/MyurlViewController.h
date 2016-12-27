// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import <UIKit/UIKit.h>

@interface MyurlViewController : UIViewController<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *tutorialsView;
@property (nonatomic, retain) NSString *textID;
@property (nonatomic, retain) NSString *textValue;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
//@property (strong, nonatomic) IBOutlet UIProgressView*   progressView;
@end
