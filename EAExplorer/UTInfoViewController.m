//
//  UTInfoViewController.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/16/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTInfoViewController.h"
#import "UTGCPViewController.h"

@interface UTInfoViewController ()

@end

@implementation UTInfoViewController

@synthesize delegate;

@synthesize vertexNumberSwitch;
@synthesize timeSwitch;
@synthesize violationCounterSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	vertexNumberSwitch.on = delegate.showVertexNumber;
	timeSwitch.on = !(delegate.stopwatchLabel.hidden);
	violationCounterSwitch.on = !(delegate.violationCountLabel.hidden);
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)vertexNumberSwitchValueChanged:(id)sender {
	delegate.showVertexNumber = ((UISwitch *)sender).on;
	[delegate updateVertexButtonLabels];
}

- (IBAction)timeSwitchValueChanged:(id)sender {
	delegate.stopwatchLabel.hidden = !(((UISwitch *)sender).on);
}

- (IBAction)violationCounterSwitchValueChanged:(id)sender {
	delegate.violationCountLabel.hidden = !(((UISwitch *)sender).on);
}

- (IBAction)backButtonAction:(id)sender {
	[self dismissViewControllerAnimated:YES completion:^{}];
}
@end
