//
//  UTGCPGenerator.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTGCP.h"

int order;

int conflictCountCompare(const NSUInteger *a, const NSUInteger *b)
{
	return ((NSUInteger *)(*a))[order] - ((NSUInteger *)(*b))[order];
}

@implementation UTGCP

@synthesize numberOfVertices;
@synthesize numberOfEdges;
@synthesize numberOfColors;
@synthesize adjacencyMatrix;
@synthesize randomIndexMap;
@synthesize colorNumbers;
@synthesize conflictVertexFlags;
@synthesize solved;

// @synthesize numberOfTraials;

- (id)initWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c
{
	if (self = [super init]) {
		numberOfVertices	= v;
		order				= v;
		numberOfEdges		= e;
		numberOfColors		= c;

		adjacencyMatrix			= calloc(v * v	, sizeof(NSUInteger));
		colorNumbers			= calloc(v		, sizeof(NSUInteger));
		conflictVertexFlags		= calloc(v		, sizeof(NSUInteger));
		randomIndexMap			= calloc(v		, sizeof(NSUInteger));
		
		[self generateAdjacencyMatrix];
	}
	
	return self;
}

+ (id)GCPWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c
{
	return [[UTGCP alloc] initWithNumberOfVertices:v numberOfEdges:e numberOfColors:c];
}


- (void)generateAdjacencyMatrix
{
	// prepare required number of ones
	NSUInteger numberOfVerticesInColor = numberOfVertices / numberOfColors;
	NSUInteger numberOfCombinationOfDifferentColors = numberOfColors * (numberOfColors - 1) / 2;
	NSUInteger numberOfCanditates = numberOfVerticesInColor * numberOfVerticesInColor * numberOfCombinationOfDifferentColors;
	NSUInteger *canditates = calloc(numberOfCanditates, sizeof(NSUInteger));
	NSUInteger k; // index of the array of the canditates
	for (k = 0; k < numberOfEdges; k++) {
		canditates[k] = 1;
	}

	// store 0 or 1 into canditate elements
	k = 0;
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		for (NSUInteger j = (i / numberOfVerticesInColor + 1) * numberOfVerticesInColor; j < numberOfVertices; j++) { // never connects the same color
			NSUInteger r = (numberOfCanditates - k) * (double)rand() / (RAND_MAX + 1.0);
			adjacencyMatrix[i * numberOfVertices + j] = canditates[r];
			k++;
			canditates[r] = canditates[numberOfCanditates - k];
		}
	}
	free(canditates);
	
	// random mapping for quiz
	NSUInteger nv = numberOfVertices;
	for (NSUInteger i = 0; i < nv; i++) { // ordered uint array to numberOfVertices - 1
		randomIndexMap[i] = i;
	}
	for (NSUInteger i = 1; i < nv; i++) {
		NSUInteger r = (nv - i) * (double)rand() / (RAND_MAX + 1.0); // 0 <= r < numberOfVerticles - i
		NSUInteger temp = randomIndexMap[r];
		randomIndexMap[r] = randomIndexMap[nv - i];
		randomIndexMap[nv - i] = temp;
	}
}

- (BOOL)verify
{
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		NSUInteger colorNumber = colorNumbers[i];
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
			if (adjacencyMatrix[i * numberOfVertices + j]) { // if edge exists between vi and vj
				if (colorNumbers[j] == colorNumber) { // if violate constraint
					return NO;
				}
			}
		}
	}
	solved = YES;
	return YES;
}

- (NSUInteger)conflictCount
{
	NSUInteger conflictCount = 0;
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
			if (adjacencyMatrix[i * numberOfVertices + j]
				&& colorNumbers[i] == colorNumbers[j]) {
				conflictCount++;
			}
		}
	}

	return conflictCount;
}

- (NSUInteger)conflictCountWithColorNumbers:(NSUInteger *)numbers
{
	NSUInteger conflictCount = 0;
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
			if (adjacencyMatrix[i * numberOfVertices + j]
				&& numbers[i] == numbers[j]) {
				conflictCount++;
			}
		}
	}
	
	return conflictCount;
}

- (void)updateConflictIndices
{
	// clear conflict indices to 0
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
				conflictVertexFlags[i] = 0;
		}
	}
	
	// set conflict indices
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
			if (adjacencyMatrix[i * numberOfVertices + j]
				&& colorNumbers[i] == colorNumbers[j]) {
				// conflict occurs between i and j
				conflictVertexFlags[i] = 1;
				conflictVertexFlags[j] = 1;
			}
		}
	}
}

