//
//  UTGCPViewController.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UTGCPViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>



@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *graphView;

@property (weak, nonatomic) IBOutlet UIImageView *edgeImageView;

@property (weak, nonatomic) IBOutlet UIImageView *circleImageView;

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;



@property (weak, nonatomic) IBOutlet UITextField *numberOfColorsField;

@property (weak, nonatomic) IBOutlet UITextField *numberOfVerticesField;

@property (weak, nonatomic) IBOutlet UITextField *numberOfEdgesField;



@property (weak, nonatomic) IBOutlet UIButton *generateButton;

@property (weak, nonatomic) IBOutlet UIButton *verificationButton;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;


- (IBAction)generateButtonAction:(id)sender;

- (IBAction)verificationButtonAction:(id)sender;




@end
