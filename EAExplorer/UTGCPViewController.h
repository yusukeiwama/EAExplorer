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
#import "UTGCP.h"

@interface UTGCPViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UTRadialButtonViewProtocol>

@property UTGCP *gcp;
@property BOOL showVertexNumber;
@property BOOL showTimer;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *graphView;
@property (weak, nonatomic) IBOutlet UIImageView *edgeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *circleImageView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UTPlotView *plotView;
@property (weak, nonatomic) IBOutlet UILabel *generationLabel;
@property (weak, nonatomic) IBOutlet UITextField *numberOfColorsField;
@property (weak, nonatomic) IBOutlet UITextField *numberOfVerticesField;
@property (weak, nonatomic) IBOutlet UITextField *numberOfEdgesField;
@property (weak, nonatomic) IBOutlet UIButton *generateButton;
@property (weak, nonatomic) IBOutlet UIButton *verificationButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *ConflictCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *stopwatchLabel;


- (IBAction)generateButtonAction:(id)sender;
- (IBAction)verificationButtonAction:(id)sender;
- (void)updateVertexButtonLabels;


@end
