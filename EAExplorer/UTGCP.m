//
//  UTGCPGenerator.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "UTGCP.h"

@implementation UTGCP

@synthesize numberOfVertices;
@synthesize numberOfEdges;
@synthesize numberOfColors;
@synthesize adjacencyMatrix;
@synthesize randomIndexMap;
@synthesize colorNumbers;
@synthesize conflictVertexFlags;
@synthesize solved;

@synthesize conflictCounts;

// @synthesize numberOfTraials;

- (id)initWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c
{
	if (self = [super init]) {
		numberOfVertices	= v;
		numberOfEdges		= e;
		numberOfColors		= c;

		adjacencyMatrix			= calloc(v * v	, sizeof(NSUInteger));
		colorNumbers			= calloc(v		, sizeof(NSUInteger));
		conflictVertexFlags		= calloc(v		, sizeof(NSUInteger));
		
		conflictCounts = [NSMutableArray array];
		
		[self generateNaively];
		[self printMatrix];
	}
	
	return self;
}

+ (id)GCPWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c
{
	return [[UTGCP alloc] initWithNumberOfVertices:v numberOfEdges:e numberOfColors:c];
}


- (void)generateNaively
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
	
	// random mapping
	NSUInteger v = numberOfVertices;
	NSUInteger *tempMatrix = calloc(v * v, sizeof(NSUInteger));
	memcpy(tempMatrix, adjacencyMatrix, sizeof(NSUInteger) * v * v);
	randomIndexMap = calloc(v, sizeof(NSUInteger));
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

- (void)updateConflictIndices
{
	printf("conflictIndices: \n");
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
	// print conflict indices
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		printf("%lu ", (unsigned long)conflictVertexFlags[i]);
	}
	printf("(FLAG)\n");
}

- (NSUInteger)solveInHCWithNoImprovementLimit:(NSUInteger)limit
{
	[conflictCounts removeAllObjects];
	
	NSUInteger noImprovementCount = 0;
	NSUInteger minConflictCount = [self conflictCount];
	NSUInteger *minConflictColorNumbers = calloc(numberOfVertices, sizeof(NSUInteger));
	memcpy(minConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));

	// 1. initialize vertex colors in random
	printf("initialized random vertex colors\n");
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		colorNumbers[i] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
	}

	// 2. end judgement
	NSUInteger conflictCount = [self conflictCount];
	NSUInteger generation = 1;
	[conflictCounts addObject:[NSNumber numberWithUnsignedInteger:conflictCount]];
	while (conflictCount) {
		// if noImprovementCount exceeds its limit, end HC and return 0(fail to solve)
		if (noImprovementCount >= limit) {
			printf("fail to solve...\n");
			if ([self conflictCount] > minConflictCount) {
				// restore minimum conflict color numbers
				// CAUTION: If there's no improvement, before-calculation states is restored.
				memcpy(colorNumbers, minConflictColorNumbers, numberOfVertices * sizeof(NSUInteger));
				free(minConflictColorNumbers);
			}
			return 0;
		}
		printf("generation = %4lu\t", (unsigned long)generation);
		printf("Conflict Count = %lu\t", (unsigned long)conflictCount);
		
		// 3. pick a vertex
		[self updateConflictIndices];
		NSUInteger conflictVertexCount = 0;
		for (int i = 0; i < numberOfVertices; i++) {
			conflictVertexCount += conflictVertexFlags[i];
		}
		printf("Conflict Vertex Count = %3lu\t", (unsigned long)conflictVertexCount);
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
		printf("targetIndex = %3lu\t", (unsigned long)targetIndex);
		
		// 4. change vertex color to minimize the conflict count
		NSUInteger minConflictCount = conflictCount;\
		NSUInteger oldConflictCount = conflictCount;
		NSUInteger oldTargetColorNumber = colorNumbers[targetIndex];
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
			if (tempConflictCount <= minConflictCount) {
				minConflictCount = tempConflictCount;
				minColorNumbers[minColorNumberIndex] = tempColorNumber;
				minColorNumberIndex++;
			}
		}
		NSUInteger minIndexCount = 0;
		if (minConflictCount == oldConflictCount) {
			// if there is no improvement, revert color
			colorNumbers[targetIndex] = oldTargetColorNumber;
			noImprovementCount++;
		} else {
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
			printf("new vertex colors\n");
			for (int i = 0; i < numberOfVertices; i++) {
				printf("%lu ", (unsigned long)colorNumbers[i]);
			}
			printf("\n");
		}
		generation++;
		printf("\n");
		printf("conflictCount = %lu\n", (unsigned long)[[conflictCounts lastObject] unsignedIntegerValue]);
		[conflictCounts addObject:[NSNumber numberWithUnsignedInteger:conflictCount]];
	}
	
	printf("SUCCEED!\n");
	return generation;
}

