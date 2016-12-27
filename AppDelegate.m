// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "AppDelegate.h"

#import "MenuViewController.h"

@implementation AppDelegate
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    inetReach = [Reachability reachabilityForInternetConnection];
    [inetReach startNotifier];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Menu" bundle:nil] instantiateInitialViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

// Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    [self updateInterfaceWithReachability: curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)curReach
{
    NetworkStatus curStatus;
    BOOL m_bReachableViaWWAN;
    BOOL m_bReachableViaWifi;
    BOOL m_bReachable;
    //  According to curReach, modify current internal flags
    
    //  Internet reachability
    //  Need network status to know real reachability method
    curStatus = [curReach currentReachabilityStatus];
    
    NSUserDefaults *data = [NSUserDefaults standardUserDefaults];
    
    //  Modify current network status flags
    if(curStatus == NotReachable)
    {
        NSLog(@"notreach2");
        [data setObject:@"0" forKey:@"testNetWork"];
    }
    else if (curStatus == ReachableViaWiFi)
    {
        NSLog(@"wifi2");
        [data setObject:@"1" forKey:@"testNetWork"];
    }
    else if (curStatus == ReachableViaWWAN)
    {
        NSLog(@"wwan2");
        [data setObject:@"1" forKey:@"testNetWork"];
    }
    /*if (curStatus == ReachableViaWWAN) {
     m_bReachableViaWWAN = true;
     } else {
     m_bReachableViaWWAN = false;
     }
     
     if (curStatus == ReachableViaWiFi) {
     m_bReachableViaWifi = true;
     } else {
     m_bReachableViaWifi = false;
     }*/
    
    //  Reachable is the OR result of two internal connection flags
    m_bReachable = (m_bReachableViaWifi || m_bReachableViaWWAN);
    
    if (!m_bReachable) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"注意" message:@"無法連結網路" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"EnterBackground:");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"EnterBackground:");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"EnterForeground:");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"BecomeActive:");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"terminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
