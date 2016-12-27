// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "ASImageSharingViewController.h"
//#import "WXApi.h"
//#import "WXApiObject.h"
@implementation ASImageSharingViewController
@synthesize imageToPost;
@synthesize imageView;
@synthesize channelName;
@synthesize btnBack;
@synthesize myValue;


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set back button label
    [self.topBar setTitle:@"分享截图"];
    
    imageView.image = imageToPost;
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setBtnBack:nil];
    [self setTopBar:nil];
    [self setTopBar:nil];
    [super viewDidUnload];
}


- (IBAction)onButtonBackPushed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction) onButtonSharePushed:(id)sender
{
    
    NSString * mesg =@"testmess";
    NSLog(@"share : %@",mesg);
    
    
    int a= myValue;
    if (a==0)
    {
        //[self showmymessage:@"a==0"];
        NSArray *activityItems = @[imageToPost];
        
        // support for iOS5
        if( !NSClassFromString(@"UIActivityViewController") )
        {
            UIImageWriteToSavedPhotosAlbum(imageToPost, nil, nil, nil);
            return;
        }
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        // for iPad on iOS8 we need to specify where the presentation should come frome
        if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            activityViewController.popoverPresentationController.barButtonItem = (UIBarButtonItem*) sender;
        }
        
        [self presentViewController:activityViewController animated:YES completion:nil];
        
        
    }else if (a==1)
    {
        NSString * mesg =@"1";
        NSLog(@"share : %@",mesg);
        // [self showmymessage:@"a!=0"];
        
        /*   WXMediaMessage *message = [WXMediaMessage message];
         [message setThumbImage:[UIImage imageNamed:@"facebook"]];
         
         WXImageObject *ext = [WXImageObject object];
         NSString* filePath = [[NSBundle mainBundle] pathForResource:@"env_map"
         ofType:@"png"
         inDirectory:@"Content_crossplatform/TrackingSamples/Assets"];
         
         ext.imageData = [NSData dataWithContentsOfFile:filePath];
         UIImage* image = [UIImage imageWithData:ext.imageData];
         //  ext.imageData = UIImagePNGRepresentation(image);
         ext.imageData = UIImagePNGRepresentation(imageView.image);
         message.mediaObject = ext;
         
         SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
         req.bText = NO;
         req.message = message;
         // req.scene = WXSceneTimeline;//分享朋友圈
         req.scene =  WXSceneSession;
         [WXApi sendReq:req];*/
        
        //构造SendAuthReq结构体
        //SendAuthReq* req = [[SendAuthReq alloc] init];
        //  SendAuthReq* req =[[[SendAuthReq alloc ] init ] autorelease ];
        //req.scope = @"snsapi_userinfo" ;
        //req.state = @"123" ;
        //第三方向微信终端发送一个SendAuthReq消息结构
        //[WXApi sendReq:req];
        
        
    }else if (a==2)
    {
        NSString * mesg =@"2";
        NSLog(@"share : %@",mesg);
        // [self showmymessage:@"a!=0"];
        
        //WXMediaMessage *message = [WXMediaMessage message];
        //[message setThumbImage:[UIImage imageNamed:@"facebook"]];
        
        //WXImageObject *ext = [WXImageObject object];
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"env_map"
                                                             ofType:@"png"
                                                        inDirectory:@"Content_crossplatform/TrackingSamples/Assets"];
        
        //ext.imageData = [NSData dataWithContentsOfFile:filePath];
        //UIImage* image = [UIImage imageWithData:ext.imageData];
        //  ext.imageData = UIImagePNGRepresentation(image);
        //ext.imageData = UIImagePNGRepresentation(imageView.image);
        //message.mediaObject = ext;
        
        //SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
        //req.bText = NO;
        //req.message = message;
        //req.scene = WXSceneTimeline;//分享朋友圈
        // req.scene =  WXSceneSession;
        //[WXApi sendReq:req];
        
        
    }
    else if (a==3)
    {
        NSString * mesg =@"3";
        NSLog(@"share : %@",mesg);
        
        //WXMediaMessage *message = [WXMediaMessage message];
        //[message setThumbImage:[UIImage imageNamed:@"facebook"]];
        
        //WXImageObject *ext = [WXImageObject object];
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"env_map"
                                                             ofType:@"png"
                                                        inDirectory:@"Content_crossplatform/TrackingSamples/Assets"];
        
        //ext.imageData = [NSData dataWithContentsOfFile:filePath];
        //UIImage* image = [UIImage imageWithData:ext.imageData];
        //  ext.imageData = UIImagePNGRepresentation(image);
        //ext.imageData = UIImagePNGRepresentation(imageView.image);
        //message.mediaObject = ext;
        
        //SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
        //req.bText = NO;
        //req.message = message;
        //req.scene = WXSceneFavorite;//添加到微信收藏
        
        //[WXApi sendReq:req];
        
        
    }
    else if (a==4)
    {
        NSString * mesg =@"4";
        NSLog(@"share : %@",mesg);
        
        //构造SendAuthReq结构体
        //SendAuthReq* req = [[SendAuthReq alloc] init];
        //  SendAuthReq* req =[[[SendAuthReq alloc ] init ] autorelease ];
        //req.scope = @"snsapi_userinfo" ;
        //req.state = @"123" ;
        //第三方向微信终端发送一个SendAuthReq消息结构
        //[WXApi sendReq:req];
        
        
    }
}
-(void) showmymessage:(NSString*) mytext
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:mytext
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape; //支援橫向
    
    //return  UIInterfaceOrientationMaskPortrait; //支援縱向
    
    //  return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscape; //支持自動旋轉
}
//  [self setActiveModel:4];
//文字分享
/* SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
 req.text=@"和我一起玩艺互动吧";
 req.bText=YES;
 req.scene=WXSceneTimeline;
 [WXApi sendReq: req];*/

/*  WXMediaMessage *message = [WXMediaMessage message];
 [message setThumbImage:[UIImage imageNamed:@"res5thumb.png"]];
 
 WXImageObject *ext = [WXImageObject object];
 NSString* filePath = [[NSBundle mainBundle] pathForResource:@"env_map"
 ofType:@"png"
 inDirectory:@"Content_crossplatform/TrackingSamples/Assets"];
 
 ext.imageData = [NSData dataWithContentsOfFile:filePath];
 UIImage* image = [UIImage imageWithData:ext.imageData];
 ext.imageData = UIImagePNGRepresentation(image);
 message.mediaObject = ext;
 
 SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
 req.bText = NO;
 req.message = message;
 // req.scene = WXSceneTimeline;//分享朋友圈
 req.scene =  WXSceneSession;
 [WXApi sendReq:req];*/
/*  WXMediaMessage *message = [WXMediaMessage message];
 message.title = @"乔布斯访谈";
 message.description = @"饿着肚皮，傻逼着。";
 [message setThumbImage:[UIImage imageNamed:@"res7.jpg"]];
 
 WXVideoObject *ext = [WXVideoObject object];
 ext.videoUrl = @"http://home.advmedia.com.tw/metaio/tv.3g2";
 
 message.mediaObject = ext;
 
 SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
 req.bText = NO;
 req.message = message;
 req.scene = WXSceneSession;
 
 [WXApi sendReq:req];
 
 */
@end
