//
//  UTGCPGenerator.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum UTGCPAlgorithm {
	UTGCPAlgorithmHillClimbing = 1,
	UTGCPAlgorithmHC = UTGCPAlgorithmHillClimbing,
	UTGCPAlgorithmIteratedHillClimbing = 2,
	UTGCPAlgorithmIHC = UTGCPAlgorithmIteratedHillClimbing
} UTGCPAlgorithm;

/**
 Graph Coloring Problem generator
 */
@interface UTGCP : NSObject

@property (readonly) NSUInteger numberOfVertices;
@property (readonly) NSUInteger numberOfEdges;
@property (readonly) NSUInteger numberOfColors;

@property (readonly) NSUInteger *adjacencyMatrix;
@property (readonly) NSUInteger *randomIndexMap;
@property (readonly) NSUInteger *colorNumbers;
@property (readonly) NSUInteger *conflictVertexFlags;

@property (readonly) BOOL solved;


/* Graph Coloring Problem Generator ================================ */
/** 
 designated initializer
 
 @param v number of vertices
 @param c number of colors
 */
- (id)initWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c;
+ (id)GCPWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c;

// Check if there's no conflict
- (BOOL)verify;

- (NSUInteger)conflictCount;

/* Algorithms ====================================================== */
// solve in Hill Climbing method
- (BOOL)solveInHCWithMaxGeneration:(NSUInteger)m;

// solve in Iterated Hill Climbing method
- (BOOL)solveInIHCWithMaxGeneration:(NSUInteger)maxGeneration iteration:(NSUInteger)iteration;

- (BOOL)solving;

- (void)printMatrix;

@end


/*
 実装したいことリスト
 平面性判定
 ゲーム化（スコア
 何色使っているか
 */