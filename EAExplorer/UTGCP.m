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

- (id)initWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c
{
	if (self = [super init]) {
		numberOfVertices	= v;
		numberOfEdges		= e;
		numberOfColors		= c;

		adjacencyMatrix			= calloc(v * v	, sizeof(NSUInteger));
		colorNumbers			= calloc(v		, sizeof(NSUInteger));
		conflictVertexFlags		= calloc(v		, sizeof(NSUInteger));
		
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
	NSUInteger c = 0;
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
			if (adjacencyMatrix[i * numberOfVertices + j]
				&& colorNumbers[i] == colorNumbers[j]) {
				c++;
			}
		}
	}

	return c;
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
		printf("%d ", conflictVertexFlags[i]);
	}
	printf("(FLAG)\n");
}

- (BOOL)solveInHCWithMaxGeneration:(NSUInteger)maxGeneration
{
	// 1. initialize vertex colors in random
	printf("initialized random vertex colors\n");
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		colorNumbers[i] = numberOfColors * (double)rand() / (RAND_MAX + 1.0);
		printf("%d ", colorNumbers[i]);
	}
	printf("\n");

	// 2. end judgement
	NSUInteger conflictCount = [self conflictCount];
	NSUInteger generation = 1;
	while (conflictCount) {
		// if generation exceeds max generation, end HC and return NO(fail to solve)
		if (generation > maxGeneration) {
			printf("fail to solve...\n");
			return NO;
		}
		printf("generation = %4d\t", generation);
		printf("Conflict Count = %d\t", conflictCount);
		
		// 3. pick a vertex
		[self updateConflictIndices];
		NSUInteger conflictVertexCount = 0;
		for (int i = 0; i < numberOfVertices; i++) {
			conflictVertexCount += conflictVertexFlags[i];
		}
		printf("Conflict Vertex Count = %3d\t", conflictVertexCount);
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
		printf("targetIndex = %3d\t", targetIndex);
		
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
			colorNumbers[targetIndex] = oldTargetColorNumber;
		} else {
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
				printf("%d ", colorNumbers[i]);
			}
			printf("\n");
		}
		generation++;
		printf("\n");
	}
	
	printf("SUCCEED!\n");
	return YES;
}

- (BOOL)solveInIHCWithMaxGeneration:(NSUInteger)maxGeneration iteration:(NSUInteger)iteration
{
	for (NSUInteger i = 0; i < iteration; i++) {
		if ([self solveInHCWithMaxGeneration:maxGeneration]) {
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)solving
{
	NSUInteger c = 0;
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		c += colorNumbers[i];
	}
	if (c) { // If color numbers are changed, this problem is being solved.
		if ([self verify]) { // If the problem has already been solved,
			return NO;
		}
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
}

@end
