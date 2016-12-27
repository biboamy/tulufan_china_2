// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import <QuartzCore/QuartzCore.h>
#import "GPSARViewController.h"
//#import "WebViewControll.h"
#import "myapi.h"
#import "Database.h"
#import "AppDelegate.h"
#import "UIDevice-Hardware.h"
#import "ASImageSharingViewController.h"
#include <metaioSDK/Common/SensorsComponentIOS.h>
#include <metaioSDK/IMetaioSDKIOS.h>

class Callback : public metaio::IShaderMaterialOnSetConstantsCallback
{
    //if([testDevice caseInsensitiveCompare:@"0"] != 0)
    //    static long test[2] = {0,static_cast<long>(1469255451287L)};
     //   else
    long test[2] = {0,static_cast<long>(50000L)};
    
public:
    int status;
    NSString* testDevice;


    Callback(GPSARViewController* vc) :
    m_vc(vc)
    {
    
    }
    
private:
    
    
    virtual void onSetShaderMaterialConstants(const metaio::stlcompat::String& shaderMaterialName, void* extra,
                                              metaio::IShaderMaterialSetConstantsService* constantsService)override
    {
            
        int max, increase;
        
        if([testDevice caseInsensitiveCompare:@"iPhone 5"] != 0) // iphone5之外的
        {NSLog(@"hi1");
            if(status==0)
            {max=100; increase=20L;}
            else if(status==1)
            {max=630; increase=4L;}
            else if(status==2)
            {max=650; increase=4L;}
            else if(status==3)
            {max=600; increase=4L;}
            else if(status==5)
            {max=580; increase=4L;}
            else if(status==6)
            {max=570; increase=4L;}
            else if(status==7)
            {max=600; increase=4L;}
        }
        else
        {NSLog(@"hi2");
            if(status==0)
            {max=80; increase=20L;}
            else if(status==1)
            {max=600; increase=4L;}
            else if(status==2)
            {max=700; increase=4L;}
            else if(status==3)
            {max=600; increase=4L;}
            else if(status==5)
            {max=560; increase=4L;}
            else if(status==6)
            {max=350; increase=4L;}
            else if(status==7)
            {max=175; increase=7L;}
        }
        //const float time[1] = { 0.5f * (1.0f + (float)sin(CACurrentMediaTime())) };
        
        
        const float time2[1] = { 0.5f * (1.0f + (float)sin(test[1] / 1000.0)) };
        if (test[0] <= max) { // 跑 75 次大約是從全透明至完整型態
            if ((0.5f * (1.0f + (float) sin([[NSDate date] timeIntervalSince1970] / 1000.0))) > 0) // 取用時間頻率
            {
                NSLog(@"Now %ld Time is : %f  %f  %ld",test[0],(0.5f * (1.0f + (float) sin(test[1] / 1000.0))),[[NSDate date] timeIntervalSince1970],test[1]);
                constantsService->setShaderUniformF("myValue", time2, 1);
            }
        }
        test[0]++;
        test[1] = test[1] + increase;
    }

    __weak GPSARViewController* m_vc;
};


class AnnotatedGeometriesGroupCallback : public metaio::IAnnotatedGeometriesGroupCallback
{
public:
    AnnotatedGeometriesGroupCallback(GPSARViewController* _vc) : vc(_vc)
    {
        
    }
    
    virtual metaio::IGeometry* loadUpdatedAnnotation(metaio::IGeometry* geometry, void* userData, metaio::IGeometry* existingAnnotation) override
    {
        return [vc loadUpdatedAnnotation:geometry userData:userData existingAnnotation:existingAnnotation];
    }
    
    GPSARViewController* vc;
    //NSLog(@"1");
};

@interface GPSARViewController ()<NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, assign) AnnotatedGeometriesGroupCallback *annotatedGeometriesGroupCallback;
@property (nonatomic, strong) NSURLSessionDownloadTask * task;
//ensure only one alert is shown at the same time
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) BOOL working;
- (UIImage*)getAnnotationImageForTitle:(NSString*)title;
@end

@implementation GPSARViewController
{
    Callback*		m_pCallback;
}

@synthesize readvalue;

#pragma mark - UIViewController lifecycle

static dispatch_once_t once;

-(void) becomeActive
{
    downloadTest=1;
    [self modelDownload];
}

- (void) viewDidLoad
{
    
    [super viewDidLoad];
    
    //側網路狀態
    NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
    NSString *value1 = [data1 objectForKey:@"testNetWork"];
    if([value1 caseInsensitiveCompare:@"0"]==0) testNetWork=0;
    else testNetWork=1;
    
    NSString *value = [data1 objectForKey:@"testVIP"];

  
        //記錄位置
        [[[Database alloc] init] open];
        //[[[Database alloc] init] deleteData];
        char *msg = [[[Database alloc] init] initialized:@"status"];
        NSString* message = [NSString stringWithFormat:@"%s", msg];
        
        NSArray *array1;
        
        if([@"table status already exists" caseInsensitiveCompare:message]==0)
        {
            array1 = [[[Database alloc] init] selectData:@"status"];
            finalStatus = [array1[0] intValue];
            status = finalStatus;
        }
        else
        {
            finalStatus=0;
            status = finalStatus;
            [[[Database alloc] init] insertData:[NSString stringWithFormat:@"%d", finalStatus] tableName:@"status"];
        }
        
        [[[Database alloc] init] close];
        
        if(status==8)
            status=7;
        
        //instant tracking
        m_mustUseInstantTrackingEvent = NO;
        
        //test screen
        if(([[UIScreen mainScreen] bounds].size.width)>900)
            testScreen=1;
        else
            testScreen=0;
        
        //抓模型值
        [[[Database alloc] init] open];
        char *msg2 = [[[Database alloc] init] initializedValue:@"modelValue"];
        NSString* message2 = [NSString stringWithFormat:@"%s", msg2];
        
        if([@"table modelValue already exists" caseInsensitiveCompare:message2]==0)
        {
            int i;
            for(i=0; i<8; i++)
            {
                NSArray *arrayValue = [[[Database alloc] init] selectDataValue:@"modelValue" selectId:i+1];
                xValue[i] = [arrayValue[0] floatValue]; yValue[i] = [arrayValue[1] floatValue]; zValue[i] = [arrayValue[2] floatValue];
                size[i] = [arrayValue[3] floatValue];
                xrValue[i] = [arrayValue[4] floatValue]; yrValue[i] = [arrayValue[5] floatValue]; zrValue[i] = [arrayValue[6] floatValue];
                NSLog(@"enterq?");
                //NSLog(@"value: %f %f %f %f %f %f %f",xValue[i],yValue[i],zValue[i],size[i],xrValue[i],yrValue[i],zrValue[i]);
            }
            
            
        }
        else
        {
            NSString *ConText = @"http://app.cqplayart.cn/json/android-test.php";//get json url
            
            NSURL *url = [NSURL URLWithString:ConText];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            NSData* data_json = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];//將json存入data中
            NSDictionary* jsonObj = [NSJSONSerialization JSONObjectWithData:data_json options:NSJSONReadingMutableContainers   error:nil];
            
            int i;
            for(i=0; i<8; i++)
            {
                NSArray *xArray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"xValue"];
                NSArray *yArray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"yValue"];
                NSArray *zArray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"zValue"];
                
                NSArray *Modelarray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"size"];
                
                NSArray *xrArray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"rotationX"];
                NSArray *yrArray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"rotationY"];
                NSArray *zrArray = [[jsonObj objectForKey:[NSString stringWithFormat:@"model%d", i+1]] valueForKey:@"rotationZ"];
                
                [[[Database alloc] init] insertDataValue:@"modelValue" xValue:[xArray[0] floatValue] yValue:[yArray[0] floatValue] zValue:[zArray[0] floatValue] size:[Modelarray[0] floatValue] xRotation:[xrArray[0] floatValue] yRotation:[yrArray[0] floatValue] zRotation:[zrArray[0] floatValue]];
                
                xValue[i] = [xArray[0] floatValue]; yValue[i] = [yArray[0] floatValue]; zValue[i] = [zArray[0] floatValue];
                size[i] = [Modelarray[0] floatValue];
                xrValue[i] = [xrArray[0] floatValue]; yrValue[i] = [yrArray[0] floatValue]; zrValue[i] = [zrArray[0] floatValue];
            }
        }
        [[[Database alloc] init] close];
        
        
        //gesture handler
        int m_gestures = 1<<2;
        int m_gestures1 = 1<<0;
        int m_gestures2 = 1<<0;
        int m_gestures_t = 0xFF;
        m_gestureHandler = [[GestureHandlerIOS alloc] initWithSDK:m_pMetaioSDK withView:self.glkView withGestures:m_gestures];
        m_gestureHandler1 = [[GestureHandlerIOS alloc] initWithSDK:m_pMetaioSDK withView:self.glkView withGestures:m_gestures1];
        m_gestureHandler2 = [[GestureHandlerIOS alloc] initWithSDK:m_pMetaioSDK withView:self.glkView withGestures:m_gestures2];
        
        //後面兩區
        playBtnStatus=1;
        
        //test status
        //status=0;
        
        detectTalk=2;
        
        //gps
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter = 3.0f;
        [locationManager requestWhenInUseAuthorization];
        [locationManager startUpdatingLocation];
        
        self.working=false;
        self.alertView = nil;
        [self testmygps];//load GPS value
        
        //m_pMetaioSDK->stopCamera();
        
        [self createProgress];
        [self createAlertModel];
        [self create3D];
        [self createPlayGuide];
        [self createPictureTaken];
        [self createSecondPage];
        [self createFinalPage];
        //[self load3Dmodel];
        [self nextAppear];
        [self cameraGuideAni];
        [self finderDisappear];
        
        [self addGeo];
        //download
        downloadType=0;
        testloading=0;
        downloadTest=1;
        [self getJson];
        
        //字幕機
        testTXT=1;
        
        //下載休眠
        if(title==NULL) [[NSNotificationCenter defaultCenter]addObserver:self
                                                                selector:@selector(becomeActive)
                                                                    name:UIApplicationDidBecomeActiveNotification
                                                                  object:nil];
  
}

//for VIP

//download
-(void) getJson
{
    NSLog(@"enter?");
    if(testNetWork==1){
        
        NSString *ConText = @"http://app.cqplayart.cn/assets/jsonvalue_beta.php";//get json url
        //NSString *ConText = @"http://cqplayart.cn/assets/jsonvalue_beta2.php";
        NSURL *url = [NSURL URLWithString:ConText];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSData* data_json = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];//將json存入data中
        NSDictionary* jsonObj =
        [NSJSONSerialization JSONObjectWithData:data_json
                                        options:NSJSONReadingMutableContainers   error:nil];
        
        NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
        
        //model data
        NSArray *Model1array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model1Name"];
        [data1 setObject:Model1array[0] forKey:@"model1Name"];
        NSArray *Model2array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model2Name"];
        [data1 setObject:Model2array[0] forKey:@"model2Name"];
        NSArray *Model3array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model3Name"];
        [data1 setObject:Model3array[0] forKey:@"model3Name"];
        NSArray *Model4array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model4Name"];
        [data1 setObject:Model4array[0] forKey:@"model4Name"];
        NSArray *Model5array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model5Name"];
        [data1 setObject:Model5array[0] forKey:@"model5Name"];
        NSArray *Model6array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model6Name"];
        [data1 setObject:Model6array[0] forKey:@"model6Name"];
        NSArray *Model7array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model7Name"];
        [data1 setObject:Model7array[0] forKey:@"model7Name"];
        NSArray *Model8array = [[jsonObj objectForKey:@"modeldata"] valueForKey:@"model8Name"];
        [data1 setObject:Model8array[0] forKey:@"model8Name"];
        
        //people data
        NSArray *people1array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File1Name"];
        [data1 setObject:people1array[0] forKey:@"File1Name"];
        NSArray *people2array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File2Name"];
        [data1 setObject:people2array[0] forKey:@"File2Name"];
        NSArray *people3array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File3Name"];
        [data1 setObject:people3array[0] forKey:@"File3Name"];
        NSArray *people4array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File4Name"];
        [data1 setObject:people4array[0] forKey:@"File4Name"];
        NSArray *people5array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File5Name"];
        [data1 setObject:people5array[0] forKey:@"File5Name"];
        NSArray *people6array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File6Name"];
        [data1 setObject:people6array[0] forKey:@"File6Name"];
        NSArray *people7array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File7Name"];
        [data1 setObject:people7array[0] forKey:@"File7Name"];
        NSArray *people8array = [[jsonObj objectForKey:@"mandata"] valueForKey:@"File8Name"];
        [data1 setObject:people8array[0] forKey:@"File8Name"];
        
        //QSC model
        NSArray *QSCmodel;
        int i;
        for(i=0; i<20; i++)
        {
            QSCmodel = [[jsonObj objectForKey:@"QSC"] valueForKey:[NSString stringWithFormat:@"QSC%d", i+1]];
            [data1 setObject:QSCmodel[0] forKey:[NSString stringWithFormat:@"QSC%d", i+1]];
        }
        
        for(i=0; i<8; i++){
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"model%dName", i+1]];
            NSLog(@"%@",model[i]);
        }
        for(i=8; i<16; i++){
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"File%dName", i-7]];
            NSLog(@"%@",model[i]);
        }
        for(i=16; i<36; i++)
        {
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"QSC%d", i-15]];
            NSLog(@"%@",model[i]);
        }
        //語音
        NSArray *guideData;
        for(i=36; i<44; i++)
        {
            guideData = [[jsonObj objectForKey:@"guide"] valueForKey:[NSString stringWithFormat:@"guide%i", i-35]];
            [data1 setObject:guideData[0] forKey:[NSString stringWithFormat:@"guide%i", i-35]];
        }
        for(i=36; i<44; i++)
        {
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"guide%i", i-35]];
            NSLog(@"%@",model[i]);
        }
    }
    else
    {
        NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
        
        int i;
        for(i=0; i<8; i++)
        {
            NSString *modelName = [NSString stringWithFormat:@"model%dName", i+1];
            model[i] = [data1 objectForKey:modelName];
        }
        for(i=8; i<16; i++)
        {
            NSString *FileName = [NSString stringWithFormat:@"File%dName", i-7];
            model[i] = [data1 objectForKey:FileName];
        }
        for(i=16; i<36; i++)
        {
            NSString *QSCName = [NSString stringWithFormat:@"QSC%d", i-15];
            model[i] = [data1 objectForKey:QSCName];
        }
        for(i=36; i<44; i++)
        {
            model[i] = [data1 objectForKey:[NSString stringWithFormat:@"guide%i", i-35]];
            NSLog(@"%@",model[i]);
        }
    }
    [self modelDownload];
}

