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
@synthesize colorNumbers;

- (id)initWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c
{
	if (self = [super init]) {
//		srand(383); // prime number
		
		numberOfVertices	= v;
		numberOfEdges		= e;
		numberOfColors		= c;

		adjacencyMatrix = calloc(v * v, sizeof(unsigned char));
		colorNumbers = calloc(v, sizeof(NSUInteger));
		
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
	NSUInteger numberOfVerticesInColor = numberOfVertices / numberOfColors;
	NSUInteger numberOfCombinationOfDifferentColors = numberOfColors * (numberOfColors - 1) / 2;
	NSUInteger numberOfCanditates = numberOfVerticesInColor * numberOfVerticesInColor * numberOfCombinationOfDifferentColors;
	NSUInteger *canditates = calloc(numberOfCanditates, sizeof(NSUInteger));
	NSUInteger k;
	for (k = 0; k < numberOfEdges; k++) {
		canditates[k] = 1;
	}

	k = 0;
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		for (NSUInteger j = (i / numberOfVerticesInColor + 1) * numberOfVerticesInColor; j < numberOfVertices; j++) { // never connects the same color
			NSUInteger r = (numberOfCanditates - k) * (double)rand() / (RAND_MAX + 1.0);
			adjacencyMatrix[i * numberOfVertices + j] = canditates[r];
			k++;
			canditates[r] = canditates[numberOfCanditates - k];
		}
	}
}

- (BOOL)verify
{
	for (NSUInteger i = 0; i < numberOfVertices - 1; i++) {
		NSUInteger colorNumber = colorNumbers[i];
		for (NSUInteger j = i + 1; j < numberOfVertices; j++) {
			if (adjacencyMatrix[i * numberOfVertices + j]) {
				if (colorNumbers[j] == colorNumber) {
					return NO;
				}
			}
		}
	}
	return YES;
}

- (BOOL)solving
{
	// If color numbers are changed, this problem is being solved.
	NSUInteger c = 0;
	for (NSUInteger i = 0; i < numberOfVertices; i++) {
		c += colorNumbers[i];
	}
	if (c) {
		if ([self verify]) {
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
			printf("%d ", adjacencyMatrix[i * numberOfVertices + j]);
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
