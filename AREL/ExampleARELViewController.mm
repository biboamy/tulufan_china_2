// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "ExampleARELViewController.h"
#import "MyurlViewController.h"
#import "ASImageSharingViewController.h"


@interface ExampleARELViewController ()
{
    NSString *urlId;
    NSString *urlValue;
    NSString *urlname;
    NSString *urltype;
    NSString *urldir;
    NSString *httpname;
    NSString *httptype;
    NSString *httpdir;
    NSString *myfs;
    NSString *textID;
    NSString *textok;
    NSString *textValue;
    NSString *textno;
    NSString *textcheck;
}

@end
@implementation ExampleARELViewController
@synthesize arelWebView;
@synthesize m_splashScreenImage;
@synthesize m_splashScreenImage_bg;



#pragma mark - IARELInterpreterIOSDelegate


- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
// Override to handle "saved to gallery" event
    
}

-(bool) openWebsiteWithUrl:(NSString *)url inExternalApp:(bool)openInExternalApp
{
    
NSString* action = [[url componentsSeparatedByString:@"="] objectAtIndex:1];

if ([[url lowercaseString] hasPrefix:@"myurl"]) {
    
  
if ([action isEqualToString:@"doWriteFile"]) {
        //doThingA
     
        urlId =[[url componentsSeparatedByString:@"="] objectAtIndex:2];
        urlValue = [[url componentsSeparatedByString:@"="] objectAtIndex:3];
        myfs = [[url componentsSeparatedByString:@"="] objectAtIndex:4];
        [self writeObjFile];
    
    }
    else if ([action isEqualToString:@"doReadFile"]) {
       
        urlId =[[url componentsSeparatedByString:@"="] objectAtIndex:2];
        myfs =[[url componentsSeparatedByString:@"="] objectAtIndex:3];
       [self readObjFile];

        
    }
    else if ([action isEqualToString:@"changevolume"]) {
        
      urlValue =[[url componentsSeparatedByString:@"*"] objectAtIndex:1];
     
      //  NSInteger b = [urlValue integerValue];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        float value = [numberFormatter numberFromString:urlValue].floatValue;
        
        MPMusicPlayerController *musicPlayerController = [MPMusicPlayerController applicationMusicPlayer];
        musicPlayerController.volume = value;
        
    
    }
    else if ([action isEqualToString:@"getvolume"]) {
        
        urlValue =[[url componentsSeparatedByString:@"*"] objectAtIndex:1];
        
        [self  getVolume];
    }
    else if ([action isEqualToString:@"externalWeb"]) {
        urldir =[[url componentsSeparatedByString:@"*"] objectAtIndex:1];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urldir]];//外部瀏覽器
    }

   
    else if ([action isEqualToString:@"internalWeb"]) {
        urlname =[[url componentsSeparatedByString:@"="] objectAtIndex:2];
        urltype = [[url componentsSeparatedByString:@"="] objectAtIndex:3];
        urldir =[[url componentsSeparatedByString:@"*"] objectAtIndex:1];
        @try {
            
            if ([[urlname lowercaseString] isEqualToString:@"online"]&&[[urltype lowercaseString] isEqualToString:@"link"]){
                [self runobjwebsite];}
            else {
                      NSLog(@"error!!");
            }
            
        }
        @catch (NSException * e) {
        
            NSLog(@"Exception: %@", e);
        }
        @finally {
            
            NSLog(@"finally");
        }
        
        
    }
    
    else if ([action isEqualToString:@"finishapp"]) {

        NSString *a = [[url componentsSeparatedByString:@"="] objectAtIndex:2];
        textID = a;
        
        NSString *b = [[url componentsSeparatedByString:@"="] objectAtIndex:3];
        textValue = b;
        
        NSString *c =[[url componentsSeparatedByString:@"="] objectAtIndex:4];
        textok = c;
        
        NSString *d = [[url componentsSeparatedByString:@"="] objectAtIndex:5];
        textno = d;
        
        NSString *e = [[url componentsSeparatedByString:@"="] objectAtIndex:6];
        textcheck = e;
        if ([[e lowercaseString] rangeOfString:@"yes"].location != NSNotFound)
        {
            UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:a
                                                             message:b
                                                            delegate:self
                                                   cancelButtonTitle:c
                                                   otherButtonTitles: nil];
            [alert addButtonWithTitle:d];
            [alert show];
        }
        else if ([[e lowercaseString] rangeOfString:@"no"].location != NSNotFound)
            
        {
            [self dismissViewControllerAnimated:YES completion:nil];//  直到找到最底层为止
        }

    }else if ([action isEqualToString:@"localhostWeb"]) {
        urlname =[[url componentsSeparatedByString:@"="] objectAtIndex:2];
        urltype = [[url componentsSeparatedByString:@"="] objectAtIndex:3];
        urldir =[[url componentsSeparatedByString:@"="] objectAtIndex:4];
        
        [self runobjwebsite];
        
    }
    else if ([action isEqualToString:@"showmessage"]) {
        
        urlname =[[url componentsSeparatedByString:@"="] objectAtIndex:2];
        urltype = [[url componentsSeparatedByString:@"="] objectAtIndex:3];
        urldir =[[url componentsSeparatedByString:@"="] objectAtIndex:4];
        [self runObjMessage];
        
    }
    else if ([action isEqualToString:@"hideLoadingScreen"]) {
        
         [self.m_splashScreenImage_bg setHidden:TRUE];
        
        [self.m_splashScreenImage setHidden:TRUE];
        
    
        
        
    }
}
    
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
 
    if (buttonIndex == 0)
    {
        NSLog(@"You have clicked Cancel");
    }
    else if(buttonIndex == 1)
    {
        NSLog(@"You have clicked GOO");
        [self dismissViewControllerAnimated:YES completion:nil];// // 直到找到最底层为止
    }
}
- (void)  getVolume
{

    float vol = [[MPMusicPlayerController applicationMusicPlayer] volume];
    
    vol=vol*16;
    
    NSString* Text = [[NSString alloc] initWithFormat:@"%f", vol];
    NSString *myreadfs=@"('%@')";
    NSString *ConText = [NSString stringWithFormat:@"%@%@", urlValue,myreadfs];
    [arelWebView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,Text ]];
    
}

