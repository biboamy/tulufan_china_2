//
//  myapi.h
//  PlayArtTemplate
//
//  Created by MediaAdv on 2016/3/15.
//  Copyright © 2016年 Metaio GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface myapi : NSObject
{
    UIImage * getimg;
       Reachability *inetReach;
}
-(UIImage *) getimg : (NSString *)  p;
/*使用+(void)不需要例項就可以呼叫,如果使用-(void)記得宣告    
 myapi * b = [[myapi alloc] init];
 */
+(void) copyfile;
+(void) checkfilef:(NSString* )frompath  checkfilet:(NSString *) topath;
+(void)showalert: (NSString *)  p;
+(NSString *)checknetwork;

@end
