//
//  myapi.m
//  PlayArtTemplate
//
//  Created by MediaAdv on 2016/3/15.
//  Copyright © 2016年 Metaio GmbH. All rights reserved.
//



#import "myapi.h"

@implementation myapi

+(void) checkfilef: (NSString *) frompath checkfilet: (NSString *)  topath
{
    NSLog(@"checkfile");
    
          NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager copyItemAtPath:frompath toPath:topath error:nil];
    //判断文件是否存在
    
    if (success){
        BOOL isExist = [fileManager fileExistsAtPath:topath];
        if (isExist)
        {
            NSLog(@"%@%@",@"檔案存在：",topath);
            
        }
        else
            NSLog(@"%@%@",@"檔案不存在：",topath);
        
    }
    /*
     NSURL *url=[NSURL URLWithString:@"http://home.advmedia.com.tw/metaio/frame.png"];
     UIImage *imgFromUrl =[[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:url]];
     [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(imgFromUrl)forKey:@"key_for_your_image"];
     
     NSData* imageData = [[NSUserDefaults standardUserDefaults]objectForKey:@"key_for_your_image"];
     //   CGImageRef cgRef=imgFromUrl.CGImage;
     
     UIImage *theImage = NULL;
     
     NSString *imageFileName = [BT_strings getFileNameFromURL:theURL];
     NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:theURL]];
     theImage =  [[UIImage alloc] initWithData:imageData];
     
     */
    
   
}
+(void) copyfile
{
    NSLog(@"copyfile");
         NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //建立新資料夾
    //製作新資料夾的路徑
    NSString *newFolderPath = [docDir stringByAppendingPathComponent:@"NewMaterial"];
    
    //建立新資料夾
    
    if ([fileManager createDirectoryAtPath:newFolderPath withIntermediateDirectories:YES attributes:nil error:nil])
        
        NSLog(@"%@%@",@"新資料夾建立成功：",newFolderPath);
    //复制文件（重命名）
    
    NSString *toPath = [newFolderPath stringByAppendingPathComponent:@"newframe.png"];
    [fileManager createDirectoryAtPath:[toPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    BOOL success = [fileManager copyItemAtPath:@"" toPath:toPath error:nil];
    //判断文件是否存在
    
    if (success){
        BOOL isExist = [fileManager fileExistsAtPath:toPath];
        if (isExist)
        {
            NSLog(@"%@%@",@"檔案存在：",toPath);
            
        }
        else
            NSLog(@"%@%@",@"檔案不存在：",toPath);
        
    }
}
- (UIImage *)getimg: (NSString *)  p
{
    NSURL *imgurl = [NSURL URLWithString:p];
    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:imgurl]];
    
    return image;
}
- (UIImage *) getImageFromURL: (NSString *)theURL {
    UIImage *theImage = NULL;
    /*
     NSString *imageFileName = [BT_strings getFileNameFromURL:theURL];
     NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:theURL]];
     theImage =  [[UIImage alloc] initWithData:imageData];
     [BT_fileManager saveImageToFile:theImage fileName:imageFileName];
     */
    
    NSLog(@"下載中...");
    // 透過網址取得圖片
    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://blog.it4fun.net/wp-content/uploads/2013/05/Core-Graphics_bliss.png"]]];
    
    NSLog(@"%f,%f",image.size.width,image.size.height);
    
    // 把它存在Document資料夾
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSLog(@"%@%@",@"Document資料夾：",docDir);
    
    NSLog(@"儲存成 png");
    NSString *pngFilePath = [NSString stringWithFormat:@"%@/test.png",docDir];
    NSData *data1 = [NSData dataWithData:UIImagePNGRepresentation(image)];
    [data1 writeToFile:pngFilePath atomically:YES];
    
    NSLog(@"儲存成  jpeg");
    NSString *jpegFilePath = [NSString stringWithFormat:@"%@/test.jpeg",docDir];
    NSData *data2 = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0f)];//1.0f = 100% 不失真
    [data2 writeToFile:jpegFilePath atomically:YES];
    
    NSLog(@"儲存完成");
    
    return theImage;
}

+(void)showalert: (NSString *)  p
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
     message:p
     delegate:nil
     cancelButtonTitle:@"Okay"
     otherButtonTitles:nil, nil];
     [alertView show];
}
+(NSString *)checknetwork{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
      return @"notreach";
        NSLog(@"notreach");
       
    }
    else if (status == ReachableViaWiFi)
    {
        return @"wifi";

        NSLog(@"wifi");

    }
    else if (status == ReachableViaWWAN)
    {
        return @"wwan";
        

        NSLog(@"wwan");
          }
}

@end

