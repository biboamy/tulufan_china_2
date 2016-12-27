// Copyright 2007-2014 metaio GmbH. All rights reserved.
#import "NonARELTutorialViewController.h"

@interface NonARELTutorialViewController ()

@end

@implementation NonARELTutorialViewController

- (IBAction)onCloseButtonClicked:(UIButton*)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
- (void) startDefaultCamera
{
    
    [super startDefaultCamera];
   
    
}
@end
