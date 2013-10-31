//
//  UTGCPViewController.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTGCPViewController.h"
#import "UTInfoViewController.h"
#import "UTStopwatch.h"

#define MAX_NUMBER_OF_VERTICES 300

@interface UTGCPViewController ()

@end

@implementation UTGCPViewController {
	NSMutableArray *vertexButtons;
	BOOL repeatability;
	UTStopwatch *stopwatch;
	NSTimer *timer;
	NSTimeInterval timerTimeInterval;
	UTRadialButtonView *radialButtonView;
}

@synthesize seed;
@synthesize gcp;
@synthesize showVertexNumber;
@synthesize noImprovementLimit, maxIteration;
@synthesize titleLabel;
@synthesize graphView;
@synthesize edgeImageView, circleImageView;
@synthesize plotView;
@synthesize numberOfVerticesField, numberOfEdgesField, numberOfColorsField;
@synthesize resultLabel;
@synthesize indicator;
@synthesize stopwatchLabel;
@synthesize ConflictCountLabel;

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
	timerTimeInterval = 1.0;
	
	repeatability = YES;

	if (repeatability) { // EXPERIMENT MODE
		seed = 101;
		srand(seed); // prime number (for repeatability)
		UILabel *testLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 350, 60, 500, 72)]; // top-right
		testLabel.transform = CGAffineTransformMakeRotation(M_PI_4);
		testLabel.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.8];
		testLabel.text = @"BETA";
		testLabel.font = [UIFont fontWithName:@"Optima-ExtraBlack" size:72];
		testLabel.textColor = [UIColor redColor];
		testLabel.textAlignment = NSTextAlignmentCenter;
		testLabel.adjustsFontSizeToFitWidth = YES;
		[self.view addSubview:testLabel];
		showVertexNumber = YES;
	} else { // RELEASE MODE
		seed = (unsigned)time(NULL);
		srand(seed);
	}

	NSUInteger numberOfColors	= 3;
	NSUInteger numberOfVertices = numberOfColors * 3 * 3 * 3;
	NSUInteger numberOfEdges	= 3 * numberOfVertices; // e = c * v (sparse)
//	NSUInteger numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4; // e = v * (v - 1) / 4 (dense)
	noImprovementLimit	= 100;
	maxIteration	= 10;
	
	numberOfColorsField.text	= [NSString stringWithFormat:@"%lu", (unsigned long)numberOfColors];
	numberOfVerticesField.text	= [NSString stringWithFormat:@"%lu", (unsigned long)numberOfVertices];
	numberOfEdgesField.text		= [NSString stringWithFormat:@"%lu", (unsigned long)numberOfEdges];

	CGFloat radialButtonViewRadius = 50;
//	NSArray *buttonTitles = @[@"HC", @"IHC", @"?", @"?", @"?"];
	NSArray *buttonTitles = @[@"HC", @"IHC"];
	radialButtonView = [[UTRadialButtonView alloc] initWithFrame:CGRectMake(graphView.center.x - radialButtonViewRadius,
																		   graphView.center.y - radialButtonViewRadius,
																		   2 * radialButtonViewRadius,
																		   2 * radialButtonViewRadius)
														   titles:buttonTitles
														delegate:self];
	[self.view addSubview:radialButtonView];
	
	plotView.delegate = self;
	
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
	numberOfVerticesField.text	= [NSString stringWithFormat:@"%lu", (unsigned long)gcp.numberOfVertices];
	numberOfEdgesField.text		= [NSString stringWithFormat:@"%lu", (unsigned long)gcp.numberOfEdges];
	numberOfColorsField.text	= [NSString stringWithFormat:@"%lu", (unsigned long)gcp.numberOfColors];
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
	CGFloat fontSize = r;
	if (gcp.numberOfVertices < 7) { // view boundary check
		r = 2 * M_PI * R / 7.0 / 2.0 / 2.0;
		fontSize = r;
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
		aButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:fontSize];
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

- (void)updateVertexColors
{
	for (int i = 0; i < gcp.numberOfVertices; i++) {
		UIButton *aButton = vertexButtons[i];
		[aButton setBackgroundColor:[self colorWithTapCount:gcp.colorNumbers[i]]];
	}
}

