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

// @property (readonly) NSUInteger numberOfTraials;


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
/** Solve in Hill Climbing method. This method returns history of conflict count for each generation. You can check if GCP was solved by seeing lastObject of it. @return History of conflict count for each generation. */
- (NSArray *)solveInHCWithNoImprovementLimit:(NSUInteger)limit;

// solve in Iterated Hill Climbing method.
- (NSArray *)solveInIHCWithNoImprovementLimit:(NSUInteger)limit maxIteration:(NSUInteger)maxIteration;

// solve in Evolutionary Computation (a.k.a. EC). returns YES if succeeds
- (NSArray *)solveInESIncludeParents:(BOOL)includeParents
					 numberOfParents:(NSUInteger)numberOfParents
					numberOfChildren:(NSUInteger)numberOfChildren
				  maxNumberOfGenerations:(NSUInteger)maxNumberOfGenerations;

- (BOOL)solving;

- (void)printMatrix;

@end

/*
 ToDo
 ・ESを親を含める・含めないがすぐに切り替えられるように変更。具体的には親子をひとつのgene配列に格納する
 ・グラフを早めに実装してアルゴリズムの特性に早く慣れる
 */

/*
 実装したいことリスト
 違反辺のハイライト
 平面性判定
 ゲーム化（スコア
 何色使っているか
 */


/*
 
 GA
 突然変異をベースとせず、交叉をベースとする。突然変異も起こす。
 適応度によって確率的に選択する
 突然変異を起こす確率は、1/エッジ数（＝遺伝子座数）で全部の遺伝子座について行う。目安は1%
 スケーリングも試す（べき乗は指数によって差が広がる部分と狭まる部分がある）
 交叉方法は世代の中では共通にすること。一様交叉のマスクビットの決め方はランダム。
 世代交代後にエリートを無条件にコピーし、最悪の個体を捨てる。
 
 */