- (void) modelDownload{
    NSLog(@"downloadtype:%d %d",downloadType, downloadTest);
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    while(downloadType<44 && downloadTest==1){
        //data save each version
        NSString *temp1 = [NSString stringWithFormat:@"temp%d",downloadType];
        NSString *value = [data objectForKey:temp1];
        
        NSString *checkDownload = [data objectForKey:@"checkDownLoad"];
        NSLog(@"value:%@ %@",value,model[downloadType]);
        
        if( [model[downloadType] compare:value]==NSOrderedSame){//if version is the newest
            NSString *docDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *FilePath;
            NSString *temp;
            if(downloadType<36) temp=[NSString stringWithFormat:@"/%@.zip",model[downloadType]];
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
            
            //model1url = [NSString stringWithFormat:@"%@%@%@", @"http://advmedia.cqplayart.cn/",model[downloadType],@".zip"];
            if(downloadType<36) model1url = [NSString stringWithFormat:@"%@%@%@", @"http://app.cqplayart.cn/metaio/",model[downloadType],@".zip"];
            else model1url = [NSString stringWithFormat:@"%@%@%@", @"http://app.cqplayart.cn/metaio/",model[downloadType],@".3g2"];
            
            self.task = [session downloadTaskWithURL:[NSURL URLWithString:[model1url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
            [self.task resume];
        }
        NSLog(@"download: %d",downloadType);
        
    }
    if(downloadType==44)
    {
        std::vector<metaio::Camera> cameras = m_pMetaioSDK->getCameraList();
        m_pMetaioSDK->startCamera(cameras[0]);
        testloading=1;
        if(status==0)
        {
            [self createFirstPage];
            point1->setTexture([[[NSBundle mainBundle] pathForResource:@"pointL1" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        }
        else
        {
            nextPageTime=1;
            
            NSLog(@"hihi");
            
            [self createFirstPage];
            
            m_pMetaioSDK->unloadGeometry(firstPageModel);
            firstPageModel=NULL;
            
            secondPageGuide->setScale(2);
            secondPageGuide->setTranslation(metaio::Vector3d(0.0f, -30.0f, 0.0f));
            
            NSString* mapString = [NSString stringWithFormat:@"map%i", status];
            map->setTexture([[[NSBundle mainBundle] pathForResource:mapString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            point[status]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"pointL%i", status+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            NSLog(@"hihi2");
            if(finalStatus!=8)[self nextClick];
            else if(finalStatus==8) [self completePage];
        }
    }
}

-(void) completePage
{
    iknow->setVisible(false);
    firstPageTalk->setVisible(false);
    tangshengSound->stopMovieTexture();
    
    blackBack->setVisible(true);
    map->setVisible(true);
    map->setTranslation(metaio::Vector3d(0.0f, 0.0f, 19.0f));
    
    point[status]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"point%i", status+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    status=8;
    
    int i;
    for(i=0; i<8; i++)
        point[i]->setVisible(true);
    
    NSString* completeAlert_model = [[NSBundle mainBundle] pathForResource:@"completeAlert"
                                                                    ofType:@"png"
                                                               inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (completeAlert_model)
    {
        const char *utf8Path = [completeAlert_model UTF8String];
        completeAlert = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        completeAlert->setCoordinateSystemID(0);
        completeAlert->setScale(0.4f);
        completeAlert->setRelativeToScreen(20,8);
        completeAlert->setVisible(true);
        completeAlert->setRenderOrder(20,false,true);
        completeAlert->setTranslation(metaio::Vector3d(10.0f, 10.0f, 20.0f));
    }
}

//自創function
//選擇人物互動的語音和字幕
-(void) startQSCsound:(int) temp
{
    //parse subtitle
    endIndex=1;
    if(recordStatus<18) [self parseSRT:8 chooseTalk:recordStatus];
    else [self parseSRT:8 chooseTalk:temp];
    
    //start 字幕機
    testTextStart=1;
    
    //detectTalk=0;
    swTalk=0;
    
    //map controll
    QSCmapClickStop=1;
    
    const char *test;
    if(recordStatus<18)
        test = [[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"QSCtalk%i", recordStatus] ofType:@"mp4" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String];
    else
        test = [[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"QSCtalk%i", temp] ofType:@"mp4" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String];
    
    bool success = QSCtalk->setMovieTexture(test);
    
    int i;
    for(i=0; i<3; i++)
        clickEnable[i]=0;
    
    if(temp<18)
        [self choosePeople:temp];
    else if(temp>17)
    {
        [self choosePeople:temp];
        NSLog(@"success");
    }
    else
        [self choosePeople:recordStatus];
    
    if(success) QSCtalk->startMovieTexture(false);
    startPeopleTalk=1;
}

//選擇講話時的動作
-(void) choosePeople:(int) temp
{
    if(temp==2)
        guanyuan->startAnimation("ani_B1",true);
    else if(temp==3)
        guowang->startAnimation("ani_A1",true);
    else if(temp==4)
        guanyuan->startAnimation("ani_B2",true);
    else if(temp==5)
        guowang->startAnimation("ani_A2",true);
    else if(temp==6)
        guanyuan->startAnimation("ani_B3",true);
    else if(temp==7)
        guowang->startAnimation("ani_A3",true);
    else if(temp==8)
        guanyuan->startAnimation("ani_B4",true);
    else if(temp==9)
        guowang->startAnimation("ani_A4",true);
    else if(temp==10)
        guanyuan->startAnimation("ani_B5",true);
    else if(temp==12)
        anguohou->startAnimation("ani_D1",true);
    else if(temp==13)
        guowang->startAnimation("ani_A5",true);
    else if(temp==14)
        anguohou->startAnimation("ani_D2",true);
    else if(temp==15)
        anguohou->startAnimation("ani_D3",true);
    else if(temp==16)
        guanyuan->startAnimation("ani_B6",true);
    else if(temp==17)
        anguohou->startAnimation("ani_D4",true);
    else if(temp==18)
        shouwei_01->startAnimation("ani_C1",true);
    else if(temp==19)
        shouwei_02->startAnimation("ani_C2",true);
    else if(temp==20)
        shouwei_03->startAnimation("ani_C3",true);
    else if(temp==21)
        shouwei_04->startAnimation("ani_C4",true);
    else if(temp==22)
        shouwei_05->startAnimation("ani_C5",true);
    else if(temp==23)
        shouwei_06->startAnimation("ani_C6",true);
    else if(temp==24)
        shouwei_07->startAnimation("ani_C7",true);
}

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

-(void) createFirstPage
{
    NSString* imgTitle_model = [[NSBundle mainBundle] pathForResource:@"title"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (imgTitle_model)
    {
        const char *utf8Path = [imgTitle_model UTF8String];
        title = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        title->setCoordinateSystemID(0);
        title->setScale(0.53f);
        title->setRenderOrder(4);
        title->setRelativeToScreen(24,8);
    }
    NSString* titleWord_model = [[NSBundle mainBundle] pathForResource:@"titleWord"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (titleWord_model)
    {
        const char *utf8Path = [titleWord_model UTF8String];
        titleWord = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        titleWord->setCoordinateSystemID(0);
        titleWord->setScale(0.52f);
        titleWord->setRenderOrder(5);
        titleWord->setRelativeToScreen(24,8);
    }
    NSString* back_model = [[NSBundle mainBundle] pathForResource:@"btn_arExit"
                                                           ofType:@"png"
                                                      inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (back_model)
    {
        const char *utf8Path = [back_model UTF8String];
        
        exitAR = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        exitAR->setCoordinateSystemID(0);
        exitAR->setScale(0.35f);
        exitAR->setRenderOrder(6);
        exitAR->setRelativeToScreen(9,8);
        exitAR->setTranslation(metaio::Vector3d(0.0f, -10.0f, 1.0f));
    }
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
        blackBack->setRenderOrder(5,false,true);
        blackBack->setVisible(false);
        blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 6.0f));
    }
    NSString* model3D_model = [[NSBundle mainBundle] pathForResource:@"tangsheng"
                                                              ofType:@"zip"
                                                         inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (model3D_model)
    {
        const char *utf8Path = [model3D_model UTF8String];
        firstPageModel = m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(utf8Path));
        firstPageModel->setVisible(true);
        firstPageModel->startAnimation("ani_talk",true);
        firstPageModel->setScale(7.0f);
        firstPageModel->setRelativeToScreen(5,8);
        firstPageModel->setRenderOrder(7);
        firstPageModel->setTranslation(metaio::Vector3d(60.0f, 30.0f, 4.0f));
    }
    NSString* firstPageTalk_model = [[NSBundle mainBundle] pathForResource:@"talk0"
                                                                    ofType:@"png"
                                                               inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (firstPageTalk_model)
    {
        const char *utf8Path = [firstPageTalk_model UTF8String];
        
        firstPageTalk = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        firstPageTalk->setCoordinateSystemID(0);
        firstPageTalk->setScale(2.0f);
        firstPageTalk->setRelativeToScreen(48,8);
        firstPageTalk->setRenderOrder(20);
        firstPageTalk->setTranslation(metaio::Vector3d(20.0f, 10.0f, 3.0f));
    }
    NSString* iknowImg_model = [[NSBundle mainBundle] pathForResource:@"iknowImg"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (iknowImg_model)
    {
        const char *utf8Path = [iknowImg_model UTF8String];
        iknow = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        iknow->setCoordinateSystemID(0);
        iknow->setScale(0.6f);
        iknow->setRelativeToScreen(6,8);
        iknow->setRenderOrder(16);
        iknow->setTranslation(metaio::Vector3d(-25.0f, 15.0f, 21.0f));
        //iknow->setVisible(false);
    }
    NSString* tangshengSound_model = [[NSBundle mainBundle] pathForResource:@"guide0"
                                                                     ofType:@"mp3"
                                                                inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(tangshengSound_model)
    {
        const char *utf8Path = [tangshengSound_model UTF8String];
        tangshengSound =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        tangshengSound->startMovieTexture(false);
        tangshengSound->setCoordinateSystemID(0);
    }
    
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    NSString *testTracking = [data objectForKey:@"tracking"];
    
    NSString* clickSound_model = [[NSBundle mainBundle] pathForResource:@"click"
                                                                 ofType:@"3g2"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(clickSound_model)
    {
        const char *utf8Path = [clickSound_model UTF8String];
        clickSound =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        clickSound->setCoordinateSystemID(0);
    }
}

-(void) createAlertModel
{
    NSString* arriveAlert_model = [[NSBundle mainBundle] pathForResource:@"arriveAlert0"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (arriveAlert_model)
    {
        const char *utf8Path = [arriveAlert_model UTF8String];
        arriveAlert = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        arriveAlert->setCoordinateSystemID(0);
        arriveAlert->setScale(0.4f);
        arriveAlert->setRelativeToScreen(20,8);
        arriveAlert->setVisible(false);
        arriveAlert->setRenderOrder(4,false,true);
        arriveAlert->setTranslation(metaio::Vector3d(0.0f, 10.0f, 5.0f));
    }
    NSString* notArriveAlert_model = [[NSBundle mainBundle] pathForResource:@"notArriveAlert0"
                                                                     ofType:@"png"
                                                                inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (notArriveAlert_model)
    {
        const char *utf8Path = [notArriveAlert_model UTF8String];
        notArriveAlert = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        notArriveAlert->setCoordinateSystemID(0);
        notArriveAlert->setScale(0.4f);
        notArriveAlert->setRelativeToScreen(20,8);
        notArriveAlert->setVisible(false);
        notArriveAlert->setRenderOrder(2,false,true);
        notArriveAlert->setTranslation(metaio::Vector3d(0.0f, 20.0f, 0.0f));
    }
}

-(void) createPlayGuide
{
    
    NSString* pleaseTouch_model = [[NSBundle mainBundle] pathForResource:@"pleaseTouch"
                                                              ofType:@"png"
                                                         inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (pleaseTouch_model)
    {
        const char *utf8Path = [pleaseTouch_model UTF8String];
        pleaseTouch = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        pleaseTouch->setCoordinateSystemID(0);
        pleaseTouch->setScale(0.5f);
        pleaseTouch->setRelativeToScreen(5,8);
        pleaseTouch->setRenderOrder(5);
        pleaseTouch->setTranslation(metaio::Vector3d(25.0f, 65.0f, 0.0f));
        pleaseTouch->setVisible(false);
    }
    NSString* modelToggle_model = [[NSBundle mainBundle] pathForResource:@"modelToggle"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (modelToggle_model)
    {
        const char *utf8Path = [modelToggle_model UTF8String];
        modelToggle = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        modelToggle->setCoordinateSystemID(0);
        modelToggle->setScale(0.8f);
        modelToggle->setRelativeToScreen(5,8);
        modelToggle->setTranslation(metaio::Vector3d(35.0f, 63.0f, 0.0f));
        modelToggle->setVisible(false);
    }
    NSString* modelToggle2_model = [[NSBundle mainBundle] pathForResource:@"modelToggle2"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (modelToggle2_model)
    {
        const char *utf8Path = [modelToggle2_model UTF8String];
        modelToggle2 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        modelToggle2->setCoordinateSystemID(0);
        modelToggle2->setScale(0.8f);
        modelToggle2->setRelativeToScreen(5,8);
        modelToggle2->setTranslation(metaio::Vector3d(35.0f, 63.0f, 0.0f));
        modelToggle2->setVisible(false);
    }
    NSString* pleaseTouchDim_model = [[NSBundle mainBundle] pathForResource:@"pleaseTouchDim"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (pleaseTouchDim_model)
    {
        const char *utf8Path = [pleaseTouchDim_model UTF8String];
        pleaseTouchDim = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        pleaseTouchDim->setCoordinateSystemID(0);
        pleaseTouchDim->setScale(0.8f);
        pleaseTouchDim->setRelativeToScreen(5,8);
        pleaseTouchDim->setRenderOrder(5);
        pleaseTouchDim->setTranslation(metaio::Vector3d(28.0f, 65.0f, 0.0f));
        pleaseTouchDim->setVisible(false);
    }
    NSString* playBtn_model = [[NSBundle mainBundle] pathForResource:@"playBtn"
                                                              ofType:@"png"
                                                         inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (playBtn_model)
    {
        const char *utf8Path = [playBtn_model UTF8String];
        playBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        playBtn->setCoordinateSystemID(0);
        playBtn->setScale(0.5f);
        playBtn->setRelativeToScreen(5,8);
        playBtn->setRenderOrder(51);
        playBtn->setTranslation(metaio::Vector3d(15.0f, 15.0f, 0.0f));
        playBtn->setVisible(false);
    }
    NSString* pauseBtn_model = [[NSBundle mainBundle] pathForResource:@"pause"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (pauseBtn_model)
    {
        const char *utf8Path = [pauseBtn_model UTF8String];
        pauseBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        pauseBtn->setCoordinateSystemID(0);
        pauseBtn->setScale(0.5f);
        pauseBtn->setRelativeToScreen(5,8);
        pauseBtn->setRenderOrder(51);
        pauseBtn->setTranslation(metaio::Vector3d(15.0f, 15.0f, 1.0f));
        pauseBtn->setVisible(false);
    }
    NSString* replayBtn_model = [[NSBundle mainBundle] pathForResource:@"replay"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (replayBtn_model)
    {
        const char *utf8Path = [replayBtn_model UTF8String];
        replayBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        replayBtn->setCoordinateSystemID(0);
        replayBtn->setScale(0.5f);
        replayBtn->setRelativeToScreen(5,8);
        replayBtn->setRenderOrder(51);
        replayBtn->setTranslation(metaio::Vector3d(15.0f, 15.0f, 1.0f));
        replayBtn->setVisible(false);
    }
    NSString* next_model = [[NSBundle mainBundle] pathForResource:@"next"
                                                           ofType:@"png"
                                                      inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (next_model)
    {
        const char *utf8Path = [next_model UTF8String];
        next = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        next->setCoordinateSystemID(2);
        next->setScale(0.6f);
        next->setRenderOrder(10);
        next->setRelativeToScreen(10,8);
        next->setVisible(false);
        next->setTranslation(metaio::Vector3d(0.0f, -80.0f, 5.0f));
    }
    
    NSString* guideSound_model = [[NSBundle mainBundle] pathForResource:@"hot6"
                                                                 ofType:@"3g2"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(guideSound_model)
    {
        const char *utf8Path = [guideSound_model UTF8String];
        guideSound =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        guideSound->setCoordinateSystemID(0);
    }
}
-(void) createSecondPage
{
    NSString* linkingPath = [[NSBundle mainBundle] pathForResource:@"linking"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (linkingPath)
    {
        const char *utf8Path = [linkingPath UTF8String];
        linking = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        linking->setScale(0.5f);
        linking->setRenderOrder(50,false,true);
        linking->setVisible(false);
        linking->setTranslation(metaio::Vector3d(0.0f, 0.0f, 10.0f));
        linking->setRelativeToScreen(48,8);
    }
    NSString* secondPageGuide_model = [[NSBundle mainBundle] pathForResource:@"secondPageGuide"
                                                                  ofType:@"mov"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(secondPageGuide_model)
    {
        const char *utf8Path = [secondPageGuide_model UTF8String];
        secondPageGuide =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        secondPageGuide->setScale(3.0f);
        secondPageGuide->setRelativeToScreen(48,8);
        secondPageGuide->setVisible(false);
        secondPageGuide->setRenderOrder(18,false,true);
        secondPageGuide->setTranslation(metaio::Vector3d(0.0f, 0.0f, 15.0f));
        secondPageGuide->setCoordinateSystemID(0);
    }
    NSString* findPOI_path = [[NSBundle mainBundle] pathForResource:@"findPOI"
                                                            ofType:@"jpg"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (findPOI_path)
    {
        const char *utf8Path = [findPOI_path UTF8String];
        findPOI = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        findPOI->setScale(1.5f);
        findPOI->setRenderOrder(5,false,true);
        findPOI->setVisible(false);
        findPOI->setTranslation(metaio::Vector3d(0.0f, -50.0f, 5.0f));
        findPOI->setRelativeToScreen(48,8);
    }
    NSString* pictureTouchGuide_path = [[NSBundle mainBundle] pathForResource:@"pictureTouchGuide"
                                                             ofType:@"jpg"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (pictureTouchGuide_path)
    {
        const char *utf8Path = [pictureTouchGuide_path UTF8String];
        pictureTouchGuide = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        pictureTouchGuide->setScale(1.5f);
        pictureTouchGuide->setRenderOrder(16,false,true);
        pictureTouchGuide->setVisible(false);
        pictureTouchGuide->setTranslation(metaio::Vector3d(0.0f, 0.0f, 16.0f));
        pictureTouchGuide->setRelativeToScreen(48,8);
    }
}
-(void) createFinalPage
{
    NSString* topFramPath = [[NSBundle mainBundle] pathForResource:@"topFrame"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (topFramPath)
    {
        const char *utf8Path = [topFramPath UTF8String];
        topFrame = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        topFrame->setScale(0.3f);
        topFrame->setRelativeToScreen(24,8);
        topFrame->setVisible(false);
    }
    NSString* leftFramePath = [[NSBundle mainBundle] pathForResource:@"leftFrame"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (leftFramePath)
    {
        const char *utf8Path = [leftFramePath UTF8String];
        leftFrame = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        leftFrame->setScale(10.0f);
        leftFrame->setRelativeToScreen(33,8);
        leftFrame->setVisible(false);
    }
    NSString* rightFramePath = [[NSBundle mainBundle] pathForResource:@"rightFrame"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (rightFramePath)
    {
        const char *utf8Path = [rightFramePath UTF8String];
        rightFrame = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        rightFrame->setScale(10.0f);
        rightFrame->setRelativeToScreen(34,8);
        rightFrame->setVisible(false);
    }
    NSString* bottomFramePath = [[NSBundle mainBundle] pathForResource:@"bottomFrame"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (bottomFramePath)
    {
        const char *utf8Path = [bottomFramePath UTF8String];
        bottomFrame = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        bottomFrame->setScale(0.3f);
        bottomFrame->setRelativeToScreen(20,8);
        bottomFrame->setVisible(false);
    }
    NSString* frameModelLeftPath = [[NSBundle mainBundle] pathForResource:@"frameModelLeft"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (frameModelLeftPath)
    {
        const char *utf8Path = [frameModelLeftPath UTF8String];
        frameModelLeft = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        frameModelLeft->setScale(1.5f);
        frameModelLeft->setRelativeToScreen(5,8);
        frameModelLeft->setTranslation(metaio::Vector3d(32.0f, 15.0f, 2.0f));
        frameModelLeft->setVisible(false);
    }
    NSString* frameModelRightPath = [[NSBundle mainBundle] pathForResource:@"frameModelRight"
                                                                   ofType:@"png"
                                                              inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (frameModelRightPath)
    {
        const char *utf8Path = [frameModelRightPath UTF8String];
        frameModelRight = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        frameModelRight->setScale(1.7f);
        frameModelRight->setRelativeToScreen(6,8);
        frameModelRight->setTranslation(metaio::Vector3d(-30.0f, 15.0f, 1.0f));
        frameModelRight->setVisible(false);
    }
    NSString* yesBtnPath = [[NSBundle mainBundle] pathForResource:@"yesBtn"
                                                                    ofType:@"png"
                                                               inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (yesBtnPath)
    {
        const char *utf8Path = [yesBtnPath UTF8String];
        yesBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        yesBtn->setScale(0.43f);
        yesBtn->setVisible(false);
        yesBtn->setRelativeToScreen(48,8);
        yesBtn->setRenderOrder(21);
        yesBtn->setTranslation(metaio::Vector3d(-58.0f, -30.0f, 21.0f));
    }
    NSString* noBtnPath = [[NSBundle mainBundle] pathForResource:@"noBtn"
                                                           ofType:@"png"
                                                      inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (noBtnPath)
    {
        const char *utf8Path = [noBtnPath UTF8String];
        noBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        noBtn->setScale(0.43f);
        noBtn->setVisible(false);
        noBtn->setRenderOrder(21);
        noBtn->setRelativeToScreen(48,8);
        noBtn->setTranslation(metaio::Vector3d(58.0f, -30.0f, 21.0f));
    }
    NSString* checkPanelPath = [[NSBundle mainBundle] pathForResource:@"checkPanel"
                                                          ofType:@"png"
                                                     inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (checkPanelPath)
    {
        const char *utf8Path = [checkPanelPath UTF8String];
        checkPanel = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        checkPanel->setScale(2.0f);
        checkPanel->setVisible(false);
        checkPanel->setRenderOrder(20);
        checkPanel->setRelativeToScreen(48,8);
        checkPanel->setTranslation(metaio::Vector3d(0.0f, 0.0f,20.0f));
    }
    NSString* checkWordPath = [[NSBundle mainBundle] pathForResource:@"checkWord"
                                                          ofType:@"png"
                                                     inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (checkWordPath)
    {
        const char *utf8Path = [checkWordPath UTF8String];
        checkWord = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        checkWord->setScale(0.25f);
        checkWord->setVisible(false);
        checkWord->setRenderOrder(21);
        checkWord->setRelativeToScreen(48,8);
        checkWord->setTranslation(metaio::Vector3d(0.0f, 25.0f,21.0f));
    }
}

-(void) createShading:(metaio::IGeometry *)tempModel
{
    NSString* shaderMaterialsFilename = [[NSBundle mainBundle] pathForResource:@"shader_materials"
                                                                        ofType:@"xml"
                                                                   inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (shaderMaterialsFilename)
    {
        const char* utf8Path = [shaderMaterialsFilename UTF8String];
        bool successaaa = m_pMetaioSDK->loadShaderMaterials(metaio::Path::fromUTF8(utf8Path));

        tempModel->setShaderMaterial("tutorial_customshading");
        
        m_pCallback = new Callback(self);
        m_pCallback->status = status;
        
        m_pCallback->testDevice = [[UIDevice currentDevice] platformString];

        tempModel->setShaderMaterialOnSetConstantsCallback(m_pCallback);
    }
}

- (void)dealloc
{
    //remove shader material callback
    if(model3D3!=NULL)model3D3->setShaderMaterialOnSetConstantsCallback(0);
    delete m_pCallback;
    m_pCallback = 0;
}

-(void) changeSeconPage //第一次
{
    firstPageTalk->setVisible(false);
    m_pMetaioSDK->unloadGeometry(firstPageModel);
    firstPageModel=NULL;
    tangshengSound->stopMovieTexture();
    
    detectRadarExit=0;
    //m_radar->setVisible(true);
    secondPageGuide->setVisible(true);
    secondPageGuide->startMovieTexture(true);
    blackBack->setVisible(true);
    m_radar->setVisible(false);
    
}

-(void) create3D
{
    NSString* mapBtn_model = [[NSBundle mainBundle] pathForResource:@"mapBtn"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (mapBtn_model)
    {
        const char *utf8Path = [mapBtn_model UTF8String];
        mapBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        mapBtn->setCoordinateSystemID(0);
        mapBtn->setScale(0.45f);
        mapBtn->setRenderOrder(6);
        mapBtn->setRelativeToScreen(10,8);
        mapBtn->setVisible(false);
        mapBtn->setTranslation(metaio::Vector3d(0.0f, -3.0f, 1.0f));
    }
    NSString* map_model = [[NSBundle mainBundle] pathForResource:@"map0"
                                                          ofType:@"png"
                                                     inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (map_model)
    {
        const char *utf8Path = [map_model UTF8String];
        map = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        map->setCoordinateSystemID(0);
        map->setScale(3.5f);
        map->setRelativeToScreen(48,8);
        map->setRenderOrder(52,false,true);
        map->setTranslation(metaio::Vector3d(0.0f, -7.0f, 19.0f));
        map->setVisible(false);
    }
    NSString* point1_model = [[NSBundle mainBundle] pathForResource:@"point1"
                                                          ofType:@"png"
                                                     inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point1_model)
    {
        const char *utf8Path = [point1_model UTF8String];
        point1 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point1->setCoordinateSystemID(0);
        point1->setScale(0.6f);
        point1->setRelativeToScreen(48,8);
        point1->setRenderOrder(53,false,true);
        point1->setTranslation(metaio::Vector3d(186.0f, -87.0f, 20.0f));
        point1->setVisible(false);
        point[0] = point1;
    }
    NSString* point2_model = [[NSBundle mainBundle] pathForResource:@"point2"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point2_model)
    {
        const char *utf8Path = [point2_model UTF8String];
        point2 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point2->setCoordinateSystemID(0);
        point2->setScale(0.6f);
        point2->setRelativeToScreen(48,8);
        point2->setRenderOrder(53,false,true);
        point2->setTranslation(metaio::Vector3d(167.0f, -28.0f, 20.0f));
        point2->setVisible(false);
        point[1] = point2;
    }
    NSString* point3_model = [[NSBundle mainBundle] pathForResource:@"point3"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point3_model)
    {
        const char *utf8Path = [point3_model UTF8String];
        point3 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point3->setCoordinateSystemID(0);
        point3->setScale( 0.6f);
        point3->setRelativeToScreen(48,8);
        point3->setRenderOrder(53,false,true);
        point3->setTranslation(metaio::Vector3d(100.0f, -58.0f, 20.0f));
        point3->setVisible(false);
        point[2] = point3;
    }
    NSString* point4_model = [[NSBundle mainBundle] pathForResource:@"point4"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point4_model)
    {
        const char *utf8Path = [point4_model UTF8String];
        point4 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point4->setCoordinateSystemID(0);
        point4->setScale(0.6f);
        point4->setRelativeToScreen(48,8);
        point4->setRenderOrder(53,false,true);
        point4->setTranslation(metaio::Vector3d(25.0f, -35.0f, 20.0f));
        point4->setVisible(false);
        point[3] = point4;
    }
    NSString* point5_model = [[NSBundle mainBundle] pathForResource:@"point5"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point5_model)
    {
        const char *utf8Path = [point5_model UTF8String];
        point5 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point5->setCoordinateSystemID(0);
        point5->setScale(0.6f);
        point5->setRelativeToScreen(48,8);
        point5->setRenderOrder(53,false,true);
        point5->setTranslation(metaio::Vector3d(60.0f, 25.0f, 20.0f));
        point5->setVisible(false);
        point[4] = point5;
    }
    NSString* point6_model = [[NSBundle mainBundle] pathForResource:@"point6"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point6_model)
    {
        const char *utf8Path = [point6_model UTF8String];
        point6 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point6->setCoordinateSystemID(0);
        point6->setScale(0.7f);
        point6->setRelativeToScreen(48,8);
        point6->setRenderOrder(53,false,true);
        point6->setTranslation(metaio::Vector3d(-10.0f, 50.0f, 20.0f));
        point6->setVisible(false);
        point[5] = point6;
    }
    NSString* point7_model = [[NSBundle mainBundle] pathForResource:@"point7"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point7_model)
    {
        const char *utf8Path = [point7_model UTF8String];
        point7 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point7->setCoordinateSystemID(0);
        point7->setScale(0.6f);
        point7->setRelativeToScreen(48,8);
        point7->setRenderOrder(53,false,true);
        point7->setTranslation(metaio::Vector3d(-90.0f, 20.0f, 20.0f));
        point7->setVisible(false);
        point[6] = point7;
    }
    NSString* point8_model = [[NSBundle mainBundle] pathForResource:@"point8"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (point8_model)
    {
        const char *utf8Path = [point8_model UTF8String];
        point8 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        point8->setCoordinateSystemID(0);
        point8->setScale(0.6f);
        point8->setRelativeToScreen(48,8);
        point8->setRenderOrder(53,false,true);
        point8->setTranslation(metaio::Vector3d(-135.0f, 80.0f, 20.0f));
        point8->setVisible(false);
        point[7] = point8;
    }
    
    NSString* closeMap_model = [[NSBundle mainBundle] pathForResource:@"btn_mapClose"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (closeMap_model)
    {
        const char *utf8Path = [closeMap_model UTF8String];
        closeMap = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        closeMap->setCoordinateSystemID(0);
        closeMap->setScale(0.3f);
        if(testScreen==0){
            closeMap->setTranslation(metaio::Vector3d(-39.0f, -76.0f, 20.0f));
            closeMap->setRelativeToScreen(10,8);
        }
        else{
            closeMap->setTranslation(metaio::Vector3d(-39.0f, 85.0f, 20.0f));
            closeMap->setRelativeToScreen(34,8);
        }
        closeMap->setVisible(false);
        closeMap->setRenderOrder(52, false, true);
    }
    NSString* finder_model = [[NSBundle mainBundle] pathForResource:@"finder0"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (finder_model)
    {
        const char *utf8Path = [finder_model UTF8String];
        finder = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        finder->setCoordinateSystemID(0);
        finder->setScale(2.3f);
        finder->setRelativeToScreen(48,8);
        finder->setVisible(false);
        finder->setTranslation(metaio::Vector3d(0.0f, -20.0f, 5.0f));
        finder->setTransparency(0.3);
    }
    NSString* effectMovie_model = [[NSBundle mainBundle] pathForResource:@"effect"
                                                                  ofType:@"3g2"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(effectMovie_model)
    {
        const char *utf8Path = [effectMovie_model UTF8String];
        effectMovie =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), true,false);
        if(effectMovie)
        {
            effectMovie->setScale(4.0f);
            //effectMovie->setRelativeToScreen(48,8);
            effectMovie->setVisible(false);
            effectMovie->setCoordinateSystemID(0);
        }
    }
    NSString* instantBtn_model = [[NSBundle mainBundle] pathForResource:@"instantBtn"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (instantBtn_model)
    {
        const char *utf8Path = [instantBtn_model UTF8String];
        instantBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        instantBtn->setCoordinateSystemID(0);
        instantBtn->setScale(0.5f);
        instantBtn->setRelativeToScreen(34,8);
        instantBtn->setRenderOrder(1,false, true);
        instantBtn->setTranslation(metaio::Vector3d(-15.0f, -20.0f, 0.0f));
        instantBtn->setVisible(false);
    }
    NSString* resetBtn_model = [[NSBundle mainBundle] pathForResource:@"resetBtn"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (resetBtn_model)
    {
        const char *utf8Path = [resetBtn_model UTF8String];
        resetBtn = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        resetBtn->setCoordinateSystemID(0);
        resetBtn->setScale(0.5f);
        resetBtn->setRelativeToScreen(34,8);
        resetBtn->setRenderOrder(1,false, true);
        resetBtn->setTranslation(metaio::Vector3d(-15.0f, -20.0f, 0.0f));
        resetBtn->setVisible(false);
    }
    
    NSString* instantGuide_model = [[NSBundle mainBundle] pathForResource:@"instantGuide"
                                                                   ofType:@"png"
                                                              inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (instantGuide_model)
    {
        const char *utf8Path = [instantGuide_model UTF8String];
        instantGuide = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        instantGuide->setCoordinateSystemID(0);
        instantGuide->setScale(0.3f);
        instantGuide->setRelativeToScreen(34,8);
        instantGuide->setTranslation(metaio::Vector3d(-63.0f, -5.0f, 0.0f));
        instantGuide->setVisible(false);
    }
}

-(void) createPictureTaken
{
    NSString* btnModelSwift_model = [[NSBundle mainBundle] pathForResource:@"btn_modelSwitch"
                                                                    ofType:@"png"
                                                               inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (btnModelSwift_model)
    {
        const char *utf8Path = [btnModelSwift_model UTF8String];
        btnModelSwift = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        btnModelSwift->setCoordinateSystemID(0);
        btnModelSwift->setScale(0.5f);
        btnModelSwift->setRelativeToScreen(5,8);
        btnModelSwift->setRenderOrder(10);
        btnModelSwift->setTranslation(metaio::Vector3d(25.0f, 15.0f, 0.0f));
        btnModelSwift->setVisible(false);
    }
    NSString* btnCamara_model = [[NSBundle mainBundle] pathForResource:@"btn_modelCamShot"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (btnCamara_model)
    {
        const char *utf8Path = [btnCamara_model UTF8String];
        btnCamara = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        btnCamara->setCoordinateSystemID(0);
        btnCamara->setScale(0.5f);
        btnCamara->setRelativeToScreen(34,8);
        btnCamara->setRenderOrder(1,false, true);
        btnCamara->setTranslation(metaio::Vector3d(-15.0f, -20.0f, 0.0f));
        btnCamara->setVisible(false);
    }
    NSString* controll_model = [[NSBundle mainBundle] pathForResource:@"controll"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (controll_model)
    {
        const char *utf8Path = [controll_model UTF8String];
        controll = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        controll->setCoordinateSystemID(0);
        controll->setScale(1.0f);
        controll->setRelativeToScreen(6,8);
        controll->setTranslation(metaio::Vector3d(0.0f, 0.0f, 0.0f));
        controll->setRenderOrder(1,false, true);
        controll->setVisible(false);
        controllStickPoi=controll->getTranslation();
        
        [m_gestureHandler2 addObject:controll andGroup:1];
    }
    NSString* controllBack_model = [[NSBundle mainBundle] pathForResource:@"controll_back"
                                                                   ofType:@"png"
                                                              inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (controllBack_model)
    {
        const char *utf8Path = [controllBack_model UTF8String];
        controllBack = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        controllBack->setCoordinateSystemID(0);
        controllBack->setScale(1.0f);
        controllBack->setRelativeToScreen(6,8);
        controll->setRenderOrder(1,false, true);
        controllBack->setVisible(false);
    }
    NSString* touchGuide_model = [[NSBundle mainBundle] pathForResource:@"gestureGuide"
                                                                 ofType:@"png"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    if (touchGuide_model)
    {
        const char *utf8Path = [touchGuide_model UTF8String];
        touchGuide = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        touchGuide->setCoordinateSystemID(0);
        touchGuide->setScale(3.0f);
        touchGuide->setRelativeToScreen(48,8);
        touchGuide->setRenderOrder(16,false,true);
        touchGuide->setVisible(false);
        touchGuide->setTranslation(metaio::Vector3d(0.0f, 0.0f, 16.0f));
    }
    NSString* cameraGuide_model = [[NSBundle mainBundle] pathForResource:@"cameraGuide"
                                                                ofType:@"png"
                                                           inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (cameraGuide_model)
    {
        const char *utf8Path = [cameraGuide_model UTF8String];
        cameraGuide = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        cameraGuide->setCoordinateSystemID(0);
        cameraGuide->setScale(0.4f);
        cameraGuide->setRelativeToScreen(34,8);
        cameraGuide->setTranslation(metaio::Vector3d(-53.0f, -20.0f, 0.0f));
        cameraGuide->setVisible(false);
    }
}

-(void) closeFirstPage //第一次的第二個 跟 其他的guide
{
    m_pMetaioSDK->unloadGeometry(firstPageModel);
    firstPageModel=NULL;
    
    firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:@"talk1" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    
    tangshengSound->setMovieTexture([[[NSBundle mainBundle] pathForResource:@"guide1" ofType:@"mp3" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    
    const char *modelutf8Path2 = [modelPath[8] UTF8String];
    firstPageModel=  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(modelutf8Path2));
    firstPageModel->setScale(90.0f);
    firstPageModel->setRelativeToScreen(5,8);
    firstPageModel->setRenderOrder(7);
    firstPageModel->setTranslation(metaio::Vector3d(15.0f, 30.0f, 4.0f));
    
    firstPageTalk->setVisible(true);
    firstPageModel->setVisible(true);
    firstPageModel->startAnimation("ani_talk",true);
    tangshengSound->startMovieTexture(false);
}

-(void) closeGuidePage
{
    m_pMetaioSDK->setTrackingConfiguration("GPS");
    
    if(status==0)
    {
        m_pMetaioSDK->setLLAObjectRenderingLimits(5, 200);
        
        m_radar->setVisible(true);
        detectRadarExit=1;
        
        blackBack->setVisible(false);
        secondPageGuide->setVisible(false);
        
        Geo1->setTransparency(0);
    }
    else if(status<6)
    {
        Geo1->setTransparency(1);
        mapBtn->setVisible(true);
    }
    else
    {
        detectRadarExit=1;
        m_radar->setVisible(true);
        playBtnStatus=0;
        m_pMetaioSDK->setLLAObjectRenderingLimits(5, 200);
    }
    
    iknow->setVisible(false);
    firstPageTalk->setVisible(false);
    if(firstPageModel!=NULL)firstPageModel->stopAnimation();
    m_pMetaioSDK->unloadGeometry(firstPageModel);
    firstPageModel=NULL;
    tangshengSound->pauseMovieTexture();
    finder->setScale(2.3f);
    
    if(status!=0 && status<6) detectFinder=1;
}

-(void) change3D
{
    startDetecGPS=0;
    
    //clean view
    m_radar->setVisible(false);
    detectRadarExit=0;
    arriveAlert->setVisible(false);
    Geo1->setTransparency(1);
    
    //add view
    //finder->setVisible(true);
    mapBtn->setVisible(true);
    
    pleaseTouchDim->setTexture([[[NSBundle mainBundle] pathForResource:@"turnModelGuide" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        
    pictureTouchGuide->setVisible(true);
    blackBack->setVisible(true);
    iknow->setVisible(true);

    m_pMetaioSDK->setLLAObjectRenderingLimits(0, 0);
}

-(void) anguohouWalk
{
    float angle = -heading+M_PI/3-M_PI/15+0.05;
    
    float newX = 1.2*cos(angle) - 1.2*sin(angle);
    float newY = 1.2*sin(angle) + 1.2*cos(angle);
    
    vector.deleteAll();
    vectorRe.deleteAll();
    
    metaio::Vector3d oriTranslation = anguohou->getTranslation();
    float oriX = oriTranslation.x;
    float oriY = oriTranslation.y;
    float oriZ = oriTranslation.z;
    metaio::Vector3d newTranslation;
    
    newTranslation = metaio::Vector3d(oriX+newX,oriY+newY,oriZ-1);
    
    metaio::Vector3d oriScale = anguohou->getScale();
    metaio::Rotation oriRotation = anguohou->getRotation();
    
    key0.AnimationKeyFrame::index=0;
    key0.AnimationKeyFrame::translation=oriTranslation;
    key0.AnimationKeyFrame::scale=oriScale;
    key0.AnimationKeyFrame::rotation=oriRotation;
    
    key50.AnimationKeyFrame::index=50;
    key50.AnimationKeyFrame::translation=newTranslation;
    key50.AnimationKeyFrame::scale=oriScale;
    key50.AnimationKeyFrame::rotation=oriRotation;
    
    vector.push_back(key0);
    vector.push_back(key50);
    
    cAni.keyframes=vector;
    NSLog(@"walkout");
    anguohou->setCustomAnimation("walkOut", cAni);
    
    key0.AnimationKeyFrame::index=50;
    key50.AnimationKeyFrame::index=0;
    
    vectorRe.push_back(key0);
    vectorRe.push_back(key50);
    
    cAni.keyframes=vectorRe;
    
    anguohou->setCustomAnimation("walkIn", cAni);
}

-(void) walk1
{
    metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,shouwei_02,shouwei_04,shouwei_05,shouwei_06,hulu1,out3D};
    
    //算角度
    float angle = -heading+M_PI*2/3-M_PI/15;
    float angle1 = -heading+M_PI*2/3-M_PI/15-0.15;
    
    float newX = 12500*cos(angle1) - 5400*sin(angle1);
    float newY = 12500*sin(angle1) + 5400*cos(angle1);
    
    float newX_1 = 22*cos(angle) - 5*sin(angle);
    float newY_1 = 22*sin(angle) + 5*cos(angle);
    
    float newX_2 = 372*cos(angle) - 87*sin(angle);
    float newY_2 = 372*sin(angle) + 87*cos(angle);
    
    float newX_3 = 143*cos(angle) - 34*sin(angle);
    float newY_3 = 143*sin(angle) + 34*cos(angle);
    
    float newX_4 = 122*cos(angle) - 29*sin(angle);
    float newY_4 = 122*sin(angle) + 29*cos(angle);
    
    float newX_5 = 90*cos(angle) - 21*sin(angle);
    float newY_5 = 90*sin(angle) + 21*cos(angle);
    
    float newX_6 = 90*cos(angle) - 21*sin(angle);
    float newY_6 = 90*sin(angle) + 21*cos(angle);
    
    float newX_7 = 30*cos(angle1) - 7*sin(angle1);
    float newY_7 = 30*sin(angle1) + 7*cos(angle1);
    
    float newX_8 = 50*cos(angle1) - 10*sin(angle1);
    float newY_8 = 50*sin(angle1) + 10*cos(angle1);
 
    //動畫
    int i;
    for(i=0; i<9; i++)
    {
        vector.deleteAll();
        vectorRe.deleteAll();
 
        metaio::Vector3d oriTranslation = temp[i]->getTranslation();
        float oriX = oriTranslation.x;
        float oriY = oriTranslation.y;
        float oriZ = oriTranslation.z;
        metaio::Vector3d newTranslation;
        
        if(i == 0)newTranslation = metaio::Vector3d(oriX+newX,oriY+newY,oriZ);
        else if(i == 1)newTranslation = metaio::Vector3d(oriX+newX_1,oriY+newY_1,oriZ);
        else if(i == 2)newTranslation = metaio::Vector3d(oriX+newX_2,oriY+newY_2,oriZ-1);
        else if(i == 3)newTranslation = metaio::Vector3d(oriX+newX_3,oriY+newY_3,oriZ);
        else if(i == 4)newTranslation = metaio::Vector3d(oriX+newX_4,oriY+newY_4,oriZ);
        else if(i == 5)newTranslation = metaio::Vector3d(oriX+newX_5,oriY+newY_5,oriZ);
        else if(i == 6)newTranslation = metaio::Vector3d(oriX+newX_6,oriY+newY_6,oriZ);
        else if(i == 7)newTranslation = metaio::Vector3d(oriX+newX_7,oriY+newY_7,oriZ-2.7);
        else if(i == 8)newTranslation = metaio::Vector3d(oriX+newX_8,oriY+newY_8,oriZ-7.5);
        
        metaio::Vector3d oriScale = temp[i]->getScale();
        metaio::Rotation oriRotation = temp[i]->getRotation();
 
        key0.AnimationKeyFrame::index=0;
        key0.AnimationKeyFrame::translation=oriTranslation;
        key0.AnimationKeyFrame::scale=oriScale;
        key0.AnimationKeyFrame::rotation=oriRotation;
        
        key50.AnimationKeyFrame::index=50;
        key50.AnimationKeyFrame::translation=newTranslation;
        key50.AnimationKeyFrame::scale=oriScale;
        key50.AnimationKeyFrame::rotation=oriRotation;
        
        vector.push_back(key0);
        vector.push_back(key50);
        
        cAni.keyframes=vector;
        
        temp[i]->setCustomAnimation("in1", cAni);
        
        key0.AnimationKeyFrame::index=50;
        key50.AnimationKeyFrame::index=0;
        
        vectorRe.push_back(key0);
        vectorRe.push_back(key50);
        
        cAni.keyframes=vectorRe;
        
        temp[i]->setCustomAnimation("out1", cAni);
    }
}
-(void) walk2
{
    metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,shouwei_02,shouwei_04,shouwei_05,shouwei_06,hulu2,out3D2};
    
    //算角度
    float angle = -heading+M_PI/3-0.05;
    
    float newX = 14900*cos(angle) - 3500*sin(angle);
    float newY = 14900*sin(angle) + 3500*cos(angle);
    
    float newX_1 = 22*cos(angle) - 5*sin(angle);
    float newY_1 = 22*sin(angle) + 5*cos(angle);
    
    float newX_2 = 372*cos(angle) - 87*sin(angle);
    float newY_2 = 372*sin(angle) + 87*cos(angle);
    
    float newX_3 = 143*cos(angle) - 34*sin(angle);
    float newY_3 = 143*sin(angle) + 34*cos(angle);
    
    float newX_4 = 122*cos(angle) - 29*sin(angle);
    float newY_4 = 122*sin(angle) + 29*cos(angle);
    
    float newX_5 = 90*cos(angle) - 21*sin(angle);
    float newY_5 = 90*sin(angle) + 21*cos(angle);
    
    float newX_6 = 90*cos(angle) - 21*sin(angle);
    float newY_6 = 90*sin(angle) + 21*cos(angle);
    
    float newX_7 = 54*cos(angle) - 12*sin(angle);
    float newY_7 = 54*sin(angle) + 12*cos(angle);
    
    float newX_8 = 54*cos(angle) - 12*sin(angle);
    float newY_8 = 54*sin(angle) + 12*cos(angle);
    
    //動畫
    int i;
    for(i=0; i<9; i++)
    {
        vector.deleteAll();
        vectorRe.deleteAll();
        
        metaio::Vector3d oriTranslation = temp[i]->getTranslation();
        float oriX = oriTranslation.x;
        float oriY = oriTranslation.y;
        float oriZ = oriTranslation.z;
        metaio::Vector3d newTranslation;
        
        
        if(i == 0)newTranslation = metaio::Vector3d(oriX+newX,oriY+newY,oriZ);
        else if(i == 1)newTranslation = metaio::Vector3d(oriX+newX_1,oriY+newY_1,oriZ);
        else if(i == 2)newTranslation = metaio::Vector3d(oriX+newX_2,oriY+newY_2,oriZ-1);
        else if(i == 3)newTranslation = metaio::Vector3d(oriX+newX_3,oriY+newY_3,oriZ);
        else if(i == 4)newTranslation = metaio::Vector3d(oriX+newX_4,oriY+newY_4,oriZ);
        else if(i == 5)newTranslation = metaio::Vector3d(oriX+newX_5,oriY+newY_5,oriZ);
        else if(i == 6)newTranslation = metaio::Vector3d(oriX+newX_6,oriY+newY_6,oriZ);
        else if(i == 7)newTranslation = metaio::Vector3d(oriX+newX_7,oriY+newY_7,oriZ-7.5);
        else if(i == 8)newTranslation = metaio::Vector3d(oriX+newX_8,oriY+newY_8,oriZ-5);
        
        metaio::Vector3d oriScale = temp[i]->getScale();
        metaio::Rotation oriRotation = temp[i]->getRotation();
        
        key0.AnimationKeyFrame::index=0;
        key0.AnimationKeyFrame::translation=oriTranslation;
        key0.AnimationKeyFrame::scale=oriScale;
        key0.AnimationKeyFrame::rotation=oriRotation;
        
        key50.AnimationKeyFrame::index=50;
        key50.AnimationKeyFrame::translation=newTranslation;
        key50.AnimationKeyFrame::scale=oriScale;
        key50.AnimationKeyFrame::rotation=oriRotation;
        
        vector.push_back(key0);
        vector.push_back(key50);
        
        cAni.keyframes=vector;
        
        temp[i]->setCustomAnimation("in2", cAni);
        
        key0.AnimationKeyFrame::index=50;
        key50.AnimationKeyFrame::index=0;
        
        vectorRe.push_back(key0);
        vectorRe.push_back(key50);
        
        cAni.keyframes=vectorRe;
        
        temp[i]->setCustomAnimation("out2", cAni);
    }
}

-(void) walk3
{
    metaio::IGeometry* temp[] = {env3D,hulu3,out3D3};
    
    //算角度
    float angle = -heading+M_PI/7-M_PI/2+M_PI/15;

    float newX = 5100*cos(angle) - 16100*sin(angle);
    float newY = 5100*sin(angle) + 16100*cos(angle);
    
    float newX_2 = 17*cos(angle) - 54*sin(angle);
    float newY_2 = 17*sin(angle) + 54*cos(angle);
    
    float newX_3 = 17*cos(angle) - 54*sin(angle);
    float newY_3 = 17*sin(angle) + 54*cos(angle);
    
    //動畫
    int i;
    for(i=0; i<3; i++)
    {
        vector.deleteAll();
        vectorRe.deleteAll();
        
        NSLog(@"get trans: %d %f %f",i, temp[i]->getTranslation().x, temp[i]->getTranslation().y);
        
        metaio::Vector3d oriTranslation = temp[i]->getTranslation();
        float oriX = oriTranslation.x;
        float oriY = oriTranslation.y;
        float oriZ = oriTranslation.z;
        metaio::Vector3d newTranslation;
        
        
        if(i == 0)newTranslation = metaio::Vector3d(oriX+newX,oriY+newY,oriZ);
        else if(i == 1)newTranslation = metaio::Vector3d(oriX+newX_2,oriY+newY_2,oriZ-7);
        else if(i == 2)newTranslation = metaio::Vector3d(oriX+newX_3,oriY+newY_3,oriZ-3);
        metaio::Vector3d oriScale = temp[i]->getScale();
        metaio::Rotation oriRotation = temp[i]->getRotation();
        
        NSLog(@"new trans: %d %f %f",i, newTranslation.x, newTranslation.y);
        
        key0.AnimationKeyFrame::index=0;
        key0.AnimationKeyFrame::translation=oriTranslation;
        key0.AnimationKeyFrame::scale=oriScale;
        key0.AnimationKeyFrame::rotation=oriRotation;
        
        key50.AnimationKeyFrame::index=50;
        key50.AnimationKeyFrame::translation=newTranslation;
        key50.AnimationKeyFrame::scale=oriScale;
        key50.AnimationKeyFrame::rotation=oriRotation;
        
        vector.push_back(key0);
        vector.push_back(key50);
        
        cAni.keyframes=vector;

        temp[i]->setCustomAnimation("in3", cAni);
        
        key0.AnimationKeyFrame::index=50;
        key50.AnimationKeyFrame::index=0;
        
        vectorRe.push_back(key0);
        vectorRe.push_back(key50);
        
        cAni.keyframes=vectorRe;

        temp[i]->setCustomAnimation("out3", cAni);
    }
}

- (void) parseSRT:(int) testSidePanel chooseTalk:(int) talk{
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
    else if(testSidePanel==8)
    {
        NSString *file = [NSString stringWithFormat:@"QSCtalk%d", talk];
        path = [[NSBundle mainBundle] pathForResource:file ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    }
    else if(testSidePanel==9)
    {
        NSString *file = [NSString stringWithFormat:@"secondMissionGuide%d", talk];
        path = [[NSBundle mainBundle] pathForResource:file ofType:@"srt" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
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
            //(void) [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&textString];
            (void) [scanner scanUpToString:@"\r\n\r\n" intoString:&textString];
            //(void) [scanner scanUpToString:@"\r\n" intoString:&textString];
            //(void) [scanner scanUpToString:@"," intoString:&textString];
            text[[indexString intValue]]=textString;
            NSLog(@"get%d %@ end",[indexString intValue],text[[indexString intValue]]);
            endIndex++;
        }
    }
}

-(void)nextClick
{
    if(nextPageTime==0)
    {
        m_pMetaioSDK->setTrackingConfiguration("GPS");
        //detectFirstLoad=0;
        //trackDetect=0;
        
        /*if(status==0)
        {
            pleaseTouch->setTexture([[[NSBundle mainBundle] pathForResource:nextString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            pleaseTouch->setVisible(true);
        }*/
        
        [self addView];
        
        if(status!=4)
            [self setActiveModel:status];
        
        nextPageTime=1;
        status++;
        if(status>finalStatus)
            finalStatus=status;
        
        //change next
        NSString* nextString = [NSString stringWithFormat:@"next%i", status];
        next->setTexture([[[NSBundle mainBundle] pathForResource:nextString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        
        //get model rotation value
        if(status==1) modelPos=metaio::Vector3d(-M_PI/2, -M_PI/2, 0);
        else modelPos=metaio::Vector3d(0, -M_PI/2, 0);
        
        //說明層
        if(status==1)
            [self pictureTakenGuide];
        
    }
    else if(nextPageTime==1)
    {
        if(testQSC==1)
        {
            //change map
            NSString* mapString = [NSString stringWithFormat:@"map%i", status];
            map->setTexture([[[NSBundle mainBundle] pathForResource:mapString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            int i;
            for(i=0; i<8; i++)
                point[i]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"point%i", i+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            point[status]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"pointL%i", status+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            testQSC=0;
            secondMissionEnd=0;
        }
        
        //change map
        NSString* mapString = [NSString stringWithFormat:@"map%i", status];
        if(status!=8 && status==finalStatus) map->setTexture([[[NSBundle mainBundle] pathForResource:mapString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        int i;
        for(i=0; i<8; i++)
            point[i]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"point%i", i+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        if(status<8)point[status]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"pointL%i", status+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);

        next->setTexture([[[NSBundle mainBundle] pathForResource:@"next" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);

        if(status==8)
            [self missionComplete];
        else
            [self changeMission];
        
        nextPageTime=0;
     }

}

-(void) changeMission
{
    NSLog(@"i am here");
    
    checkStatus=status;
    
    [[[Database alloc] init] open];
    [[[Database alloc] init] updateData:finalStatus];
    [[[Database alloc] init] close];
    
    getModelSize=0;
    firstTrack=0;
    
    [m_gestureHandler removeObject:people];
    [m_gestureHandler removeObject:pictureModel];
    [m_gestureHandler1 removeObject:people];
    [m_gestureHandler1 removeObject:pictureModel];
    
    //unload model3D
    if(status!=5 && model3D3!=NULL)
    {
        m_pMetaioSDK->unloadGeometry(model3D3);
        model3D3=NULL;
    }
    
    //upload geometry
    setActiveModel=NULL;
    if(people!=NULL && pictureModel!=NULL)
    {
        m_pMetaioSDK->unloadGeometry(people);
        m_pMetaioSDK->unloadGeometry(pictureModel);
        pictureModel = NULL;
        people=NULL;
    }
    
    
    
    iknowTime=1;
    if(status>5)
    {
        Geo1->setTransparency(0);
        firstTimePlay=1;//for the last two
        pleaseTouchDim->setTexture([[[NSBundle mainBundle] pathForResource:@"turnPoiGuide" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
    
    getTouchEnd=0;//controll stick
    
    NSString *soundPath;
    NSString *talkPath;
    
    if(Geo1!=NULL)
        annotatedGeometriesGroup->removeGeometry(Geo1);
    
    
    metaio::LLACoordinate lla = [self getLLA:status];
    
    //改語音和人物
    NSString* talkingString = [NSString stringWithFormat:@"talk%i", status+1];
    firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:talkingString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    NSString* guideString = [NSString stringWithFormat:@"guide%i", status+1];
    tangshengSound->setMovieTexture([[[NSBundle mainBundle] pathForResource:guideString ofType:@"mp3" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    
    if(status<6)
    {
        //改辨識框
        NSString *finderString = [NSString stringWithFormat:@"finder%i", status];
        finder->setTexture([[[NSBundle mainBundle] pathForResource:finderString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
    
    //改guide model
    const char *modelutf8Path2 = [modelPath[status+8] UTF8String];
    //firstPageModel->setTexture(metaio::Path::fromUTF8(modelutf8Path2));
    firstPageModel=  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(modelutf8Path2));
    firstPageModel->setScale(90.0f);
    firstPageModel->setRelativeToScreen(5,8);
    firstPageModel->setRenderOrder(7);
    firstPageModel->setTranslation(metaio::Vector3d(15.0f, 30.0f, 4.0f));
    
    //改poi座標點
    Geo1->setTranslationLLA(lla);
    
    //clean view
    next->setVisible(false);
    controll->setVisible(false);
    controllBack->setVisible(false);
    btnCamara->setVisible(false);
    btnModelSwift->setVisible(false);
    mapBtn->setVisible(false);
    finder->setVisible(false);
    if(status==5 && guowang!=NULL)
    {
        if(QSCtalk!=NULL) QSCtalk->pauseMovieTexture();
        
        recordStatus=0;
        
        metaio::IGeometry* unload[] = {treasureBox,env3D,enter3D,out3D,enter3D2,out3D2,enter3D3,out3D3,missionBar,guowang,guideModel1,guideModel2,guideModel3,guideModel4,guanyuan,anguohou,QSCtalk,secondMissionGuide,shouweiAlert};
        
        int i;
        for(i=0; i<19; i++)
        {
            if(unload[i]!=NULL)
            {
                m_pMetaioSDK->unloadGeometry(unload[i]);
                unload[i]=NULL;
                env3D=NULL;
                if(guideModel1!=NULL) guideModel1=NULL;
                if(QSCtalk!=NULL) QSCtalk=NULL;
                if(secondMissionGuide!=NULL) secondMissionGuide=NULL;
            }
        }
        for(i=0; i<7; i++)
        {
            if(shouwei[i]!=NULL)
            {
                m_pMetaioSDK->unloadGeometry(shouwei[i]);
                shouwei[i]=NULL;
            }
        }
        for(i=0; i<4; i++)
        {
            if(hulu[i]!=NULL)
            {
                m_pMetaioSDK->unloadGeometry(hulu[i]);
                hulu[i]=NULL;
            }
        }
        if(textGuide!=NULL)
        {
            m_pMetaioSDK->unloadGeometry(textGuide);
            textGuide=NULL;
        }
    }
    
    //add view
    detectRadarExit=0;
    //m_radar->setVisible(true);
    firstPageTalk->setVisible(true);
    firstPageModel->setVisible(true);
    firstPageModel->startAnimation("ani_talk",true);
    m_radar->setVisible(false);
    iknow->setVisible(true);
    
    tangshengSound->startMovieTexture(false);
    
}

-(void) addView
{
    //tracking stuff
    model3D3->setVisible(false);
    
    //clean view
    replayBtn->setVisible(false);
    next->setVisible(false);
    finder->setVisible(false);
    pleaseTouch->setVisible(false);
    
    //add view
    btnCamara->setVisible(true);
    btnModelSwift->setVisible(true);
    controll->setVisible(true);
    controllBack->setVisible(true);
}

- (void)setActiveModel:(int)modelIndex
{
    if(modelIndex!=4)
    {
        const char *modelutf8Path1 = [modelPath[modelIndex] UTF8String];
        const char *modelutf8Path2 = [modelPath[modelIndex+8] UTF8String];
        pictureModel=  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(modelutf8Path1));
        pictureModel->setVisible(true);
        pictureModel->startAnimation("ani_appear",false);
        pictureModel->setRelativeToScreen(48,8); //位置置中
        
        if(modelIndex==0)
            pictureModel->setScale(18.0f);
        else if(modelIndex==1)
            pictureModel->setScale(12.5f);
        else if(modelIndex==2)
            pictureModel->setScale(7.5f);
        else if(modelIndex==3)
            pictureModel->setScale(14.0f);
        else if(modelIndex==5)
            pictureModel->setScale(22.5f);
        else if(modelIndex==6)
            pictureModel->setScale(20.0f);
        else if(modelIndex==7)
            pictureModel->setScale(6.5f);
        
        pictureModel->setRotation(metaio::Rotation(metaio::Vector3d(-M_PI/2, 0, 0)));

        people=  m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(modelutf8Path2));
        people->setScale(150.0f);
        people->setVisible(false);
        people->setRelativeToScreen(48,8); //位置置中
        people->setTranslation(metaio::Vector3d(0.0f, -55.0f, 0.0f));
        people->setRenderOrder(0,false, true);
        
        setActiveModel=pictureModel;
        
        //testMissonChange=0;
        
        if(status!=0)
        {
            next->setVisible(true);
            next->startAnimation("ani_appear",false);
        }
        
        [m_gestureHandler addObject:setActiveModel andGroup:1];
        [m_gestureHandler1 addObject:setActiveModel andGroup:1];

    }
}

-(void) swiftTouch
{
    if(setActiveModel==people)
    {
        if(modelToggle2->getIsRendered())
        {
            modelToggle2->setVisible(false);
            btnModelSwift->setTranslation(metaio::Vector3d(25.0f, 15.0f, 1.0f));
            btnModelSwift->setRenderOrder(1);
            btnModelSwift->setTranslation(metaio::Vector3d(25.0f, 15.0f, 0.0f));
        }

        modelPos=metaio::Vector3d(0,-M_PI/2,0);
    }
    else
        modelPos=metaio::Vector3d(0,0,0);
    
    if(pictureModel->isVisible())
    {
        if(modelToggle->getIsRendered())
        {
            modelToggle->setVisible(false);
            modelToggle2->setVisible(true);
        }
        
        pictureModel->setVisible(false);
        people->setVisible(true);
        people->setRotation(metaio::Rotation(0,0,0));
        people->setScale(150.0);
        people->setTranslation(metaio::Vector3d(0.0f, -25.0f, 0.0f));
        setActiveModel=people;
        [m_gestureHandler addObject:people andGroup:1];
        [m_gestureHandler1 addObject:people andGroup:1];
        [m_gestureHandler removeObject:pictureModel];
        [m_gestureHandler1 removeObject:pictureModel];
        
        setActiveModel->setTranslation(metaio::Vector3d(0.0f, -20.0f, 0.0f));
    }
    else
    {
        pictureModel->setVisible(true);
        pictureModel->startAnimation("ani_appear",false);
        people->setVisible(false);
        setActiveModel=pictureModel;
        if(status==1)
            pictureModel->setScale(18.0f);
        else if(status==2)
            pictureModel->setScale(12.5f);
        else if(status==3)
            pictureModel->setScale(7.5f);
        else if(status==4)
            pictureModel->setScale(14.0f);
        else if(status==6)
            pictureModel->setScale(22.5f);
        else if(status==7)
            pictureModel->setScale(8.3f);
        else if(status==8)
            pictureModel->setScale(5.0f);
        
        pictureModel->setRotation(metaio::Rotation(metaio::Vector3d(-M_PI/2, 0, 0)));
        
        [m_gestureHandler addObject:pictureModel andGroup:1];
        [m_gestureHandler1 addObject:pictureModel andGroup:1];
        [m_gestureHandler removeObject:people];
        [m_gestureHandler1 removeObject:people];
        
        setActiveModel->setTranslation(metaio::Vector3d(0.0f, 0.0f, 0.0f));
    }
    
}

- (void) load3Dmodel
{

    NSString* shouweiAlert_model = [[NSBundle mainBundle] pathForResource:@"shouweiAlert"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (shouweiAlert_model)
    {
        const char *utf8Path = [shouweiAlert_model UTF8String];
        shouweiAlert = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        shouweiAlert->setCoordinateSystemID(0);
        shouweiAlert->setScale(0.4f);
        shouweiAlert->setRelativeToScreen(20,8);
        shouweiAlert->setVisible(false);
        shouweiAlert->setRenderOrder(4,false,true);
        shouweiAlert->setTranslation(metaio::Vector3d(0.0f, 40.0f, 5.0f));
    }
    
    [self shouweiAlertAni];
    
    NSString* QSCtalk_model = [[NSBundle mainBundle] pathForResource:@"QSCtalk1"
                               //pathForResource:@"rosaGuide1"
                                                              ofType:@"mp4"
                                                         inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(QSCtalk_model)
    {
        const char *utf8Path = [QSCtalk_model UTF8String];
        QSCtalk =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        QSCtalk->setCoordinateSystemID(0);
    }
    
    const char *guowang_Path = [modelPath[16] UTF8String];
    guowang=m_pMetaioSDK->createGeometry(guowang_Path);
    guowang->setScale(6.0f);
    guowang->setRenderOrder(5);
    guowang->setVisible(false);
    guowang->setTranslation(metaio::Vector3d(0.0f, 0.0f, -39.0f));
    
    const char *anguohou_Path = [modelPath[17] UTF8String];
    anguohou=m_pMetaioSDK->createGeometry(anguohou_Path);
    anguohou->setScale(0.3f);
    anguohou->setRenderOrder(5);
    anguohou->setVisible(false);
    anguohou->setTranslation(metaio::Vector3d(0.0f, 0.0f, -1.0f));
    
    const char *guanyan_Path = [modelPath[18] UTF8String];
    guanyuan=m_pMetaioSDK->createGeometry(guanyan_Path);
    guanyuan->setScale(0.4f);
    guanyuan->setRenderOrder(5);
    guanyuan->setVisible(false);
    guanyuan->setTranslation(metaio::Vector3d(0.0f, 0.0f, -3.0f));

    const char *shouwei_01_Path = [modelPath[19] UTF8String];
    shouwei_01=m_pMetaioSDK->createGeometry(shouwei_01_Path);
    shouwei_01->setScale(2.0f);
    shouwei_01->setRenderOrder(5);
    shouwei_01->setVisible(false);
    shouwei_01->setTranslation(metaio::Vector3d(0.0f, 0.0f, -15.0f));
    shouwei[0] = shouwei_01;

    const char *shouwei_02_Path = [modelPath[20] UTF8String];
    shouwei_02=m_pMetaioSDK->createGeometry(shouwei_02_Path);
    shouwei_02->setScale(2.3f);
    shouwei_02->setRenderOrder(2);
    shouwei_02->setVisible(false);
    shouwei_02->setTranslation(metaio::Vector3d(-10.0f, 0.0f, -19.0f));
    shouwei[1] = shouwei_02;

    const char *shouwei_03_Path = [modelPath[21] UTF8String];
    shouwei_03=m_pMetaioSDK->createGeometry(shouwei_03_Path);
    shouwei_03->setScale(2.0f);
    shouwei_03->setRenderOrder(5);
    shouwei_03->setVisible(false);
    shouwei_03->setTranslation(metaio::Vector3d(0.0f, 0.0f, -15.0f));
    shouwei[2] = shouwei_03;

    const char *shouwei_04_Path = [modelPath[22] UTF8String];
    shouwei_04=m_pMetaioSDK->createGeometry(shouwei_04_Path);
    shouwei_04->setScale(2.0f);
    shouwei_04->setRenderOrder(5);
    shouwei_04->setVisible(false);
    shouwei_04->setTranslation(metaio::Vector3d(0.0f, 0.0f, -16.0f));
    shouwei[3] = shouwei_04;

    const char *shouwei_05_Path = [modelPath[23] UTF8String];
    shouwei_05=m_pMetaioSDK->createGeometry(shouwei_05_Path);
    shouwei_05->setScale(2.0f);
    shouwei_05->setRenderOrder(5);
    shouwei_05->setVisible(false);
    shouwei_05->setTranslation(metaio::Vector3d(0.0f, 0.0f, -12.0f));
    shouwei[4] = shouwei_05;

    const char *shouwei_06_Path = [modelPath[24] UTF8String];
    shouwei_06=m_pMetaioSDK->createGeometry(shouwei_06_Path);
    shouwei_06->setScale(2.0f);
    shouwei_06->setRenderOrder(5);
    shouwei_06->setVisible(false);
    shouwei_06->setTranslation(metaio::Vector3d(0.0f, 0.0f, -12.0f));
    shouwei[5] = shouwei_06;

    const char *shouwei_07_Path = [modelPath[25] UTF8String];
    shouwei_07=m_pMetaioSDK->createGeometry(shouwei_07_Path);
    shouwei_07->setScale(2.0f);
    shouwei_07->setRenderOrder(5);
    shouwei_07->setVisible(false);
    shouwei_07->setTranslation(metaio::Vector3d(0.0f, 0.0f, -19.0f));
    shouwei[6] = shouwei_07;
    
    NSString* treasureBox_Model = [[NSBundle mainBundle] pathForResource:@"shu"
                                                                  ofType:@"zip"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    const char *treasureBox_Path = [treasureBox_Model UTF8String];
    treasureBox=m_pMetaioSDK->createGeometry(treasureBox_Path);
    treasureBox->setScale(1.0f);
    //treasureBox->setRelativeToScreen(48,8);
    //treasureBox->setTranslation(metaio::Vector3d(0.0f, 0.0f, 5.0f));
    treasureBox->setRenderOrder(3);
    treasureBox->setVisible(false);
    treasureBox->setRotation(metaio::Rotation(metaio::Vector3d(-M_PI/6, 0, 0)));
    
    NSString* backgroundMusic_model = [[NSBundle mainBundle] pathForResource:@"backgroundMusic"
                                                                 ofType:@"3g2"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(backgroundMusic_model)
    {
        const char *utf8Path = [backgroundMusic_model UTF8String];
        backgroundMusic =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        backgroundMusic->setCoordinateSystemID(0);
        backgroundMusic->setVisible(false);
    }
    
    const char *utf8Path = [modelPath[4] UTF8String];
    env3D=m_pMetaioSDK->createGeometry(utf8Path);
    env3D->setScale(metaio::Vector3d(300.0f, 300.0f, 300.0f));
    env3D->setTranslation(metaio::Vector3d(0.0f, 0.0f, -2100.0f));
    env3D->setRotation(metaio::Rotation(metaio::Vector3d( 0, 0, 0)));//M_PI=180度
    env3D->setRenderOrder(1);
    env3D->setVisible(false);
    
    const char *enter3D_Path = [modelPath[26] UTF8String];
    enter3D=m_pMetaioSDK->createGeometry(enter3D_Path);
    enter3D->setRenderOrder(5);
    enter3D->setVisible(false);
    enter3D->setTranslation(metaio::Vector3d(0.0f, 0.0f, -5.0f));
    
    const char *out3D_Path = [modelPath[27] UTF8String];
    out3D=m_pMetaioSDK->createGeometry(out3D_Path);
    out3D->setRenderOrder(5);
    out3D->setVisible(false);
    
    const char *enter3D2_Path = [modelPath[28] UTF8String];
    enter3D2=m_pMetaioSDK->createGeometry(enter3D2_Path);
    enter3D2->setRenderOrder(5);
    enter3D2->setVisible(false);
    enter3D2->setTranslation(metaio::Vector3d(0.0f, 0.0f, -5.0f));
    
    const char *out3D2_Path = [modelPath[29] UTF8String];
    out3D2=m_pMetaioSDK->createGeometry(out3D2_Path);
    out3D2->setRenderOrder(15);
    out3D2->setVisible(false);
    
    const char *enter3D3_Path = [modelPath[30] UTF8String];
    enter3D3=m_pMetaioSDK->createGeometry(enter3D3_Path);
    enter3D3->setRenderOrder(5);
    enter3D3->setVisible(false);
    enter3D3->setTranslation(metaio::Vector3d(0.0f, 0.0f, -5.0f));
    
    const char *out3D3_Path = [modelPath[31] UTF8String];
    out3D3=m_pMetaioSDK->createGeometry(out3D3_Path);
    out3D3->setRenderOrder(5);
    out3D3->setVisible(false);
    
    const char *hulu1_Path = [modelPath[32] UTF8String];
    hulu1=m_pMetaioSDK->createGeometry(hulu1_Path);
    hulu1->setRenderOrder(5);
    hulu1->setTranslation(metaio::Vector3d(0.0f, 0.0f, -7.0f));
    hulu1->setVisible(false);
    hulu[0]=hulu1;
    
    const char *hulu2_Path = [modelPath[33] UTF8String];
    hulu2=m_pMetaioSDK->createGeometry(hulu2_Path);
    hulu2->setRenderOrder(5);
    hulu2->setVisible(false);
    hulu[1]=hulu2;
    
    const char *hulu3_Path = [modelPath[34] UTF8String];
    hulu3=m_pMetaioSDK->createGeometry(hulu3_Path);
    hulu3->setRenderOrder(5);
    hulu3->setVisible(false);
    hulu[2]=hulu3;
    
    const char *hulu4_Path = [modelPath[35] UTF8String];
    hulu4=m_pMetaioSDK->createGeometry(hulu4_Path);
    hulu4->setRenderOrder(5);
    hulu4->setVisible(false);
    hulu4->setTranslation(metaio::Vector3d(0.0f, 0.0f, -6.8f));
    hulu[3]=hulu4;
    
    
    NSString* missionBar_model = [[NSBundle mainBundle] pathForResource:@"missionBar"
                                                                 ofType:@"png"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (missionBar_model)
    {
        const char *utf8Path = [missionBar_model UTF8String];
        missionBar = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        missionBar->setCoordinateSystemID(0);
        missionBar->setScale(0.8f);
        missionBar->setRenderOrder(10);
        missionBar->setRelativeToScreen(33,8);
        //missionBar->setTranslation(metaio::Vector3d(0.0f, 30.0f, 0.0f));
        if(testScreen==1)missionBar->setTranslation(metaio::Vector3d(0.0f, 100.0f, 0.0f));
        else missionBar->setTranslation(metaio::Vector3d(0.0f, 60.0f, 0.0f));
        missionBar->setVisible(false);
    }
    NSString* giftPanelPath = [[NSBundle mainBundle] pathForResource:@"keepGoingPanel"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (giftPanelPath)
    {
        const char *utf8Path = [giftPanelPath UTF8String];
        giftPanel = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        giftPanel->setScale(2.5f);
        giftPanel->setVisible(false);
        giftPanel->setRenderOrder(20);
        giftPanel->setRelativeToScreen(48,8);
        giftPanel->setTranslation(metaio::Vector3d(0.0f, -20.0f,20.0f));
    }

    NSString* giftBtnRightPath = [[NSBundle mainBundle] pathForResource:@"keepGoing"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (giftBtnRightPath)
    {
        const char *utf8Path = [giftBtnRightPath UTF8String];
        giftBtnRight = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        giftBtnRight->setScale(0.45f);
        giftBtnRight->setVisible(false);
        giftBtnRight->setRenderOrder(21);
        giftBtnRight->setRelativeToScreen(48,8);
        giftBtnRight->setTranslation(metaio::Vector3d(0.0f, -70.0f, 21.0f));
    }
    NSString* swCheckPanelPath = [[NSBundle mainBundle] pathForResource:@"shouweiPanel"
                                                               ofType:@"png"
                                                          inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (swCheckPanelPath)
    {
        const char *utf8Path = [swCheckPanelPath UTF8String];
        swCheckPanel = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        swCheckPanel->setScale(2.0f);
        swCheckPanel->setVisible(false);
        swCheckPanel->setRenderOrder(20);
        swCheckPanel->setRelativeToScreen(48,8);
        swCheckPanel->setTranslation(metaio::Vector3d(0.0f, 0.0f,20.0f));
    }
    NSString* swCheckYesPath = [[NSBundle mainBundle] pathForResource:@"yesBtn"
                                                           ofType:@"png"
                                                      inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (swCheckYesPath)
    {
        const char *utf8Path = [swCheckYesPath UTF8String];
        swCheckYes = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        swCheckYes->setScale(0.43f);
        swCheckYes->setVisible(false);
        swCheckYes->setRelativeToScreen(48,8);
        swCheckYes->setRenderOrder(21);
        swCheckYes->setTranslation(metaio::Vector3d(-58.0f, -30.0f, 21.0f));
    }
    NSString* swCheckNoPath = [[NSBundle mainBundle] pathForResource:@"noBtn"
                                                          ofType:@"png"
                                                     inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    
    
    
    if (swCheckNoPath)
    {
        const char *utf8Path = [swCheckNoPath UTF8String];
        swCheckNo = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        swCheckNo->setScale(0.43f);
        swCheckNo->setVisible(false);
        swCheckNo->setRenderOrder(21);
        swCheckNo->setRelativeToScreen(48,8);
        swCheckNo->setTranslation(metaio::Vector3d(58.0f, -30.0f, 21.0f));
    }
    if(swCheckNo)
    {
        secondPageGuide->setTransparency(0);
        blackBack->setVisible(false);
        linking->setVisible(false);
        blackBack->setTexture([[[NSBundle mainBundle] pathForResource:@"bg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
}

-(void) setConfiguration
{
    //tracking configuration
    m_mustUseInstantTrackingEvent = YES;
    m_pMetaioSDK->startInstantTracking("INSTANT_2D", metaio::Path(), NO);
    
    const char *modelutf8Path1 = [modelPath[status] UTF8String];
    if(status!=4)
    {
        bool success = model3D3=m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(modelutf8Path1));
        model3D3->setCoordinateSystemID(1);
    }
    effectMovie->setCoordinateSystemID(1);
    
    if(status==4)
        treasureBox->setCoordinateSystemID(1);
  
    if(model3D3){
        //NSString *ConText = @"http://cqplayart.cn/assets/jsonvalue_beta.php";
        //NSDictionary* jsonObj = [NSJSONSerialization JSONObjectWithData:[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:ConText]] returningResponse:nil error:nil] options:NSJSONReadingMutableContainers   error:nil];
        
        //get 3Dmodel position
        const metaio::SensorValues sensorValues = m_pSensorsComponent->getSensorValues();
        if (status<6)
        {
            
            model3D3->setTranslation(metaio::Vector3d(model3D3->getTranslation().x + xValue[status] , model3D3->getTranslation().y + yValue[status] , model3D3->getTranslation().z+zValue[status]));
            
            //effectMovie->setTranslation(metaio::Vector3d(temp.x,temp.y,temp.z));
            
            //set rotation
            modelRotation=1;
        }
        else if(status>5)
        {
            //set translation
            
            model3D3->setTranslation(metaio::Vector3d(xValue[status],yValue[status],zValue[status]));
            model3D3->setRelativeToScreen(48,8);
            
            //set rotation
            
            model3D3->setRotation(metaio::Rotation(metaio::Vector3d(-M_PI/2+ xrValue[status], yrValue[status], zrValue[status])));
        }
        
        //set model size
        model3D3->setScale(size[status]);
        
        /*if(status==0)
            model3D3->setScale(7.0f);
        else if(status==1)
            model3D3->setScale(5.5f);
        else if(status==2)
            model3D3->setScale(4.0f);
        else if(status==3)
            model3D3->setScale(6.0f);
        else if(status==5)
            model3D3->setScale(9.5f);
        else if(status==6)
            model3D3->setScale(8.3f);
        else if(status==7)
            model3D3->setScale(5.0f);*/
   
    }
}

-(void) chooseGuideSound:(int)Status
{

    const char *modelutf8Path2 = [modelPath[Status+36] UTF8String];
    guideSound->setMovieTexture(modelutf8Path2);
  
    //guideSound->setMovieTexture([[[NSBundle mainBundle] pathForResource:@"hot6" ofType:@"3g2" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
}

-(void) missionComplete
{
    frameModelRight->setVisible(true);
    frameModelLeft->setVisible(true);
    bottomFrame->setVisible(true);
    rightFrame->setVisible(true);
    leftFrame->setVisible(true);
    topFrame->setVisible(true);
    
    m_pMetaioSDK->setLLAObjectRenderingLimits(0, 0);
    
    status++;
    
    exitAR->setTexture([[[NSBundle mainBundle] pathForResource:@"finalExit" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    exitAR->setTranslation(metaio::Vector3d(0.0f, 0.0f, 1.0f));
    
    btnCamara->setTranslation(metaio::Vector3d(-5.0f, 0.0f, 0.0f));
    btnCamara->setTexture([[[NSBundle mainBundle] pathForResource:@"cameraFinish" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    
    //clean view
    mapBtn->setVisible(false);
    title->setVisible(false);
    titleWord->setVisible(false);
    
    next->setVisible(false);
    controll->setVisible(false);
    controllBack->setVisible(false);
    btnModelSwift->setVisible(false);
    setActiveModel->setVisible(false);
    
    //add date
    NSDate *date= [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy.MM.dd"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    dateLabel.text = dateString;
    
    [[[Database alloc] init] open];
    [[[Database alloc] init] updateData:8];
    [[[Database alloc] init] close];
}

-(void) enter360
{
    m_pMetaioSDK->setRendererClippingPlaneLimits(1, 220000);
    
    recordStatus=1;
    QSCIndex=1;
    startPeopleTalk=1;
    [self startQSCsound:recordStatus];
    
    env3D->setVisible(true);
    env3D->startAnimation("ani_appear",false);
    guowang->setVisible(true);
    guowang->startAnimation("ani_daiji01",true);
    guanyuan->setVisible(true);
    guanyuan->startAnimation("ani_daiji01",true);
    //anguohou->setVisible(true);
    //anguohou->startAnimation("ani_daiji01",true);
    
    int i;
    for(i=0; i<7; i++)
        shouwei[i]->setVisible(true);

    hulu4->setVisible(true);
    
    missionBar->setVisible(true);
    nextPageTime=1;
    detectTalk=0;

}


-(void) cameraGuideAni
{
    vector.deleteAll();
    
    cKey0.AnimationKeyFrame::index=0;
    cKey0.AnimationKeyFrame::translation=metaio::Vector3d(-53.0f, -7.0f, 0.0f);
    cKey0.AnimationKeyFrame::scale=0.0f;
    cKey0.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    cKey30.AnimationKeyFrame::index=30;
    cKey30.AnimationKeyFrame::translation=metaio::Vector3d(-53.0f, -7.0f, 0.0f);
    cKey30.AnimationKeyFrame::scale=0.3f;
    cKey30.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    cKey70.AnimationKeyFrame::index=180;
    cKey70.AnimationKeyFrame::translation=metaio::Vector3d(-53.0f, -7.0f, 0.0f);
    cKey70.AnimationKeyFrame::scale=0.3f;
    cKey70.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    cKey100.AnimationKeyFrame::index=210;
    cKey100.AnimationKeyFrame::translation=metaio::Vector3d(-53.0f, -7.0f, 0.0f);
    cKey100.AnimationKeyFrame::scale=0.0f;
    cKey100.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    vector.push_back(cKey0);
    vector.push_back(cKey30);
    vector.push_back(cKey70);
    vector.push_back(cKey100);
    
    cAni.keyframes=vector;
    cameraGuide->setCustomAnimation("ani_appear", cAni);
}

-(void) nextAppear
{
    vector.deleteAll();
    
    nextKey0.AnimationKeyFrame::index=0;
    nextKey0.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 00.0f, 5.0f);
    nextKey0.AnimationKeyFrame::scale=0.6f;
    nextKey0.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    nextKey25.AnimationKeyFrame::index=5;
    nextKey25.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, -81.0f, 5.0f);
    nextKey25.AnimationKeyFrame::scale=0.6f;
    nextKey25.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    nextKey50.AnimationKeyFrame::index=10;
    nextKey50.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, -80.0f, 5.0f);
    nextKey50.AnimationKeyFrame::scale=0.6f;
    nextKey50.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    vector.push_back(nextKey0);
    vector.push_back(nextKey25);
    vector.push_back(nextKey50);
    
    cAni.keyframes=vector;
    next->setCustomAnimation("ani_appear", cAni);
}

-(void)shouweiAlertAni
{
    vector.deleteAll();
    
    cKey0.AnimationKeyFrame::index=0;
    cKey0.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 40.0f, 5.0f);
    cKey0.AnimationKeyFrame::scale=0.0f;
    cKey0.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    cKey30.AnimationKeyFrame::index=20;
    cKey30.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 40.0f, 5.0f);
    cKey30.AnimationKeyFrame::scale=0.4f;
    cKey30.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    cKey70.AnimationKeyFrame::index=140;
    cKey70.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 40.0f, 5.0f);
    cKey70.AnimationKeyFrame::scale=0.4f;
    cKey70.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    cKey100.AnimationKeyFrame::index=160;
    cKey100.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 40.0f, 5.0f);
    cKey100.AnimationKeyFrame::scale=0.0f;
    cKey100.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    vector.push_back(cKey0);
    vector.push_back(cKey30);
    vector.push_back(cKey70);
    vector.push_back(cKey100);
    
    cAni.keyframes=vector;
    shouweiAlert->setCustomAnimation("ani_appear", cAni);
}

-(void)giftPanelAni
{
    vector.deleteAll();
    
    fKey0.AnimationKeyFrame::index=0;
    fKey0.AnimationKeyFrame::translation=giftPanel->getTranslation();
    fKey0.AnimationKeyFrame::scale=0.0f;
    fKey0.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    fKey30.AnimationKeyFrame::index=15;
    fKey30.AnimationKeyFrame::translation=giftPanel->getTranslation();
    fKey30.AnimationKeyFrame::scale=2.0f;
    fKey30.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    vector.push_back(fKey0);
    vector.push_back(fKey30);
    
    cAni.keyframes=vector;
    giftPanel->setCustomAnimation("ani_appear", cAni);
}

-(void)linkingAni
{
    vector.deleteAll();
    
    fKey0.AnimationKeyFrame::index=0;
    fKey0.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 0.0f, 0.0f);
    fKey0.AnimationKeyFrame::scale=0.0f;
    fKey0.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    fKey30.AnimationKeyFrame::index=10;
    fKey30.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, 0.0f, 0.0f);
    fKey30.AnimationKeyFrame::scale=0.5f;
    fKey30.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    vector.push_back(fKey0);
    vector.push_back(fKey30);
    
    cAni.keyframes=vector;
    linking->setCustomAnimation("ani_appear", cAni);
}

-(void) finderDisappear
{
    vector.deleteAll();
    
    fKey0.AnimationKeyFrame::index=0;
    fKey0.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, -20.0f, 5.0f);
    fKey0.AnimationKeyFrame::scale=2.3f;
    fKey0.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    fKey30.AnimationKeyFrame::index=10;
    fKey30.AnimationKeyFrame::translation=metaio::Vector3d(0.0f, -20.0f, 5.0f);
    fKey30.AnimationKeyFrame::scale=0.0f;
    fKey30.AnimationKeyFrame::rotation=metaio::Rotation(0,0,0);
    
    vector.push_back(fKey0);
    vector.push_back(fKey30);
    
    cAni.keyframes=vector;
    finder->setCustomAnimation("ani_disappear", cAni);
}

-(void) pictureTakenGuide
{
    blackBack->setVisible(true);
    modelToggle->setVisible(true);
    
    blackBack->setTransparency(0.9);
    btnModelSwift->setTranslation(metaio::Vector3d(25.0f, 15.0f, 7.0f));
    
    pleaseTouch->setRenderOrder(50);
    btnModelSwift->setRenderOrder(60,false,true);
    btnModelSwift->setTranslation(metaio::Vector3d(25.0f, 15.0f, 16.0f));
}

-(void) finderTouch
{
    finder->setVisible(false);
    instantBtn->setVisible(false);
    instantGuide->setVisible(false);
    effectMovie->setVisible(true);
    effectMovie->startMovieTexture(false);
    findPOI->setTexture([[[NSBundle mainBundle] pathForResource:@"detectEffect" ofType:@"jpg" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    findPOI->setTranslation(metaio::Vector3d(0.0f, -20.0f, 10.0f));
    detectEffectMovei=1;
    detectFinder=0;
}

//點擊map
-(void) changeStatus:(int) temp
{
    index=0;
    
    //歸回初始值
    m_pMetaioSDK->setLLAObjectRenderingLimits(0, 0);
    if(QSCtalk!=NULL) QSCtalk->stopMovieTexture();
    m_radar->setVisible(false);
    cameraGuide->stopAnimation();
    blackBack->setRenderOrder(5);
    blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 6.0f));
    if(completeAlert!=NULL)completeAlert->setVisible(false);
    map->setTranslation(metaio::Vector3d(0.0f, -7.0f, 19.0f));
    
    if(model3D3!=NULL)
    {
        m_pMetaioSDK->unloadGeometry(model3D3);
        model3D3=NULL;
    }
    if(people!=NULL && pictureModel!=NULL && setActiveModel!=NULL)
    {
        [m_gestureHandler removeObject:people];
        [m_gestureHandler removeObject:pictureModel];
        [m_gestureHandler1 removeObject:people];
        [m_gestureHandler1 removeObject:pictureModel];
        
        m_pMetaioSDK->unloadGeometry(people);
        m_pMetaioSDK->unloadGeometry(pictureModel);
        m_pMetaioSDK->unloadGeometry(setActiveModel);
        pictureModel = NULL;
        people=NULL;
        setActiveModel=NULL;
    }

    int i;
    for(i=0; i<8; i++)
        point[i]->setVisible(false);
    
    metaio::IGeometry* clear[] = {firstPageModel,firstPageTalk,iknow,secondPageGuide,tangshengSound,linking,findPOI,pictureTouchGuide,arriveAlert,notArriveAlert,mapBtn,finder,closeMap,blackBack,effectMovie,playBtn,pauseBtn,replayBtn,next,pleaseTouch,pleaseTouchDim,modelToggle,modelToggle2,btnModelSwift,controll,controllBack,btnCamara,touchGuide,cameraGuide,resetBtn,instantBtn,instantGuide,map};
    for(i=0; i<33; i++)
    {
        if(clear[i]!=NULL)
           clear[i]->setVisible(false);
    }
    if(status==4)
    {
        if(textGuide!=NULL)
        {
            m_pMetaioSDK->unloadGeometry(textGuide);
            textGuide=NULL;
        }
        
        metaio::IGeometry* unload[] = {treasureBox,env3D,enter3D,out3D,enter3D2,out3D2,enter3D3,out3D3,missionBar,guowang,guideModel1,guideModel2,guideModel3,guideModel4,guanyuan,anguohou,QSCtalk,secondMissionGuide,shouweiAlert};
        
        for(i=0; i<19; i++)
        {
            if(unload[i]!=NULL)
            {
                bool success = m_pMetaioSDK->unloadGeometry(unload[i]);
                unload[i]=NULL;
                env3D=NULL;
                if(guideModel1!=NULL) guideModel1=NULL;
                if(QSCtalk!=NULL) QSCtalk=NULL;
                if(secondMissionGuide!=NULL) secondMissionGuide=NULL;
            }
        }
        for(i=0; i<7; i++)
        {
            if(shouwei[i]!=NULL)
            {
                m_pMetaioSDK->unloadGeometry(shouwei[i]);
                shouwei[i]=NULL;
            }
        }
        for(i=0; i<4; i++)
        {
            if(hulu[i]!=NULL)
            {
                m_pMetaioSDK->unloadGeometry(hulu[i]);
                hulu[i]=NULL;
            }
        }
    }
    if(textGuide!=NULL)
    {
        m_pMetaioSDK->unloadGeometry(textGuide);
        textGuide=NULL;
    }
    
    //drawframe value
    detectPOI=0;
    detectFinder=0;
    iknowTime=0;
    detectEffectMovei=0;
    firstTimePlay=0;
    testTextStart=0;
    
    status = temp;
    
    //改辨識框
    NSString *finderString = [NSString stringWithFormat:@"finder%i", status];
    if(status<6)finder->setTexture([[[NSBundle mainBundle] pathForResource:finderString ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    
    if(textGuide!=NULL)
    {
        guideSound->pauseMovieTexture();
        m_pMetaioSDK->unloadGeometry(textGuide);
        textGuide=NULL;
    }
    
    if(temp==0)
    {
        m_radar->remove(Geo1);
        annotatedGeometriesGroup->removeGeometry(Geo1);
        m_pMetaioSDK->unloadGeometry(Geo1);
        nextPageTime=0;
        checkStatus=0;
        Geo1=NULL;
        [self addGeo];

        NSString* model3D_model = [[NSBundle mainBundle] pathForResource:@"tangsheng"
                                                                  ofType:@"zip"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
        if (model3D_model)
        {
            const char *utf8Path = [model3D_model UTF8String];
            firstPageModel = m_pMetaioSDK->createGeometry(metaio::Path::fromUTF8(utf8Path));
            firstPageModel->setVisible(true);
            firstPageModel->startAnimation("ani_talk",true);
            firstPageModel->setScale(7.0f);
            firstPageModel->setRelativeToScreen(5,8);
            firstPageModel->setRenderOrder(7);
            firstPageModel->setTranslation(metaio::Vector3d(60.0f, 30.0f, 4.0f));
        }
        
        firstPageModel->setVisible(true);
        
        firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:@"talk0" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        firstPageTalk->setVisible(true);
        
        secondPageGuide->setScale(3.0f);
        secondPageGuide->setTranslation(metaio::Vector3d(0.0f, 0.0f, 15.0f));
        
        iknow->setVisible(true);
        tangshengSound->setMovieTexture([[[NSBundle mainBundle] pathForResource:@"guide0" ofType:@"mp3" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        tangshengSound->startMovieTexture(false);
        
        for(i=0; i<8; i++)
            point[i]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"point%i", i+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        point[status]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"pointL%i", status+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        next->setTexture([[[NSBundle mainBundle] pathForResource:@"next" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        
    }
    else
    {
        nextPageTime=1;
        
        secondPageGuide->setScale(2);
        secondPageGuide->setTranslation(metaio::Vector3d(0.0f, -30.0f, 0.0f));
        
        for(i=0; i<8; i++)
            point[i]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"point%i", i+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        point[status]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"pointL%i", status+1] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        
        [self nextClick];
    }
}

-(void) loadSecondMission
{
    NSString* guideModel1_model = [[NSBundle mainBundle] pathForResource:@"guideModel1"
                                                             ofType:@"png"
                                                        inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (guideModel1_model)
    {
        const char *utf8Path = [guideModel1_model UTF8String];
        guideModel1 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        guideModel1->setCoordinateSystemID(0);
        guideModel1->setScale(0.5f);
        guideModel1->setRelativeToScreen(5,8);
        guideModel1->setRenderOrder(51);
        guideModel1->setTranslation(metaio::Vector3d(15.0f, 55.0f, 0.0f));
        guideModel1->setVisible(true);
        guideModel[0]=guideModel1;
    }
    NSString* guideModel2_model = [[NSBundle mainBundle] pathForResource:@"guideModel2"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (guideModel2_model)
    {
        const char *utf8Path = [guideModel2_model UTF8String];
        guideModel2 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        guideModel2->setCoordinateSystemID(0);
        guideModel2->setScale(0.5f);
        guideModel2->setRelativeToScreen(5,8);
        guideModel2->setRenderOrder(51);
        guideModel2->setTranslation(metaio::Vector3d(75.0f, 55.0f, 0.0f));
        guideModel2->setVisible(true);
        guideModel[1]=guideModel2;
    }
    NSString* guideModel3_model = [[NSBundle mainBundle] pathForResource:@"guideModel3"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (guideModel3_model)
    {
        const char *utf8Path = [guideModel3_model UTF8String];
        guideModel3 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        guideModel3->setCoordinateSystemID(0);
        guideModel3->setScale(0.5f);
        guideModel3->setRelativeToScreen(5,8);
        guideModel3->setRenderOrder(51);
        guideModel3->setTranslation(metaio::Vector3d(135.0f, 55.0f, 0.0f));
        guideModel3->setVisible(true);
        guideModel[2]=guideModel3;
    }
    NSString* guideModel4_model = [[NSBundle mainBundle] pathForResource:@"guideModel4"
                                                                  ofType:@"png"
                                                             inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if (guideModel4_model)
    {
        const char *utf8Path = [guideModel4_model UTF8String];
        guideModel4 = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        guideModel4->setCoordinateSystemID(0);
        guideModel4->setScale(0.5f);
        guideModel4->setRelativeToScreen(5,8);
        guideModel4->setRenderOrder(51);
        guideModel4->setTranslation(metaio::Vector3d(195.0f, 55.0f, 0.0f));
        guideModel4->setVisible(true);
        guideModel[3]=guideModel4;
    }
    NSString* secondMissionGuide_model = [[NSBundle mainBundle] pathForResource:@"secondMissionGuide1"
                                                                 ofType:@"mp4"
                                                            inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    if(secondMissionGuide_model)
    {
        const char *utf8Path = [secondMissionGuide_model UTF8String];
        secondMissionGuide =  m_pMetaioSDK->createGeometryFromMovie(metaio::Path::fromUTF8(utf8Path), false,false);
        secondMissionGuide->setCoordinateSystemID(0);
    }
}

-(void) QSCsecondMission
{
    //clean page
    blackBack->setVisible(false);
    shouweiAlert->setVisible(false);
    giftBtnRight->setVisible(false);
    giftPanel->setVisible(false);
    m_pMetaioSDK->unloadGeometry(textGuide);
    textGuide=NULL;
    missionBar->setTexture([[[NSBundle mainBundle] pathForResource:@"missionBarCheck" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    
    //add view
    enter3D->setVisible(true);
    enter3D->startAnimation("ani_go",true);
    enter3D2->setVisible(true);
    enter3D2->startAnimation("ani_go",true);
    enter3D3->setVisible(true);
    enter3D3->startAnimation("ani_go",true);
    
    //找出葫蘆提醒
    NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    textGuide = m_pMetaioSDK->createGeometryFromCGImage([@"test" UTF8String], [[self getBillboardImage:@"请找寻紫金葫芦，并完成语音导览" andPath:texturePath] CGImage]);
    textGuide->setCoordinateSystemID(0);
    textGuide->setScale(0.8);
    textGuide->setRelativeToScreen(20,8);
    textGuide->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
    textGuide->setRenderOrder(50);
    textGuide->setVisible(true);
    
    int i;
    for(i=3; i<10; i++)
        clickEnable[i] = 0;
    for(i=0; i<7; i++)
        shouwei[i]->startAnimation("ani_daiji01",true);
    
    [self loadSecondMission];
    
    startSecondMissionGuide=1;

    for(i=0; i<4; i++)
        testSecondTalkEnable[i]=1;
}

-(void) startSecondMissionGuide:(int) temp
{
    startSecondMissionGuide=0;
    QSCmapClickStop=1;
    
    [self parseSRT:9 chooseTalk:temp];
    
    //start 字幕機
    testTextStart=1;
    testChooseWhich=temp;
    
    const char *test = [[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"secondMissionGuide%i", temp] ofType:@"mp4" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String];
    //const char *test = [[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"CSQ"] ofType:@"3g2" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets/CSQ"] UTF8String];
    secondMissionGuide->setMovieTexture(test);
    
    secondMissionGuide->startMovieTexture();
}

//自創end

//load GPS value
- (void) testmygps
{
    // Create radar object
    m_radar = m_pMetaioSDK->createRadar();
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *assetFolder = @"tutorialContent_crossplatform/Tulufan/Assets";
    NSString *radarPath = [mainBundle pathForResource:@"radar_new"
                                               ofType:@"png"
                                          inDirectory:assetFolder];
    const char *radarUtf8Path = [radarPath UTF8String];
    
    m_radar->setBackgroundTexture(metaio::Path::fromUTF8(radarUtf8Path));
    
    m_radar->setRelativeToScreen(metaio::IGeometry::ANCHOR_TR);
    m_radar->setSize(9.5 * 15);
    m_radar->setObjectsSize(9.5 * 2);
    m_radar->setVisible(false);
    NSString *yellowPath = [mainBundle pathForResource:@"none"
                                                ofType:@"png"
                                           inDirectory:assetFolder];
    const char *yellowUtf8Path = [yellowPath UTF8String];
    m_radar->setObjectsDefaultTexture(metaio::Path::fromUTF8(yellowUtf8Path));
    m_radar->setObjectsSize(14.0);
    
}

- (void) addGeo
{
    m_pMetaioSDK->setTrackingConfiguration("GPS");
    annotatedGeometriesGroup = m_pMetaioSDK->createAnnotatedGeometriesGroup();
    self.annotatedGeometriesGroupCallback = new AnnotatedGeometriesGroupCallback(self);
    annotatedGeometriesGroup->registerCallback(self.annotatedGeometriesGroupCallback);
    
    //m_pMetaioSDK->setLLAObjectRenderingLimits(5, 200);
    m_pMetaioSDK->setLLAObjectRenderingLimits(0, 0);
    m_pMetaioSDK->setRendererClippingPlaneLimits(10, 220000);
    
    metaio::LLACoordinate lla1;

    if(status==6 || status==7)
       lla1 = metaio::LLACoordinate(0, 0, 0, 0);
    else
        lla1 = [self getLLA:status];

    Geo1 = [self createPOIGeometry:lla1];
    annotatedGeometriesGroup->addGeometry(Geo1, (void*)"岗哨区");
    m_radar->add(Geo1);
}

-(metaio::LLACoordinate) getLLA:(int) statusValue
{
    NSLog(@"first?");
    
    NSArray *lota1;
    NSArray *lotn1;
    
    NSUserDefaults *data1 = [NSUserDefaults standardUserDefaults];
    float lota;
    float lotn;
    
    NSString *value1 = [data1 objectForKey:@"testNetWork"];
    if([value1 caseInsensitiveCompare:@"0"]==0) testNetWork=0;
    else testNetWork=1;
    
    if(testNetWork==1)
    {
        //NSString *ConText = @"http://cqplayart.cn/assets/jsonvalue_beta.php";
        NSString *ConText = @"http://app.cqplayart.cn/assets/jsonvalue_beta2.php";
        NSURL *url = [NSURL URLWithString:ConText];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSData* data_json = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSDictionary* jsonObj = [NSJSONSerialization JSONObjectWithData:data_json options:NSJSONReadingMutableContainers   error:nil];
        
        NSString *location = @"location0";
        
        lota1 = [[jsonObj objectForKey:location] valueForKey:[NSString stringWithFormat:@"lota%d", statusValue+1]];
        lotn1 = [[jsonObj objectForKey:location] valueForKey:[NSString stringWithFormat:@"lotn%d", statusValue+1]];
        
        NSArray *arriveValueString = [[jsonObj objectForKey:location] valueForKey:@"arrive"];
        if(status == finalStatus) arriveValue = [arriveValueString[0] intValue];
        else arriveValue = 50000000;
        
        locationTarget = [[CLLocation alloc] initWithLatitude:[lota1[0] floatValue] longitude:[lotn1[0] floatValue]];
        NSLog(@"target:%f %f",[lota1[0] floatValue],[lotn1[0] floatValue]);
        [data1 setObject:[[NSNumber numberWithFloat:[lota1[0] floatValue]] stringValue] forKey:[NSString stringWithFormat:@"lota%d", statusValue+1]];
        [data1 setObject:[[NSNumber numberWithFloat:[lotn1[0] floatValue]] stringValue] forKey:[NSString stringWithFormat:@"lotn%d", statusValue+1]];
        
        lota = [[data1 objectForKey:[NSString stringWithFormat:@"lota%d", statusValue+1]] floatValue];
        lotn = [[data1 objectForKey:[NSString stringWithFormat:@"lotn%d", statusValue+1]] floatValue];
    }
    else
    {
        locationTarget = [[CLLocation alloc] initWithLatitude:42.947126 longitude:89.067748];
        
        if(statusValue==0)
        {
            lota = 42.947126;
            lotn = 89.067748;
        }
        else if(statusValue==6)
        {
            lota = 42.95603;
            lotn = 89.064208;
        }
        else if(statusValue==7)
        {
            lota = 42.95577;
            lotn = 89.063563;
        }
    }

    
    metaio::LLACoordinate lla1 = metaio::LLACoordinate(lota, lotn, 0, 0);
    
    if(status==6)
    {
        annotatedGeometriesGroup->addGeometry(Geo1, (void*)"大佛寺");
        Geo1->setTexture([[[NSBundle mainBundle] pathForResource:@"DFSpoi" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
    else if(status==7)
    {
        annotatedGeometriesGroup->addGeometry(Geo1, (void*)"塔林");
        Geo1->setTexture([[[NSBundle mainBundle] pathForResource:@"TLpoi" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
    
    self.working = true;
    
    return lla1;
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
    [self ImageSharing:image];
}
- (void) ImageSharing:(UIImage *)image
{
    ASImageSharingViewController* controller = [[ASImageSharingViewController alloc] initWithNibName:@"ASImageSharingViewController" bundle:nil];
    controller.imageToPost = image;
    
    controller.myValue = readvalue;
    [self presentViewController:controller animated:YES completion:nil];
    
    //還原頁面
    btnCamara->setVisible(true);
    exitAR->setVisible(true);
    if(status<9)
    {
        btnModelSwift->setVisible(true);
        controllBack->setVisible(true);
        controll->setVisible(true);
        next->setVisible(true);
        next->startAnimation("ani_appear",false);
        title->setVisible(true);
        titleWord->setVisible(true);
        mapBtn->setVisible(true);
    }

}
-(void) onScreenshotSaved:(const NSString*) filepath
{
    NSLog(@"Image saved: %@", filepath);
}
//screen shot end

- (void)viewWillDisappear:(BOOL)animated
{
    // as soon as the view disappears, we stop rendering and stop the camera
    m_pMetaioSDK->stopCamera();
    [super viewWillDisappear:animated];
    
    if(testCamera==0) [self tesetdisapp];
}
- (void) tesetdisapp
{
    //annotatedGeometriesGroup->registerCallback(NULL);
    if (self.annotatedGeometriesGroupCallback) {
        delete self.annotatedGeometriesGroupCallback;
        self.annotatedGeometriesGroupCallback = NULL;
    }
}

//for VIP end

- (void)drawFrame
{
    //測試是否到達地點
    CLLocationDistance distance = [locationCurrent distanceFromLocation:locationTarget];
    if(startDetecGPS==1)
    {
        //if(distance < 50000000){
        if(distance < arriveValue){
            arriveAlert->setVisible(true);
            testArrive=1;
        }
        else{
            notArriveAlert->setVisible(true);
            testArrive=0;
        }
    }
    
    
    const metaio::SensorValues sensorValues = m_pSensorsComponent->getSensorValues();
    
    int topDetect = 166;
    
    int downDetect = -80;
    
    float m[9];
    sensorValues.attitude.getRotationMatrix(m);
    
    metaio::Vector3d v(m[6], m[7], m[8]);
    v = v.getNormalized();
    v /= v.norm();
    
    if (self.working && Geo1->getIsRendered())
    {
        //[self tesedrawframe];//gps controll
        Geo1->setBillboardModeEnabled(true);
    }
    
    if(pictureModel!=NULL && (pictureModel->getCurrentFrame())>20 && testSwift==0 && !(modelToggle->getIsRendered()) && !(modelToggle2->getIsRendered()) && status==1)
    {
        blackBack->setTransparency(0.2);
        touchGuide->setVisible(true);
        iknow->setVisible(true);
        
        testSwift=1;
    }
    
    //model3d3 rotation
    if (modelRotation==1)
    {
        [self modelRotation];
    }
    
    if(status==0 && detectPOI==1)
    {
        if(Geo1->getIsRendered())
        {
            findPOI->setVisible(false);
        }
        else
        {
            findPOI->setVisible(true);
        }
    }

    //loading status
    if(testloading==1){
        m_pMetaioSDK->unloadGeometry(loadingImage);
        m_pMetaioSDK->unloadGeometry(loadingModel);
        m_pMetaioSDK->unloadGeometry(loadingPicture);
        m_Label1.text=@"";
        m_Label2.text=@"";
        m_Label3.text=@"";
    }
    
    //測試model是否太大
    if(setActiveModel!=NULL && setActiveModel->getIsRendered() && setActiveModel==pictureModel){
        metaio::Vector3d test = setActiveModel->getScale();
        
        if(status==1){
            if(test.x>35 || test.y>35 || test.z>35){
                setActiveModel->setScale(metaio::Vector3d(35.0, 35.0, 35.0));
            }
        }
        else if(status==2){
            if(test.x>20 || test.y>20 || test.z>20){
                setActiveModel->setScale(metaio::Vector3d(20.0f, 20.0f, 20.0f));
            }
        }
        else if(status==3)
        {
            if(test.x>14 || test.y>14 || test.z>14){
                setActiveModel->setScale(metaio::Vector3d(14.0f, 14.0f, 14.0f));
            }
        }
        else if(status==4){
            if(test.x>32 || test.y>32 || test.z>32){
                setActiveModel->setScale(metaio::Vector3d(32.0f, 32.0f, 32.0f));
            }
        }
        else if(status==6){
            if(test.x>34 || test.y>34 || test.z>34){
                setActiveModel->setScale(metaio::Vector3d(34.0f, 34.0f, 34.0f));
            }
        }else if(status==7){
            if(test.x>25 || test.y>25 || test.z>25){
                setActiveModel->setScale(metaio::Vector3d(25.0f, 25.0f, 25.0f));
            }
        }
        else if(status==8){
            if(test.x>12 || test.y>12 || test.z>12){
                setActiveModel->setScale(metaio::Vector3d(12.0f, 12.0f, 12.0f));
            }
        }
        
    }
    
    //換導覽字幕
    if (tangshengSound!=NULL)
    {
        metaio::MovieTextureStatus testGuide = tangshengSound->getMovieTextureStatus();
        if(testGuide.currentPosition>0)
        {
            if(status==0)
            {
                if(testGuide.currentPosition>37)
                {
                    if(iknowTime==0)iknow->setVisible(true);
                    firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:@"talk0_2" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
                }
            }
            else if(status==3)
            {
                if(testGuide.currentPosition>25)
                    firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:@"talk4_2" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            }
            else if(status==4)
            {
                if(testGuide.currentPosition>33)
                    firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:@"talk5_2" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            }
            else if(status==5)
            {
                if(testGuide.currentPosition>28)
                    firstPageTalk->setTexture([[[NSBundle mainBundle] pathForResource:@"talk6_2" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            }
        }
    }
    
    
    
    //字幕機
    metaio::MovieTextureStatus test;
    if(status==4 && env3D!=NULL && env3D->getIsRendered())
        test = QSCtalk->getMovieTextureStatus();
    else if(guideSound!=NULL)
        test = guideSound->getMovieTextureStatus();
    if(guideModel1!=NULL && guideModel1->getIsRendered())
        test = secondMissionGuide->getMovieTextureStatus();
    if (testTextStart==1 && endIndex>index){
        float current = test.currentPosition*1000;
        if(timer[index]>current){
            if(testTXT==1){
                //NSLog(@"testtxt:%@, %d",text[index],timer[index]);
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
        //m_pMetaioSDK->unloadGeometry(textGuide);
    }
    
    //控制板
    if(getTouchEnd==1)
    {
        float OriX = controllStickPoi.x;
        float OriY = controllStickPoi.y;
        float NowX = controll->getTranslation().x;
        float NowY = controll->getTranslation().y;
        
        NSLog(@"%f %f", modelPos.x, modelPos.y);
        
        modelPos.x = modelPos.x - ((OriX-NowX)/3000);
        modelPos.y = modelPos.y + ((OriY-NowY)/3000);
        setActiveModel->setRotation(metaio::Rotation(modelPos.y,modelPos.x,0));
    }
    
    //大佛寺poi座標偵測
    if(status>5 && Geo1->getIsRendered() && playBtnStatus==0)
    {
        playBtn->setVisible(true);
        pleaseTouch->setVisible(true);
        pleaseTouchDim->setVisible(false);
        playBtn->setTexture([[[NSBundle mainBundle] pathForResource:@"playBtn" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        
    }
    if(status>5 && !(Geo1->getIsRendered()) && playBtnStatus==0)
    {
        playBtn->setVisible(true);
        pleaseTouch->setVisible(false);
        pleaseTouchDim->setVisible(true);
        playBtn->setTexture([[[NSBundle mainBundle] pathForResource:@"playBtnDim" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
    
    //控制movie status
    if(effectMovie!=NULL && effectMovie->getIsRendered())
    {
        findPOI->setVisible(false);
        secondPageGuide->setVisible(false);
        secondPageGuide->pauseAnimation();
        
        if(map->getIsRendered())
            effectMovie->pauseMovieTexture();
        else
            effectMovie->startMovieTexture();
    }
    else if(detectEffectMovei==1)
    {
        effectMovie->pauseMovieTexture();
        if((-200)*v.z > downDetect && (-200)*v.z <topDetect)
        {
            findPOI->setVisible(true);
            secondPageGuide->setVisible(false);
            secondPageGuide->pauseMovieTexture();
        }
        else
        {
            findPOI->setVisible(false);
            secondPageGuide->setVisible(true);
            secondPageGuide->startMovieTexture(true);
        }
    }
    

    //看是否辨識到3d model
    if(model3D3!=NULL && model3D3->getIsRendered() && !(pauseBtn->getIsRendered()) && !(replayBtn->getIsRendered()) && firstTimePlay==1 && status!=4)
    {
        playBtn->setVisible(true);
        pleaseTouch->setVisible(true);
        secondPageGuide->setVisible(false);
        secondPageGuide->pauseMovieTexture();
        pleaseTouchDim->setVisible(false);
        playBtn->setTexture([[[NSBundle mainBundle] pathForResource:@"playBtn" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
    }
    else if(model3D3!=NULL && !(model3D3->getIsRendered()) && firstTimePlay==1 && status!=4)
    {
        if((-200)*v.z > downDetect && (-200)*v.z <topDetect)
        {
            secondPageGuide->setVisible(false);
            secondPageGuide->pauseAnimation();
            playBtn->setVisible(true);
            pleaseTouchDim->setVisible(true);
            playBtn->setTexture([[[NSBundle mainBundle] pathForResource:@"playBtnDim" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        }
        else
        {
            playBtn->setVisible(false);
            pleaseTouchDim->setVisible(false);
            secondPageGuide->setVisible(true);
            secondPageGuide->startMovieTexture(true);
        }
        pleaseTouch->setVisible(false);
    }
    
    //看是否持平
    if(detectFinder==1)
    {
        if((-200)*v.z > downDetect && (-200)*v.z <topDetect)
        {
            finder->setVisible(true);
            instantBtn->setVisible(true);
            instantGuide->setVisible(true);
            secondPageGuide->setVisible(false);
            secondPageGuide->pauseAnimation();
        }
        else
        {
            finder->setVisible(false);
            instantBtn->setVisible(false);
            instantGuide->setVisible(false);
            secondPageGuide->setVisible(true);
            secondPageGuide->startMovieTexture(true);
        }
    }
    
    if(recordStatus==11 && testTalk==1)
    {
        [self startQSCsound:11];
        testTalk=0;
    }
    
    //test QSC second mission end
    if(secondMissionEnd==4 && missionBar!=NULL)
    {
        missionBar->setTexture([[[NSBundle mainBundle] pathForResource:@"missionBarCheck2" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        next->setVisible(true);
        status++;
        if(status>finalStatus)
            finalStatus=status;
        secondMissionEnd=0;
    }
    
    if(testLoad3D==1)
    {
        [self load3Dmodel];
        testLoad3D=0;
    }
    
    [super drawFrame];
}

//model rotation handler
- (void) modelRotation
{
    
    if (m_pMetaioSDK && m_pSensorsComponent)
    {
        /*const metaio::SensorValues sensorValues = m_pSensorsComponent->getSensorValues();
        
        heading = 0.0f;
        if (sensorValues.hasAttitude())
        {
            float m[9];
            sensorValues.attitude.getRotationMatrix(m);
            
            metaio::Vector3d v(m[6], m[7], m[8]);
            v = v.getNormalized();
            
            heading = -atan2(v.y, v.x) - (float)M_PI_2;
        }*/
        
        const metaio::Rotation rot((float)M_PI + xrValue[status], M_PI + yrValue[status], M_PI + zrValue[status]);
        model3D3->setRotation(rot);
        const metaio::Rotation rot2((float)M_PI+M_PI/5, -M_PI, M_PI);
        effectMovie->setRotation(rot2);
    }
    modelRotation=0;
}

//gps controll
- (void) tesedrawframe
{
    // make pins appear upright
    if (m_pMetaioSDK && m_pSensorsComponent)
    {
        const metaio::SensorValues sensorValues = m_pSensorsComponent->getSensorValues();
        
        heading = 0.0f;
        if (sensorValues.hasAttitude())
        {
            float m[9];
            sensorValues.attitude.getRotationMatrix(m);
            
            metaio::Vector3d v(m[6], m[7], m[8]);
            v = v.getNormalized();
            NSLog(@"vector: %f %f %f",v.x, v.y, v.z);
            heading = -atan2(v.y, v.x) - (float)M_PI_2;
        }

        const metaio::Rotation rot((float)M_PI_2, 0.0f, -heading);
        
        Geo1->setRotation(rot);
        
    }
    self.working=false;
}

#pragma mark - Handling Touches

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint loc = [touch locationInView:self.glkView];
    float scale = self.glkView.contentScaleFactor;
    metaio::IGeometry* modelTouch = m_pMetaioSDK->getGeometryFromViewportCoordinates(loc.x * scale, loc.y * scale, true);
    
    if(modelTouch!=NULL && touches!=nil && event!=nil)
    {
        [m_gestureHandler touchesBegan:touches withEvent:event withView:self.glkView];
        [m_gestureHandler1 touchesBegan:touches withEvent:event withView:self.glkView];
        [m_gestureHandler2 touchesBegan:touches withEvent:event withView:self.glkView];
    }

    
    if(modelTouch==NULL)
    {
        return 0;
    }
    if (modelTouch == exitAR)//close app
    {
        clickSound->startMovieTexture(false);
        blackBack->setRenderOrder(19);
        blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 16.0f));
        
        m_radar->setVisible(false);
        iknow->setTranslation(metaio::Vector3d(-25.0f, 15.0f, 0.0f));
        
        if(textGuide!=NULL && textGuide->getIsRendered())
            guideSound->pauseMovieTexture();
        if(firstPageTalk!=NULL && firstPageTalk->getIsRendered())
            tangshengSound->pauseMovieTexture();
        if(effectMovie->getIsRendered())
            testEffectStatus=0;
        if(QSCtalk!=NULL && QSCmapClickStop==1)
            QSCtalk->pauseMovieTexture();
        if(secondMissionGuide!=NULL && QSCmapClickStop==1)
            secondMissionGuide->pauseMovieTexture();
        
            checkWord->setVisible(true);
            checkPanel->setVisible(true);
            blackBack->setVisible(true);
            yesBtn->setVisible(true);
            noBtn->setVisible(true);
            dateLabel.textColor = [UIColor blackColor];
    
        
    }
    else if(modelTouch==yesBtn)
    {
        clickSound->startMovieTexture(false);
        
        metaio::IGeometry* clear[] = {firstPageModel,firstPageTalk,iknow,secondPageGuide,tangshengSound,linking,findPOI,pictureTouchGuide,arriveAlert,notArriveAlert,mapBtn,finder,closeMap,blackBack,effectMovie,playBtn,pauseBtn,replayBtn,next,pleaseTouch,pleaseTouchDim,modelToggle,modelToggle2,btnModelSwift,controll,controllBack,btnCamara,touchGuide,cameraGuide,treasureBox,env3D,enter3D,out3D,enter3D2,out3D2,enter3D3,out3D3,missionBar,guowang,guanyuan,anguohou,resetBtn,instantBtn,instantGuide,map,shouweiAlert};
        int i;
        for(i=0; i<42; i++)
        {
            m_pMetaioSDK->unloadGeometry(clear[i]);
            clear[i]=NULL;
        }
        
        for(i=0; i<7; i++)
        {
            m_pMetaioSDK->unloadGeometry(shouwei[i]);
            shouwei[i]=NULL;
        }
            
        for(i=0; i<4; i++)
        {
            m_pMetaioSDK->unloadGeometry(hulu[i]);
            hulu[i]=NULL;
        }
        
        testCamera=0;
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    else if(modelTouch==noBtn)
    {
        clickSound->startMovieTexture(false);
        blackBack->setRenderOrder(5);
        blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 6.0f));
        
        iknow->setTranslation(metaio::Vector3d(-25.0f, 15.0f, 16.0f));
        
        if(textGuide!=NULL && textGuide->getIsRendered())
        {
            if(playBtn->getIsRendered() || replayBtn->getIsRendered())
                guideSound->pauseAnimation();
            else if(pauseBtn->getIsRendered())
                guideSound->startMovieTexture();
        }
        if(effectMovie->getIsRendered())
            testEffectStatus=1;
        if(QSCtalk!=NULL && QSCmapClickStop==1 && guideModel1==NULL)
            QSCtalk->startMovieTexture();
        if(secondMissionGuide!=NULL && QSCmapClickStop==1)
            secondMissionGuide->startMovieTexture();
        
        blackBack->setVisible(false);
        yesBtn->setVisible(false);
        noBtn->setVisible(false);
        checkPanel->setVisible(false);
        checkWord->setVisible(false);
        
        if(detectRadarExit==1)
            m_radar->setVisible(true);
        
        dateLabel.textColor = [UIColor colorWithRed:153.0/255.0 green:102.0/255.0 blue:51.0/255.0 alpha:1.0];
    }
    else if(modelTouch==swCheckYes)
    {
        swCheckNo->setVisible(false);
        swCheckYes->setVisible(false);
        swCheckPanel->setVisible(false);
        
        if(testShouwei==2)
        {
            giftPanel->setVisible(true);
            [self giftPanelAni];
            giftPanel->startAnimation("ani_appear",false);
            
        }
        else
        {
            blackBack->setVisible(false);
            shouweiAlert->setVisible(true);
            shouweiAlert->startAnimation("ani_appear",false);
            NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
            m_pMetaioSDK->unloadGeometry(textGuide);
            textGuide=NULL;

            textGuide = m_pMetaioSDK->createGeometryFromCGImage([@"test" UTF8String], [[self getBillboardImage:@"请再次與守衛說話找出內奸" andPath:texturePath] CGImage]);
            textGuide->setCoordinateSystemID(0);
            textGuide->setScale(0.8);
            textGuide->setRelativeToScreen(20,8);
            textGuide->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
            textGuide->setRenderOrder(50);
            textGuide->setVisible(true);
        }
        
    }
    else if(modelTouch==swCheckNo)
    {
        blackBack->setVisible(false);
        swCheckNo->setVisible(false);
        swCheckYes->setVisible(false);
        swCheckPanel->setVisible(false);
    }
    else if(modelTouch==giftBtnRight)
    {
        [self QSCsecondMission];
    }
    else if(modelTouch==guanyuan && clickEnable[1]==1)
        [self startQSCsound:recordStatus];
    else if(modelTouch==guowang && clickEnable[0]==1)
        [self startQSCsound:recordStatus];
    else if(modelTouch==anguohou && clickEnable[2]==1)
    {
        if((recordStatus==12 || recordStatus==14))
            [self startQSCsound:recordStatus];
        else if((recordStatus==15 || recordStatus==17))
            [self startQSCsound:recordStatus];
    }
    else if(modelTouch==shouwei_01 && clickEnable[3]==1 && swTalk==1)
    {
        clickEnable[3]=0;
        testShouwei=1;
        [self startQSCsound:18];
    }
    else if(modelTouch==shouwei_02 && clickEnable[4]==1 && swTalk==1)
    {
        clickEnable[4]=0;
        testShouwei=2;
        [self startQSCsound:19];
    }
    else if(modelTouch==shouwei_03 && clickEnable[5]==1 && swTalk==1)
    {
        clickEnable[5]=0;
        testShouwei=3;
        [self startQSCsound:20];
    }
    else if(modelTouch==shouwei_04 && clickEnable[6]==1 && swTalk==1)
    {
        clickEnable[6]=0;
        testShouwei=4;
        [self startQSCsound:21];
    }
    else if(modelTouch==shouwei_05 && clickEnable[7]==1 && swTalk==1)
    {
        clickEnable[7]=0;
        testShouwei=5;
        [self startQSCsound:22];
    }
    else if(modelTouch==shouwei_06 && clickEnable[8]==1 && swTalk==1)
    {
        clickEnable[8]=0;
        testShouwei=6;
        [self startQSCsound:23];
    }
    else if(modelTouch==shouwei_07 && clickEnable[9]==1 && swTalk==1)
    {
        clickEnable[9]=0;
        testShouwei=7;
        [self startQSCsound:24];
    }
    else if(modelTouch==hulu1 && testSecondTalkEnable[0]==1 && startSecondMissionGuide==1)
        [self startSecondMissionGuide:1];
    else if(modelTouch==hulu2 && testSecondTalkEnable[1]==1 && startSecondMissionGuide==1)
        [self startSecondMissionGuide:2];
    else if(modelTouch==hulu3 && testSecondTalkEnable[2]==1 && startSecondMissionGuide==1)
        [self startSecondMissionGuide:3];
    else if(modelTouch==hulu4 && testSecondTalkEnable[3]==1 && startSecondMissionGuide==1)
        [self startSecondMissionGuide:4];
    else if(modelTouch ==title)
        [self QSCsecondMission];

    //map touch
    else if(modelTouch==point1 && 0<=finalStatus && checkStatus!=0)
        [self changeStatus:0];
    else if(modelTouch==point2 && 1<=finalStatus && checkStatus!=1)
        [self changeStatus:1];
    else if(modelTouch==point3 && 2<=finalStatus && checkStatus!=2)
        [self changeStatus:2];
    else if(modelTouch==point4 && 3<=finalStatus && checkStatus!=3)
        [self changeStatus:3];
    else if(modelTouch==point5 && 4<=finalStatus && checkStatus!=4)
        [self changeStatus:4];
    else if(modelTouch==point6 && 5<=finalStatus && checkStatus!=5)
        [self changeStatus:5];
    else if(modelTouch==point7 && 6<=finalStatus && checkStatus!=6)
        [self changeStatus:6];
    else if(modelTouch==point8 && 7<=finalStatus && checkStatus!=7)
        [self changeStatus:7];
    else if(modelTouch==iknow)
    {
        clickSound->startMovieTexture(false);
        NSLog(@"%d",iknowTime);
        
        if(iknowTime==0)
        {
            [self closeFirstPage];
            iknowTime=1;
        }
        else if(iknowTime==1)
        {
            if(status==0)[self changeSeconPage];
            else if(status==4)
            {
                [self linkingAni];
                blackBack->setTexture([[[NSBundle mainBundle] pathForResource:@"bg2" ofType:@"jpg" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
                blackBack->setTransparency(0);
                blackBack->setVisible(true);
                linking->setVisible(true);
                linking->startAnimation("ani_appear",false);
                secondPageGuide->setTransparency(1);
                
                [self closeGuidePage];
                
                //[self load3Dmodel];
            }
            else [self closeGuidePage];
            
            iknowTime=2;
        }
        else if(iknowTime==2)
        {
            if(status==0)
            {
                detectPOI=1;
                poiTouch=1;
                startDetecGPS=1;
                [self closeGuidePage];
            }
            if(status==4)
            {
                blackBack->setVisible(false);
                touchGuide->setVisible(false);
                iknow->setVisible(false);
                //arriveAlert->setVisible(true);
                
                [self enter360];
            }
            iknowTime=3;
            
        }
        else if(iknowTime==3)
        {//[self enter360];
            blackBack->setVisible(false);
            iknow->setVisible(false);
            pictureTouchGuide->setVisible(false);
            
            secondPageGuide->setScale(2);
            secondPageGuide->setTranslation(metaio::Vector3d(0.0f, -30.0f, 0.0f));
            
            testEffectStatus=0;
            detectFinder=1;
            
            iknowTime=4;
        }
        else if(iknowTime==4)
        {
            iknow->setVisible(false);
            blackBack->setVisible(false);
            touchGuide->setVisible(false);
            pleaseTouch->setRenderOrder(0);
            cameraGuide->setVisible(true);
            cameraGuide->startAnimation("ani_appear",false);
        }

    }
    else if(modelTouch==mapBtn)
    {
        clickSound->startMovieTexture(false);
        
        metaio::IGeometry* mapGroup[] = {map,point1, point2,point3,point4,point5,point6,point7,point8};
        
        int i;
        for(i=0; i<9; i++)
            mapGroup[i]->setVisible(true);

        blackBack->setVisible(true);
        blackBack->setRenderOrder(19,false,true);
        blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 16.0f));
        if(guideSound!=NULL)
            guideSound->pauseMovieTexture();
        if(effectMovie->getIsRendered())
            testEffectStatus=0;
        if(QSCtalk!=NULL && QSCmapClickStop==1)
            QSCtalk->pauseMovieTexture();
        if(secondMissionGuide!=NULL && QSCmapClickStop==1)
            secondMissionGuide->pauseMovieTexture();
        //m_pMetaioSDK->pauseTracking();
        closeMap->setVisible(true);
    }
    else if(modelTouch==closeMap)
    {
        clickSound->startMovieTexture(false);
        
        metaio::IGeometry* mapGroup[] = {map,point1, point2,point3,point4,point5,point6,point7,point8};
        
        int i;
        for(i=0; i<9; i++)
            mapGroup[i]->setVisible(false);
        
        blackBack->setVisible(false);
        blackBack->setRenderOrder(5);
        blackBack->setTranslation(metaio::Vector3d(0.0f, 0.0f, 6.0f));
        if(textGuide!=NULL && textGuide->getIsRendered())
        {
            if(playBtn->getIsRendered() || replayBtn->getIsRendered())
                guideSound->pauseAnimation();
            else if(pauseBtn->getIsRendered())
                guideSound->startMovieTexture();
        }
        if(effectMovie->getIsRendered())
            testEffectStatus=1;
        if(QSCtalk!=NULL && QSCmapClickStop==1 && guideModel1==NULL)
            QSCtalk->startMovieTexture();
        if(secondMissionGuide!=NULL && QSCmapClickStop==1)
            secondMissionGuide->startMovieTexture();
        closeMap->setVisible(false);
    }
    else if(modelTouch==playBtn && (status>5 || model3D3->getIsRendered()))
    {
        clickSound->startMovieTexture(false);
        
        if(firstTimePlay==1)
        {
            [self chooseGuideSound:status];
            
            if(status==6 || status==7)
            {
                Geo1->setTransparency(1);
                
                playBtnStatus=1;
                getModelSize=1;
                [self setConfiguration];
                detectRadarExit=0;
                m_radar->setVisible(false);
                playBtn->setVisible(false);
                mapBtn->setVisible(true);
                
                model3D3->setCoordinateSystemID(0);
                model3D3->setVisible(true);
                model3D3->startAnimation("ani_appear",false);
                
                [self createShading:model3D3];
                
                m_pMetaioSDK->setLLAObjectRenderingLimits(0, 0);
            }
            
            //字幕機
            endIndex=1;
            
            [self parseSRT:status chooseTalk:0];
            
            firstTimePlay=0;
            testTextStart=1;
        }
        
        guideSound->startMovieTexture(false);
        playBtn->setVisible(false);
        pleaseTouch->setVisible(false);
        resetBtn->setVisible(false);
        
        pauseBtn->setVisible(true);
    }
    else if(modelTouch==pauseBtn)
    {
        clickSound->startMovieTexture(false);
        
        playBtn->setVisible(true);
        pauseBtn->setVisible(false);
        guideSound->pauseMovieTexture();
    }
    else if(modelTouch==replayBtn)
    {
        clickSound->startMovieTexture(false);
        
        //playBtnStatus=0;
        next->setVisible(false);
        guideSound->startMovieTexture(false);
        replayBtn->setVisible(false);
        pauseBtn->setVisible(true);
        testTXT=1;
        testTextStart=1;
    }
    else if(modelTouch==next)
    {
        clickSound->startMovieTexture(false);
        
        [self nextClick];
    }
    else if(modelTouch==btnCamara)
    {
        clickSound->startMovieTexture(false);
        
        btnCamara->setVisible(false);
        btnModelSwift->setVisible(false);
        controllBack->setVisible(false);
        controll->setVisible(false);
        next->setVisible(false);
        title->setVisible(false);
        titleWord->setVisible(false);
        mapBtn->setVisible(false);
        exitAR->setVisible(false);
        cameraGuide->stopAnimation();
        cameraGuide->setVisible(false);
        
        testCamera=1;
        
        [self onSaveScreen];
    }
    else if(modelTouch==btnModelSwift)
    {
        clickSound->startMovieTexture(false);
        
        [self swiftTouch];
    }
    else if(modelTouch==controll)
    {
        controll->setTransparency(0.35f);
        getTouchEnd=1;
    }
    else if(modelTouch==treasureBox)
    {
        clickSound->startMovieTexture(false);
        
        testQSC=1;
        treasureBox->startAnimation("ani_open",false);
    }
    else if(enter3D!=NULL && modelTouch==enter3D)
    {
        clickSound->startMovieTexture(false);
        
        //clean view
        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,enter3D2,out3D2,enter3D3,out3D3,hulu1,hulu2,hulu3,hulu4,anguohou};
        int i;
        for(i=0; i<21; i++)
        {
            if(i==0 || i==1 || i==2 || i==4 || i==6 || i==8 || i==9 || i==10 || i==16)
                temp[i]->startAnimation("in1",false);
            else
                temp[i]->setVisible(false);
        }
        
        
    }
    else if (modelTouch==out3D)
    {
        clickSound->startMovieTexture(false);
        
        out3D->setVisible(false);

        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,enter3D2,out3D2,enter3D3,out3D3,hulu1,hulu2,hulu3,hulu4,anguohou};
        
        int i;
        for(i=0; i<21; i++)
        {
            if(i!=0) temp[i]->setVisible(false);
            if(i==0 || i==1 || i==2 || i==4 || i==6 || i==8 || i==9 || i==10 || i==16)
                temp[i]->startAnimation("out1",false);
        }
    }
    else if(enter3D2!=NULL && modelTouch==enter3D2)
    {
        clickSound->startMovieTexture(false);
        
        //clean view
        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,enter3D2,out3D2,enter3D3,out3D3,hulu1,hulu2,hulu3,hulu4,anguohou};
        int i;
        for(i=0; i<21; i++)
        {
            if(i==0 || i==1 || i==2 || i==6 || i==8 || i==9 || i==10 || i==13 || i==17)
                temp[i]->startAnimation("in2",false);
            else
                temp[i]->setVisible(false);
        }

    }
    else if (modelTouch==out3D2)
    {
        clickSound->startMovieTexture(false);
        
        out3D2->setVisible(false);
        hulu2->setVisible(false);
        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,enter3D2,out3D2,enter3D3,out3D3,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,hulu1,hulu2,hulu3,hulu4,anguohou};
        
        int i;
        for(i=0; i<21; i++)
        {
            if(i!=0) temp[i]->setVisible(false);
            if(i==0 || i==1 || i==2 || i==6 || i==10 || i==12 || i==13 || i==14 || i==17)
                temp[i]->startAnimation("out2",false);
        }

    }
    else if(modelTouch==enter3D3)
    {
        clickSound->startMovieTexture(false);
        
        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,enter3D2,out3D2,enter3D3,out3D3,hulu1,hulu2,hulu3,hulu4,anguohou};
        int i;
        for(i=0; i<21; i++)
        {
            if(i==0 || i==15 || i==18)
                temp[i]->startAnimation("in3",false);
            else
                temp[i]->setVisible(false);
        }
    }
    else if (modelTouch==out3D3)
    {
        clickSound->startMovieTexture(false);
        
        out3D3->setVisible(false);
        env3D->startAnimation("ani_kaimen02",false);
        hulu3->setVisible(false);
    }
    else if(modelTouch==instantBtn)
    {
        finder->startAnimation("ani_disappear",false);
        
        [self setConfiguration];
    }
    else if(modelTouch==resetBtn)
    {
        testEffectStatus=0;
        detectFinder=1;
        
        //clean view
        playBtn->setVisible(false);
        pleaseTouchDim->setVisible(false);
        pleaseTouch ->setVisible(false);
        model3D3->setVisible(false);
        resetBtn->setVisible(false);
        
        //add view
        finder->setScale(2.3f);
        
        firstTimePlay=0;
        detectFinder=1;
        
        m_pMetaioSDK->setTrackingConfiguration("GPS");
    }
    else
    {
    
        @try {
            std::string testname;
            if(modelTouch!=NULL){
                testname= modelTouch->getName();
            }
            
            NSString *nameNSString = [NSString stringWithUTF8String:testname.c_str()];
            NSLog(@"testname %@",nameNSString);
            
            if((modelTouch == Geo1 || [@"岗哨区" caseInsensitiveCompare:nameNSString]==0) && nameNSString!=NULL && status==0 && poiTouch==1 && testArrive==1)
            {
                    clickSound->startMovieTexture(false);
                
                detectPOI=0;
                poiTouch=0;
                    [self change3D];
            }
        }
        
        @finally {
            NSLog(@"finally");
        }
    }
    
}

- (void) onInstantTrackingEvent:(bool)success file:(const NSString*) filepath
{
    if (success)
    {
        if (m_mustUseInstantTrackingEvent)
        {
            m_pMetaioSDK->setTrackingConfiguration(metaio::Path::fromUTF8([filepath UTF8String]));
        }
    }
    else
    {
        NSLog(@"SLAM has timed out!");
    }
}

- (void)onTrackingEvent:(const metaio::stlcompat::Vector<metaio::TrackingValues>&)trackingValues
{
    
    
    /*NSLog(@"track");

        metaio::TrackingValues tv = trackingValues[0];
        NSLog(@"hi:%d",tv.coordinateSystemID);

            if(detectFirstLoad==1 && detectFirstPlay==1)
            {
                [self detectSuccess:tv.coordinateSystemID];
                
                detectFirstPlay=0;
            }
            if(effectMovie->getIsRendered() && detectFirstLoad==1)
            {
                if(testEffectStatus==0)
                    testEffectStatus=1;
                else
                    testEffectStatus=0;
            }
            if(status!=4 && detectFirstLoad==1 && !(effectMovie->getIsRendered()) && trackDetect==1)
            {NSLog(@"got1");
                if(model3D3!=NULL && firstTrack==0)
                {
                    model3D3->setVisible(false);
                    finder->setVisible(true);
                    firstTrack=1;
                    return;
                }
                if(model3D3!=NULL && firstTrack==1)
                {
                    finder->setVisible(false);
                    model3D3->setVisible(true);
                    model3D3->startAnimation("ani_appear",false);
                    firstTrack=0;
                    return ;
                }
            }
        
    if(detectFirstLoad==0)
        detectFirstLoad=1;
*/
    
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [m_gestureHandler touchesMoved:touches withEvent:event withView:self.glkView];
    [m_gestureHandler1 touchesMoved:touches withEvent:event withView:self.glkView];
    [m_gestureHandler2 touchesMoved:touches withEvent:event withView:self.glkView];
 
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [m_gestureHandler touchesEnded:touches withEvent:event withView:self.glkView];
    [m_gestureHandler1 touchesEnded:touches withEvent:event withView:self.glkView];
    [m_gestureHandler2 touchesEnded:touches withEvent:event withView:self.glkView];

    
    if(getTouchEnd==1)
    {
        controll->setTransparency(0);
        controll->setTranslation(controllStickPoi);
        getTouchEnd=0;
    }
    
}
- (void) onAnimationEnd:(metaio::IGeometry *)geometry andName:(const NSString *)animationName
{
    
     NSLog(@"naem:%@",animationName);
    
    /*if(geometry==linking)
    {
        [self closeGuidePage];
        [self load3Dmodel];
    }*/
    
    if(geometry==env3D && [animationName  isEqual: @"in1"])
    {
        //add view
        out3D->setVisible(true);
        hulu1->setVisible(true);
        
        out3D->startAnimation("ani_go",true);
    }
    
    else if(geometry==env3D && [animationName  isEqual: @"in2"])
    {
        //add view
        out3D2->setVisible(true);
        hulu2->setVisible(true);
     
        out3D2->startAnimation("ani_go",true);
    }
    
    else if(geometry==env3D && [animationName  isEqual: @"in3"])
    {
        //add view
        out3D3->setVisible(true);
        hulu3->setVisible(true);
        
        out3D3->startAnimation("ani_go",true);
        env3D->startAnimation("ani_dashui01",true);
    }
    else if(geometry==env3D  && [animationName  isEqual: @"ani_kaimen02"])
    {
        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,enter3D2,out3D2,enter3D3,out3D3,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,hulu1,hulu2,hulu3,hulu4,anguohou};
        
        int i;
        for(i=0; i<21; i++)
            if(i==0 || i==15 || i==18)
                temp[i]->startAnimation("out3",false);
    }

    else if((geometry==env3D && [animationName  isEqual: @"out3"]) || (geometry==env3D && [animationName  isEqual: @"out2"]) || (geometry==env3D && [animationName  isEqual: @"out1"]))
    {
        metaio::IGeometry* temp[] = {env3D,guanyuan,guowang,enter3D,out3D,enter3D2,out3D2,enter3D3,out3D3,shouwei_01,shouwei_02,shouwei_03,shouwei_04,shouwei_05,shouwei_06,shouwei_07,hulu1,hulu2,hulu3,hulu4,anguohou};
        
        int i;
        for(i=0; i<21; i++)
        {
            if(i==4 || i==6 || i==8 || i==16 || i==17 || i==18)temp[i]->setVisible(false);
            else if(i!=20) temp[i]->setVisible(true);
        }
    }
    else if(geometry==treasureBox)
    {
        m_pMetaioSDK->setTrackingConfiguration("GPS");
        
        const metaio::SensorValues sensorValues = m_pSensorsComponent->getSensorValues();
        
        heading = 0.0f;
        //if (sensorValues.hasAttitude())
        //{
            float m[9];
            sensorValues.attitude.getRotationMatrix(m);
            
            metaio::Vector3d v(m[6], m[7], m[8]);
            v = v.getNormalized();
            
            heading = -atan2(v.y, v.x) - (float)M_PI_2;
        //}
        
        //NSLog(@"head:%f",heading);
        
        const metaio::Rotation rot((float)M_PI, M_PI, -heading+M_PI/7-M_PI/15);
        env3D->setRotation(rot);
        const metaio::Rotation rot2(0, 0, -heading+M_PI/7-M_PI-M_PI/15);
        guowang->setRotation(rot2);
        guanyuan->setRotation(rot2);
        shouwei_01->setRotation(rot2);
        shouwei_02->setRotation(metaio::Rotation(metaio::Vector3d(0, 0, -heading+M_PI/7-M_PI-M_PI/15-0.1)));
        shouwei_03->setRotation(rot2);
        shouwei_04->setRotation(metaio::Rotation(metaio::Vector3d(0, 0, -heading+M_PI/7-M_PI-M_PI/15-0.05)));
        shouwei_05->setRotation(rot2);
        shouwei_06->setRotation(rot2);
        shouwei_07->setRotation(rot2);
        anguohou->setRotation(rot2);
        enter3D->setRotation(rot2);
        out3D->setRotation(rot2);
        enter3D2->setRotation(metaio::Rotation(metaio::Vector3d(0, 0, -heading+M_PI/7-M_PI-M_PI/15+0.05)));
        out3D2->setRotation(rot2);
        enter3D3->setRotation(rot2);
        out3D3->setRotation(rot2);
        
        hulu1->setRotation(metaio::Rotation(metaio::Vector3d(0, 0, -heading+M_PI/7-M_PI-M_PI/15-0.01)));
        hulu2->setRotation(rot2);
        hulu3->setRotation(rot2);
        hulu4->setRotation(metaio::Rotation(metaio::Vector3d(0, 0, -heading+M_PI/7-M_PI-M_PI/15-0.01)));
        
        NSLog(@"heading: %f",heading);
        
        [self anguohouWalk];
        [self walk1];
        [self walk2];
        [self walk3];
        
        //clean view
        m_pMetaioSDK->setTrackingConfiguration("ORIENTATION");
        treasureBox->setVisible(false);
        arriveAlert->setVisible(false);
        
        //backgroundMusic->startMovieTexture(true);
        
        
        //add view
        blackBack->setVisible(true);
        iknow->setVisible(true);
        touchGuide->setVisible(true);
        
        arriveAlert->setTexture([[[NSBundle mainBundle] pathForResource:@"findRoom" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        next->setTexture([[[NSBundle mainBundle] pathForResource:@"next5" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        touchGuide->setTexture([[[NSBundle mainBundle] pathForResource:@"720guide" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        
        
    }
    
    else if(geometry==cameraGuide && !(next->getIsRendered()))
    {
        next->setVisible(true);
        next->startAnimation("ani_appear",false);
    }
    else if(geometry==finder)
    {
        [self finderTouch];
    }
    else if(geometry==anguohou && [animationName  isEqual: @"walkOut"])
        anguohou->startAnimation("ani_daiji03",true);
    else if(geometry==anguohou && [animationName  isEqual: @"walkIn"])
        anguohou->setVisible(false);
    else if(geometry==linking)
        testLoad3D=1;
    else if(geometry==giftPanel)
    {
        giftBtnRight->setVisible(true);
    }
}
//animationend

- (void) onMovieEnd:(metaio::IGeometry *)geometry andMoviePath:(const NSString *)moviePath
{
    if(geometry==effectMovie)
    {
        detectEffectMovei=0;
        
        if(status==4)//官署區
        {
            arriveAlert->setTexture([[[NSBundle mainBundle] pathForResource:@"findTreasure" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
            
            //clean view
            finder->setVisible(false);
            effectMovie->setVisible(false);
            
            //add view

            treasureBox->setVisible(true);
            arriveAlert->setVisible(true);
        }
        else
        {
            model3D3->setVisible(true);
            model3D3->startAnimation("ani_appear",false);
            firstTimePlay=1;
            resetBtn->setVisible(true);
            
            [self createShading:model3D3];
            //playBtn->setVisible(true);
            pleaseTouch->setVisible(true);
            effectMovie->setVisible(false);
        }
    }
    else if(geometry==guideSound)
    {
        testTextStart=0;
        next->setVisible(true);
        next->startAnimation("ani_appear",false);
        pauseBtn->setVisible(false);
        replayBtn->setVisible(true);
        textGuide->setVisible(false);
    }
    else if(geometry==tangshengSound)
    {
        tangshengSound->setVisible(false);
        firstPageModel->stopAnimation();
    }
    else if(geometry==QSCtalk)
    {
        recordStatus++;
        startPeopleTalk=0;
        QSCmapClickStop=0;
        
        //reset value
        
        
        if((recordStatus%2 == 0 && recordStatus<11) || recordStatus==16)
        {
            if(recordStatus==16)
            {
                guanyuan->startAnimation("ani_daiji05",true);
                anguohou->startAnimation("ani_daiji02",true);
            }
            else
            {
                guowang->startAnimation("ani_daiji01",true);
                guanyuan->startAnimation("ani_daiji02",true);
            }
            clickEnable[1] = 1;
            
        }
        else if((recordStatus%2 == 1 && recordStatus<11) || recordStatus==13)
        {
            if(recordStatus==13)
            {
                guowang->startAnimation("ani_daiji02",true);
                anguohou->startAnimation("ani_daiji02",true);
            }
            else
            {
                guanyuan->startAnimation("ani_daiji01",true);
                guowang->startAnimation("ani_daiji02",true);
            }
            clickEnable[0] = 1;
        }
        else if(recordStatus==11)
        {
            guowang->startAnimation("ani_daiji01",true);
            guanyuan->startAnimation("ani_daiji01",true);
            testTalk=1;
        }
        else if(recordStatus>11 && recordStatus<18 && recordStatus!=13 && recordStatus!= 16)
        {
            if(recordStatus==12)
            {
                anguohou->setVisible(true);
                anguohou->startAnimation("walkOut",false);
            }
            else if(recordStatus==14)
            {
                guowang->startAnimation("ani_daiji01",true);
                anguohou->startAnimation("ani_daiji03",true);
            }
            else if(recordStatus==15)
            {
                guanyuan->startAnimation("ani_zhuansheng01",false);
                anguohou->startAnimation("ani_daiji03",true);
            }
            else if(recordStatus==17)
            {
                guanyuan->startAnimation("ani_daiji04",true);
                anguohou->startAnimation("ani_daiji03",true);
            }
            detectTalk=1;
            clickEnable[2] = 1;
        }
        else if(recordStatus==18)
        {
            //守衛說話
            NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];

            m_pMetaioSDK->unloadGeometry(textGuide);
            textGuide=NULL;
            textGuide = m_pMetaioSDK->createGeometryFromCGImage([@"test" UTF8String], [[self getBillboardImage:@"请与守卫说话" andPath:texturePath] CGImage]);
            textGuide->setCoordinateSystemID(0);
            textGuide->setScale(0.8);
            textGuide->setRelativeToScreen(20,8);
            textGuide->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
            textGuide->setRenderOrder(50);
            textGuide->setVisible(true);
            
            anguohou->startAnimation("walkIn",false);
            guanyuan->startAnimation("ani_zhuansheng02",false);
            
            swTalk=1;
            int i;
            for(i=0; i<7; i++)
                shouwei[i]->startAnimation("ani_daiji02",true);
            for(i=3; i<10; i++)
                clickEnable[i] = 1;
        }
        else if(recordStatus>18 && recordStatus<26)
        {
            swTalk=1;
            if(recordStatus==25) // end talk
            {
                swTalk=1;
                m_pMetaioSDK->unloadGeometry(textGuide);
                textGuide=NULL;
                
                NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
                textGuide = m_pMetaioSDK->createGeometryFromCGImage([@"test" UTF8String], [[self getBillboardImage:@"请再次與守衛說話找出內奸" andPath:texturePath] CGImage]);
                textGuide->setCoordinateSystemID(0);
                textGuide->setScale(0.8);
                textGuide->setRelativeToScreen(20,8);
                textGuide->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
                textGuide->setRenderOrder(50);
                textGuide->setVisible(true);
                int i;
                for(i=0; i<7; i++)
                    shouwei[i]->startAnimation("ani_daiji02",true);
                for(i=3; i<10; i++)
                    clickEnable[i] = 1;
            }
            else
            {
                int i;
                for(i=3; i<10; i++)
                    if(clickEnable[i]==0) shouwei[i-3]->startAnimation("ani_daiji01",true);
            }
        }
        else if(recordStatus>25)
        {
            swTalk=1;
            int i;
            for(i=0; i<7; i++)
                shouwei[i]->startAnimation("ani_daiji02",true);
            for(i=3; i<10; i++)
                clickEnable[i] = 1;
            
            blackBack->setVisible(true);
            swCheckPanel->setVisible(true);
            swCheckNo->setVisible(true);
            swCheckYes->setVisible(true);
        }

        //testStartTalk=1;
    }
    else if(geometry==secondMissionGuide)
    {
        startSecondMissionGuide=1;
        QSCmapClickStop=0;
        testTextStart=0;
        
        guideModel[testChooseWhich-1]->setTexture([[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"guideModelDim%d",testChooseWhich] ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"] UTF8String]);
        testSecondTalkEnable[testChooseWhich-1] = 0;
        
        secondMissionEnd++;
        
        //找出葫蘆提醒
        NSString* texturePath = [[NSBundle mainBundle] pathForResource:@"textBg" ofType:@"png" inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
        m_pMetaioSDK->unloadGeometry(textGuide);
        textGuide=NULL;
        textGuide = m_pMetaioSDK->createGeometryFromCGImage([@"test" UTF8String], [[self getBillboardImage:@"请找寻紫金葫芦，并完成语音导览" andPath:texturePath] CGImage]);
        textGuide->setCoordinateSystemID(0);
        textGuide->setScale(0.8);
        textGuide->setRelativeToScreen(20,8);
        textGuide->setTranslation(metaio::Vector3d(0.0f, -40.0f, 0.0f));
        textGuide->setRenderOrder(50);
        textGuide->setVisible(true);
    }
}

#pragma mark - Helper methods

//poi controll
- (metaio::IGeometry*)createPOIGeometry:(const metaio::LLACoordinate&)lla
{
    NSString* picturePath = [[NSBundle mainBundle] pathForResource:@"CSQpoi"
                                                            ofType:@"png"
                                                       inDirectory:@"tutorialContent_crossplatform/Tulufan/Assets"];
    metaio::IGeometry* geo;
    
    if (picturePath)
    {
        const char *utf8Path = [picturePath UTF8String];
        geo = m_pMetaioSDK->createGeometryFromImage(metaio::Path::fromUTF8(utf8Path));
        annotatedGeometriesGroup->setConnectingLineColorForGeometry(Geo1, 240, 130, 30, 255);
        geo->setScale(450.0f);
        geo->setRenderOrder(3,false,true);
        geo->setTranslationLLA(lla);
        geo->setLLALimitsEnabled(true);
    }
    return geo;
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

//annotation controll
- (metaio::IGeometry*)loadUpdatedAnnotation:(metaio::IGeometry*)geometry userData:(void*)userData existingAnnotation:(metaio::IGeometry*)existingAnnotation
{
    if (existingAnnotation)
    {
        return existingAnnotation;
    }
    if (!userData)
    {
        return 0;
    }
    
    UIImage* thumbnail;
    UIImage* img;
    NSString * nstr;
    const char *str;
    
    if(strcmp("岗哨区", (const char*)userData)==0){
        nstr=@"岗哨区";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_1.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,5);
    }
    else if(strcmp("大型院落", (const char*)userData)==0){
        nstr=@"大型院落";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_2.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,2);
    }
    else if(strcmp("商业区", (const char*)userData)==0){
        nstr=@"商业区";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_3.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,2);
    }
    else if(strcmp("官署区", (const char*)userData)==0){
        nstr=@"官署区";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_4.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,5);
    }
    else if(strcmp("仓储区", (const char*)userData)==0){
        nstr=@"仓储区";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_5.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,5);
    }
    else if(strcmp("居住区", (const char*)userData)==0){
        nstr=@"居住区";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_6.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,5);
    }
    else if(strcmp("大佛寺", (const char*)userData)==0){
        nstr=@"大佛寺";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_7.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,2);
        playBtn->setVisible(true);
    }
    else {
        nstr=@"塔林";
        str=[nstr UTF8String];
        thumbnail = [UIImage imageNamed:@"tutorialContent_crossplatform/Tulufan/Assets/poiPic_8.png"];
        img = metaio::createAnnotationImage([NSString stringWithCString:str encoding:NSUTF8StringEncoding],geometry->getTranslationLLA(),m_currentLocation,thumbnail,nil,2);
        playBtn->setVisible(true);
    }
    metaio::IGeometry* mma;
    mma=m_pMetaioSDK->createGeometryFromCGImage([[NSString stringWithFormat:@"annotation-%s", (const char*)userData] UTF8String], img.CGImage, true, false);
    
    mma->setName(str);
    
    NSLog(@"setname %s",str);
    
    return mma;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        float dtest=0;
        dtest=totalBytesWritten * 1.0 / totalBytesExpectedToWrite;
        //列印下載百分比
        NSLog(@"%f",totalBytesWritten * 1.0 / totalBytesExpectedToWrite);
        
        if (dtest<1)
        {
            int changeInt = (int) (dtest*100);
            NSString *name;
            if(downloadType==0) name=@"岗哨区模型";
            else if(downloadType==1) name=@"大型院落模型";
            else if(downloadType==2) name=@"商业区模型";
            else if(downloadType==3) name=@"官署区模型";
            else if(downloadType==4) name=@"仓储区模型";
            else if(downloadType==5) name=@"居住区模型";
            else if(downloadType==6) name=@"大佛寺模型";
            else if(downloadType==7) name=@"塔林模型";
            else if(downloadType==8) name=@"岗哨区人物";
            else if(downloadType==9) name=@"大型院落人物";
            else if(downloadType==10) name=@"商业区人物";
            else if(downloadType==11) name=@"官署区人物";
            else if(downloadType==12) name=@"仓储区人物";
            else if(downloadType==13) name=@"居住区人物";
            else if(downloadType==14) name=@"大佛寺人物";
            else if(downloadType==15) name=@"塔林人物";
            else if(downloadType<36) name=@"官署區模型";
            else name=@"語音";
            
            NSString *myString2 = [[NSNumber numberWithInt:changeInt] stringValue];
            NSString *combined2 = [NSString stringWithFormat:@"当前进度：%@%@", myString2, @"%"];
            m_Label1.text = [NSString stringWithFormat:@"当前档案：%@", name];
            
            if(testprogress==0) m_Label3.text=[NSString stringWithFormat:@"整体进度：%d%@", 0,@"%"];
            
            m_Label2.text=combined2;
        }
        
        
        if (dtest==1)
        {
            NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
            [data setObject:@"0" forKey:[NSString stringWithFormat:@"%d",downloadType]];
            
            NSString *temp1 = [NSString stringWithFormat:@"temp%d",downloadType];
            [data setObject:model[downloadType] forKey:temp1];
            NSString *value1 = [data objectForKey:temp1];
            NSLog(@"value:%@ %@",temp1,model[downloadType]);
            
            NSString *checkDownloadProgress = [data objectForKey:@"DownloadNum"];
            int value = [checkDownloadProgress intValue];
            testprogress=testprogress+1;
            NSLog(@"dtest:%d %d",testprogress,value);
            float test=testprogress*100/(value+28);
            NSString *myString3 = [[NSNumber numberWithFloat:test] stringValue];
            NSString *combined3 = [NSString stringWithFormat:@"整体进度：%@%@", myString3,@"%"];
            m_Label3.text=combined3;
            [m_Label3 sizeToFit];
            if(testprogress==value+28)
            {
                testloading=1;
            }
            
        }
        
        
    });
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    //[self downloadModel:downloadType didFinishDownloadingToURL:location];//choose which one to download
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *FilePath;
    
    NSString *temp;
    if(downloadType<36)temp=[NSString stringWithFormat:@"/%@.zip",model[downloadType]];
    else temp=[NSString stringWithFormat:@"/%@.3g2",model[downloadType]];
    NSLog(@"model:%@",model[downloadType]);

    FilePath=[docDir stringByAppendingString:temp];
    
    [fileManager moveItemAtPath:location.path toPath:FilePath error:nil];
    BOOL isExist_m = [fileManager fileExistsAtPath:FilePath];
    if(isExist_m){
        NSLog(@"%@%@",@"檔案存在_false：",FilePath);
        modelPath[downloadType]=FilePath;

    }
    dispatch_async(dispatch_get_main_queue(), ^{
        downloadTest=1;
        downloadType=downloadType+1;
        
        [self modelDownload];
    
    });
}
- (NSString*) createLabel1:(int)index creatName:(NSString *)name createPath:(NSString *)createPath
{
    return [NSString stringWithFormat:@"%@/%@",createPath,name];
}

//download model and sound function
-(void) downloadModel:(int)index didFinishDownloadingToURL:(NSURL *)location
{
    
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape; //支援橫向
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
}
//gps
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
    //第0個位置資訊，表示為最新的位置資訊
    locationCurrent = [locations objectAtIndex:0];
    m_currentLocation = metaio::LLACoordinate(locationCurrent.coordinate.latitude, locationCurrent.coordinate.longitude,0,0);
    //顯示在label上
    NSLog(@"經緯度資訊=%f / %f",locationCurrent.coordinate.latitude, locationCurrent.coordinate.longitude);
    
}

/**/
-(IBAction)xadd:(id)sender
{

    metaio::Vector3d x = env3D->getTranslation();
    x.x = x.x + 100;
    env3D->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    //shouwei_01->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    NSLog(@"x %f y %f",x.x, x.y);

    
    
}
-(IBAction)xminius:(id)sender
{
    metaio::Vector3d x = env3D->getTranslation();
    x.x = x.x - 100;
    env3D->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    //shouwei_01->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    NSLog(@"x %f y %f",x.x, x.y);
}
-(IBAction)yadd:(id)sender
{
    metaio::Vector3d x = env3D->getTranslation();
    x.y = x.y + 100;
    env3D->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    //shouwei_01->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    NSLog(@"x %f y %f",x.x, x.y);
}
-(IBAction)yminius:(id)sender
{
    metaio::Vector3d x = env3D->getTranslation();
    x.y = x.y - 100;
    env3D->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    //shouwei_01->setTranslation(metaio::Vector3d(x.x,x.y,x.z));
    NSLog(@"x %f y %f",x.x, x.y);
}

@end