- (NSArray *)solveInHCWithNoImprovementLimit:(NSUInteger)limit
{
	NSMutableArray *conflictHistory = [NSMutableArray array];
	NSUInteger noImprovementCount = 0;
	
	// Back-up before-state
	NSUInteger beforeConflictCount = [self conflictCount];
	NSUInteger *beforeConflictColorNumbers = calloc(numberOfVertices, sizeof(NSUInteger));
	memcpy(beforeConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));

	// 1. initialize vertex colors in random
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		colorNumbers[i] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
	}

	// 2. end judgement
	NSUInteger conflictCount = [self conflictCount];
	NSUInteger generation = 1;
	[conflictHistory addObject:[NSNumber numberWithUnsignedInteger:conflictCount]];
	while (conflictCount) {
		// if noImprovementCount exceeds its limit, end HC and return 0(fail to solve)
		if (noImprovementCount > limit) { // fail to solve
			if ([self conflictCount] > beforeConflictCount) {
				// If there's no improvement compared with before-state, discard changes and restore before-state.
				memcpy(colorNumbers, beforeConflictColorNumbers, numberOfVertices * sizeof(NSUInteger));
			}
			free(beforeConflictColorNumbers);
			return conflictHistory;
		}
		
		// 3. pick a conflict vertex
		[self updateConflictIndices];
		NSUInteger conflictVertexCount = 0;
		for (int i = 0; i < numberOfVertices; i++) {
			conflictVertexCount += conflictVertexFlags[i];
		}
		NSUInteger targetConflictVertexOrder = conflictVertexCount * (double)rand() / (RAND_MAX + 1.0) + 1;
		NSUInteger targetIndex = 0;
		NSUInteger conflictVertexOrder = 0;
		for (int i = 0; i < numberOfVertices; i++) {
			conflictVertexOrder += conflictVertexFlags[targetIndex];
			if (conflictVertexOrder == targetConflictVertexOrder) {
				break;
			}
			targetIndex++;
		}
		
		// 4. change a vertex color to minimize the conflict count
		NSUInteger minConflictCount = conflictCount;
		NSUInteger unchangedColorConflictCount = conflictCount;
		NSUInteger unchangedTargetColorNumber = colorNumbers[targetIndex];
		NSUInteger minColorNumbers[numberOfColors - 1];
		for (int i = 0; i < numberOfColors - 1; i++) {
			minColorNumbers[i] = -1;
		}
		NSUInteger minColorNumberIndex = 0;
		NSUInteger tempConflictCount;
		NSUInteger tempColorNumber = colorNumbers[targetIndex];
		for (int i = 0; i < numberOfColors - 1; i++) {
			tempColorNumber = (tempColorNumber + 1) % numberOfColors;
			colorNumbers[targetIndex] = tempColorNumber;
			tempConflictCount = [self conflictCount];
			if (tempConflictCount < minConflictCount) {
				minConflictCount = tempConflictCount;
				for (int i = 0; i < numberOfColors - 1; i++) {
					minColorNumbers[i] = -1;
				}
				minColorNumberIndex = 0;
				minColorNumbers[0] = tempColorNumber;
			} else if (tempConflictCount == minConflictCount) {
				minColorNumbers[minColorNumberIndex] = tempColorNumber;
				minColorNumberIndex++;
			}
		}
		NSUInteger minIndexCount = 0;
		if (minConflictCount >= unchangedColorConflictCount) { // no improvement...
			noImprovementCount++;
			// revert to unchanged color
			colorNumbers[targetIndex] = unchangedTargetColorNumber;
		} else { // improved!
			noImprovementCount = 0;
			for (int i = 0; i < numberOfColors - 1; i++) {
				if (minColorNumbers[i] != -1) {
					minIndexCount++;
				}
			}
			NSUInteger newColorNumberIndex = minIndexCount * (double)rand() / (RAND_MAX + 1.0);
			NSUInteger newColorNumber = minColorNumbers[newColorNumberIndex];
			colorNumbers[targetIndex] = newColorNumber;
			conflictCount = [self conflictCount];
		}
		generation++;
		[conflictHistory addObject:[NSNumber numberWithUnsignedInteger:conflictCount]];
	}
	
	free(beforeConflictColorNumbers);
	return conflictHistory;
}

