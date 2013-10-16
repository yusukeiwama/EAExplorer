//
//  UTGCPViewController.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTGCPViewController.h"
#import "UTGCP.h"
#import "UTInfoViewController.h"
#import "UTStopwatch.h"

#define MAX_NUMBER_OF_VERTICES 100

@interface UTGCPViewController ()

@end

@implementation UTGCPViewController {
	UTGCP *gcp;
	NSMutableArray *vertexButtons;
	BOOL repeatability;
	UTStopwatch *stopwatch;
	NSTimer *timer;
}

@synthesize showVertexNumber;

@synthesize titleLabel;
@synthesize graphView;
@synthesize edgeImageView, circleImageView;
@synthesize numberOfVerticesField, numberOfEdgesField, numberOfColorsField;
@synthesize resultLabel;
@synthesize indicator;
@synthesize stopwatchLabel;

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
	
	stopwatch = [[UTStopwatch alloc] init];
	
	repeatability = NO;

	if (repeatability) {
		srand(383); // prime number (for repeatability)
		UILabel *testLabel = [[UILabel alloc] initWithFrame:CGRectMake(-150, 60, 500, 72)];
		testLabel.transform = CGAffineTransformMakeRotation(- M_PI_4);
		testLabel.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8];
		testLabel.text = @"BETA";
		testLabel.font = [UIFont fontWithName:@"Optima-ExtraBlack" size:72];
		testLabel.textColor = [UIColor redColor];
		testLabel.textAlignment = NSTextAlignmentCenter;
		testLabel.adjustsFontSizeToFitWidth = YES;
		[self.view addSubview:testLabel];
	} else {
		srand((unsigned)time(NULL));
	}

	NSUInteger numberOfColors	= 3;
	NSUInteger numberOfVertices = numberOfColors * 3;
//	NSUInteger numberOfEdges	= 3 * numberOfVertices; // e = c * v (sparse)
	NSUInteger numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4; // e = v * (v - 1) / 4 (dense)
	
	numberOfColorsField.text = [NSString stringWithFormat:@"%d", numberOfColors];
	numberOfVerticesField.text = [NSString stringWithFormat:@"%d", numberOfVertices];
	numberOfEdgesField.text = [NSString stringWithFormat:@"%d", numberOfEdges];

	[self generateNewGCP];
	[self updateGraphView];
	[self updateFields];
	resultLabel.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateFields
{
	numberOfVerticesField.text	= [NSString stringWithFormat:@"%d", gcp.numberOfVertices];
	numberOfEdgesField.text		= [NSString stringWithFormat:@"%d", gcp.numberOfEdges];
	numberOfColorsField.text	= [NSString stringWithFormat:@"%d", gcp.numberOfColors];
}


- (void)updateGraphView
{
	CGFloat lineWidth = 15.0 / gcp.numberOfVertices;
//	if (lineWidth < 0.5) {
//		lineWidth = 0.5;
//	}
	UIColor *lineColor = [UIColor blackColor];
	CGFloat R = graphView.frame.size.height * 2.0 / 5.0; // graph visual radius
	CGFloat r = 2 * M_PI * R / gcp.numberOfVertices / 2.0 / 2.0; // vertex visual radius
	if (gcp.numberOfVertices < 7) { // view boundary check
		r = 2 * M_PI * R / 7.0 / 2.0 / 2.0;
	}
	
	// draw vertices randomly
	for (UIButton *aButton in vertexButtons) {
		[aButton removeFromSuperview];
	}
	if (vertexButtons == nil) {
		vertexButtons = [NSMutableArray array];
	} else {
		[vertexButtons removeAllObjects];
	}
	CGFloat theta = 2.0 * M_PI / gcp.numberOfVertices;
	for (int i = 0; i < gcp.numberOfVertices; i++) {
		UIButton *aButton = [UIButton buttonWithType:UIButtonTypeSystem];
		aButton.frame = CGRectMake(graphView.frame.size.width / 2.0 + R * cos(theta * gcp.randomIndexMap[i] + M_PI_2) - r,
								   graphView.frame.size.height / 2.0 - R * sin(theta * gcp.randomIndexMap[i] + M_PI_2) - r,
								   2 * r, 2 * r);
		[aButton addTarget:self action:@selector(vertexButtonAction:) forControlEvents:UIControlEventTouchDown];
		[aButton setBackgroundColor:[self colorWithTapCount:0]];
		[aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		aButton.titleLabel.adjustsFontSizeToFitWidth = YES;
		aButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:18];
		aButton.layer.cornerRadius = r;
		[graphView addSubview:aButton];
		[vertexButtons addObject:aButton];
	}
	[self updateVertexButtonLabels];
	
	UIGraphicsBeginImageContextWithOptions(graphView.frame.size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetStrokeColorWithColor(context, [lineColor CGColor]);
	
	// draw circle
	for (UIButton *aButton in vertexButtons) {
		CGContextAddEllipseInRect(context, CGRectMake(aButton.frame.origin.x, aButton.frame.origin.y, 2 * r, 2 * r));
	}
	
	CGContextStrokePath(context);
	circleImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	
	// draw edges
	for (int i = 0; i < gcp.numberOfVertices; i++) {
		UIButton *aButton = vertexButtons[i];
		for (int j = 0; j < gcp.numberOfVertices; j++) {
			if (gcp.adjacencyMatrix[i * gcp.numberOfVertices + j]) {
				CGContextMoveToPoint(context, aButton.center.x, aButton.center.y);
				CGContextAddLineToPoint(context, ((UIButton *)(vertexButtons[j])).center.x, ((UIButton *)(vertexButtons[j])).center.y);
			}
		}
	}
	CGContextStrokePath(context);
	edgeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[graphView bringSubviewToFront:circleImageView];
	
	[indicator stopAnimating];
}

- (void)vertexButtonAction:(id)sender
{
	UIButton *button = sender;
	NSInteger i = [vertexButtons indexOfObject:sender];
	gcp.colorNumbers[i] = (gcp.colorNumbers[i] + 1) % gcp.numberOfColors;
	[button setBackgroundColor:[self colorWithTapCount:gcp.colorNumbers[i]]]; // change color with tap count
}

- (UIColor *)colorWithTapCount:(NSUInteger)t
{
	switch (t) {
		case 0: return [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0]; // red
		case 1: return [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1.0]; // green
		case 2: return [UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]; // blue
		case 3: return [UIColor colorWithRed:1.0 green:1.0 blue:0.5 alpha:1.0]; // yellow
		case 4: return [UIColor colorWithRed:0.5 green:1.0 blue:1.0 alpha:1.0]; // cyan
		case 5: return [UIColor colorWithRed:1.0 green:0.5 blue:1.0 alpha:1.0]; // magenta
		case 6: return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]; // white
		case 7: return [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]; // black
		default: return [UIColor clearColor]; // clear color indicates an error
	}
}


