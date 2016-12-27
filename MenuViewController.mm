// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "MenuViewController.h"
#import "AREL/ExampleARELViewController.h"
//#import "NonAREL/TutorialContentTypes/ContentTypesViewController.h"
#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "myapi.h"
@interface MenuViewController ()
{
    NSString *tutorialId;
    NSString *arelConfigFile;
    AVAudioPlayer *theAudio;
    AVAudioPlayer *mixAudio;
}
@end

@implementation MenuViewController
@synthesize textID;
@synthesize textValue;

@synthesize activityImg;
@synthesize activityImgSmall;
@synthesize tutorialsView;
@synthesize activityIndicator;
@synthesize questionView;

- (void)viewWillAppear:(BOOL)animated
{
    [self loadview];
    
    
}
- (BOOL)loadview {
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"tutorialContent_crossplatform/Menu_map"];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    //NSString *urlString = @"http://7xsiv0.com2.z0.glb.clouddn.com/food/food.html?/";
    //NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    //activityImg.hidden=false;
    
    [tutorialsView loadRequest:requestObj];
}
//透過委派，實作經緯度更新
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
    //第0個位置資訊，表示為最新的位置資訊
    CLLocation * location = [locations objectAtIndex:0];
    
    //取得經緯度資訊，並組合成字串
    NSString * str = [[NSString alloc] initWithFormat:@"緯度:%f, 經度:%f"
                      , location.coordinate.latitude
                      , location.coordinate.longitude];
    
    
    NSString *myreadfs=@"('%@')";
    NSString *ConText = [NSString stringWithFormat:@"%@%@", @"getgps",myreadfs];
    
    
    [tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,str ]];
    
    //顯示在label上
    NSLog(@"經緯度資訊=%@",str);
    
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    
    NSURL* theURL = [request mainDocumentURL];
    NSString* absoluteString = [theURL absoluteString];
    tutorialId = [[absoluteString componentsSeparatedByString:@"="] lastObject];
    
    NSString *urlString = [[request URL] absoluteString];
    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"urlString=%@",urlString);
    NSArray *urlComps = [urlString componentsSeparatedByString:@"://"];
    
    
    
    
    
    if ([[absoluteString lowercaseString] hasPrefix:@"metaiosdkexample://"])
    {//activityImg.hidden=NO;
        /*NSString *value;
         
         textID=@"memory";
         textValue=@"01";
         NSString *str = textValue;
         NSString *string = [NSString stringWithString: str];
         //write
         NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
         value = [data objectForKey:textID];
         [data setObject:string forKey:textID];
         //read
         value = [data objectForKey:textID];
         NSLog(@"this is test:%@",value);*/
        
        //[tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,textID,value ]];
        //UIImage * image1 = [UIImage imageWithContentsOfFile: @"Content_crossplatform/TrackingSamples/Assets/loading_1.png"];
        //UIImageView * myImageView = [[UIImageView alloc] initWithImage: image1];
        //[self.view addSubview:myImageView];
        
        
        if (tutorialId)
        {
            UIViewController* vc = [[UIStoryboard storyboardWithName:tutorialId bundle:nil] instantiateInitialViewController];
            vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:vc animated:NO completion:nil];
            
        }
        return NO;
    }
    
    else  if([[absoluteString lowercaseString] hasPrefix:@"metaiosdkexamplearel://"])
    {
        if (tutorialId)
        {
            arelConfigFile = @"index";
            NSString *tutorialDir = [NSString stringWithFormat:@"tutorialContent_crossplatform/%@", tutorialId];
            NSString *arelConfigFilePath = [[NSBundle mainBundle] pathForResource:arelConfigFile ofType:@"xml" inDirectory:tutorialDir];
            NSLog(@"Will be loading AREL from %@",arelConfigFilePath);
            ExampleARELViewController* tutorialViewController = [[UIStoryboard storyboardWithName:@"AREL" bundle:nil] instantiateInitialViewController];
            tutorialViewController.arelFilePath = arelConfigFilePath;
            tutorialViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:tutorialViewController animated:YES completion:nil];
            if(theAudio.playing){
                [theAudio pause];
            }
            
        }
        return NO;
    }
    
    else  if([[absoluteString lowercaseString] hasPrefix:@"goturpan:///?startmap"])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://w.goturpan.com/home/home.action"]];//外部瀏覽器
        
        return NO;
        
        
        
    }
    else if  ([[absoluteString lowercaseString] rangeOfString:@"setsysvolume"].location != NSNotFound)
    {
        
        
        
       /*
        NSString *urlValue = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"#"] objectAtIndex:1]];
        
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        float value = [numberFormatter numberFromString:urlValue].floatValue;
        
        MPMusicPlayerController *musicPlayerController = [MPMusicPlayerController applicationMusicPlayer];
        musicPlayerController.volume = value;
        
        */
    }
    else if  ([[absoluteString lowercaseString] rangeOfString:@"getsysvolume"].location != NSNotFound)
    {
        
        
        textValue = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        [self  getVolume];
    }
    
    else if ([[absoluteString lowercaseString] rangeOfString:@"audioready"].location != NSNotFound)
    {
        NSString *a = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        NSString *b = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:2]];
        NSString *c = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:3]];
        NSString *feedback = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:4]];
        
        if(!theAudio.playing){
            
            NSString *path = [[NSBundle mainBundle] pathForResource:a
                                                             ofType:b inDirectory:c];
            theAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL
                                                                     fileURLWithPath:path] error:NULL];
            [theAudio prepareToPlay];
            
            [theAudio stop];
        }
        
        
        NSString *pathtype=@".";
        NSString *pathname = [NSString stringWithFormat:@"%@%@%@", a,pathtype,b];
        
        NSString *myreadfs=@"('%@')";
        NSString *ConText = [NSString stringWithFormat:@"%@%@", feedback,myreadfs];
        
        
        [tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,pathname ]];
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"mixready"].location != NSNotFound)
    {
        NSString *a = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        NSString *b = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:2]];
        NSString *c = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:3]];
        NSString *d = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:4]];
        NSString * mixloop = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:5]];
        
        
        NSString *mixpath = [[NSBundle mainBundle] pathForResource:a
                                                            ofType:b inDirectory:c];
        NSInteger loop = [mixloop integerValue];
        mixAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:mixpath] error:NULL];
        
        [mixAudio prepareToPlay];
        mixAudio.numberOfLoops = loop;
        [mixAudio stop];
        
        NSString *pathtype=@".";
        NSString *pathname = [NSString stringWithFormat:@"%@%@%@", a,pathtype,b];
        
        NSString *myreadfs=@"('%@')";
        NSString *ConText = [NSString stringWithFormat:@"%@%@", d,myreadfs];
        
        [tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,pathname ]];
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"mixplay"].location != NSNotFound)
    {
        
        
        [mixAudio play];
        
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"mixplay"].location != NSNotFound)
    {
        
        
        [mixAudio play];
        
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"mixstop"].location != NSNotFound)
    {
        
        mixAudio.currentTime = 0;  //当前播放时间设置为0
        [mixAudio stop];
        
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"audiostatus"].location != NSNotFound)
    {
        NSString *status = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        
        
        if ([[status lowercaseString] rangeOfString:@"stop"].location != NSNotFound)
        {
            if(!theAudio.playing){
                return NO;
            }
            theAudio.currentTime = 0;  //当前播放时间设置为0
            [theAudio stop];
            
        }
        else if ([[status lowercaseString] rangeOfString:@"play"].location != NSNotFound)
        {
            if(theAudio.playing){
                return NO;
            }
            [theAudio play];
            
        }
        else if ([[status lowercaseString] rangeOfString:@"pause"].location != NSNotFound)
        {
            if(!theAudio.playing){
                return NO;
            }
            [theAudio pause];
            
        }
        
    }
    
    else if ([[absoluteString lowercaseString] rangeOfString:@"setaudiotime"].location != NSNotFound)
    {
        NSString *volumestatus = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"#"] objectAtIndex:1]];
        
        float b = [volumestatus floatValue];
        
        
        theAudio.currentTime = b;//可以指定从任意位置开始播放
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"setaudiovolume"].location != NSNotFound)
    {
        NSString *volumestatus = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"#"] objectAtIndex:1]];
        
        float b = [volumestatus floatValue];
        
        theAudio.volume = b;
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"setaudioloops"].location != NSNotFound)
    {
        NSString *volumestatus = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        
        NSInteger b = [volumestatus integerValue];
        
        
        theAudio.numberOfLoops = b;
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"setmixloops"].location != NSNotFound)
    {
        NSString *volumestatus = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        
        NSInteger b = [volumestatus integerValue];
        
        
        mixAudio.numberOfLoops = b;
    }
    
    else if ([[absoluteString lowercaseString] rangeOfString:@"finishapp"].location != NSNotFound)
    {
        // Open in external browser
        
        NSLog(@"finishapp");
        [self exitApplication];
        
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"openurl"].location != NSNotFound)
    {
        // Open in external browser
        
        NSString *uri = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"#"] objectAtIndex:1]];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];//外部瀏覽器
        
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"showmsg"].location != NSNotFound)
    {
        // Open in external browser
        NSString *a = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:1]];
        NSString *b = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:2]];
        NSString *c = [[NSString alloc] initWithString: [[urlString componentsSeparatedByString:@"."] objectAtIndex:3]];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:a message:b delegate:nil cancelButtonTitle:c otherButtonTitles:nil];
        [alert show];
        
        
    }
    
    
    else if ([[absoluteString lowercaseString] rangeOfString:@"writefile"].location != NSNotFound)
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
        NSLog(@"test:%@",ConText);
        NSLog(@"test1:%@",textID);
        NSLog(@"test2:%@",value);
        
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
        NSLog(@"test:%@",ConText);
        NSLog(@"test1:%@",textID);
        NSLog(@"test2:%@",value);
        [tutorialsView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,textID,value ]];
        return NO;
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"wxlogin"].location != NSNotFound)
    {
        
        
        [self wxlogin];
        [self loadview];
        
    }
    else if ([[absoluteString lowercaseString] rangeOfString:@"getlogin"].location != NSNotFound)
    {
     
        
    }
    
    
    /* //偵測網址回到app
     else if ([[absoluteString lowercaseString] rangeOfString:@"www.advmedia.com.tw"].location != NSNotFound)
     {
     //write
     
     NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
     [data setObject:@"yes" forKey:@"keyapp"];
     
     NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"Content_crossplatform/Menu"];
     NSURL *url = [NSURL fileURLWithPath:htmlPath];
     NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
     
     [tutorialsView loadRequest:requestObj];
     return NO;
     
     }
     
     */
    return YES;
}
- (void)  wxlogin
{

}
- (void)  getVolume
{
    /*
    float vol = [[MPMusicPlayerController applicationMusicPlayer] volume];
    
    vol=vol*16;
    
    NSString* Text = [[NSString alloc] initWithFormat:@"%f", vol];
    
    NSString *myreadfs=@"('%@')";
    NSString *ConText = [NSString stringWithFormat:@"%@%@", textValue,myreadfs];*/
    
}
- (void)viewDidLoad
{
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    
    NSString *status=[myapi checknetwork];
    
    if([status isEqual: @"notreach"])
    {
        NSLog(@"notreach");
        [data setObject:@"0" forKey:@"testNetWork"];
    }
    else if ([status isEqual: @"wifi"])
    {
        NSLog(@"wifi");
        [data setObject:@"1" forKey:@"testNetWork"];
    }
    else if ([status isEqual: @"wwan"])
    {
        NSLog(@"wwan");
        [data setObject:@"1" forKey:@"testNetWork"];
    }
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    tutorialsView.delegate = self;
    //建立CLLocationManger，
    //並存於locationManager實體變數中
    locationManager = [[CLLocationManager alloc] init];
    
    //委派予self
    locationManager.delegate = self;
    //设备使用电池供电时候，最高的精度
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    //距离过滤器
    
    locationManager.distanceFilter = 3.0f;
    //詢問授權app權限
    [locationManager requestWhenInUseAuthorization];
    //傳送startUpdatingLocation訊息，
    //開始更新訊息
    [locationManager startUpdatingLocation];
    
}


