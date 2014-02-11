//
//  UTGCPViewController.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UTRadialButtonView.h"
#import "UTPlotView.h"
#import "USKGCP.h"

@interface UTGCPViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UTRadialButtonViewProtocol>

@property USKGCP *gcp;
@property BOOL showVertexNumber;
@property BOOL showTimer;


// Read by InfoViewController.
@property (weak, nonatomic) IBOutlet UILabel *ConflictCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopwatchLabel;



- (void)updateVertexButtonLabels;




@end
