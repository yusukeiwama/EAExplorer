//
//  UTGCPSolver.h
//  EAExplorer
//
//  Created by Yusuke Iwama on 10/17/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UTGCP.h"

/// Solver for Graph Coloring Problems
@interface UTGCPSolver : NSObject

+ (void *)HCWithGCP:(UTGCP *)gcp;

@end
