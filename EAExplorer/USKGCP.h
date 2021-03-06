//
//  UTGCPGenerator.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "USKQueue.h"

#define HC_NO_IMPROVEMENT_LIMIT 100

#define IHC_ITERATION

enum UTGCPAlgorithm {
	UTGCPAlgorithmHillClimbing         = 1,
	UTGCPAlgorithmHC                   = UTGCPAlgorithmHillClimbing,
	UTGCPAlgorithmIteratedHillClimbing = 2,
	UTGCPAlgorithmIHC                  = UTGCPAlgorithmIteratedHillClimbing
};
typedef enum _UTGCPAlgorithm UTGCPAlgorithm;

enum _UTGAScaling {
	UTGAScalingNone = 0,
	UTGAScalingLinear,
	UTGAScalingSigma,
	UTGAScalingPower
};
typedef enum _UTGAScaling UTGAScaling;

enum _USKGCPSolverAlgorithm {
    USKGCPAlgorithmHC,
    USKGCPAlgorithmIHC,
    USKGCPAlgorithmES,
    USKGCPAlgorithmESplus,
    USKGCPAlgorithmGA,
    USKGCPAlgorithmHGA
};
typedef enum _USKGCPSolverAlgorithm USKGCPAlgorithm;

/*
 In this GCP class, the colors of vertices are represented by a ColoringRef type,
 which is an array of int. The size of the array is n + 1 and the last element
 has the number of conflicts in that coloring. (n is a.k.a. the order of the graph.)
 */
typedef int *USKGCPColoringRef;

@interface USKGCP : NSObject

@property (nonatomic, readonly) int numberOfColors;
@property (nonatomic, readonly) int numberOfVertices;
@property (nonatomic, readonly) int numberOfEdges;

@property (nonatomic, readonly) int *adjacencyMatrix;

@property (nonatomic, readonly) USKGCPColoringRef currentColoring;
@property (nonatomic, readonly) int currentNumberOfConflicts; // deprecated.=> numberOfConflicts will be made

@property (nonatomic, readonly) int *randomIndexMap;

@property (nonatomic, readonly, getter = isSolved) BOOL solved;

/*
 Each algorithm returns the best-so-far coloring.
 Separately, each algorithm enqueues all the colorings generated in its procedure into a log queue.
 */
@property (nonatomic, readonly) USKQueue *logQueue;

- (BOOL)solving;

/// number of calculation of the number of conflict. it is used in assessment of algorithms.
@property (nonatomic, readonly) int numberOfCalculations;

// @property (readonly) int numberOfTraials;

- (id)initWithNumberOfColors:(int)numColors vertices:(int)numVertices edges:(int)numEdges;
+ (id)GCPWithNumberOfColors:(int)numColors vertices:(int)numVertices edges:(int)numEdges;
- (void)reInitializeColoring;

// Check if there's no conflict
- (BOOL)verify;

- (int)numberOfConflicts;


/*
 @param maxGeneration                     The maximum number of generations to run.
 @param maxGenerationWithoutImprovement   The maximum number of generations wihout improvement.
 @param maxNumberOfCountingConflicts      The maximum number of times to call the function that counts the number of conflicts.
 @param shouldReInitializeCurrentColoring If YES, solve GCP from the re-initialized state(reset and solve). If NO, solve GCP from current coloring state(resume solving).
 
 @return The best-so-far coloring for this GCP.
 */
- (USKGCPColoringRef)coloringsByHillClimbingWithMaxGeneration:(int)maxGeneration
                              maxGenerationWithoutImprovement:(int)maxGenerationWithoutImprovement
                                 maxNumberOfCountingConflicts:(int)maxNumberOfCountingConflicts
                            shouldReInitializeCurrentColoring:(BOOL)shouldReInitializeCurrentColoring;


// Solve GCP by using a pre-tuned algorithm.
//- (USKGCPColoringRef)coloringByAlgorithm:(USKGCPAlgorithm)alg;

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







