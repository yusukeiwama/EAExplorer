//
//  UTPlotView.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/27/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum UTYType
{
	UTYTypeUnsingedInteger = 0,
	UTYTypeDouble
} UTYType;

@interface UTPlotView : UIImageView

@property id delegate;

- (void)plotWithX:(NSArray *)X Y:(NSArray *)Y;
- (void)multiplePlotWithX:(NSArray *)X Y:(NSArray *)Y type:(UTYType)type;

@end
