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

#define SEED 821

typedef enum ExperimentMode {
	ExperimentModeNone = 0,
	ExperimentModeHC,
	ExperimentModeIHC,
	ExperimentModeES,
	ExperimentModeESplus,
	ExperimentModeGA
	} ExperimentMode;

@interface UTGCPViewController ()

@end

@implementation UTGCPViewController {
	ExperimentMode experimentMode;
	
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
@synthesize generationLabel;
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

	experimentMode = ExperimentModeNone;
	
	stopwatch = [[UTStopwatch alloc] init];
	timerTimeInterval = 1.0;
	
	if (experimentMode) {
		srand(SEED); // reproducible when experimentMode is on
	} else {
		srand(SEED); // reproducible when experimentMode is on
//		srand((unsigned)time(NULL)); // irreproducible when experimentMode is off
	}
	
	// Set parameters.
	numberOfColors		= 3;
	numberOfVertices	= 30 * numberOfColors;
	numberOfEdges		= 3 * numberOfVertices; // sparse
//	numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4; // dense
	[self updateFields]; // update fields for number of colors, vertices, edges.
	
	/*
	 制約密度d = m/n ... 2-2.5が一番むずかしい
	 d-fグラフを作る！
	 制約密度dによって最適なアルゴリズムが違う。現実問題がどのような制約密度を持つかによってアルゴリズムを見積もることができる。
	 nが10^30までは厳密解法を適用すべき
	 */
	
	generationLabel.text = @"";
	
	CGFloat radialButtonViewRadius = 50;
	NSArray *buttonTitles = @[@"HC", @"IHC", @"ES", @"ES+", @"GA", @"HGA"];
	radialButtonView = [[UTRadialButtonView alloc] initWithFrame:CGRectMake(graphView.center.x - radialButtonViewRadius,
																		   graphView.center.y - radialButtonViewRadius,
																		   2 * radialButtonViewRadius,
																		   2 * radialButtonViewRadius)
														   titles:buttonTitles
														delegate:self];
	[self.view addSubview:radialButtonView];
	[self.view bringSubviewToFront:resultLabel];
	
	plotView.delegate = self;
	
	showVertexNumber = YES;
	
	[self generateNewGCP];
	
	if (experimentMode != ExperimentModeNone) {
		// general experiment settings
		NSArray *plotDataArray;
		NSMutableString *resultCSVString = [NSMutableString string];
		NSUInteger numberOfExperimentsForEachCondition = 10;
		BOOL sparse = YES;
		
		// prepare output file
		NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
		NSString *documentDir = [filePaths objectAtIndex:0];
		NSString *outputPath;
		
		switch (experimentMode) {
			case ExperimentModeHC:
			{
				outputPath = [documentDir stringByAppendingPathComponent:@"resultHC.csv"];
				NSUInteger noImprovementLimit = 100;
				[resultCSVString appendString:@"seed,noImprovementLimit,maxIteration,numberOfVertices,numberOfEdges,experimentNo,success\n"];
			HC:
				for (numberOfVertices = 30; numberOfVertices <= 150; numberOfVertices += 30) { // 5 patterns
					if (sparse) { // sparse
						numberOfEdges	= 3 * numberOfVertices;
					} else { // dense
						numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4;
					}
					[self generateNewGCP];
					for (NSInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
						plotDataArray = [gcp solveInHCWithNoImprovementLimit:noImprovementLimit];
						[self saveConflictHistory:plotDataArray
										 fileName:[NSString stringWithFormat:@"conflictHistoryInHCWithSd%dLmt%luV%dE%dNo%d.txt", SEED, (unsigned long)noImprovementLimit, numberOfVertices, numberOfEdges, i]];
						[resultCSVString appendFormat:@"%d,%lu,%d,%d,%d,%d,%d\n", SEED, (unsigned long)noImprovementLimit, 1, numberOfVertices, numberOfEdges, i, ([(NSNumber *)(plotDataArray.lastObject) unsignedIntegerValue] == 0)];
					}
				}
				if (sparse) {
					sparse = NO;
					goto HC;
				}
				break;
			}
			case ExperimentModeIHC:
			{
				outputPath = [documentDir stringByAppendingPathComponent:@"resultIHC.csv"];
				NSUInteger noImprovementLimit = 100;
				NSUInteger maxIteration = 5;
			IHC:
				for (numberOfVertices = 30; numberOfVertices <= 150; numberOfVertices += 30) { // 5 patterns
					if (sparse) { // sparse
						numberOfEdges	= 3 * numberOfVertices;
					} else { // dense
						numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4;
					}
					[self generateNewGCP];
					for (NSInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
						plotDataArray = [gcp solveInIHCWithNoImprovementLimit:noImprovementLimit maxIteration:maxIteration];
						[self saveConflictHistory:plotDataArray
										 fileName:[NSString stringWithFormat:@"conflictHistoryInIHCWithSd%dLmt%luIt%dV%dE%dNo%d.txt", SEED, (unsigned long)noImprovementLimit, maxIteration, numberOfVertices, numberOfEdges, i]];
						[resultCSVString appendFormat:@"%d,%d,%d,%d,%d,%ld,%d\n", SEED, noImprovementLimit, maxIteration, numberOfVertices, numberOfEdges, (long)i, ([(NSNumber *)(plotDataArray.lastObject) unsignedIntegerValue] == 0)];
					}
				}
				if (sparse) {
					sparse = NO;
					goto IHC;
				}
				break;
			}
			case ExperimentModeES:
			{
				outputPath = [documentDir stringByAppendingPathComponent:@"resultES.csv"];
				[resultCSVString appendString:@"sd,maxgen,prt,chd,in,vtx,edge,no,gen,suc\n"];
			ES:
				for (numberOfVertices = 30; numberOfVertices <= 150; numberOfVertices += 30) { // 5 patterns
					if (sparse) { // sparse
						numberOfEdges	= 3 * numberOfVertices;
					} else { // dense
						numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4;
					}
					[self generateNewGCP];
					
					for (NSUInteger g = 40; g <= 200; g += 40) { // 5 patterns
						//								for (NSUInteger p = 40; p <= 200; p += 40) { // 5 patterns
						NSUInteger p = 80;
						//									for (NSUInteger k = 2; k <= 10; k += 2) { // 5 patterns
						NSUInteger k = 8;
						for (NSInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
							NSUInteger c = p * k;
							plotDataArray = [gcp solveInESIncludeParents:NO numberOfParents:p numberOfChildren:c maxNumberOfGenerations:g];
							[self saveConflictHistory:plotDataArray
											 fileName:[NSString stringWithFormat:@"conflictHistoryInESWithSd%dGen%ldP%ldC%ldIn%dV%ldE%ldNo%ld.txt", SEED, (unsigned long)g, (unsigned long)p, (unsigned long)c, NO, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i]];
							[resultCSVString appendFormat:@"%d,%ld,%ld,%ld,%d,%ld,%ld,%ld,%ld,%ld\n", SEED, (unsigned long)g, (unsigned long)p, (unsigned long)c, NO, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i, (unsigned long)(plotDataArray.count), (unsigned long)([(NSNumber *)((plotDataArray.lastObject)[0]) unsignedIntegerValue] == 0)];
							printf("V%luE%dG%dNo%d\n", (unsigned long)numberOfVertices, numberOfEdges, g, i);
							//									}
							//								}
						}
					}
				}
				if (sparse) {
					sparse = NO;
					goto ES;
				}
				break;
			}
			case ExperimentModeESplus:
			{
				outputPath = [documentDir stringByAppendingPathComponent:@"resultESplus.csv"];
				[resultCSVString appendString:@"sd,maxgen,prt,chd,in,vtx,edge,no,gen,suc\n"];
			ESplus:
				for (numberOfVertices = 30; numberOfVertices <= 150; numberOfVertices += 30) { // 5 patterns
					if (sparse) { // sparse
						numberOfEdges	= 3 * numberOfVertices;
					} else { // dense
						numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4;
					}
					[self generateNewGCP];
					for (NSUInteger g = 40; g <= 200; g += 40) { // 5 patterns
						//								for (NSUInteger p = 40; p <= 200; p += 40) { // 5 patterns
						NSUInteger p = 80;
						//									for (NSUInteger k = 2; k <= 10; k += 2) { // 5 patterns
						NSUInteger k = 8;
						NSUInteger c = p * k;
						for (NSUInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
							plotDataArray = [gcp solveInESIncludeParents:YES numberOfParents:p numberOfChildren:c maxNumberOfGenerations:g];
							[self saveConflictHistory:plotDataArray
											 fileName:[NSString stringWithFormat:@"conflictHistoryInESplusWithSd%dGen%ldP%ldC%ldIn%dV%ldE%ldNo%ld.txt", SEED, (unsigned long)g, (unsigned long)p, (unsigned long)c, YES, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i]];
							[resultCSVString appendFormat:@"%d,%ld,%ld,%ld,%d,%ld,%ld,%ld,%ld,%ld\n", SEED, (unsigned long)g, (unsigned long)p, (unsigned long)c, YES, (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i, (unsigned long)(plotDataArray.count), (unsigned long)([(NSNumber *)((plotDataArray.lastObject)[0]) unsignedIntegerValue] == 0)];
							printf("V%luE%dG%dNo%d\n", (unsigned long)numberOfVertices, numberOfEdges, g, i);
						}
						//									}
						//								}
					}
				}
				if (sparse) {
					sparse = NO;
					goto ESplus;
				}
				break;
			}
			case ExperimentModeGA:
			{
				outputPath = [documentDir stringByAppendingPathComponent:@"resultGA.csv"];
				[resultCSVString appendString:@"sd,pop,crs,mut,sc,elt,mxgen,gen,vtx,edge,no,fit\n"];
			GAEXPERIMENT:
				for (numberOfVertices = 30; numberOfVertices <= 150; numberOfVertices += 30) { // change vertices(5 patterns)
					if (sparse) { // sparse
						numberOfEdges	= 3 * numberOfVertices;
					} else { // dense
						numberOfEdges	= numberOfVertices * (numberOfVertices - 1) / 4;
					}
					[self generateNewGCP];
					NSUInteger p = 100; // best: 100
					NSUInteger c = 0; // uniform crossover
					double m = 0.01; // best: 1%
					UTGAScaling s = UTGAScalingLinear; // best: Linear
					NSUInteger e = p * 0.1; // best: 10%
					NSUInteger mg = 200; // best: 200
					for (NSUInteger i = 0; i < numberOfExperimentsForEachCondition; i++) {
						plotDataArray = [gcp solveInGAWithPopulationSize:p numberOfCrossovers:c mutationRate:m scaling:s numberOfElites:e maxNumberOfGenerations:mg];
						[self saveConflictHistory:plotDataArray
										 fileName:[NSString stringWithFormat:@"GAResultWithSd%dPop%ldCrs%ldMut%1.3fSc%dElt%ldMxGen%ldGen%ldV%ldE%ldNo%ldFit%1.3f.txt", SEED, (unsigned long)p, (unsigned long)c, m, s, (unsigned long)e, (unsigned long)mg, (unsigned long)(plotDataArray.count), (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i,  [(NSNumber *)((plotDataArray.lastObject)[0]) doubleValue]]];
						[resultCSVString appendFormat:@"%d,%ld,%ld,%1.3f,%d,%ld,%ld,%ld,%ld,%ld,%ld,%1.3f\n", SEED, (unsigned long)p, (unsigned long)c, m, s, (unsigned long)e, (unsigned long)mg, (unsigned long)(plotDataArray.count), (unsigned long)numberOfVertices, (unsigned long)numberOfEdges, (unsigned long)i, [(NSNumber *)((plotDataArray.lastObject)[0]) doubleValue]];
					}
				}
				if (sparse) { // change density(2 patterns)
					sparse = NO;
					goto GAEXPERIMENT;
				}
				break;
			}
			default:
			{
				break;
			}
		}
		// save csv file
		NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
		if ([resultCSVString writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
			NSLog(@"%@ is saved", outputPath);
		}

	}
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
		switch (experimentMode) {
			case ExperimentModeGA:
				for (NSUInteger i = 0; i < history.count; i++) {
					[stringRepresentationOfConflictHistory appendFormat:@"%1.3f, %1.3f, %1.3f\n", [history[i][0] doubleValue], [history[i][1] doubleValue], [history[i][2] doubleValue]];
				}
				break;
			default:
				for (NSUInteger i = 0; i < history.count; i++) {
					[stringRepresentationOfConflictHistory appendFormat:@"%lu, %lu, %lu\n", (unsigned long)[history[i][0] unsignedIntegerValue], (unsigned long)[history[i][1] unsignedIntegerValue], (unsigned long)[history[i][2] unsignedIntegerValue]];
				}
				break;
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
		NSLog(@"%@ is saved", name);
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
	NSUInteger noImprovementLimit = 100;	// OPTIMIZED
	
	// for IHC
	NSUInteger maxIteration = 5;	// OPTIMIZED
	
	// for ES
	NSUInteger numberOfParents = 80;	// OPTIMIZED
	NSUInteger numberOfChildren = numberOfParents * 8;	// OPTIMIZED
	NSUInteger maxNumberOfGenerationsES = 160;	// OPTIMIZED
	NSUInteger maxNumberOfGenerationsESplus = 120;	// OPTIMIZED
	
	// for GA
	NSUInteger populationSize = 100;	// OPTIMIZED
	NSUInteger numberOfCrossovers = 0; // if 0, uniform crossover will be used.	// OPTIMIZED
	double mutationRate = 0.01;	// OPTIMIZED
	UTGAScaling scaling = UTGAScalingLinear;	// OPTIMIZED
//	UTGAScaling scaling = UTGAScalingPower;
	double eliteRate = 0.1;	// OPTIMIZED
	NSUInteger numberOfElites = populationSize * eliteRate;
	NSUInteger maxNumberOfGenerationsGA = 300;	// OPTIMIZED
	NSUInteger maxNumberOfGenerationsHGA = 200;	// OPTIMIZED
	
	// for plot
	NSArray *plotData;
	
	// switch algorithms
	switch (i) {
		case 0: // HC ... good at dense, fast
			plotData = [gcp solveInHCWithNoImprovementLimit:noImprovementLimit];
			[plotView plotWithX:nil Y:plotData];
			break;
		case 1: // IHC ... good at dense, fast
			plotData = [gcp solveInIHCWithNoImprovementLimit:noImprovementLimit
												maxIteration:maxIteration];
			[plotView plotWithX:nil Y:plotData];
			break;
		case 2: // ES ... good at sparse, slow
			plotData = [gcp solveInESIncludeParents:NO
									numberOfParents:numberOfParents
								   numberOfChildren:numberOfChildren
							 maxNumberOfGenerations:maxNumberOfGenerationsES];
			[plotView multiplePlotWithX:nil Y:plotData type:UTYTypeUnsingedInteger];
			break;
		case 3: // ES+ ... good at dense, slow
			plotData = [gcp solveInESIncludeParents:YES
									numberOfParents:numberOfParents
								   numberOfChildren:numberOfChildren
							 maxNumberOfGenerations:maxNumberOfGenerationsESplus];
			[plotView multiplePlotWithX:nil Y:plotData type:UTYTypeUnsingedInteger];
			break;
		case 4: // GA
			plotData = [gcp solveInGAWithPopulationSize:populationSize
									 numberOfCrossovers:numberOfCrossovers
										   mutationRate:mutationRate
												scaling:scaling
										 numberOfElites:numberOfElites
								 maxNumberOfGenerations:maxNumberOfGenerationsGA];
			[plotView multiplePlotWithX:nil Y:plotData type:UTYTypeDouble];
//			NSLog(@"%@\n%@", [fitnessHistory[0] description], [fitnessHistory[1] description]);
			break;
		case 5: // HGA
			plotData = [gcp solveInHGAWithPopulationSize:populationSize
									  numberOfCrossovers:numberOfCrossovers
											mutationRate:mutationRate
												 scaling:scaling
										  numberOfElites:numberOfElites
								  maxNumberOfGenerations:maxNumberOfGenerationsHGA];
		default:
			plotData = [NSArray array];
			break;
	}
	generationLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)plotData.count];
	[self updateVertexColors];
	ConflictCountLabel.text = [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)[gcp conflictCount]];
}

@end
