//
//  UTInfoViewController.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/16/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UTGCPViewController;

@interface UTInfoViewController : UIViewController

@property UTGCPViewController *delegate;

@property (weak, nonatomic) IBOutlet UISwitch *vertexNumberSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *timeSwitch;


- (IBAction)vertexNumberSwitchValueChanged:(id)sender;
- (IBAction)timeSwitchValueChanged:(id)sender;

- (IBAction)backButtonAction:(id)sender;

@end


/*
 

*/