- (NSUInteger)solveInIHCWithNoImprovementLimit:(NSUInteger)limit maxIteration:(NSUInteger)maxIteration
{
	[conflictCounts removeAllObjects];
	NSMutableArray *tempConflictCounts = [NSMutableArray array];
	
	NSUInteger generation	= 0;
	// select minimum conflict answer
	NSUInteger minConflictCount = [self conflictCount];
	NSUInteger *minConflictColorNumbers = calloc(numberOfVertices, sizeof(NSUInteger));
	memcpy(minConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));
	for (NSUInteger i = 0; i < maxIteration; i++) {
		NSUInteger tempGeneration = [self solveInHCWithNoImprovementLimit:limit];
		if (tempGeneration) { // non zero tempGeneration means success in solving in HC
			generation += tempGeneration;
			free(minConflictColorNumbers);
			for (NSUInteger i = 0; i < [conflictCounts count]; i++) { // save conflict counts
				[tempConflictCounts addObject:conflictCounts[i]];
			}
			[conflictCounts removeAllObjects];
			conflictCounts = tempConflictCounts;
			return generation;
		}
		if ([self conflictCount] < minConflictCount) { // update minimum conflict count and colors
			minConflictCount = [self conflictCount];
			memcpy(minConflictColorNumbers, colorNumbers, numberOfVertices * sizeof(NSUInteger));
		}
		for (NSUInteger i = 0; i < [conflictCounts count]; i++) { // save conflict counts
			[tempConflictCounts addObject:conflictCounts[i]];
		}
		generation += limit;
	}
	// restore minimum conflict color numbers
	// CAUTION: If there's no improvement, before-calculation states is restored.
	memcpy(colorNumbers, minConflictColorNumbers, numberOfVertices * sizeof(NSUInteger));

	free(minConflictColorNumbers);

	[conflictCounts removeAllObjects];
	conflictCounts = tempConflictCounts;
	
	return 0;
}

- (NSUInteger)solveInESIncludeParents:(BOOL)includeParents
					  numberOfParents:(NSUInteger)numberOfParents
					 numberOfChildren:(NSUInteger)numberOfChildren
						 mutationRate:(double)mutationRate
{
	// initialize parents
	NSUInteger **parents = calloc(numberOfParents, sizeof(NSUInteger));
	for (NSUInteger i = 0; i < numberOfParents; i++) {
		parents[i] = calloc(numberOfVertices, sizeof(NSUInteger)); // parent[i] is array of colorNumbers
		for (NSUInteger j = 0; j < numberOfVertices; j++) {
			parents[i][j] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
		}
	}
	// initialize children
	NSUInteger **children = calloc(numberOfChildren, sizeof(NSUInteger));
	for (NSUInteger i = 0; i < numberOfChildren; i++) {
		children[i] = calloc(numberOfVertices, sizeof(NSUInteger)); // children[i] is array of colorNumbers
	}
	for (NSUInteger i = 0; i < numberOfChildren; i++) {
		memcpy(children[i], parents[(int)(numberOfParents * (double)rand() / (RAND_MAX + 1.0))], numberOfVertices * sizeof(NSUInteger)); // select a parent as a child
		children[i][(int)(numberOfVertices * (double)rand() / (RAND_MAX + 1.0))] = numberOfColors * (double)rand() / (RAND_MAX + 1.0); // mutate random index into random color
	}
	
	
	return 0;
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
}

@end
