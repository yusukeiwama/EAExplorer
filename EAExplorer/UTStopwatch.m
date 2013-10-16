//
//  UTStopwatch.m
//  EAExplorer
//
//  Created by Yusuke Iwama on 10/15/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTStopwatch.h"

@implementation UTStopwatch

@synthesize time;
@synthesize startTime;
@synthesize stopTime;

- (void)start
{
	startTime = [NSDate date];
}

- (void)stop
{
	stopTime = [NSDate date];
}

- (NSTimeInterval)time
{
	return [[NSDate date] timeIntervalSince1970] - [startTime timeIntervalSince1970];
}

@end
