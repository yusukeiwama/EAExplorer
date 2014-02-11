//
//  UTGCPGenerator.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HC_NO_IMPROVEMENT_LIMIT 100

#define IHC_ITERATION

typedef enum UTGCPAlgorithm {
	UTGCPAlgorithmHillClimbing         = 1,
	UTGCPAlgorithmHC                   = UTGCPAlgorithmHillClimbing,
	UTGCPAlgorithmIteratedHillClimbing = 2,
	UTGCPAlgorithmIHC                  = UTGCPAlgorithmIteratedHillClimbing
} UTGCPAlgorithm;

typedef enum UTGAScaling {
	UTGAScalingNone = 0,
	UTGAScalingLinear,
	UTGAScalingSigma,
	UTGAScalingPower
} UTGAScaling;

@interface USKGCP : NSObject

@property (nonatomic, readonly) int numberOfVertices;
@property (nonatomic, readonly) int numberOfEdges;
@property (nonatomic, readonly) int numberOfColors;

@property (nonatomic, readonly) int *adjacencyMatrix;
@property (nonatomic, readonly) int *randomIndexMap;
@property (nonatomic, readonly) int *colorNumbers;

@property (nonatomic, readonly, getter = isSolved) BOOL solved;
- (BOOL)solving;

/// number of calculation of the number of conflict. it is used in assessment of algorithms.
@property (nonatomic, readonly) int numberOfCalculations;

// @property (readonly) int numberOfTraials;

- (id)initWithNumberOfVertices:(int)numberOfVertices
                 numberOfEdges:(int)numberOfEdges
                numberOfColors:(int)numberOfColors;
+ (id)GCPWithNumberOfVertices:(int)numberOfVertices
                numberOfEdges:(int)numberOfEdges
               numberOfColors:(int)numberOfColors;

// Check if there's no conflict
- (BOOL)verify;

- (int)numberOfConflicts;

/* Algorithms ====================================================== */
/** 
 Solve in Hill Climbing method. This method returns history of conflict count for each generation. You can check if GCP was solved by seeing lastObject of it.
 @param noImprovementLimit Number of no-improvement generation to abort.
 @return History of conflict count for each generation. 
 */
- (NSArray *)solveInHCWithNoImprovementLimit:(int)limit;

/** 
 solve in Iterated Hill Climbing method. 
 */
- (NSArray *)solveInIHCWithNoImprovementLimit:(int)limit maxIteration:(int)maxIteration;

/** 
 solve in Evolutionary Computation (a.k.a. EC). returns YES if succeeds 
 */
- (NSArray *)solveInESIncludeParents:(BOOL)includeParents
					 numberOfParents:(int)numberOfParents
					numberOfChildren:(int)numberOfChildren
				  maxNumberOfGenerations:(int)maxNumberOfGenerations;

/**
 Solve in Genetic Algorithm.
 @param populationSize Population size.
 @param numberOfCrossovers Number of crossover. If it is set to 0, uniform crossover technique will be used.
 @param mutationRate Mutation rate.
 @param scaling Scaling technique to be used.
 @param numberOfElites Number of elite to be selected as next generation. If it is greater than the number of gene loci - 1, number of gene loci - 1 will be used.
 @param maxNumberOfGenerations Max number of generations.
 */
- (NSArray *)solveInGAWithPopulationSize:(int)populationSize
					  numberOfCrossovers:(int)numberOfCrossovers // 0 ... uniform
							mutationRate:(double)mutationRate
								 scaling:(UTGAScaling)scaling
						  numberOfElites:(int)numberOfElites
				  maxNumberOfGenerations:(int)maxNumberOfGenerations;

/**
 Solve in Hill Climbing & Genetic Hibrid Algorithm. Fast convergence.
 @param populationSize Population size.
 @param numberOfCrossovers Number of crossover. If it is set to 0, uniform crossover technique will be used.
 @param mutationRate Mutation rate.
 @param scaling Scaling technique to be used.
 @param numberOfElites Number of elite to be selected as next generation. If it is greater than the number of gene loci - 1, number of gene loci - 1 will be used.
 @param noImprovementLimit Number of no-improvement generation to abort.
 @param maxNumberOfGenerations Max number of generations.
 */
- (NSArray *)solveInHGAWithPopulationSize:(int)populationSize
					   numberOfCrossovers:(int)numberOfCrossovers
							 mutationRate:(double)mutationRate
								  scaling:(UTGAScaling)scaling
						   numberOfElites:(int)numberOfElites
					numberOfChildrenForHC:(int)numberOfChildrenForHC
					   noImprovementLimit:(int)limit
				   maxNumberOfGenerations:(int)maxNumberOfGenerations;


- (void)printMatrix;

@end

/*
 実装したいことリスト
 違反辺のハイライト
 平面性判定
 ゲーム化（スコア
 何色使っているか
 */

/*
 実験したいこと
 制約密度による各アルゴリズムの特性を比較プロット
 
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







