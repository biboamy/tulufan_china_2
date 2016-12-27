// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "LocationBasedARViewController.h"
//#import "SphereMenu.h"
#import "myapi.h"
#import "AppDelegate.h"
#import "ASImageSharingViewController.h"

@interface LocationBasedARViewController ()<NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSURLSessionDownloadTask * task;
@end

@implementation LocationBasedARViewController

@synthesize readvalue;

-(void) becomeActive
{
    downloadTest=1;
    [self modelDownload];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    [data setObject:@"0" forKey:@"testIn"];
    
    downloadTest=1;
    
    [self createProgress];
    
    [self testNetwork];
    
    
    NSString *value;
    
    NSString* textID=@"firstTime";
    NSString* textValue=@"01";
    NSString *str = textValue;
    NSString *string = [NSString stringWithString: str];
    
    value = [data objectForKey:textID];
    
    const char *cString = [value cStringUsingEncoding:NSASCIIStringEncoding];
    
    if(cString!=NULL){
        NSLog(@"this is test:%@",value);
        testFirstTime=1;
    }
    else{
        [data setObject:string forKey:textID];
        NSLog(@"first time");
        testFirstTime=0;
    }
    
    //test screen
    if(([[UIScreen mainScreen] bounds].size.width)>900)
        testScreen=1;
    else
        testScreen=0;
    
    
    enable = 0;
    
    [self getJson];
    
    NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
    NSString *value1 = [data1 objectForKey:@"testIn"];
    
    NSLog(@"value:%@",value1);
    
    //下載休眠
    if(top_title==NULL && [value1 caseInsensitiveCompare:@"1"]!=0) [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(becomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

//load check track
-(void) loadCheckTrack
{
    NSString* blackBack_model = [[NSBundle mainBundle] pathForResource:@"bg"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (blackBack_model)
    {
        const char *utf8Path = [blackBack_model UTF8String];
        blackBack = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        blackBack->setCoordinateSystemID(0);
        blackBack->setScale(5.0f);
        blackBack->setRelativeToScreen(48,8);
        blackBack->setTransparency(0.2);
        blackBack->setRenderOrder(18);
        blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 2.0f));
        blackBack->setVisible(true);
    }
    
    
    
    NSString* checkPanelPath = [[NSBundle mainBundle] pathForResource:@"trackBg"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (checkPanelPath)
    {
        const char *utf8Path = [checkPanelPath UTF8String];
        checkPanel = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        checkPanel->setScale(2.0f);
        checkPanel->setVisible(true);
        checkPanel->setRenderOrder(20);
        checkPanel->setRelativeToScreen(48,8);
        checkPanel->setTranslation(metaio::Vector3d(0.0f, 0.0f,3.0f));
    }
    NSString* trackEnterPath = [[NSBundle mainBundle] pathForResource:@"trackEnter"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (trackEnterPath)
    {
        const char *utf8Path = [trackEnterPath UTF8String];
        trackEnter = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        trackEnter->setScale(0.35f);
        trackEnter->setVisible(true);
        trackEnter->setRelativeToScreen(48,8);
        trackEnter->setRenderOrder(21);
        trackEnter->setTranslation(metaio::Vector3d(-80.0f, -60.0f, 4.0f));
    }
    NSString* trackDownloadPath = [[NSBundle mainBundle] pathForResource:@"trackDownload"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (trackDownloadPath)
    {
        const char *utf8Path = [trackDownloadPath UTF8String];
        trackDownload = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        trackDownload->setScale(0.35f);
        trackDownload->setVisible(true);
        trackDownload->setRenderOrder(21);
        trackDownload->setRelativeToScreen(48,8);
        trackDownload->setTranslation(metaio::Vector3d(80.0f, -60.0f, 4.0f));
    }
    [self loadingView];
}

//load image
-(void) loadingView
{
    NSString* shutterSound_model = [[NSBundle mainBundle] pathForResource:@"shutter"
                                                                   ofType:@"3g2"
                                                              inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(shutterSound_model)
    {
        const char *utf8Path = [shutterSound_model UTF8String];
        shutterSound =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), true); // true for transparent movie
    }
    
    
    const char *utf8PathConf = [modelPath[3] UTF8String];
    NSLog(@"load:%s ",utf8PathConf);
    bool success = m_pMetaioSDK->setTrackingConfiguration(metaio::Path::fromUTF8(utf8PathConf));
    if( !success)
        NSLog(@"No success loading the tracking configuration");
    
    
    NSString* finder_model = [[NSBundle mainBundle] pathForResource:@"xk"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (finder_model)
    {
        const char *utf8Path = [finder_model UTF8String];
        finder = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        finder->setCoordinateSystemID(0);
        finder->setScale(2.3f);
        finder->setRelativeToScreen(48,8);
        if(testFirstTime==1){
            finder->setVisible(true);
        }
        else{
            finder->setVisible(false);
        }
    }
    
    NSString* downloadTicket_model = [[NSBundle mainBundle] pathForResource:@"downloadTicket"
                                                                     ofType:@"jpg"
                                                                inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (downloadTicket_model)
    {
        const char *utf8Path = [downloadTicket_model UTF8String];
        downloadTicket = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        downloadTicket->setCoordinateSystemID(0);
        downloadTicket->setScale(0.40f);
        downloadTicket->setRenderOrder(4);
        downloadTicket->setRelativeToScreen(10,8);
        downloadTicket->setVisible(true);
        downloadTicket->setTranslation(metaio::Vector3d(0.0f, 0.0f, 1.0f));
        if(downloadTicket) NSLog(@"yes");
        else NSLog(@"no");
    }
    
    //load guide
    NSString* guideSound_model = [[NSBundle mainBundle] pathForResource:@"guide0"
                                                                 ofType:@"mp3"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(guideSound_model)
    {
        const char *utf8Path = [guideSound_model UTF8String];
        guideSound =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);;
        guideSound->setCoordinateSystemID(0);
    }
    
    // load the box
    
    const char *utf8Path = [modelPath[0] UTF8String];
    track_stuff =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(utf8Path));
    track_stuff->setScale(54.f);
    
    //load sapan sound guide
    const char *sapan_Path = [modelPath[4] UTF8String];
    sapan1 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan_Path));
    sapan1->setScale(25.0f);
    sapan1->setVisible(false);
    sapan1->setCoordinateSystemID(1);
    
    const char *sapan2_Path = [modelPath[5] UTF8String];
    sapan2 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan2_Path));
    sapan2->setScale(25.0f);
    sapan2->setVisible(false);
    sapan2->setCoordinateSystemID(1);
    
    const char *sapan3_Path = [modelPath[6] UTF8String];
    sapan3 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan3_Path));
    sapan3->setScale(25.0f);
    sapan3->setVisible(false);
    sapan3->setCoordinateSystemID(1);
    
    const char *sapan4_Path = [modelPath[7] UTF8String];
    sapan4 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan4_Path));
    sapan4->setScale(25.0f);
    sapan4->setVisible(false);
    sapan4->setCoordinateSystemID(1);
    
    const char *sapan5_Path = [modelPath[8] UTF8String];
    sapan5 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan5_Path));
    sapan5->setScale(25.0f);
    sapan5->setVisible(false);
    sapan5->setCoordinateSystemID(1);
    
    const char *sapan6_Path = [modelPath[9] UTF8String];
    sapan6 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan6_Path));
    sapan6->setScale(25.0f);
    sapan6->setVisible(false);
    sapan6->setCoordinateSystemID(1);
    
    const char *sapan7_Path = [modelPath[10] UTF8String];
    sapan7 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan7_Path));
    sapan7->setScale(25.0f);
    sapan7->setVisible(false);
    sapan7->setCoordinateSystemID(1);
    
    const char *sapan8_Path = [modelPath[11] UTF8String];
    sapan8 =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(sapan8_Path));
    sapan8->setScale(25.0f);
    sapan8->setVisible(false);
    sapan8->setCoordinateSystemID(1);
    
    const char *line_Path = [modelPath[12] UTF8String];
    line =  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(line_Path));
    line->setScale(25.0f);
    line->setVisible(false);
    line->setCoordinateSystemID(1);
    
    NSString* topTitle_model = [[NSBundle mainBundle] pathForResource:@"top"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (topTitle_model)
    {
        const char *utf8Path = [topTitle_model UTF8String];
        top_title = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        top_title->setCoordinateSystemID(0);
        top_title->setScale(0.41f);
        top_title->setRelativeToScreen(10,8);
    }
    NSString* footer_model = [[NSBundle mainBundle] pathForResource:@"foot"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (footer_model)
    {
        const char *utf8Path = [footer_model UTF8String];
        footer = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        footer->setCoordinateSystemID(0);
        footer->setScale(0.4f);
        footer->setRelativeToScreen(20,8);
    }
    NSString* back_model = [[NSBundle mainBundle] pathForResource:@"fh"
                                                           ofType:@"png"
                                                      inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (back_model)
    {
        const char *utf8Path = [back_model UTF8String];
        back_btn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        back_btn->setCoordinateSystemID(0);
        back_btn->setScale(0.41f);
        back_btn->setRelativeToScreen(9,8);
        back_btn->setRenderOrder(2,false,true);
    }
    NSString* camara_model = [[NSBundle mainBundle] pathForResource:@"cam"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (camara_model)
    {
        const char *utf8Path = [camara_model UTF8String];
        picture_taken = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        picture_taken->setCoordinateSystemID(0);
        picture_taken->setScale(0.4f);
        picture_taken->setRenderOrder(3);
        picture_taken->setRelativeToScreen(20,8);
        if(testFirstTime==1){
            picture_taken->setVisible(true);
        }
        else{
            picture_taken->setVisible(false);
        }
        picture_taken->setTranslation(metaio::Vector3d(0.0f, 50.0f, 0.0f));
    }
    
    NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (texturePath)
    {
        const char *utf8Path = [texturePath UTF8String];
        textBg = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        textBg->setCoordinateSystemID(0);
        textBg->setScale(0.8);
        textBg->setRelativeToScreen(20,8);
        textBg->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
        textBg->setRenderOrder(40);
        textBg->setVisible(false);
    }
    
    if(textBg)
    {
        if(loadingImage!=NULL)loadingImage->setVisible(false);
        if(loadingPicture!=NULL)loadingPicture->setVisible(false);
        if(loadingModel!=NULL)loadingModel->setVisible(false);
    }
    
    
}
//loadingView end

#pragma mark - App Logic

- (void) onTrackingEvent: (const metaio::stlcompat::Vector<metaio::TrackingValues>&) trackingValues
{
    if (trackingValues.empty() || !trackingValues[0].isTrackingState())
    {
        finder->setVisible(true);
        track_stuff->setVisible(false);
    }
    else if(testEnter==1)
    {
        if (track_stuff)
        {
            finder->setVisible(false);
            track_stuff->setVisible(true);
            track_stuff->startAnimation("ani_appear" , false);
        }
    }
}

- (void)onSDKReady
{
    [super onSDKReady];
}

-(void) testNetwork
{
    //側網路狀態
    NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
    NSString *value1 = [data1 objectForKey:@"testNetWork"];
    if([value1 caseInsensitiveCompare:@"0"]==0) testNetWork=0;
    else testNetWork=1;
}

-(void) getJson
{
    NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
    
    if(testNetWork==1){
        
        NSString *ConText = @"http://app.cqplayart.cn/assets/jsonvalue_beta.php";//get json url
        
        NSURL *url = [NSURL URLWithString:ConText];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSData* data_json = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];//將json存入data中
        NSDictionary* jsonObj =
        [NSJSONSerialization JSONObjectWithData:data_json
                                        options:NSJSONReadingMutableContainers   error:nil];
        
        
        //model data
        NSArray *sapan = [[jsonObj objectForKey:@"ticket"] valueForKey:@"sapan"];
        [data1 setObject:sapan[0] forKey:@"sapan"];
        NSArray *track1 = [[jsonObj objectForKey:@"ticket"] valueForKey:@"track1"];
        [data1 setObject:track1[0] forKey:@"track1"];
        NSArray *track2 = [[jsonObj objectForKey:@"ticket"] valueForKey:@"track2"];
        [data1 setObject:track2[0] forKey:@"track2"];
        NSArray *trackConf = [[jsonObj objectForKey:@"ticket"] valueForKey:@"trackConfig"];
        [data1 setObject:trackConf[0] forKey:@"trackConfig"];
        
        //sapan data
        NSArray *sapanData;
        int i;
        for(i=4; i<13; i++)
        {
            sapanData = [[jsonObj objectForKey:@"ticket"] valueForKey:[NSString stringWithFormat:@"sapan%i", i-3]];
            [data1 setObject:sapanData[0] forKey:[NSString stringWithFormat:@"sapan%i", i-3]];
        }
        NSArray *guideData;
        for(i=13; i<21; i++)
        {
            guideData = [[jsonObj objectForKey:@"guide"] valueForKey:[NSString stringWithFormat:@"guide%i", i-12]];
            [data1 setObject:guideData[0] forKey:[NSString stringWithFormat:@"guide%i", i-12]];
        }
        
        model[0] = [data1 objectForKey:@"sapan"];
        NSLog(@"%@",model[0]);
        
        model[1] = [data1 objectForKey:@"track1"];
        NSLog(@"%@",model[1]);
        
        model[2] = [data1 objectForKey:@"track2"];
        NSLog(@"%@",model[2]);
        
        model[3] = [data1 objectForKey:@"trackConfig"];
        NSLog(@"%@",model[3]);
        
        for(i=4; i<13; i++)
        {
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"sapan%i", i-3]];
            NSLog(@"%@",model[i]);
        }
        for(i=13; i<21; i++)
        {
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"guide%i", i-12]];
            NSLog(@"%@",model[i]);
        }
    }
    else
    {
        model[0] = [data1 objectForKey:@"sapan"];
        NSLog(@"%@",model[0]);
        
        model[1] = [data1 objectForKey:@"track1"];
        NSLog(@"%@",model[1]);
        
        model[2] = [data1 objectForKey:@"track2"];
        NSLog(@"%@",model[2]);
        
        model[3] = [data1 objectForKey:@"trackConfig"];
        NSLog(@"%@",model[3]);
        
        int i;
        for(i=4; i<13; i++)
        {
            model[i+4] = [data1 objectForKey:[NSString stringWithFormat:@"sapan%i", i-3]];
            NSLog(@"%@",model[i]);
        }
        for(i=13; i<21; i++)
        {
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"guide%i", i-12]];
            NSLog(@"%@",model[i]);
        }
    }
    [self modelDownload];
}

