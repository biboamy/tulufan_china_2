// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import <UIKit/UIKit.h>
//#import <metaioSDK/IMetaioSDK.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>


@interface MenuViewController : UIViewController<UIWebViewDelegate,CLLocationManagerDelegate>
{
    CLLocationManager * locationManager;
    UIImageView *loading;

}

@property (weak, nonatomic) IBOutlet UIWebView *tutorialsView;
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *activityImg;
@property (nonatomic, weak) IBOutlet UIImageView *activityImgSmall;
@property (nonatomic, retain) NSString *textID;
@property (nonatomic, retain) NSString *textValue;
@property (nonatomic, retain) NSString *firstTimeTest;
@property (nonatomic, strong) UIView* questionView;

@end
