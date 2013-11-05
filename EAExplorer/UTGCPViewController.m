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

#define MAX_NUMBER_OF_COLORS 8
#define MAX_NUMBER_OF_VERTICES 300

@interface UTGCPViewController ()

@end

@implementation UTGCPViewController {
	NSMutableArray *vertexButtons;
	UTStopwatch *stopwatch;
	NSTimer *timer;
	NSTimeInterval timerTimeInterval;
	UTRadialButtonView *radialButtonView;
	
	// Graph information
	NSUInteger numberOfColors;
	NSUInteger numberOfVertices;
	NSUInteger numberOfEdges;
}

@synthesize gcp;
@synthesize showVertexNumber;
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
	
	srand(821);
//	srand((unsigned)time(NULL));
	
	// Set parameters.
	numberOfColors		= 3;
	numberOfVertices	= 30 * numberOfColors;
	numberOfEdges		= 3 * numberOfVertices; // sparse
//	numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4; // dense

	[self updateFields];
	
	CGFloat radialButtonViewRadius = 50;
	NSArray *buttonTitles = @[@"HC", @"IHC", @"ES", @"ES+"];
	radialButtonView = [[UTRadialButtonView alloc] initWithFrame:CGRectMake(graphView.center.x - radialButtonViewRadius,
																		   graphView.center.y - radialButtonViewRadius,
																		   2 * radialButtonViewRadius,
																		   2 * radialButtonViewRadius)
														   titles:buttonTitles
														delegate:self];
	[self.view addSubview:radialButtonView];
	
	plotView.delegate = self;
	
	showVertexNumber = YES;
	
	[self generateNewGCP];
	
//	/*
	// EXPERIMENT PROGRAM STARTS HERE (NOT REQUIRED FOR RELEASE VERSION)
	// general experiment settings
	NSUInteger numberOfExperimentsForEachCondition = 10;
	NSArray *randSeeds = @[@101, @821];
	// for HC
//	NSUInteger noImprovementLimit = 100;
	// for IHC
