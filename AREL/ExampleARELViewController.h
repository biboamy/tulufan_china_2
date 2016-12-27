// Copyright 2007-2014 metaio GmbH. All rights reserved.

#import <metaioSDK/ARELViewController.h>
#import <MediaPlayer/MPMusicPlayerController.h>

@interface ExampleARELViewController : ARELViewController
{
    
    
}
@property (retain, nonatomic) IBOutlet UIImageView *m_splashScreenImage;
@property (retain, nonatomic) IBOutlet UIImageView *m_splashScreenImage_bg;
//- (IBAction)onCloseButtonClicked:(UIButton*)sender;
//@property (strong, nonatomic) IBOutlet UIWebView*        arelWebView;
- (bool)openWebsiteWithUrl:(NSString *)url inExternalApp:(bool)openInExternalApp;


@end