- (void) writeObjFile
{
    NSString *str = urlValue;
    NSString *string = [NSString stringWithString: str];
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    [data setObject:string forKey:urlId];
    
    NSString *myreadfs=@"('%@','%@')";
    NSString *ConText = [NSString stringWithFormat:@"%@%@", myfs,myreadfs];
    
    
    [arelWebView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,urlId,urlValue ]];
 
 
}
- (void) readObjFile
{
    
    NSString *value;
    value = [[NSUserDefaults standardUserDefaults] objectForKey:urlId];
    
    NSString *myreadfs=@"('%@','%@')";
    NSString *ConText = [NSString stringWithFormat:@"%@%@", myfs,myreadfs];
    
    
    [arelWebView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:ConText,urlId,value ]];

    

}
- (void) runObjMessage
{

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:urlname message:urltype delegate:nil cancelButtonTitle:urldir otherButtonTitles:nil];
    [alert show];
    
}



- (void) runobjwebsite 
{
    NSString *str1 = urlname;
    NSString *str2 = urltype;
    NSString *str3 = urldir;

    NSString *string1 = [NSString stringWithString: str1];
    NSString *string2 = [NSString stringWithString: str2];
    NSString *string3 = [NSString stringWithString: str3];
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    [data setObject:string1 forKey:@"urlkeyname"];
    [data setObject:string2 forKey:@"urlkeytype"];
    [data setObject:string3 forKey:@"urlkeydir"];
    MyurlViewController* tutorialViewController = [[UIStoryboard storyboardWithName:@"Menu2" bundle:nil] instantiateInitialViewController];
    [self presentViewController:tutorialViewController animated:YES completion:nil];
    
}
- (void) runobjhttpwebsite
{
    NSString *str1 = httpname;
    NSString *str2 = httptype;
    NSString *str3 = httpdir;
    NSString *string1 = [NSString stringWithString: str1];
    NSString *string2 = [NSString stringWithString: str2];
    NSString *string3 = [NSString stringWithString: str3];
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    [data setObject:string1 forKey:@"httpkeyname"];
    [data setObject:string2 forKey:@"httpkeytype"];
    [data setObject:string3 forKey:@"httpkeydir"];
    MyurlViewController* tutorialViewController = [[UIStoryboard storyboardWithName:@"Menu2" bundle:nil] instantiateInitialViewController];
    [self presentViewController:tutorialViewController animated:YES completion:nil];
}
- (void) runobjfinish
{
    	[self dismissViewControllerAnimated:YES completion:nil];
}

- (bool)shareScreenshot:(UIImage*)image options:(bool)saveToGalleryWithoutDialog
{
	if (saveToGalleryWithoutDialog)
	{
            dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
			});
		});
		// Return true to state that we're handling this event
      /*  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"相片儲存" message:@"儲存成功！......" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];*/
		return true;
	}
	else
	{
		// Open a share controller with the image
		NSLog(@"Implement your sharing controller here.");
        ASImageSharingViewController* controller = [[ASImageSharingViewController alloc] initWithNibName:@"ASImageSharingViewController" bundle:nil];
        controller.imageToPost = image;
        [self presentViewController:controller animated:YES completion:nil];
		return false;
	}
}




- (void)LongPress //關閉IOS9webview放大鏡
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:nil action:NULL];
    
    // 至少長按0.1秒
    longPress.minimumPressDuration = 0.1f;
    
    
    // 在觸發手勢之前,50px範圍內長按有效
    /*
     longPress.allowableMovement = 50;
    */
    // 關閉觸發手勢
    /*
     longPress.enabled = false;
     */
    [arelWebView addGestureRecognizer:longPress];

}
//强制横屏開始

//ios2-6版本
/*

 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
 NS_DEPRECATED_IOS(2_0, 6_0){
 
 return UIInterfaceOrientationIsLandscape(interfaceOrientation);
 
 }

*/
//7以上版本

 
 - (NSUInteger)supportedInterfaceOrientations
 {
return UIInterfaceOrientationMaskLandscape; //支援橫向
 
  //return  UIInterfaceOrientationMaskPortrait; //支援縱向
     
//2return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscape; //支持自動旋轉
 }


//强制横屏結束

- (BOOL)shouldAutorotate {      //是否自動旋轉
    
    return YES;
}

-(void) viewDidLoad{

    [super viewDidLoad];
    self.m_splashScreenImage_bg.frame = CGRectMake(0, 0, self.m_splashScreenImage_bg.image.size.width, self.m_splashScreenImage_bg.image.size.height);

    // 禁用用户选择
  //  [arelWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    
    // 禁用长按弹出框
    //[arelWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];

    [self LongPress];


}



@end