- (void)viewDidUnload
{
    [self setTutorialsView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
}

- (void)viewActivity
{
    //讀取條開始
    //NSLog(@"log2:%f %f", activityImg.frame.size.width, activityImg.frame.size.height);
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    
    //[activityImg setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    //activityImg.frame = CGRectMake(0,0,width, height);
    //activityImg.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    //self.activityImg.contentMode = UIViewContentModeScaleAspectFit;
    NSLog(@"log1:%f %f", width, height);
    //activityImg.bounds = CGRectMake(0, 0, width, height);
    tutorialsView.hidden=YES;
    activityIndicator.hidden=NO;
    if(width>=400){
        activityImg.hidden=NO;
        activityImgSmall.hidden=YES;
    }
    else{
        activityImgSmall.hidden=NO;
        activityImg.hidden=YES;
    }
    activityIndicator.center=self.view.center;
    
    //activityImg.center=self.view.center;
    [activityIndicator startAnimating];
}
- (void)exitApplication {
    UIViewAnimationTransition transition = UIViewAnimationTransitionCurlUp;
    UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;
    [UIView beginAnimations:@"exitApplication" context:nil];
    
    [UIView setAnimationDuration:0.5];
    
    [UIView setAnimationDelegate:self];
    
    // [UIView setAnimationTransition:UIViewAnimationCurveEaseOut forView:self.view.window cache:NO];
    
    
    [UIView setAnimationTransition:transition forView:[self view] cache:NO];
    [UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
    
    //self.view.window.bounds = CGRectMake(0, 0, 0, 0);
    
    [self view].bounds = CGRectMake(0, 0, 0, 0);
    
    [UIView commitAnimations];
    
}
- (void)animationFinished:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    
    if ([animationID compare:@"exitApplication"] == 0) {
        
        exit(0);
        
    }
    
}

- (void)viewAnimation
{
    
    //動畫開始
    UIViewAnimationTransition transition = UIViewAnimationTransitionCurlUp;
    UIViewAnimationCurve curve = UIViewAnimationCurveEaseInOut;
    [UIView beginAnimations:@"anim" context:NULL];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationTransition:transition forView:[self view] cache:YES];
    [UIView setAnimationDuration:0.5f];
    [UIView commitAnimations];
}
//开始加载数据
-(void)webViewDidStartLoad:(UIWebView *)webView {
    /* //比對正確停止刷屏動畫
     //read
     NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
     NSString *appvalue;
     appvalue = [data objectForKey:@"keyapp"];
     
     NSString * a = appvalue;
     NSString * b = @"no";
     
     if (a == b) {
     
     [self viewActivity];
     
     
     }else
     {
     [self viewActivity];
     [self viewAnimation];
     }
     */
    
    [self viewActivity];
    //[self loading];
    //[self viewAnimation];
    
    
    
}

//数据加载完
-(void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [activityIndicator stopAnimating];
    activityIndicator.hidden=YES;
    activityImg.hidden=YES;
    activityImgSmall.hidden=YES;
    tutorialsView.hidden=NO;
    [self LongPress];
    
}



- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape; //支援橫向
    
    //return  UIInterfaceOrientationMaskPortrait; //支援縱向
    //   return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscape; //支持自動旋轉
}

- (void) loading{
    
}


//强制横屏結束

- (BOOL)shouldAutorotate {
    //是否自動旋轉
    return YES;
}


// Force fullscreen without status bar on iOS 7
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
- (BOOL)LongPress {      //關閉IOS9webview放大鏡
    
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:nil action:NULL];
    longPress.minimumPressDuration = 0.1;
    [tutorialsView addGestureRecognizer:longPress];
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