- (void) modelDownload{
    NSLog(@"downloadtype:%d %d",downloadType, downloadTest);
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    while(downloadType<21 && downloadTest==1){
        
        //data save each version
        NSString *temp1 = [NSString stringWithFormat:@"temp%d",downloadType];
        NSString *value = [data objectForKey:temp1];
        
        NSString *checkDownload = [data objectForKey:@"checkDownLoad"];
        
        if( [model[downloadType] compare:value]==NSOrderedSame){//if version is the newest
            NSString *docDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *FilePath;
            NSString *temp;
            if(downloadType==3) temp=[NSString stringWithFormat:@"/%@.xml",model[downloadType]];
            else if(downloadType==1 || downloadType==2) temp=[NSString stringWithFormat:@"/%@.jpg",model[downloadType]];
            else if(downloadType<13) temp=[NSString stringWithFormat:@"/%@.zip",model[downloadType]];
            else temp=[NSString stringWithFormat:@"/%@.3g2",model[downloadType]];
            FilePath=[docDir stringByAppendingString:temp];
            modelPath[downloadType]=FilePath;
            
            NSLog(@"%@%@",@"檔案存在_true：",modelPath[downloadType]);
            downloadType=downloadType+1;
            
        }
        else{//if not
            downloadTest=0;
            
            NSURLSession * session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
            self.session = session;
            NSString *model1url;
            
            if(downloadType==3)model1url = [NSString stringWithFormat:@"%@%@%@", @"http://app.cqplayart.cn/metaio/",model[downloadType],@".xml"];
            else if(downloadType==1 || downloadType==2) model1url = [NSString stringWithFormat:@"%@%@%@", @"http://app.cqplayart.cn/metaio/",model[downloadType],@".jpg"];
            else if(downloadType<13) model1url = [NSString stringWithFormat:@"%@%@%@", @"http://app.cqplayart.cn/metaio/",model[downloadType],@".zip"];
            else model1url = [NSString stringWithFormat:@"%@%@%@", @"http://app.cqplayart.cn/metaio/",model[downloadType],@".3g2"];
            
            self.task = [session downloadTaskWithURL:[NSURL URLWithString:[model1url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
            [self.task resume];
        }
        NSLog(@"download: %d",downloadType);
        
    }
    if(downloadType==21)
    {
        std::vector<metaio::Camera> cameras = m_pMetaioSDK->getCameraList();
        m_pMetaioSDK->startCamera(cameras[0]);
        
        NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
        [data1 setObject:@"1" forKey:@"testIn"];
        
        [self loadCheckTrack];
        
        
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        float dtest=0;
        dtest=totalBytesWritten * 1.0 / totalBytesExpectedToWrite;
        //列印下載百分比
        if (dtest<1)
        {
            NSString *name;
            if(downloadType<4) name=@"即时辨识物件";
            else if(downloadType<14) name=@"沙盘模型";
            else name=@"语音导览";
            
            int changeInt = (int) (dtest*100);
            NSString *myString2 = [[NSNumber numberWithInt:changeInt] stringValue];
            NSString *combined2 = [NSString stringWithFormat:@"当前进度：%@%@", myString2, @"%"];
            m_Label1.text = [NSString stringWithFormat:@"当前档案：%@", name];
            
            if(testProgress==0) m_Label3.text=[NSString stringWithFormat:@"整体进度：%d%@", 0,@"%"];
            
            m_Label2.text=combined2;
        }
        if(dtest==1)
        {
            NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
            NSString *temp1 = [NSString stringWithFormat:@"temp%d",downloadType];
            [data setObject:model[downloadType] forKey:temp1];
            NSLog(@"%f",totalBytesWritten * 1.0 / totalBytesExpectedToWrite);
            
            testProgress=testProgress+1;
            float test=testProgress*100/21;
            NSString *myString3 = [[NSNumber numberWithFloat:test] stringValue];
            NSString *combined3 = [NSString stringWithFormat:@"整体进度：%@%@", myString3,@"%"];
            m_Label3.text=combined3;
            [m_Label3 sizeToFit];
            if(testProgress==21)
            {
                testloading=1;
            }
        }
        
    });
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *FilePath;
    
    NSString *temp;
    
    if(downloadType==1)temp=@"/track1.jpg";
    else if(downloadType==2)temp=@"/track2.jpg";
    else if(downloadType==3) temp=@"/trackConfig.xml";
    else if(downloadType<13) temp=[NSString stringWithFormat:@"/%@.zip",model[downloadType]];
    else temp=[NSString stringWithFormat:@"/%@.3g2",model[downloadType]];
    
    NSLog(@"model:%@",model[downloadType]);
    
    FilePath=[docDir stringByAppendingString:temp];
    
    [fileManager moveItemAtPath:location.path toPath:FilePath error:nil];
    BOOL isExist_m = [fileManager fileExistsAtPath:FilePath];
    if(isExist_m && FilePath!=nil){
        NSLog(@"%@%@",@"檔案存在_false：",FilePath);
        modelPath[downloadType]=FilePath;
        
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        downloadTest=1;
        downloadType=downloadType+1;
        
        [self modelDownload];
        
    });
}

//自創
-(void) createProgress
{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    CGFloat screenWidth = screenSize.width;
    CGFloat screenHeight = screenSize.height;
    
    NSString* loadingImage_model = [[NSBundle mainBundle] pathForResource:@"progressbg"
                                                                   ofType:@"png"
                                                              inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (loadingImage_model)
    {
        const char *loadingImage_path = [loadingImage_model UTF8String];
        loadingImage = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(loadingImage_path));
        loadingImage->setCoordinateSystemID(0);
        loadingImage->setRenderOrder(2);
        loadingImage->setScale(metaio::Vector3d(screenWidth/130, 0.5+screenHeight/90, 10.0f));
        loadingImage->setRelativeToScreen(48,8);
        loadingImage->setTranslation(metaio::Vector3d(0.0f, 0.0f, 2.0f));
    }
    NSString* loadingPicture_model = [[NSBundle mainBundle] pathForResource:@"progressPicture"
                                                                     ofType:@"png"
                                                                inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (loadingPicture_model)
    {
        const char *loadingPicture_path = [loadingPicture_model UTF8String];
        loadingPicture = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(loadingPicture_path));
        loadingPicture->setCoordinateSystemID(0);
        loadingPicture->setRenderOrder(3);
        loadingPicture->setScale(1.1f);
        loadingPicture->setRelativeToScreen(48,8);
        loadingPicture->setTranslation(metaio::Vector3d(0.0f, -10.0f, 3.0f));
    }
    NSString* loadingModel_model = [[NSBundle mainBundle] pathForResource:@"progressModel"
                                                                   ofType:@"png"
                                                              inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (loadingModel_model)
    {
        const char *loadingModel_path = [loadingModel_model UTF8String];
        loadingModel = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(loadingModel_path));
        loadingModel->setCoordinateSystemID(0);
        loadingModel->setRenderOrder(4);
        loadingModel->setScale(2.4f);
        loadingModel->setTranslation(metaio::Vector3d(190.0f, 40.0f, 4.0f));
        loadingModel->setRelativeToScreen(48,8);
    }
}

-(void) chooseGuideSound:(int) temp
{
    //還原
    endIndex=0;
    
    [self parseSRT:temp-1];
    
    testTextStart=1;
    testGuideStart=1;
    textBg->setVisible(true);
    
    playStatus = temp;
    
    const char *guide_Path = [modelPath[temp+12] UTF8String];
    guideSound->setMovieTexture(guide_Path);
    guideSound->startMovieTexture();
    
    if(temp==1) sapan1->startAnimation("ani_H stop",true);
    if(temp==2) sapan2->startAnimation("ani_H stop",true);
    if(temp==3) sapan3->startAnimation("ani_H stop",true);
    if(temp==4) sapan4->startAnimation("ani_H stop",true);
    if(temp==5) sapan5->startAnimation("ani_H stop",true);
    if(temp==6) sapan6->startAnimation("ani_H stop",true);
    if(temp==7) sapan7->startAnimation("ani_H stop",true);
    if(temp==8) sapan8->startAnimation("ani_H stop",true);
}

- (void) parseSRT:(int) testSidePanel {
    NSString *path;
    
    if(testSidePanel==0){
        path = [[NSBundle mainBundle] pathForResource:@"CSQ" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/CSQ"];
    }
    else if(testSidePanel==1)
    {
        path = [[NSBundle mainBundle] pathForResource:@"DXYL" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/DXYL"];
    }
    else if(testSidePanel==2)
    {
        path = [[NSBundle mainBundle] pathForResource:@"SYQ" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/SYQ"];
    }
    else if(testSidePanel==3)
    {
        path = [[NSBundle mainBundle] pathForResource:@"JZQ" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/JZQ"];
    }
    else if(testSidePanel==4)
    {
        path = [[NSBundle mainBundle] pathForResource:@"QSC" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    }
    else if(testSidePanel==5)
    {
        path = [[NSBundle mainBundle] pathForResource:@"CCQ" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/CCQ"];
    }
    else if(testSidePanel==6)
    {
        path = [[NSBundle mainBundle] pathForResource:@"DFS" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/DFS"];
    }
    else if(testSidePanel==7)
    {
        path = [[NSBundle mainBundle] pathForResource:@"TL" ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/TL"];
    }
    
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    int position;
    
    while (![scanner isAtEnd])
    {
        @autoreleasepool
        {
            NSString *indexString;//get index
            (void) [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&indexString];
            NSString *startString;//get start value
            (void) [scanner scanUpToString:@" --> " intoString:&startString];
            
            (void) [scanner scanString:@"-->" intoString:NULL];//get out
            //get end value
            (void) [scanner scanUpToString:@":" intoString:NULL];
            (void) [scanner scanString:@":" intoString:NULL];
            NSString *min;
            (void) [scanner scanUpToString:@":" intoString:&min];
            (void) [scanner scanString:@":" intoString:NULL];
            NSString *second;
            (void) [scanner scanUpToString:@"," intoString:&second];
            (void) [scanner scanString:@"," intoString:NULL];
            NSString *millisecond;
            (void) [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&millisecond];
            
            int minV = [min intValue];
            int secondV = [second intValue];
            int millisecondV = [millisecond intValue];
            int position = minV*60*1000 + secondV*1000 + millisecondV;
            timer[[indexString intValue]] = position;
            NSLog(@"get timer%d",timer[[indexString intValue]]);
            NSString *textString;//get text value
            (void) [scanner scanUpToString:@"\r\n\r\n" intoString:&textString];
            text[[indexString intValue]]=textString;
            NSLog(@"get%d %@ end",[indexString intValue],text[[indexString intValue]]);
            endIndex++;
        }
    }
}

- (UIImage*) getBillboardImage: (NSString*) title andPath: (NSString*) imagePath
{
    // first lets find out if we're drawing retina resolution or not
    float scaleFactor = [UIScreen mainScreen].scale;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        scaleFactor = 2;        // draw in high-res for iPad
    
    // then lets draw
    UIImage* bgImage = nil;
    
    bgImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
    
    UIGraphicsBeginImageContext( bgImage.size );			// create a new image context
    CGContextRef currContext = UIGraphicsGetCurrentContext();
    
    // mirror the context transformation to draw the images correctly
    CGContextTranslateCTM( currContext, 0, bgImage.size.height );
    CGContextScaleCTM(currContext, 1.0, -1.0);
    CGContextDrawImage(currContext,  CGRectMake(0, 0, bgImage.size.width, bgImage.size.height), [bgImage CGImage]);
    
    // now bring the context transformation back to what it was before
    CGContextScaleCTM(currContext, 1.0, -1.0);
    CGContextTranslateCTM( currContext, 0, -bgImage.size.height );
    
    // and add some text...
    CGContextSetRGBFillColor(currContext, 1.0f, 1.0f, 1.0f, 1.0f);
    CGContextSetTextDrawingMode(currContext, kCGTextFill);
    CGContextSetShouldAntialias(currContext, true);
    
    // draw the heading
    float border = 7*scaleFactor;
    [title drawInRect:CGRectMake(border,
                                 border,
                                 bgImage.size.width - 2 * border,
                                 bgImage.size.height - 2 * border)
             withFont:[UIFont systemFontOfSize:20*scaleFactor]
        lineBreakMode:NSLineBreakByClipping
            alignment:NSTextAlignmentCenter];
    
    // retrieve the screenshot from the current context
    UIImage* blendetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return blendetImage;
}
//自創end

#pragma mark - Handling Touches

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint loc = [touch locationInView:self.glkView];
    float scale = self.glkView.contentScaleFactor;
    metaio::IGeometry* modelTouch = m_pMetaioSDK->getGeometryFromViewportCoordinates(loc.x * scale, loc.y * scale, true);
    //
    if(modelTouch==NULL)
        return 0;
    if(modelTouch==back_btn)
    {
        NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
        [data1 setObject:@"0" forKey:@"testIn"];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if(modelTouch==trackEnter)
    {
        blackBack->setVisible(false);
        trackEnter->setVisible(false);
        trackDownload->setVisible(false);
        checkPanel->setVisible(false);
        
        testEnter=1;
    }
    else if(modelTouch==trackDownload)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://advmedia.cqplayart.cn/ticket.jpg"]];
    }
    else if(modelTouch==downloadTicket)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://advmedia.cqplayart.cn/ticket.jpg"]];
    }
    else if(modelTouch==picture_taken)
    {
        shutterSound->startMovieTexture(false);
        
        picture_taken->setVisible(false);
        back_btn->setVisible(false);
        top_title->setVisible(false);
        footer->setVisible(false);
        finder->setVisible(false);
        downloadTicket->setVisible(false);
        if(testGuideStart==1)textBg->setVisible(false);
        if(testGuideStart==1)textGuide->setVisible(false);
        metaio::IGeometry*	sapan[] = {sapan1, sapan2, sapan3, sapan4, sapan5, sapan6, sapan7, sapan8,line};
        int i;
        for(i=0; i<9; i++)
            sapan[i]->setVisible(false);
    }
    else if(modelTouch==sapan1 && testTextStart==0)
        [self chooseGuideSound:1];
    else if(modelTouch==sapan2 && testTextStart==0)
        [self chooseGuideSound:2];
    else if(modelTouch==sapan3 && testTextStart==0)
        [self chooseGuideSound:3];
    else if(modelTouch==sapan4 && testTextStart==0)
        [self chooseGuideSound:4];
    else if(modelTouch==sapan5 && testTextStart==0)
        [self chooseGuideSound:5];
    else if(modelTouch==sapan6 && testTextStart==0)
        [self chooseGuideSound:6];
    else if(modelTouch==sapan7 && testTextStart==0)
        [self chooseGuideSound:7];
    else if(modelTouch==sapan8 && testTextStart==0)
        [self chooseGuideSound:8];
    
    else{NSLog(@"can't detect");}
}

- (void) onAnimationEnd:(metaio::IGeometry *)geometry andName:(const NSString *)animationName
{
    if(geometry==track_stuff)
    {
        line->setVisible(true);
        line->startAnimation("ani_chuxian" , false);
    }
}

- (void) onMovieEnd:(metaio::IGeometry *)geometry andMoviePath:(const NSString *)moviePath
{
    if(geometry==shutterSound)
    {
        [self onSaveScreen];
    }
    else if(geometry==guideSound)
    {
        testGuideStart=0;
        testTextStart=0;
        textBg->setVisible(false);
        if(textGuide!=NULL)
        {
            m_pMetaioSDK->unloadGeometry(textGuide);
            textGuide=NULL;
        }
        
        if(playStatus==1) sapan1->startAnimation("ani_H_L", false);
        if(playStatus==2) sapan2->startAnimation("ani_H_L", false);
        if(playStatus==3) sapan3->startAnimation("ani_H_L", false);
        if(playStatus==4) sapan4->startAnimation("ani_H_L", false);
        if(playStatus==5) {sapan5->startAnimation("ani_H_L", false);NSLog(@"end");}
        if(playStatus==6) sapan6->startAnimation("ani_H_L", false);
        if(playStatus==7) sapan7->startAnimation("ani_H_L", false);
        if(playStatus==8) sapan8->startAnimation("ani_H_L", false);
        
        playStatus=0;
    }
    
}
- (void)drawFrame
{
    //loading status
    if(testloading==1){
        m_pMetaioSDK->unloadGeometry(loadingImage);
        m_pMetaioSDK->unloadGeometry(loadingModel);
        m_pMetaioSDK->unloadGeometry(loadingPicture);
        loadingPicture=NULL;
        loadingImage=NULL;
        loadingModel=NULL;
        m_Label1.text=@"";
        m_Label2.text=@"";
        m_Label3.text=@"";
    }
    
    //字幕機
    metaio::MovieTextureStatus test;
    if(guideSound!=NULL)test = guideSound->getMovieTextureStatus();
    if (testTextStart==1 && endIndex>index){
        float current = test.currentPosition*1000;
        if(timer[index]>current){
            if(testTXT==1){
                NSLog(@"testtxt:%@, %d",text[index],timer[index]);
                NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
                if (textGuide)
                {
                    m_pMetaioSDK->unloadGeometry(textGuide);
                    textGuide=NULL;
                }
                textGuide = m_pMetaioSDK->createGeometryFromCGImage([@"test" UTF8String], [[self getBillboardImage:text[index] andPath:texturePath] CGImage]);
                textGuide->setCoordinateSystemID(0);
                textGuide->setScale(0.8);
                textGuide->setRelativeToScreen(20,8);
                textGuide->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
                textGuide->setRenderOrder(50);
                textGuide->setVisible(true);
                testTXT=0;
            }
        }
        else {
            index++;
            testTXT=1;
        }
    }
    else{
        testTextStart=0;
        index=0;
    }
    
    //sapan animation
    if(line!=NULL)
    {
        float time = line->getCurrentFrame();
        
        if(time>0)
        {
            if(time>43 && time<59)
            {
                sapan8->setVisible(true);
                if(playStatus==8) sapan8->startAnimation("ani_H stop",true);
                else sapan8->startAnimation("ani_chuxian",false);
            }
            if(time>59 && time<88)
            {
                sapan4->setVisible(true);
                if(playStatus==4) sapan4->startAnimation("ani_H stop",true);
                else sapan4->startAnimation("ani_chuxian",false);
            }
            if(time>88 && time<140)
            {
                sapan6->setVisible(true);
                if(playStatus==6) sapan6->startAnimation("ani_H stop",true);
                else sapan6->startAnimation("ani_chuxian",false);
            }
            if(time>140 && time<180)
            {
                sapan5->setVisible(true);
                if(playStatus==5) sapan5->startAnimation("ani_H stop",true);
                else sapan5->startAnimation("ani_chuxian",false);
            }
            if(time>190 && time<200)
            {
                sapan2->setVisible(true);
                if(playStatus==2) sapan2->startAnimation("ani_H stop",true);
                else sapan2->startAnimation("ani_chuxian",false);
            }
            if(time>200 && time<256)
            {
                sapan1->setVisible(true);
                if(playStatus==1) sapan1->startAnimation("ani_H stop",true);
                else sapan1->startAnimation("ani_chuxian",false);
            }
            if(time>256 && time<308)
            {
                sapan3->setVisible(true);
                if(playStatus==3) sapan3->startAnimation("ani_H stop",true);
                else sapan3->startAnimation("ani_chuxian",false);
            }
            if(time>317 && time<330)
            {
                sapan7->setVisible(true);
                if(playStatus==7) sapan7->startAnimation("ani_H stop",true);
                else sapan7->startAnimation("ani_chuxian",false);
            }
        }
    }
    
    if(track_stuff!=NULL && track_stuff->getIsRendered())
        finder->setVisible(false);
    else if(track_stuff!=NULL && !(track_stuff->getIsRendered()))
    {
        metaio::IGeometry*	sapan[] = {sapan1, sapan2, sapan3, sapan4, sapan5, sapan6, sapan7, sapan8, line};
        int i;
        for(i=0; i<9; i++)
            sapan[i]->setVisible(false);
    }
    
    [super drawFrame];
}

//Screen shot
- (void)onSaveScreen
{
    [self didReadValue:0];
    m_pMetaioSDK->requestScreenshot();
}
-(void)didReadValue:(int)value
{
    readvalue=value;
    return readvalue;
}
- (void) onScreenshotImageIOS:(UIImage *)image
{
    NSLog(@"Implement your sharing controller here.");
    
    /* UIGraphicsBeginImageContext(CGSizeMake(48, 48));
     [image drawInRect:CGRectMake(0, 0, 48,48)];
     UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     
     [m_imageshow setImage:reSizeImage forState:UIControlStateNormal];*/
    
    [self ImageSharing:image];
}
- (void) ImageSharing:(UIImage *)image
{
    
    
    ASImageSharingViewController* controller = [[ASImageSharingViewController alloc] initWithNibName:@"ASImageSharingViewController" bundle:nil];
    controller.imageToPost = image;
    
    controller.myValue = readvalue;
    [self presentViewController:controller animated:YES completion:nil];
    
    picture_taken->setVisible(true);
    back_btn->setVisible(true);
    top_title->setVisible(true);
    downloadTicket->setVisible(true);
    footer->setVisible(true);
    if(testGuideStart==1)textBg->setVisible(true);
    if(testGuideStart==1)textGuide->setVisible(true);
    if(!(track_stuff->getIsRendered()))finder->setVisible(true);
    else
    {
        metaio::IGeometry*	sapan[] = {sapan1, sapan2, sapan3, sapan4, sapan5, sapan6, sapan7, sapan8, line};
        int i;
        for(i=0; i<9; i++)
            sapan[i]->setVisible(true);
    }
    
}
-(void) onScreenshotSaved:(const NSString*) filepath
{
    NSLog(@"Image saved: %@", filepath);
}
//screen shot end

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape; //支援橫向
}

@end