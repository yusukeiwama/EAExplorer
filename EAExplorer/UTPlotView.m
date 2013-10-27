//
//  UTPlotView.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/27/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTPlotView.h"

@implementation UTPlotView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)plotWithX:(NSMutableArray *)X Y:(NSMutableArray *)Y
{
	UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat lineWidth = 1.0;
	CGContextSetLineWidth(context, lineWidth);
	
	// draw axis
	CGContextMoveToPoint(context, 0.0, self.frame.size.height);
	CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height);
	CGContextMoveToPoint(context, 0.0, self.frame.size.height);
	CGContextAddLineToPoint(context, 0.0, 0.0);
	CGContextStrokePath(context);
	CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
	
	// plot
	CGFloat pitch = self.frame.size.width / Y.count;
	NSUInteger maxY = [Y[0] unsignedIntegerValue];
	CGContextMoveToPoint(context, 0, lineWidth);
	CGFloat x, y;
	for (NSUInteger i = 1; i < [Y count]; i++) {
		x = pitch * i;
		y = (1 - (double)[Y[i] unsignedIntegerValue] / maxY) * (self.frame.size.height - lineWidth) + lineWidth;
		CGContextAddLineToPoint(context, x, y);
	}
	CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] CGColor]);
	CGContextStrokePath(context);
	self.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
}


@end
