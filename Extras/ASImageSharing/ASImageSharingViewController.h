// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import <UIKit/UIKit.h>

@interface ASImageSharingViewController : UIViewController
{
    UIImage*    imageToPost;
    UIImageView *imageView;
}
@property (nonatomic, strong) UIImage*  imageToPost;
@property (nonatomic, strong) NSString* channelName;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *btnBack;
@property (strong, nonatomic) IBOutlet UINavigationItem *topBar;
@property(nonatomic, assign) int myValue;

- (IBAction)onButtonBackPushed:(id)sender;
- (IBAction)onButtonSharePushed:(id)sender;

@end
