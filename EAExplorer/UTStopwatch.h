//
//  UTStopwatch.h
//  EAExplorer
//
//  Created by Yusuke Iwama on 10/15/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UTStopwatch : NSObject

@property (readonly) NSTimeInterval time;
@property (readonly) NSDate *startTime;
@property (readonly) NSDate *stopTime;

- (void)start;

- (void)stop;


@end