//	NSUInteger maxIteration = 5;
	// for ES
	NSUInteger numberOfParents = 100;
	
	NSArray *conflictHistory;
	
	NSMutableString *resultCSVString = [NSMutableString string];
	[resultCSVString appendString:@"seed,noImprovementLimit,maxIteration,numberOfVertices,numberOfEdges,experimentNo,success\n"];

	NSMutableString *resultCSVStringES = [NSMutableString string];
	[resultCSVStringES appendString:@"seed,noImprovementLimit,numberOfParents,numberOfChildren,includeParents,numberOfVertices,numberOfEdges,experimentNo,generations,success\n"];
	
	for (NSNumber *aRandSeed in randSeeds) {
		unsigned aSeed = (unsigned)[aRandSeed integerValue];
		srand(aSeed);

		BOOL sparse = YES;
	EXPERIMENT: // do spase case and dense case
		// HC experiment
		for (numberOfVertices = 30; numberOfVertices <= 150; numberOfVertices += 30) { // 5 patterns
			// 2 patterns
			if (sparse) { // sparse
				numberOfEdges	= 3 * numberOfVertices;
			} else { // dense
				numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4;
			}

			[self generateNewGCP];

//			// HC experiment
//			for (NSInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
//				conflictHistory = [gcp solveInHCWithNoImprovementLimit:noImprovementLimit];
//				[self saveConflictHistory:conflictHistory
//								 fileName:[NSString stringWithFormat:@"conflictHistoryInHCWithSd%dLmt%dV%dE%dNo%d.txt", aSeed, noImprovementLimit, numberOfVertices, numberOfEdges, i]];
//				[resultCSVString appendFormat:@"%d,%d,%d,%d,%d,%d,%d\n", aSeed, noImprovementLimit, 1, numberOfVertices, numberOfEdges, i, ([(NSNumber *)(conflictHistory.lastObject) unsignedIntegerValue] == 0)];
//			}

//			// IHC experiment
//			for (NSUInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
//				conflictHistory = [gcp solveInIHCWithNoImprovementLimit:noImprovementLimit maxIteration:maxIteration];
//				[self saveConflictHistory:conflictHistory
//								 fileName:[NSString stringWithFormat:@"conflictHistoryInIHCWithSd%dLmt%dIt%dV%dE%dNo%d.txt", aSeed, noImprovementLimit, maxIteration, numberOfVertices, numberOfEdges, i]];
//				[resultCSVString appendFormat:@"%d,%d,%d,%d,%d,%d,%d\n", aSeed, noImprovementLimit, maxIteration, numberOfVertices, numberOfEdges, i, ([(NSNumber *)(conflictHistory.lastObject) unsignedIntegerValue] == 0)];
//			}
			
			for (NSUInteger l = 10; l <= 100; l += 30) { // 4 patterns
				for (NSUInteger p = 40; p <= 200; p += 40) { // 5 patterns
					for (NSUInteger k = 2; k <= 10; k += 2) { // 5 patterns
						NSUInteger c = p * k;
						
						// ES experiment
						for (NSUInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
							conflictHistory = [gcp solveInESIncludeParents:NO numberOfParents:p numberOfChildren:c noImprovementLimit:l];
							[self saveConflictHistory:conflictHistory
											 fileName:[NSString stringWithFormat:@"conflictHistoryInESWithSd%dLmt%ldP%ldC%ldIn%dV%ldE%ldNo%ld.txt", aSeed, (unsigned long)l, (unsigned long)p, (unsigned long)c, NO, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i]];
							[resultCSVStringES appendFormat:@"%d,%ld,%ld,%ld,%d,%ld,%ld,%ld,%ld,%ld\n", aSeed, (unsigned long)l, (unsigned long)p, (unsigned long)c, NO, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i, (unsigned long)(conflictHistory.count), (unsigned long)([(NSNumber *)((conflictHistory.lastObject)[0]) unsignedIntegerValue] == 0)];
						}
						
						// ES+ experiment
						for (NSUInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
							conflictHistory = [gcp solveInESIncludeParents:YES numberOfParents:p numberOfChildren:c noImprovementLimit:l];
							[self saveConflictHistory:conflictHistory
											 fileName:[NSString stringWithFormat:@"conflictHistoryInESWithSd%dLmt%ldP%ldC%ldIn%dV%ldE%ldNo%ld.txt", aSeed, (unsigned long)l, (unsigned long)p, (unsigned long)c, YES, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i]];
							[resultCSVStringES appendFormat:@"%d,%ld,%ld,%ld,%d,%ld,%ld,%ld,%ld,%ld\n", aSeed, (unsigned long)l, (unsigned long)p, (unsigned long)c, YES, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i, (unsigned long)(conflictHistory.count), (unsigned long)([(NSNumber *)((conflictHistory.lastObject)[0]) unsignedIntegerValue] == 0)];

						}
					}
				}
			}
		
		}
		if (sparse) {
			sparse = NO;
			goto EXPERIMENT;
		}
	}
	NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
	NSString *documentDir = [filePaths objectAtIndex:0];
	NSString *outputPath = [documentDir stringByAppendingPathComponent:@"result.csv"];
	NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
	if ([resultCSVString writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
		NSLog(@"%@ is saved", outputPath);
	}
	// EXPERIMENT PROGRAM ENDS HERE (NOT REQUIRED FOR RELEASE VERSION)
//	 */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveConflictHistory:(NSArray *)history fileName:(NSString *)name
{
	 NSMutableString *stringRepresentationOfConflictHistory = [NSMutableString string];
	if ([history[0] isKindOfClass:[NSArray class]]) {
		for (NSUInteger i = 0; i < history.count; i++) {
			[stringRepresentationOfConflictHistory appendFormat:@"%lu, %lu, %lu\n", (unsigned long)[history[i][0] unsignedIntegerValue], (unsigned long)[history[i][1] unsignedIntegerValue], (unsigned long)[history[i][2] unsignedIntegerValue]];
		}
	} else {
		for (NSUInteger i = 0; i < history.count; i++) {
			[stringRepresentationOfConflictHistory appendFormat:@"%lu\n", (unsigned long)[history[i] unsignedIntegerValue]];
		}
	}
	 NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
	 NSString *documentDir = [filePaths objectAtIndex:0];
	 NSString *outputPath = [documentDir stringByAppendingPathComponent:name];
	 NSURL *outputURL = [NSURL fileURLWithPath:outputPath]; // Example Path: /Users/yusukeiwama/Library/Application Support/iPhone Simulator/7.0.3/Applications/B90652A7-F520-4AB8-A56D-407C99FFE76D/Library/Documentation/G2CC_C3V9E18G100I10S383
	if ([stringRepresentationOfConflictHistory writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
		NSLog(@"%@ is saved", outputPath);
	}
}

- (void)updateFields
{
	numberOfColorsField.text	= [NSString stringWithFormat:@"%lu", (unsigned long)numberOfColors];
	numberOfVerticesField.text	= [NSString stringWithFormat:@"%lu", (unsigned long)numberOfVertices];
	numberOfEdgesField.text		= [NSString stringWithFormat:@"%lu", (unsigned long)numberOfEdges];
}

- (void)updateGraphView
{
	CGFloat lineWidth = 15.0 / gcp.numberOfVertices;
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
	// Generate a new Graph Coloring Problem.
	gcp = [[UTGCP alloc] initWithNumberOfVertices:numberOfVertices numberOfEdges:numberOfEdges numberOfColors:numberOfColors];
	[self updateGraphView];
	ConflictCountLabel.text = [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)[gcp conflictCount]];

	// Set timer for stopwatch.
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
	
	numberOfColors = [numberOfColorsField.text integerValue];		// number of colors
	numberOfVertices = [numberOfVerticesField.text integerValue];	// number of vertices
	numberOfEdges = [numberOfEdgesField.text integerValue];			// number of edges
	
	// check c
	if (numberOfColors < 2) { // 2 <= c <= 8
		numberOfColors = 2;
		numberOfColorsField.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfColors];
	} else if (numberOfColors > MAX_NUMBER_OF_COLORS) {
		numberOfColors = MAX_NUMBER_OF_COLORS;
		
		numberOfColorsField.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfColors];
	}

	// check v
	if (numberOfVertices < numberOfColors) {
		numberOfVertices = numberOfColors;
	}
	if (numberOfVertices > MAX_NUMBER_OF_VERTICES) {
		numberOfVertices = MAX_NUMBER_OF_VERTICES;
	}
	numberOfVertices = numberOfVertices / numberOfColors * numberOfColors;
	numberOfVerticesField.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfVertices];

	// check e
	if (numberOfEdges > (numberOfVertices / numberOfColors) * (numberOfVertices / numberOfColors) * numberOfColors * (numberOfColors - 1) / 2) {
		numberOfEdges = (numberOfVertices / numberOfColors) * (numberOfVertices / numberOfColors) * numberOfColors * (numberOfColors - 1) / 2;
		numberOfEdgesField.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfEdges];
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
	// for HC
	NSUInteger noImprovementLimit = 100;
	NSUInteger maxIteration = 5;
	// for ES
	NSUInteger numberOfParents = 100;
	NSUInteger numberOfChildren = numberOfParents * 10;
	NSUInteger noImprovementLimitES = 50;
	NSUInteger noImprovementLimitESplus = 10;
	// for plot
	NSArray *conflictCountHistory;
	switch (i) {
		case 0: // HC
			conflictCountHistory = [gcp solveInHCWithNoImprovementLimit:noImprovementLimit];
			[plotView plotWithX:nil Y:conflictCountHistory];
			break;
		case 1: // IHC
			conflictCountHistory = [gcp solveInIHCWithNoImprovementLimit:noImprovementLimit maxIteration:maxIteration];
			[plotView plotWithX:nil Y:conflictCountHistory];
			break;
		case 2: // ES
			conflictCountHistory = [gcp solveInESIncludeParents:NO numberOfParents:numberOfParents numberOfChildren:numberOfChildren noImprovementLimit:noImprovementLimitES];
			[plotView multiplePlotWithX:nil Y:conflictCountHistory];
			break;
		case 3: // ES+
			conflictCountHistory = [gcp solveInESIncludeParents:YES numberOfParents:numberOfParents numberOfChildren:numberOfChildren noImprovementLimit:noImprovementLimitESplus];
			[plotView multiplePlotWithX:nil Y:conflictCountHistory];
			break;
		default:
			conflictCountHistory = [NSArray array];
			break;
	}
	[self updateVertexColors];
	ConflictCountLabel.text = [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)[gcp conflictCount]];
}

@end
