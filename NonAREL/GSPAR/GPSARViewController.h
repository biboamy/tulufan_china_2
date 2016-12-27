// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "NonARELTutorialViewController.h"
#import <metaioSDK/GestureHandlerIOS.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <metaioSDK/IMetaioSDK.h>

namespace metaio
{
    class IGeometry;   // forward declaration
}

@interface GPSARViewController : NonARELTutorialViewController<CLLocationManagerDelegate>
{
    
    CLLocationManager * locationManager;
    CLLocation * locationCurrent;
    CLLocation *locationTarget;
    metaio::LLACoordinate   m_currentLocation;
    
    //gesture handler
    GestureHandlerIOS* m_gestureHandler;
    GestureHandlerIOS* m_gestureHandler1;
    GestureHandlerIOS* m_gestureHandler2;
    
    GestureHandlerIOS* m_gestureHandler3;
    
    
    //download stuff
    NSString *model[44];
    NSString *modelPath[44];//createModelPath
    int downloadType;
    int testprogress;//測試現在下載進度
 
    //gps poi
    float heading;
    
    //test network
    int testNetWork;
    
    //test now status
    int status;
    int finalStatus;
    int checkStatus;
    
    //test mission change
    int testMissonChange;
    
    //test tracking
    NSString *trackingPath;
    
    //test next click
    int nextPageTime;
    
    //test camera
    int testCamera;
    
    //testscreen
    int testScreen;
    
    //test QSC
    int testQSC;
    
    //get model size
    int getModelSize;
    
    //test detect poi play btn
    int poiDetectPlay;
    
    //get tracking package
    int trackValue;
    
    //click sound
    metaio::IGeometry* clickSound;
    
    //int test Value
    int distanceValue;
    
    //test swift time
    int testSwift;
    
    //set tracking first time
    int firstTrack;
    
    //model rotation update
    int modelRotation;
    
    //detect poi on screen
    int detectPOI;
    
    //detect effect movie持平
    int detectEffectMovei;
    
    //detect POI touch
    int poiTouch;
    
    //detect exit radar
    int detectRadarExit;
    
    //set geo transparency
    int geoTrans;
    
    //loading image
    int testloading;
    int downloadTest;
    metaio::IGeometry* loadingImage;
    metaio::IGeometry* loadingPicture;
    metaio::IGeometry* loadingModel;
    
    //radar stuff
    metaio::IAnnotatedGeometriesGroup* annotatedGeometriesGroup;
    metaio::IGeometry* Geo1;
    metaio::IRadar* m_radar;
    
    //first page stuff
    metaio::IGeometry* exitAR;
    metaio::IGeometry* title;
    metaio::IGeometry* titleWord;
    metaio::IGeometry* firstPageModel;
    metaio::IGeometry* firstPageTalk;
    metaio::IGeometry* iknow;
    
    //second page stuff
    metaio::IGeometry* secondPageGuide;
    metaio::IGeometry* tangshengSound;
    metaio::IGeometry* linking;
    metaio::IGeometry* findPOI;
    metaio::IGeometry* pictureTouchGuide;
    int startDetecGPS;
    int iknowTime;
    
    //arrive alert
    metaio::IGeometry* arriveAlert;
    metaio::IGeometry* notArriveAlert;
    int testArrive;
    int arriveValue;
    
    //算持平
    int detectFinder;
    
    //tracking
    int startTracking;
    //int detectFirstLoad;
    int detectFirstPlay;
    int testEffectStatus;
    
    //model3D3 value
    float xValue[8];
    float yValue[8];
    float zValue[8];
    float size[8];
    float xrValue[8];
    float yrValue[8];
    float zrValue[8];
    
    //3D detect
    metaio::IGeometry* mapBtn;
    metaio::IGeometry* finder;
    metaio::IGeometry* closeMap;
    metaio::IGeometry* model3D3;
    
    //map
    metaio::IGeometry* map;
    metaio::IGeometry* point[8];
    metaio::IGeometry* point1;
    metaio::IGeometry* point2;
    metaio::IGeometry* point3;
    metaio::IGeometry* point4;
    metaio::IGeometry* point5;
    metaio::IGeometry* point6;
    metaio::IGeometry* point7;
    metaio::IGeometry* point8;
    
    //detect success
    metaio::IGeometry* blackBack;
    metaio::IGeometry* effectMovie;
    metaio::IGeometry* playBtn;
    metaio::IGeometry* pauseBtn;
    metaio::IGeometry* replayBtn;
    metaio::IGeometry* next;
    metaio::IGeometry* guideSound;
    metaio::IGeometry* pleaseTouch;
    metaio::IGeometry* pleaseTouchDim;
    metaio::IGeometry* modelToggle;
    metaio::IGeometry* modelToggle2;
    int testPlayGuide;
    int firstTimePlay;
    
    //合拍模式
    metaio::IGeometry* btnModelSwift;
    metaio::IGeometry* controll;
    metaio::IGeometry* controllBack;
    metaio::IGeometry* btnCamara;
    metaio::IGeometry* pictureModel;
    metaio::IGeometry* people;
    metaio::IGeometry* setActiveModel;
    metaio::IGeometry* touchGuide;
    metaio::IGeometry* cameraGuide;
    
    //controll stick
    int getTouchEnd;
    metaio::Vector3d controllStickPoi;
    metaio::Vector3d modelPos;
    