- (IBAction)generateButtonAction:(id)sender {
	// alart when solving
	if ([gcp solving]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Generate New Graph"
															message:@"The problem you are solving will be discarded."
														   delegate:self
												  cancelButtonTitle:@"Cancel"
												  otherButtonTitles:@"OK", nil];
		[alertView show];
	} else {
		[indicator startAnimating];
		[self performSelector:@selector(generateNewGCP) withObject:nil afterDelay:0.01];
	}
}

- (void)generateNewGCP
{
	gcp = [[UTGCP alloc] initWithNumberOfVertices:[numberOfVerticesField.text integerValue]
									numberOfEdges:[numberOfEdgesField.text integerValue]
								   numberOfColors:[numberOfColorsField.text integerValue]];
	[self updateGraphView];

	timer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(updateStopwatchLabel) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[stopwatch start];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0: return;
		case 1: [self generateNewGCP];
		default: return;
	}
}

- (IBAction)verificationButtonAction:(id)sender {
	NSTimeInterval t = stopwatch.time;
	BOOL OK = [gcp verify];
	if (OK) {
		resultLabel.text = @"OK";
		resultLabel.textColor = [UIColor greenColor];
		[timer invalidate];
		stopwatchLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)t / 60, (int)t % 60, (int)((t - (int)t) * 100)];
	} else {
		resultLabel.text = @"NG";
		resultLabel.textColor = [UIColor redColor];
	}
	resultLabel.hidden = NO;
	[UIView animateWithDuration:0.2
						  delay:2.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^{
						 if (OK) {
							 resultLabel.transform = CGAffineTransformMakeScale(2.0, 2.0);
						 } else {
							 resultLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
						 }
						 resultLabel.alpha = 0.0;
					 }
					 completion:^(BOOL finished){
						 resultLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
						 resultLabel.hidden = YES;
						 resultLabel.alpha = 1.0;
					 }];
}

- (void)updateVertexButtonLabels
{
	for (NSUInteger i = 0; i < [vertexButtons count]; i++) {
		NSUInteger r = 0;
		for (r = 0; r < gcp.numberOfVertices; r++) {
			if (i == gcp.randomIndexMap[r]) {
				break;
			}
		}
		UIButton *aButton = vertexButtons[r];
		if (showVertexNumber) {
			[aButton setTitle:[NSString stringWithFormat:@"%d", i] forState:UIControlStateNormal];
		} else {
			[aButton setTitle:@"" forState:UIControlStateNormal];
		}
	}
}

- (void)updateStopwatchLabel
{
	NSTimeInterval t = stopwatch.time;
	stopwatchLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)t / 60, (int)t % 60, (int)((t - (int)t) * 100)];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//	[UIView animateWithDuration:0.3 animations:^{
		self.view.frame = CGRectMake(self.view.frame.origin.x,
									 self.view.frame.origin.y - 264,
									 self.view.frame.size.width,
									 self.view.frame.size.height);
//	}];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[UIView animateWithDuration:0.3 animations:^{
		self.view.frame = CGRectMake(self.view.frame.origin.x,
									 self.view.frame.origin.y + 264,
									 self.view.frame.size.width,
									 self.view.frame.size.height);
	}];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	
	NSUInteger c = [numberOfColorsField.text integerValue];		// number of colors
	NSUInteger v = [numberOfVerticesField.text integerValue];	// number of vertices
	NSUInteger e = [numberOfEdgesField.text integerValue];		// number of edges
	
	// check c
	if (c < 2) { // 2 <= c <= 8
		c = 2;
		numberOfColorsField.text = [NSString stringWithFormat:@"%d", c];
	} else if (c > 8) {
		c = 8;
		numberOfColorsField.text = [NSString stringWithFormat:@"%d", c];
	}

	// check v
	if (v < c) {
		v = c;
	}
	if (v > MAX_NUMBER_OF_VERTICES) {
		v = MAX_NUMBER_OF_VERTICES;
	}
	v = v / c * c;
	numberOfVerticesField.text = [NSString stringWithFormat:@"%d", v];

	// check e
	if (e > (v / c) * (v / c) * c * (c - 1) / 2) {
		e = (v / c) * (v / c) * c * (c - 1) / 2;
		numberOfEdgesField.text = [NSString stringWithFormat:@"%d", e];
	}
		
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	UTInfoViewController *destinationViewController = [segue destinationViewController];
	destinationViewController.delegate = self;
}

@end
