// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import <UIKit/UIKit.h>
#import "Reachability.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    Reachability *inetReach;
}

@property (strong, nonatomic) UIWindow *window;

@end
