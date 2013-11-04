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
	NSUInteger *geneA = (NSUInteger *)(*a);
	NSUInteger *geneB = (NSUInteger *)(*b);
	
	return geneA[order] - geneB[order];
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
	NSUInteger v = numberOfVertices;
	for (NSUInteger i = 0; i < v; i++) { // ordered uint array to numberOfVertices - 1
		randomIndexMap[i] = i;
	}
	for (NSUInteger i = 1; i < v; i++) {
		NSUInteger r = (v - i) * (double)rand() / (RAND_MAX + 1.0); // 0 <= r < numberOfVerticles - i
		NSUInteger temp = randomIndexMap[r];
		randomIndexMap[r] = randomIndexMap[v - i];
		randomIndexMap[v - i] = temp;
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
				  noImprovementLimit:(NSUInteger)limit
{
	// Back-up before-state
	NSUInteger beforeConflictCount = [self conflictCount];
	NSUInteger *beforeConflictColorNumbers = calloc(numberOfVertices, sizeof(NSUInteger));
	memcpy(beforeConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));
	
	NSMutableArray *conflictHistory = [NSMutableArray array];
	NSUInteger aveConflictCount = 0;
	
	// alloc genes
	NSUInteger **genes = calloc(numberOfParents + numberOfChildren, sizeof(NSUInteger *));
	
	// initialize parents with random colors
	for (int i = 0; i < numberOfParents; i++) {
		genes[i] = calloc(numberOfVertices + 1, sizeof(NSUInteger)); // parents[i] is array of colorNumbers
		for (int j = 0; j < numberOfVertices; j++) {
			genes[i][j] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
		}
		NSUInteger tmpConflictCount = [self conflictCountWithColorNumbers:genes[i]];
		genes[i][numberOfVertices] = tmpConflictCount;
		aveConflictCount += tmpConflictCount;
	}
	aveConflictCount /= numberOfParents;

	// sort parents
	qsort(genes, numberOfParents, sizeof(NSUInteger *), (int(*)(const void *, const void *))conflictCountCompare);
	NSUInteger tempMinConflictCount = [self conflictCountWithColorNumbers:genes[0]];
	NSArray *conflictInfo = @[[NSNumber numberWithUnsignedInteger:genes[0][numberOfVertices]],
							  [NSNumber numberWithUnsignedInteger:aveConflictCount],
							  [NSNumber numberWithUnsignedInteger:genes[numberOfParents - 1][numberOfVertices]]];
	[conflictHistory addObject:conflictInfo];
	aveConflictCount = 0;
	
	// initialize children
	for (int i = numberOfParents; i < numberOfParents + numberOfChildren; i++) {
		genes[i] = calloc(numberOfVertices + 1, sizeof(NSUInteger)); // children[i] is array of colorNumbers
	}

	NSUInteger noImprovementCount = 0;
	while (tempMinConflictCount) {
		// end judgement
		// if noImprovementCount exceeds its limit, end ES
		if (noImprovementCount > limit) { // fail to solve
			if ([self conflictCountWithColorNumbers:genes[0]] > beforeConflictCount) { // not improved...
				// If there's no improvement compared with before-state, discard changes and restore before-state.
				memcpy(colorNumbers, beforeConflictColorNumbers, numberOfVertices * sizeof(NSUInteger));
			} else { // improved!
				// copy the best parent to colorNumbers
				memcpy(colorNumbers, genes[0], numberOfVertices * sizeof(NSUInteger));
			}
			free(beforeConflictColorNumbers);
			return conflictHistory;
		}
		
		// generate children
		for (int i = numberOfParents; i < numberOfParents + numberOfChildren; i++) {
			memcpy(genes[i], genes[(int)(numberOfParents * (double)rand() / (RAND_MAX + 1.0))], numberOfVertices * sizeof(NSUInteger)); // select a parent as a child
			NSInteger targetIndex = numberOfVertices * (double)rand() / (RAND_MAX + 1.0); // mutate rondom index
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
				memcpy(genes[i], genes[numberOfParents + i], sizeof(NSUInteger) * numberOfVertices + 1);
			}
		}
		
		// check if improved
		if (genes[0][numberOfVertices] < tempMinConflictCount) { // improved
			tempMinConflictCount = genes[0][numberOfVertices];
			noImprovementCount = 0;
		} else { // not improved
			noImprovementCount++;
		}

				
		// add conflictInfo into conflictHistory
		aveConflictCount = 0;
		for (int i = 0; i < numberOfParents; i++) {
			aveConflictCount += genes[i][numberOfVertices];
			printf("%d ", genes[i][numberOfVertices]);
		}
		printf("\n\n");
		aveConflictCount /= numberOfParents;
		conflictInfo = @[[NSNumber numberWithUnsignedInteger:genes[0][numberOfVertices]],
						 [NSNumber numberWithUnsignedInteger:aveConflictCount],
						 [NSNumber numberWithUnsignedInteger:genes[numberOfParents - 1][numberOfVertices]]];
		[conflictHistory addObject:conflictInfo];
	}
	
	memcpy(colorNumbers, genes[0], sizeof(NSUInteger) * numberOfVertices);
	free(beforeConflictColorNumbers);
	return conflictHistory; // success!
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
