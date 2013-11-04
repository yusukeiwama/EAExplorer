//
//  UTPlotView.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/27/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTPlotView.h"
#import "UTGCPViewController.h"

@implementation UTPlotView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)plotWithX:(NSArray *)X Y:(NSArray *)Y
{	
	UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat lineWidth = 1.0;
	CGContextSetLineWidth(context, lineWidth);
	
//	CGRect axisRect = CGRectMake(20.0, 0.0, self.frame.size.width - 20.0, self.frame.size.height - 20.0);
	
	CGFloat margin = 6.0;
	
	// draw axis
	CGContextMoveToPoint(context, lineWidth / 2.0, self.frame.size.height - margin);
	CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height - margin);
	CGContextMoveToPoint(context, lineWidth / 2.0, self.frame.size.height - margin);
	CGContextAddLineToPoint(context, lineWidth / 2.0, 0.0);
	CGContextStrokePath(context);
	CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
	
	// plot
	CGFloat pitch = (self.frame.size.width - margin) / Y.count;
	NSUInteger maxY = 0;
	for (NSUInteger i = 0; i < Y.count; i++) {
		if (maxY < [Y[i] unsignedIntegerValue]) {
			maxY = [Y[i] unsignedIntegerValue];
		}
	}
	CGContextMoveToPoint(context, 0, lineWidth);
	CGFloat x, y;
	for (NSUInteger i = 1; i < [Y count]; i++) {
		x = pitch * i;
		y = (1 - (double)[Y[i] unsignedIntegerValue] / maxY) * (self.frame.size.height - lineWidth - margin) + lineWidth;
		CGContextAddLineToPoint(context, x, y);
	}
	CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] CGColor]);
	CGContextStrokePath(context);
	
	// plot red point if success
	if ([Y[Y.count - 1] unsignedIntegerValue] == 0) {
		CGFloat r = 4.0;
		CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:1.0 green:0.0 blue:122.0/255.0 alpha:1.0] CGColor]);
		CGContextFillEllipseInRect(context, CGRectMake(pitch * (Y.count - 1) - r,
													  self.frame.size.height - lineWidth - r - margin,
													  2.0 * r,
													  2.0 * r));
	}
	
	self.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}

- (void)multiplePlotWithX:(NSArray *)X Y:(NSArray *)Y
{
	UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat lineWidth = 1.0;
	CGContextSetLineWidth(context, lineWidth);
	
	//	CGRect axisRect = CGRectMake(20.0, 0.0, self.frame.size.width - 20.0, self.frame.size.height - 20.0);
	
	CGFloat margin = 6.0;
	
	// draw axis
	CGContextMoveToPoint(context, lineWidth / 2.0, self.frame.size.height - margin);
	CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height - margin);
	CGContextMoveToPoint(context, lineWidth / 2.0, self.frame.size.height - margin);
	CGContextAddLineToPoint(context, lineWidth / 2.0, 0.0);
	CGContextStrokePath(context);
	CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
	
	// draw lines
	NSUInteger numberOfLines = ((NSArray *)(Y[0])).count;
	NSUInteger maxY = 0;
	for (NSUInteger j = 0; j < numberOfLines; j++) {
		for (NSUInteger i = 0; i < Y.count; i++) {
			if (maxY < [Y[i][j] unsignedIntegerValue]) {
				maxY = [Y[i][j] unsignedIntegerValue];
			}
		}
	}
	for (NSUInteger j = 0; j < numberOfLines; j++) {
		// plot
		CGFloat pitch = (self.frame.size.width - margin) / Y.count;
		CGContextMoveToPoint(context, 0, lineWidth);
		CGFloat x, y;
		for (NSUInteger i = 1; i < [Y count]; i++) {
			x = pitch * i;
			y = (1 - (double)[Y[i][j] unsignedIntegerValue] / maxY) * (self.frame.size.height - lineWidth - margin) + lineWidth;
			CGContextAddLineToPoint(context, x, y);
		}
		CGContextSetStrokeColorWithColor(context, [[UIColor colorWithHue:1.0 / numberOfLines * j saturation:1.0 brightness:1.0 alpha:1.0] CGColor]);
		CGContextStrokePath(context);
		
		// plot red point if success
		if ([Y[Y.count - 1][j] unsignedIntegerValue] == 0) {
			CGFloat r = 4.0;
			CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:1.0 green:0.0 blue:122.0/255.0 alpha:1.0] CGColor]);
			CGContextFillEllipseInRect(context, CGRectMake(pitch * (Y.count - 1) - r,
														   self.frame.size.height - lineWidth - r - margin,
														   2.0 * r,
														   2.0 * r));
		}
	}
	
	self.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}


@end