- (NSArray *)solveInIHCWithNoImprovementLimit:(NSUInteger)limit
							maxIteration:(NSUInteger)maxIteration
{
	NSMutableArray *conflictCountHistory = [NSMutableArray array];
	// select minimum conflict answer
	NSUInteger minConflictCount = [self conflictCount];
	// save before-state so that it can revert when there is no improvement
	NSUInteger *minConflictColorNumbers = calloc(numberOfVertices, sizeof(NSUInteger));
	memcpy(minConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));
	// iterate HC
	for (NSUInteger i = 0; i < maxIteration; i++) {
		NSArray *conflictCountHistoryInHC;
		conflictCountHistoryInHC = [self solveInHCWithNoImprovementLimit:limit];
		[conflictCountHistory addObjectsFromArray:conflictCountHistoryInHC];
		if ([[conflictCountHistory lastObject] unsignedIntegerValue] == 0) { // succeeded in HC
			free(minConflictColorNumbers);
			return conflictCountHistory;
		} else { // failed in HC
			if ([self conflictCount] < minConflictCount) { // update minimum conflict count and colors
				minConflictCount = [self conflictCount];
				memcpy(minConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));
			}
		}
	}
	// restore minimum conflict color numbers
	// CAUTION: If there's no improvement, before-calculation states is restored.
	memcpy(colorNumbers, minConflictColorNumbers, numberOfVertices * sizeof(NSUInteger));
	free(minConflictColorNumbers);
	
	return conflictCountHistory;
}

- (NSArray *)solveInESIncludeParents:(BOOL)includeParents
				numberOfParents:(NSUInteger)numberOfParents
			   numberOfChildren:(NSUInteger)numberOfChildren
				  maxNumberOfGenerations:(NSUInteger)maxNumberOfGenerations
{
//	// Back-up before-state
	NSUInteger beforeConflictCount = [self conflictCount];
	NSUInteger *beforeConflictColorNumbers = calloc(numberOfVertices, sizeof(NSUInteger));
	memcpy(beforeConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));
	
	NSMutableArray *conflictHistory = [NSMutableArray array];
	NSUInteger aveConflictCount = 0;
	
	NSUInteger **genes = calloc(numberOfParents + numberOfChildren, sizeof(NSUInteger *));
	for (int i = 0; i < numberOfParents + numberOfChildren; i++) {
		genes[i] = calloc(numberOfVertices + 1, sizeof(NSUInteger)); // last element is conflictCount
	}
	
	// initialize parents with random colors
	for (int i = 0; i < numberOfParents; i++) {
		for (int j = 0; j < numberOfVertices; j++) {
			genes[i][j] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
		}
		genes[i][numberOfVertices] = [self conflictCountWithColorNumbers:genes[i]];
		aveConflictCount += genes[i][numberOfVertices];
	}
	aveConflictCount /= numberOfParents;

	// sort parents
	qsort(genes, numberOfParents, sizeof(NSUInteger *), (int(*)(const void *, const void *))conflictCountCompare);
	NSUInteger tempMinConflictCount = genes[0][numberOfVertices];
	NSArray *conflictInfo = @[[NSNumber numberWithUnsignedInteger:genes[0][numberOfVertices]],
							  [NSNumber numberWithUnsignedInteger:aveConflictCount],
							  [NSNumber numberWithUnsignedInteger:genes[numberOfParents - 1][numberOfVertices]]];
	[conflictHistory addObject:conflictInfo];
	aveConflictCount = 0;

	// evolution start
	NSUInteger numberOfGenerations = 1;
	while (tempMinConflictCount) {
		// end judgement
		// if noImprovementCount exceeds its limit, end ES
		if (numberOfGenerations >= maxNumberOfGenerations) { // fail to solve
			if (tempMinConflictCount > beforeConflictCount) { // not improved...
				// If there's no improvement compared with before-state, restore before-state.
				memcpy(colorNumbers, beforeConflictColorNumbers, numberOfVertices * sizeof(NSUInteger));
			} else { // improved!
				// copy the best parent to colorNumbers
				memcpy(colorNumbers, genes[0], numberOfVertices * sizeof(NSUInteger));
			}
			break;
		}
		
		// generate children
		for (int i = numberOfParents; i < numberOfParents + numberOfChildren; i++) {
			memcpy(genes[i], genes[(int)(numberOfParents * (double)rand() / (RAND_MAX + 1.0))], numberOfVertices * sizeof(NSUInteger)); // select a parent as a child
			NSInteger targetIndex = numberOfVertices * (double)rand() / (RAND_MAX + 1.0); // mutate random index
			NSUInteger tmpColorNumber = genes[i][targetIndex];
			while (tmpColorNumber == genes[i][targetIndex]) { // mutate color at the index into random but different color
				genes[i][targetIndex] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
			}
			genes[i][numberOfVertices] = [self conflictCountWithColorNumbers:genes[i]];
		}

		if (includeParents) {
			// sort children and parents
			qsort(genes, numberOfParents + numberOfChildren, sizeof(NSUInteger *), (int(*)(const void *, const void *))conflictCountCompare);
		} else {
			// sort children
			qsort(genes + numberOfParents, numberOfChildren, sizeof(NSUInteger *), (int(*)(const void *, const void *))conflictCountCompare);
			
			// select good children as parents
			for (int i = 0; i < numberOfParents; i++) {
// /*				memcpy(genes[i], genes[numberOfParents + i], sizeof(NSUInteger) * numberOfVertices + 1); // I couldn't figure out why on earth this doesn't work!! */
				for (int j = 0; j <= numberOfVertices; j++) {
					genes[i][j] = genes[numberOfParents + i][j];
				}
			}
		}
		
		// check if improved
		if (genes[0][numberOfVertices] < tempMinConflictCount) { // improved
			tempMinConflictCount = genes[0][numberOfVertices];
		}
		
		// add conflictInfo into conflictHistory
		aveConflictCount = 0;
		for (int i = 0; i < numberOfParents; i++) {
			aveConflictCount += genes[i][numberOfVertices];
		}
		aveConflictCount /= numberOfParents;
		conflictInfo = @[[NSNumber numberWithUnsignedInteger:genes[0][numberOfVertices]],
						 [NSNumber numberWithUnsignedInteger:aveConflictCount],
						 [NSNumber numberWithUnsignedInteger:genes[numberOfParents - 1][numberOfVertices]]];
		[conflictHistory addObject:conflictInfo];
		
		numberOfGenerations++;
	}
	
	if (tempMinConflictCount == 0) { // success
		memcpy(colorNumbers, genes[0], sizeof(NSUInteger) * numberOfVertices);
	}
	free(beforeConflictColorNumbers);
	for (int i = 0; i < numberOfParents + numberOfChildren; i++) {
		free(genes[i]);
	}
	free(genes);

	return conflictHistory; // success!
}