    //complete page
    metaio::IGeometry* completeAlert;
    
    //官署區
    metaio::IGeometry* treasureBox;
    metaio::IGeometry* env3D;
    metaio::IGeometry* enter3D;
    metaio::IGeometry* out3D;
    metaio::IGeometry* enter3D2;
    metaio::IGeometry* out3D2;
    metaio::IGeometry* enter3D3;
    metaio::IGeometry* out3D3;
    metaio::IGeometry* missionBar;
    metaio::IGeometry* backgroundMusic;
    metaio::IGeometry* guowang;
    metaio::IGeometry* guanyuan;
    metaio::IGeometry* shouwei[7];
    metaio::IGeometry* shouwei_01;
    metaio::IGeometry* shouwei_02;
    metaio::IGeometry* shouwei_03;
    metaio::IGeometry* shouwei_04;
    metaio::IGeometry* shouwei_05;
    metaio::IGeometry* shouwei_06;
    metaio::IGeometry* shouwei_07;
    metaio::IGeometry* anguohou;
    metaio::IGeometry* hulu[4];
    metaio::IGeometry* hulu1;
    metaio::IGeometry* hulu2;
    metaio::IGeometry* hulu3;
    metaio::IGeometry* hulu4;
    metaio::IGeometry* shouweiAlert;

    int testTalk;
    int detectTalk;
    int testLoad3D;
    int testShouwei;
    
    
    //官署區 語音
    metaio::IGeometry* QSCtalk;
    int recordStatus;
    int testStartTalk;
    int startPeopleTalk;
    int QSCIndex;
    int swTalk;
    int QSCmapClickStop;
    int secondMissionEnd;
    
    //獎券
    metaio::IGeometry* giftPanel;
    metaio::IGeometry* giftBtnRight;
    
    //確認是否為內奸
    metaio::IGeometry* swCheckPanel;
    metaio::IGeometry* swCheckYes;
    metaio::IGeometry* swCheckNo;
    
    //官署區第二關
    metaio::IGeometry* guideModel1;
    metaio::IGeometry* guideModel2;
    metaio::IGeometry* guideModel3;
    metaio::IGeometry* guideModel4;
    metaio::IGeometry* guideModel[4];
    metaio::IGeometry* secondMissionGuide;
    int startSecondMissionGuide;
    int testChooseWhich;
    int testSecondTalkEnable[4];
    
    
    //官署區動畫
    metaio::CustomAnimation cAni;
    metaio::CustomAnimation cAniRe;
    metaio::AnimationKeyFrame key0;
    metaio::AnimationKeyFrame key50;
    metaio::stlcompat::Vector<metaio::AnimationKeyFrame> vector;
    metaio::stlcompat::Vector<metaio::AnimationKeyFrame> vectorRe;
    int clickEnable[10];
    
    //next animation
    metaio::AnimationKeyFrame nextKey0;
    metaio::AnimationKeyFrame nextKey50;
    metaio::AnimationKeyFrame nextKey25;
    
    //camera guide animation
    metaio::AnimationKeyFrame cKey0;
    metaio::AnimationKeyFrame cKey30;
    metaio::AnimationKeyFrame cKey70;
    metaio::AnimationKeyFrame cKey100;
    
    //finder animation
    metaio::AnimationKeyFrame fKey0;
    metaio::AnimationKeyFrame fKey30;
    
    //final page
    metaio::IGeometry* topFrame;
    metaio::IGeometry* leftFrame;
    metaio::IGeometry* rightFrame;
    metaio::IGeometry* bottomFrame;
    metaio::IGeometry* frameModelLeft;
    metaio::IGeometry* frameModelRight;
    metaio::IGeometry* yesBtn;
    metaio::IGeometry* noBtn;
    metaio::IGeometry* checkPanel;
    metaio::IGeometry* checkWord;
    
    //字幕機
    int timer[100];//存字幕時間
    NSString *text[100];//存字幕
    metaio::IGeometry* textGuide;//將字幕化成圖
    int testTextStart;//測試是否開始播放字幕
    int index;//時間目前跑到哪裡
    int endIndex;//最後的時間
    int testTXT;//判斷圖只畫一次
    
    //test playbtn
    int playBtnStatus;
    
    //instant tracking
    bool m_mustUseInstantTrackingEvent;
    metaio::IGeometry* resetBtn;
    metaio::IGeometry* instantBtn;
    metaio::IGeometry* instantGuide;
    
    
    
    //metaio::Vector3d x;
    
    __weak IBOutlet UILabel* m_Label1;
    __weak IBOutlet UILabel* m_Label2;
    __weak IBOutlet UILabel* m_Label3;
    
    __weak IBOutlet UILabel* dateLabel;
    
    __weak IBOutlet UILabel* scaleLabel;
    
    __weak IBOutlet UIButton* xAdd;
    __weak IBOutlet UIButton* xminus;
    __weak IBOutlet UIButton* yAdd;
    __weak IBOutlet UIButton* yminus;
    __weak IBOutlet UIButton* zAdd;
    __weak IBOutlet UIButton* zminus;
    
    int xxx;
    int zzz;
    int yyy;
    
}
@property (nonatomic, assign) int  readvalue;

- (metaio::IGeometry*)loadUpdatedAnnotation:(metaio::IGeometry*)geometry userData:(void*)userData existingAnnotation:(metaio::IGeometry*)existingAnnotation;

@end
