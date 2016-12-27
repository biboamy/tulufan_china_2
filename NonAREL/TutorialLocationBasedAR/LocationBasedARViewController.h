// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "NonARELTutorialViewController.h"

@interface LocationBasedARViewController : NonARELTutorialViewController
{
    //下載頁面
    metaio::IGeometry*	loadingImage;
    metaio::IGeometry*	loadingPicture;
    metaio::IGeometry*	loadingModel;
    int testProgress;
    int testloading;
    
    metaio::IGeometry*	track_stuff;
    metaio::IGeometry*	finder;
    metaio::IGeometry*	top_title;
    metaio::IGeometry*	back_btn;
    metaio::IGeometry*	picture_taken;
    metaio::IGeometry*	footer;
    metaio::IGeometry*	sapan1;
    metaio::IGeometry*	sapan2;
    metaio::IGeometry*	sapan3;
    metaio::IGeometry*	sapan4;
    metaio::IGeometry*	sapan5;
    metaio::IGeometry*	sapan6;
    metaio::IGeometry*	sapan7;
    metaio::IGeometry*	sapan8;
    metaio::IGeometry*	line;
    
    metaio::IGeometry*	shutterSound;
    
    metaio::IGeometry* guideSound;
    
    //download background
    metaio::IGeometry* downloadTicket;
    
    //便是確認
    metaio::IGeometry* checkPanel;
    metaio::IGeometry* trackDownload;
    metaio::IGeometry* trackEnter;
    metaio::IGeometry* blackBack;
    
    //字幕機
    int timer[100];//存字幕時間
    NSString *text[100];//存字幕
    metaio::IGeometry* textGuide;//將字幕化成圖
    metaio::IGeometry* textBg;//
    int testTextStart;//測試是否開始播放字幕
    int index;//時間目前跑到哪裡
    int endIndex;//最後的時間
    int testTXT;//判斷圖只畫一次
    
    //download stuff
    NSString *model[21];
    NSString *modelPath[21];//createModelPath
    int downloadType;
    int downloadTest;
    
    int enable;
    int count;
    int testFirstTime;
    int testGuideStart;
    int testEnter;
    int playStatus;
    
    int testScreen;
    
    //test network
    int testNetWork;
    
    __weak IBOutlet UILabel* m_Label1;
    __weak IBOutlet UILabel* m_Label2;
    __weak IBOutlet UILabel* m_Label3;
}
@property (nonatomic, assign) int  readvalue;

@end