- (NSArray *)solveInGAWithPopulationSize:(NSUInteger)populationSize
					  numberOfCrossovers:(NSUInteger)numberOfCrossovers
							mutationRate:(double)mutationRate
								 scaling:(UTGAScaling)scaling
						  numberOfElites:(NSUInteger)numberOfElites
				  maxNumberOfGenerations:(NSUInteger)maxNumberOfGenerations
{
	if (numberOfElites > populationSize) {
		return nil;
	}
	NSMutableArray *fitnessHistory = [NSMutableArray array]; // data to return
	NSArray *fitnessInfo;
	NSUInteger numberOfGeneration = 1;
	
	double *parentFitnesses	= calloc(populationSize, sizeof(double));
	NSUInteger **parents	= calloc(populationSize, sizeof(NSUInteger *));
	NSUInteger **children	= calloc(populationSize + numberOfElites, sizeof(NSUInteger *));
	for (NSUInteger i = 0; i < populationSize; i++) {
		parents[i]	= calloc(numberOfVertices + 1, sizeof(NSUInteger)); // last element is conflictCount
	}
	for (NSUInteger i = 0; i < populationSize + numberOfElites; i++) {
		children[i]	= calloc(numberOfVertices + 1, sizeof(NSUInteger)); // last element is conflictCount
	}
	BOOL eliteDidChange = YES;
	
	// 1. Initialize parents with random colors
	for (NSUInteger i = 0; i < populationSize; i++) {
		for (NSUInteger j = 0; j < numberOfVertices; j++) {
			parents[i][j] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
		}
		parents[i][numberOfVertices] = [self conflictCountWithColorNumbers:parents[i]]; // put conflictCount into the last element
	}
	// sort parents by conflictCounts in ascending order.
	qsort(parents, populationSize, sizeof(NSUInteger *), (int(*)(const void *, const void *))conflictCountCompare);
	
	while (1) {
		// 3-a. Evaluate parents (Evaluate before end judgement so that it can save fitnessHistory for each generation)
		// calculate parentFitnesses
		double totalParentFitness = 0.0;
		for (NSUInteger i = 0; i < populationSize; i++) {
			parentFitnesses[i] = 1.0 - ((double)(parents[i][numberOfVertices]) / numberOfEdges);
			totalParentFitness += parentFitnesses[i];
		}
		fitnessInfo = @[[NSNumber numberWithDouble:parentFitnesses[0]],
						[NSNumber numberWithDouble:totalParentFitness / populationSize],
						[NSNumber numberWithDouble:parentFitnesses[populationSize - 1]]];
		[fitnessHistory addObject:fitnessInfo];
		
		// 2-a. End Judgement (SUCCESS)
		if (parents[0][numberOfVertices] == 0) { // no conflict, success
			memcpy(colorNumbers, parents[0], numberOfVertices * sizeof(NSUInteger));
			break;
		}
		// 2-b. End Judgement (FAILURE)
		// check if elite did change
//		eliteDidChange = NO;
//		for (NSUInteger i = 0; i < numberOfVertices; i++) {
//			if (elites[0][i] != children[0][i]) {
//				eliteDidChange = YES;
//				break;
//			}
//		}
		if (numberOfGeneration >= maxNumberOfGenerations
			|| eliteDidChange == NO) {
			// compare old color number and new color number
			if ([self conflictCountWithColorNumbers:parents[0]] < [self conflictCount]) { // improved
				memcpy(colorNumbers, children[0], numberOfVertices * sizeof(NSUInteger));
			}
			break;
		}
		
		// 3-b. Scale Fitnesses
		switch (scaling) {
			case UTGAScalingLinear:
			{
				/*
				 In linear scaling method, you must keep in mind a few things below.
				 - if the best and worst fitness are the same, 0-division arithmetic error will occur.
				 - if all the fitness are the same except one, totalFitness will be 1.0. and corresponding parent will always be selected in selecting section.
				 */
				if (parentFitnesses[0] != parentFitnesses[populationSize - 1]
					&& parentFitnesses[1] != parentFitnesses[populationSize - 1]) { // prevent inf when best == worst
					double a = -parentFitnesses[populationSize - 1] / (parentFitnesses[0] - parentFitnesses[populationSize - 1]);
					double b = 1.0 / (parentFitnesses[0] - parentFitnesses[populationSize - 1]);
					totalParentFitness = 0.0;
					for (NSUInteger i = 0; i < populationSize; i++) {
						parentFitnesses[i] = a + b * parentFitnesses[i];
						totalParentFitness += parentFitnesses[i];
					}
				}
				break;
			}
			case UTGAScalingPower:
			{
				double power = 10.0;
				totalParentFitness = 0.0;
				for (NSUInteger i = 0; i < populationSize; i++) {
					parentFitnesses[i] = pow(power, parentFitnesses[i]);
					totalParentFitness += parentFitnesses[i];
				}
				break;
			}
			default:
				break;
		}
		
		// 5-a. Generate crossover mask
		NSUInteger crossoverMask[numberOfVertices];
		for (NSUInteger i = 0; i < numberOfVertices; i++) { // initialize
			crossoverMask[i] = 0;
		}
		switch (numberOfCrossovers) {
			case 0: // uniform crossover
				for (NSUInteger i = 0; i < numberOfVertices; i++) {
					crossoverMask[i] = 2.0 * (double)rand() / (RAND_MAX + 1.0); // 0 or 1
				}
				break;
			default: // n-time crossover
			{
				NSUInteger crossover = 0;
				while (crossover != numberOfCrossovers) {
					NSUInteger crossoverIndex = (int)((numberOfVertices - 1) * (double)rand() / (RAND_MAX + 1.0) + 1); // prevent 0
					if (crossoverMask[crossoverIndex] == 0) {
						crossoverMask[crossoverIndex] = 1;
						crossover++;
					};
				}
				NSUInteger currentMask = crossoverMask[0];
				for (NSUInteger i = 1; i < numberOfVertices; i++) {
					if (crossoverMask[i] == 1) { // change mask at this point
						if (crossoverMask[i-1] == 0) {
							currentMask = 1;
						} else {
							crossoverMask[i] = 0;
							currentMask = 0;
						}
					} else {
						crossoverMask[i] = currentMask;
					}
				}
				break;
			}
		}
		
		// 4. Selection
		for (NSUInteger i = 0; i < populationSize; i += 2) {
			double winValue1, winValue2;
			NSUInteger winIndex1 = 0;
			NSUInteger winIndex2 = 0;
			// if rouletteValue get greater than winvalue, the index at that time will be target index.
			double rouletteValue = 0.0;
			while (winIndex1 == winIndex2) {
				winValue1 = totalParentFitness * (double)rand() / (RAND_MAX + 1.0);
				winValue2 = totalParentFitness * (double)rand() / (RAND_MAX + 1.0);
				for (NSUInteger j = 0; j < populationSize; j++) {
					rouletteValue += parentFitnesses[j];
					if (rouletteValue > winValue1) {
						winIndex1 = j;
						break;
					}
				}
				rouletteValue = 0.0;
				for (NSUInteger j = 0; j < populationSize; j++) {
					rouletteValue += parentFitnesses[j];
					if (rouletteValue > winValue2) {
						winIndex2 = j;
						break;
					}
				}
			}
			
			// 5-b. Crossover
			for (NSUInteger j = 0; j < numberOfVertices; j++) {
				if (i+1 >= populationSize) {
					if (crossoverMask[i] == 0) {
						children[i][j] = parents[winIndex1][j];
					} else {
						children[i][j] = parents[winIndex2][j];
					}
				} else {
					if (crossoverMask[i] == 0) {
						children[i	][j]	= parents[winIndex1][j];
						children[i+1][j]	= parents[winIndex2][j];
					} else {
						children[i	][j]	= parents[winIndex2][j];
						children[i+1][j]	= parents[winIndex1][j];
					}
				}
			}
		}
		
		// 6. Mutation
		for (NSUInteger i = 0; i < populationSize; i++) {
			for (NSUInteger j = 0; j < numberOfVertices; j++) {
				if (((double)rand() / (RAND_MAX + 1.0)) < mutationRate) {
					// mutate
					NSUInteger newColorNumber = (numberOfColors - 1) * (double)rand() / (RAND_MAX + 1.0);
					if (newColorNumber == children[i][j]) {
						children[i][j] = numberOfColors - 1;
					} else {
						children[i][j] = newColorNumber;
					}
				}
			}
		}
		
		// 7. Swap with elite
		// insert elites
		for (NSUInteger i = 0; i < numberOfElites; i++) {
			memcpy(children[populationSize + i], parents[i], (numberOfVertices + 1) * sizeof(NSUInteger));
		}
		
		// calculate conflict counts of children
		for (NSUInteger i = 0; i < populationSize + numberOfElites; i++) {
			children[i][numberOfVertices] = [self conflictCountWithColorNumbers:children[i]];
		}
		// sort children by conflictCounts in ascending order.
		qsort(children, populationSize + numberOfElites, sizeof(NSUInteger *), (int(*)(const void *, const void *))conflictCountCompare);
		
		// change generation
		for (NSUInteger i = 0; i < populationSize; i++) {
			memcpy(parents[i], children[i], (numberOfVertices + 1) * sizeof(NSUInteger));
		}
		
		numberOfGeneration++;
	}
	
	// free memory
	for (NSUInteger i = 0; i < populationSize; i++) {
		free(parents[i]);
		free(children[i]);
	}
	free(parentFitnesses);
	free(parents);
	free(children);
	
	return fitnessHistory;
}

- (BOOL)solving
{
	NSUInteger editedAmount = 0;
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		editedAmount += colorNumbers[i];
	}
	if (editedAmount) { // If color numbers are changed, this problem is being solved.
//		if ([self verify]) { // If the problem has already been solved, it is regarded as solved
//			return NO;
//		}
		return YES;
	} else {
		return NO;
	}
}

- (void)printMatrix
{
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		for (NSUInteger j = 0; j < numberOfVertices; j++) {
			printf("%lu ", (unsigned long)adjacencyMatrix[i * numberOfVertices + j]);
		}
		printf("\n");
	}
	printf("\n");
}

- (void)dealloc
{
	free(adjacencyMatrix);
	free(colorNumbers);
	free(conflictVertexFlags);
	free(randomIndexMap);
}

@end
