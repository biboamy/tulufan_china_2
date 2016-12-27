// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "MyurlViewController.h"


@interface MyurlViewController ()

@end

@implementation MyurlViewController
@synthesize tutorialsView;
@synthesize textID;
@synthesize textValue;
@synthesize activityIndicator;
//@synthesize progressView;
- (void)viewWillAppear:(BOOL)animated
{
    //tutorialsView.scalesPageToFit =YES;
    
    //傳值
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    NSString *myname;
    myname = [data objectForKey:@"urlkeyname"];
    NSString *mytype;
    mytype = [data objectForKey:@"urlkeytype"];
    NSString *mydir;
    mydir = [data objectForKey:@"urlkeydir"];
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:myname ofType:mytype inDirectory:mydir];
    
  

    if ([[myname lowercaseString] isEqualToString:@"online"]&&[[mytype lowercaseString] isEqualToString:@"link"])
    {
        
        
        NSURL *url = [NSURL URLWithString:mydir];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        [tutorialsView loadRequest:requestObj];
        
        
    }
    else
        //   else if ([[myname lowercaseString] hasPrefix:@"index"])
    {
       /*脫機*/
        NSURL *url = [NSURL fileURLWithPath:htmlPath];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        /*顯示*/
        [tutorialsView loadRequest:requestObj];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* theURL = [request mainDocumentURL];
    NSString* absoluteString = [theURL absoluteString];
    NSArray *components = [absoluteString componentsSeparatedByString:@":"];
    
    NSString *urlString = [[request URL] absoluteString];
    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if ([[absoluteString lowercaseString] rangeOfString:@"finishapp"].location != NSNotFound){
    [self dismissViewControllerAnimated:YES completion:nil];// 直到找到最底层为止
    }
     else if ([[absoluteString lowercaseString] rangeOfString:@"openurl"].location != NSNotFound)
     {
         NSString *uri = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"#"] objectAtIndex:1]];
         
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];//外部瀏覽器
     }
     else if ([[absoluteString lowercaseString] rangeOfString:@"writefile"].location != NSNotFound)//寫入檔案
     {
         // Open in external browser
         NSString *mykey = [[NSString alloc] initWithString: [[absoluteString componentsSeparatedByString:@"."] objectAtIndex:1]];
         
         NSString *mykeyvalue = [[NSString alloc] initWithString: [[absoluteString componentsSeparatedByString:@"."] objectAtIndex:2]];
         
         NSString *myfs = [[NSString alloc] initWithString: [[absoluteString componentsSeparatedByString:@"."] objectAtIndex:3]];
         
         NSString *myreadfs=@"('%@','%@')";
         NSString *ConText = [NSString stringWithFormat:@"%@%@", myfs,myreadfs];
         
         textID=mykey;
         textValue=mykeyvalue;
         NSString *str = textValue;
         NSString *string = [NSString stringWithString: str];
         //write
         NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
         [data setObject:string forKey:textID];
         //read
         NSString *value;
         value = [data objectForKey:textID];
         
         [tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,textID,value ]];
         
         return NO;
         
         
     }
     else if ([[absoluteString lowercaseString] rangeOfString:@"readfile"].location != NSNotFound)
     {
         // Open in external browser
         NSString *mykey = [[NSString alloc] initWithString: [[absoluteString componentsSeparatedByString:@"."] objectAtIndex:1]];
         
         NSString *myfs = [[NSString alloc] initWithString: [[absoluteString componentsSeparatedByString:@"."] objectAtIndex:2]];
         
         textID=mykey;
         
         NSString *myreadfs=@"('%@','%@')";
         NSString *ConText = [NSString stringWithFormat:@"%@%@", myfs,myreadfs];
         
         //read
         NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
         NSString *value;
         value = [data objectForKey:textID];
         [tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,textID,value ]];
         
         
         
         return NO;
         
         
     }
   
    
    return YES;
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    tutorialsView.delegate = self;
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidUnload
{
    [self setTutorialsView:nil];
    [super viewDidUnload];
    //Release any retained subviews of the main view.
}




//开始加载数据
-(void)webViewDidStartLoad:(UIWebView *)webView {
    activityIndicator.hidden=NO;
    activityIndicator.center=self.view.center;
    [activityIndicator startAnimating];
}

//数据加载完
-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [activityIndicator stopAnimating];
    activityIndicator.hidden=YES;
}

// Force fullscreen without status bar on iOS 7
- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
   // return UIInterfaceOrientationMaskLandscape; //支援橫向
    
    return  UIInterfaceOrientationMaskPortrait; //支援縱向
    
    //return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscape; //支持自動旋轉
}


//强制横屏結束

- (BOOL)shouldAutorotate {      //是否自動旋轉
    
    return YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