- (void)vertexButtonAction:(id)sender
{
	
	UIButton *button = sender;
	NSInteger i = [vertexButtons indexOfObject:sender];
	gcp.colorNumbers[i] = (gcp.colorNumbers[i] + 1) % gcp.numberOfColors;
	[button setBackgroundColor:[self colorWithTapCount:gcp.colorNumbers[i]]]; // change color with tap count
	ConflictCountLabel.text = [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)[gcp conflictCount]];
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
	// hide keyboard
	if (numberOfColorsField.editing) {
		[self textFieldShouldReturn:numberOfColorsField];
	} else if (numberOfVerticesField.editing) {
		[self textFieldShouldReturn:numberOfVerticesField];
	} else if (numberOfEdgesField.editing) {
		[self textFieldShouldReturn:numberOfEdgesField];
	}

	// alart when solving
	if (gcp.solved || gcp.solving == NO) {
		[indicator startAnimating];
//		if (radialButtonView.selectingMenus) { // hide radial menus when generate button action occurs
//			[radialButtonView hideMenus];
//		}
		[self performSelector:@selector(generateNewGCP) withObject:nil afterDelay:0.01];
	} else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Generate New Graph"
															message:@"The problem you are solving will be discarded."
														   delegate:self
												  cancelButtonTitle:@"Cancel"
												  otherButtonTitles:@"OK", nil];
		[alertView show];
	}
}

- (void)generateNewGCP
{
	gcp = [[UTGCP alloc] initWithNumberOfVertices:[numberOfVerticesField.text integerValue]
									numberOfEdges:[numberOfEdgesField.text integerValue]
								   numberOfColors:[numberOfColorsField.text integerValue]];
	[self updateGraphView];
	ConflictCountLabel.text = [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)[gcp conflictCount]];

	if (timer.isValid) { // invalidate old timer
		[timer invalidate];
	}
	timer = [NSTimer timerWithTimeInterval:timerTimeInterval target:self selector:@selector(updateStopwatchLabel) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[stopwatch start];
	stopwatchLabel.text = @"00:00:00";
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
	BOOL shouldUpdateStopwatchLabel;
	if (gcp.solved == NO) {
		shouldUpdateStopwatchLabel = YES;
	}
	BOOL OK = [gcp verify];

	if (OK) {
		resultLabel.text = @"Correct!";
		resultLabel.textColor = [UIColor greenColor];
		[timer invalidate];
		if (shouldUpdateStopwatchLabel) {
			stopwatchLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)t / 60, (int)t % 60, (int)((t - (int)t) * 100)];
		}
	} else {
		resultLabel.text = @"Wrong...";
		resultLabel.textColor = [UIColor redColor];
		printf("%lu Contlicts\n", (unsigned long)[gcp conflictCount]);
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
			[aButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)i + 1] forState:UIControlStateNormal];
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
		numberOfColorsField.text = [NSString stringWithFormat:@"%lu", (unsigned long)c];
	} else if (c > 8) {
		c = 8;
		
		numberOfColorsField.text = [NSString stringWithFormat:@"%lu", (unsigned long)c];
	}

	// check v
	if (v < c) {
		v = c;
	}
	if (v > MAX_NUMBER_OF_VERTICES) {
		v = MAX_NUMBER_OF_VERTICES;
	}
	v = v / c * c;
	numberOfVerticesField.text = [NSString stringWithFormat:@"%lu", (unsigned long)v];

	// check e
	if (e > (v / c) * (v / c) * c * (c - 1) / 2) {
		e = (v / c) * (v / c) * c * (c - 1) / 2;
		numberOfEdgesField.text = [NSString stringWithFormat:@"%lu", (unsigned long)e];
	}
		
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	UTInfoViewController *destinationViewController = [segue destinationViewController];
	destinationViewController.delegate = self;
}

- (void)radialButtonActionWithIndex:(NSUInteger)i sender:(id)sender
{
	switch (i) {
		case 0:
			[gcp solveInHCWithNoImprovementLimit:noImprovementLimit];
			break;
		case 1:
			[gcp solveInIHCWithNoImprovementLimit:noImprovementLimit maxIteration:maxIteration];
			break;
		default:
			break;
	}
	[self updateVertexColors];
	[plotView plotWithX:nil Y:gcp.conflictCounts];
	ConflictCountLabel.text = [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)[gcp conflictCount]];
}

@end
