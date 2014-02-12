//
//  UTGCPGenerator.m
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import "USKGCP.h"

static int indexForConflicts; // = n. Used for C function.

int countConflicts(USKGCPColoringRef c, int n, int *A)
{
    int numConflicts = 0;
    
    for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
            // Count the number of pairs that are adjacent and the same color.
            if (A[i * n + j] == 1 && c[i] == c[j]) {
                numConflicts++;
            }
        }
    }
    
    return numConflicts;
};

int compareConflicts(const void *a, const void *b)
{
	return (*((USKGCPColoringRef *)a))[indexForConflicts] - (*((USKGCPColoringRef *)b))[indexForConflicts];
}


@implementation USKGCP {
    int *_conflictVertexFlags;
	int *_crossoverMask;
}

/*
 CAUTION:
 c, n, m, A
 provides direct access to the instance variables in a single character.
 It's not safe for future reuse in which KVC is required.
 But now, to keep convenience for maintainance, direct access is being used.
 */
// Fundamental Information for this COP(Combinatorial Optimization Problem).
@synthesize numberOfColors   = c; // The number of possible values that variables can be.
@synthesize numberOfVertices = n; // The number of variables this problem has.(a.k.a. order in graph theory.)
@synthesize numberOfEdges    = m; // The number of constraints in this problem. (a.k.a. size in graph theory.)

// Generated Information for this GCP.
@synthesize adjacencyMatrix  = A;

@synthesize solved;
@synthesize numberOfCalculations;

// @synthesize numberOfTraials;

- (id)initWithNumberOfColors:(int)numColors vertices:(int)numVertices edges:(int)numEdges
{
	if (self = [super init]) {
        c = numColors;
		n = numVertices;
        m = numEdges;
        
		indexForConflicts = n;

		A = calloc(n * n, sizeof(int)); // Adjacency matrix.
		
        _currentColoring     = calloc(n + 1, sizeof(int));
		_conflictVertexFlags = calloc(n,     sizeof(int));
		_randomIndexMap		 = calloc(n,     sizeof(int));
		_crossoverMask	     = calloc(n,     sizeof(int));
		
		[self generateAdjacencyMatrix];
        [self generateRandomIndexMap];
        [self reInitializeColoring];
	}
	
	return self;
}

+ (id)GCPWithNumberOfColors:(int)numColors vertices:(int)numVertices edges:(int)numEdges
{
	return [[USKGCP alloc] initWithNumberOfColors:numColors vertices:numVertices edges:numEdges];
}

- (void)reInitializeColoring
{
    bzero(_currentColoring, n * sizeof(int));
    _currentColoring[n] = countConflicts(_currentColoring, n, A);
}

- (void)generateAdjacencyMatrix
{
    /*
     Compute the number of elements that can possibly be 1.
     The number of 1s corresponds to m(a.k.a. the number of edges) because 1 in
     adjacency matrix means that there is an edge there.
     To get solvable GCP, fill only elements in the cell in which elements are
     different color combinations.

     Adjacency matrix example for a solvable GCP:
       R G B
     R| |1|1|
     G| | |1|
     B| | | |
     */
	int verticesPerColor = n / c;
	int numDifferentColorCombinations = c * (c - 1) / 2;
	int numCandidates = verticesPerColor * verticesPerColor * numDifferentColorCombinations;

    /*
     Prepare m 1s. And therefore, (numberOfCandidates - m) of zeros.

     candidates = {1, ... ,     1, 0, ... ,                      0}
     (index:       0, ... , m - 1, m, ... , numberOfCandidates - 1}
     */
    int candidates[numCandidates];
    bzero(candidates, numCandidates * sizeof(int));
	int k;
	for (k = 0; k < m; k++) {
		candidates[k] = 1;
	}

	// Fill zero or one in candidate elements in A(a.k.a. adjacency matrix.)
	k = 0;
	for (int i = 0; i < n; i++) {
		for (int j = (i / verticesPerColor + 1) * verticesPerColor; j < n; j++) { // never connects the same colors
            // Get a value in the candidates in index range from 0 to ((numberOfCandidates - 1) - k).
			int r = (numCandidates - k) * (double)rand() / (RAND_MAX + 1.0);
			A[i * n + j] = candidates[r];
			k++;
            // Overwrite used value in the range with the unused value out of the range.
			candidates[r] = candidates[numCandidates - k];
		}
	}
}

- (void)generateRandomIndexMap
{
    // Prepare ordered index map.
    int orderedIndexMap[n];
	for (int i = 0; i < n; i++) {
        orderedIndexMap[i] = i;
    }
    
    // Generate random index map by choosing a value from ordered index map randomly.
    for (int i = 0; i < n; i++) {
        int r = (n - i) * (double)rand() / (RAND_MAX + 1.0);
        _randomIndexMap[i] = orderedIndexMap[r];
        // Overwrite used value in the range with the unused value out of the range.
        orderedIndexMap[r] = orderedIndexMap[(n -1) - i];
    }
}

- (BOOL)verify
{
	for (int i = 0; i < n - 1; i++) {
		int colorNumber = _currentColoring[i];
		for (int j = i + 1; j < n; j++) {
			if (A[i * n + j] && _currentColoring[j] == colorNumber) {
                return NO;
			}
		}
	}
	solved = YES;
	return YES;
}


- (int)numberOfConflicts
{
	int numConflicts = 0;
    
	for (int i = 0; i < n - 1; i++) {
		for (int j = i + 1; j < n; j++) {
			if (A[i * n + j] && _currentColoring[i] == _currentColoring[j]) {
				numConflicts++;
			}
		}
	}
	
	numberOfCalculations++;
	return numConflicts;
}

- (int)numberOfConflictsWithColorNumbers:(int *)colorNo
{
	int numConflicts = 0;
    
	for (int i = 0; i < n - 1; i++) {
		for (int j = i + 1; j < n; j++) {
			if (A[i * n + j] && colorNo[i] == colorNo[j]) {
				numConflicts++;
			}
		}
	}
	
	numberOfCalculations++;
	return numConflicts;
}

- (void)updateConflictIndices
{
	// clear conflict indices to 0
	for (int i = 0; i < n - 1; i++) {
		for (int j = i + 1; j < n; j++) {
            _conflictVertexFlags[i] = 0;
		}
	}
	
	// set conflict indices
	for (int i = 0; i < n - 1; i++) {
		for (int j = i + 1; j < n; j++) {
			if (A[i * n + j]
				&& _currentColoring[i] == _currentColoring[j]) {
				// conflict occurs between i and j
				_conflictVertexFlags[i] = 1;
				_conflictVertexFlags[j] = 1;
			}
		}
	}
}

- (void)updateConflictVertexFlagsWithColorNumbers:(int *)numbers
{
	// clear conflict indices to 0
	for (int i = 0; i < n - 1; i++) {
		_conflictVertexFlags[i] = 0;
	}
	
	// set conflict indices
	for (int i = 0; i < n - 1; i++) {
		for (int j = i + 1; j < n; j++) {
			if (A[i * n + j]	// if vertex i and j are adjacent
				&& numbers[i] == numbers[j]) {	// and their colors are the same
				// conflict occurs between i and j
				_conflictVertexFlags[i] = 1;
				_conflictVertexFlags[j] = 1;
			}
		}
	}
}

- (NSArray *)solveInHCWithNoImprovementLimit:(int)limit
{
	int newColorNumbers[n];
	int newConflictCount;
	int beforeConflictCount = [self numberOfConflicts]; // conflict count in before state.
	NSMutableArray *conflictHistory = [NSMutableArray array];
	int noImprovementCount = 0;
	int generation = 1;
	
	// 1. initialize vertex colors in random
	for (int i = 0; i < n; i++) {
		newColorNumbers[i] = c * (double)rand() / (RAND_MAX + 1.0);
	}
	
	// 2. end judgement
	newConflictCount = [self numberOfConflictsWithColorNumbers:newColorNumbers];
	[conflictHistory addObject:@(newConflictCount)];
	while (newConflictCount) {
		// if noImprovementCount exceeds its limit, end HC.
		if (noImprovementCount > limit) { // fail to solve
			if (newConflictCount < beforeConflictCount) {
				memcpy(_currentColoring, newColorNumbers, n * sizeof(int));
			}
			return conflictHistory;
		}
		
		// 3. pick a conflict vertex
		[self updateConflictVertexFlagsWithColorNumbers:newColorNumbers];
		int numberOfConflictVertices = 0;
		for (int i = 0; i < n; i++) {
			numberOfConflictVertices += _conflictVertexFlags[i]; // count the number of conflict vetices.
		}
		int targetConflictVertexOrder = numberOfConflictVertices * (double)rand() / (RAND_MAX + 1.0) + 1;
		int targetConflictVertexIndex = 0;
		int conflictVertexOrder = 0;
		for (int i = 0; i < n; i++) {
			conflictVertexOrder += _conflictVertexFlags[i];
			if (conflictVertexOrder == targetConflictVertexOrder) { // did find target conflict vertex
				break;
			}
			targetConflictVertexIndex++;
		}
		
		// 4. change a vertex color to minimize the conflict count
		int minConflictCount = newConflictCount;
		int unchangedColorConflictCount = newConflictCount;
		int unchangedTargetColorNumber = newColorNumbers[targetConflictVertexIndex];
		int canditateColorNumbers[c - 1]; 
		for (int i = 0; i < c - 1; i++) {
			canditateColorNumbers[i] = -1; // initialize canditate color numbers with -1 (none)
		}
		int canditateColorNumberIndex = 0;
		int tempConflictCount;
		int canditateColorNumber = newColorNumbers[targetConflictVertexIndex]; // initialize canditate color number with current color number
		for (int i = 0; i < c - 1; i++) {
			canditateColorNumber = (canditateColorNumber + 1) % c; // next canditate color number
			newColorNumbers[targetConflictVertexIndex] = canditateColorNumber;
			tempConflictCount = [self numberOfConflictsWithColorNumbers:newColorNumbers];
			if (tempConflictCount < minConflictCount) {
				minConflictCount = tempConflictCount;
				for (int i = 0; i < c - 1; i++) {
					canditateColorNumbers[i] = -1; // reset canditate color numbers
				}
				canditateColorNumberIndex = 0;
				canditateColorNumbers[0] = canditateColorNumber; // set candiate color number
			} else if (tempConflictCount == minConflictCount) {
				canditateColorNumbers[canditateColorNumberIndex] = canditateColorNumber; // add new canditate color number
				canditateColorNumberIndex++;
			}
		}
		int numberOfCanditateColorNumbers = 0;
		if (minConflictCount >= unchangedColorConflictCount) { // no improvement...
			noImprovementCount++;
			// revert to unchanged color
			newColorNumbers[targetConflictVertexIndex] = unchangedTargetColorNumber;
		} else { // improved!
			noImprovementCount = 0;
			for (int i = 0; i < c - 1; i++) {
				if (canditateColorNumbers[i] != -1) {
					numberOfCanditateColorNumbers++; // count the number of canditate color numbers
				}
			}
			int newColorNumberIndex = numberOfCanditateColorNumbers * (double)rand() / (RAND_MAX + 1.0);
			int newColorNumber = canditateColorNumbers[newColorNumberIndex];
			newColorNumbers[targetConflictVertexIndex] = newColorNumber;
			newConflictCount = minConflictCount;
		}
		generation++;
		[conflictHistory addObject:@(newConflictCount)];
	}
	
	memcpy(_currentColoring, newColorNumbers, n * sizeof(int));
	return conflictHistory;
}

- (NSArray *)solveInIHCWithNoImprovementLimit:(int)limit
							maxIteration:(int)maxIteration
{
	NSMutableArray *conflictCountHistory = [NSMutableArray array];

	for (int i = 0; i < maxIteration; i++) {
		NSArray *conflictCountHistoryInHC;
		conflictCountHistoryInHC = [self solveInHCWithNoImprovementLimit:limit];
		[conflictCountHistory addObjectsFromArray:conflictCountHistoryInHC];
		if ([[conflictCountHistory lastObject] unsignedIntegerValue] == 0) { // succeeded in HC
			return conflictCountHistory;
		}
	}
	
	return conflictCountHistory;
}

- (NSArray *)solveInESIncludeParents:(BOOL)includeParents
				numberOfParents:(int)numberOfParents
			   numberOfChildren:(int)numberOfChildren
				  maxNumberOfGenerations:(int)maxNumberOfGenerations
{
//	// Back-up before-state
	int beforeConflictCount = [self numberOfConflicts];
	int *beforeConflictColorNumbers = calloc(n, sizeof(int));
	memcpy(beforeConflictColorNumbers, _currentColoring, n * sizeof(int));
	
	NSMutableArray *conflictHistory = [NSMutableArray array];
	int aveConflictCount = 0;
	
	int **genes = calloc(numberOfParents + numberOfChildren, sizeof(int *));
	for (int i = 0; i < numberOfParents + numberOfChildren; i++) {
		genes[i] = calloc(n + 1, sizeof(int)); // last element is conflictCount
	}
	
	// initialize parents with random colors
	for (int i = 0; i < numberOfParents; i++) {
		for (int j = 0; j < n; j++) {
			genes[i][j] = c * (double)rand() / (RAND_MAX + 1.0);
		}
		genes[i][n] = [self numberOfConflictsWithColorNumbers:genes[i]];
		aveConflictCount += genes[i][n];
	}
	aveConflictCount /= numberOfParents;

	// sort parents
	qsort(genes, numberOfParents, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
	int tempMinConflictCount = genes[0][n];
	NSArray *conflictInfo = @[@(genes[0][n]),
							  @(aveConflictCount),
							  @(genes[numberOfParents - 1][n])];
	[conflictHistory addObject:conflictInfo];
	aveConflictCount = 0;

	// evolution start
	int numberOfGenerations = 1;
	while (tempMinConflictCount) {
		// end judgement
		// if noImprovementCount exceeds its limit, end ES
		if (numberOfGenerations >= maxNumberOfGenerations) { // fail to solve
			if (tempMinConflictCount > beforeConflictCount) { // not improved...
				// If there's no improvement compared with before-state, restore before-state.
				memcpy(_currentColoring, beforeConflictColorNumbers, n * sizeof(int));
			} else { // improved!
				// copy the best parent to colorNumbers
				memcpy(_currentColoring, genes[0], n * sizeof(int));
			}
			break;
		}
		
		// generate children
		for (int i = numberOfParents; i < numberOfParents + numberOfChildren; i++) {
			memcpy(genes[i], genes[(int)(numberOfParents * (double)rand() / (RAND_MAX + 1.0))], n * sizeof(int)); // select a parent as a child
			int targetIndex = n * (double)rand() / (RAND_MAX + 1.0); // mutate random index
			int tmpColorNumber = genes[i][targetIndex];
			while (tmpColorNumber == genes[i][targetIndex]) { // mutate color at the index into random but different color
				genes[i][targetIndex] = c * (double)rand() / (RAND_MAX + 1.0);
			}
			genes[i][n] = [self numberOfConflictsWithColorNumbers:genes[i]];
		}

		if (includeParents) {
			// sort children and parents
			qsort(genes, numberOfParents + numberOfChildren, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
		} else {
			// sort children
			qsort(genes + numberOfParents, numberOfChildren, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
			
			// select good children as parents
			for (int i = 0; i < numberOfParents; i++) {
// /*				memcpy(genes[i], genes[numberOfParents + i], sizeof(int) * _n + 1); // I couldn't figure out why on earth this doesn't work!! */
				for (int j = 0; j <= n; j++) {
					genes[i][j] = genes[numberOfParents + i][j];
				}
			}
		}
		
		// check if improved
		if (genes[0][n] < tempMinConflictCount) { // improved
			tempMinConflictCount = genes[0][n];
		}
		
		// add conflictInfo into conflictHistory
		aveConflictCount = 0;
		for (int i = 0; i < numberOfParents; i++) {
			aveConflictCount += genes[i][n];
		}
		aveConflictCount /= numberOfParents;
		conflictInfo = @[@(genes[0][n]),
						 @(aveConflictCount),
						 @(genes[numberOfParents - 1][n])];
		[conflictHistory addObject:conflictInfo];
		
		numberOfGenerations++;
	}
	
	if (tempMinConflictCount == 0) { // success
		memcpy(_currentColoring, genes[0], sizeof(int) * n);
	}
	free(beforeConflictColorNumbers);
	for (int i = 0; i < numberOfParents + numberOfChildren; i++) {
		free(genes[i]);
	}
	free(genes);

	return conflictHistory; // success!
}

- (NSArray *)solveInGAWithPopulationSize:(int)populationSize
					  numberOfCrossovers:(int)numberOfCrossovers
							mutationRate:(double)mutationRate
								 scaling:(UTGAScaling)scaling
						  numberOfElites:(int)numberOfElites
				  maxNumberOfGenerations:(int)maxNumberOfGenerations
{
	if (numberOfElites > populationSize) {
		return nil;
	}
	NSMutableArray *fitnessHistory = [NSMutableArray array]; // data to return
	NSArray *fitnessInfo;
	int numberOfGeneration = 1;
	
	double *parentFitnesses	= calloc(populationSize, sizeof(double));
	int **parents	= calloc(populationSize, sizeof(int *));
	int **children	= calloc(populationSize, sizeof(int *));
	for (int i = 0; i < populationSize; i++) {
		parents[i]	= calloc(n + 1, sizeof(int)); // last element is conflictCount
	}
	for (int i = 0; i < populationSize; i++) {
		children[i]	= calloc(n + 1, sizeof(int)); // last element is conflictCount
	}
	
	// 1. Initialize parents with random colors
	for (int i = 0; i < populationSize; i++) {
		for (int j = 0; j < n; j++) {
			parents[i][j] = c * (double)rand() / (RAND_MAX + 1.0);
		}
		parents[i][n] = [self numberOfConflictsWithColorNumbers:parents[i]]; // put conflictCount into the last element
	}
	// sort parents by conflictCounts in ascending order.
	qsort(parents, populationSize, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
	
	while (1) {
		// 3-a. Evaluate parents (Evaluate before end judgement so that it can save fitnessHistory for each generation)
		// calculate parentFitnesses
		double totalParentFitness = 0.0;
		for (int i = 0; i < populationSize; i++) {
			parentFitnesses[i] = 1.0 - ((double)(parents[i][n]) / m);
			totalParentFitness += parentFitnesses[i];
		}
		fitnessInfo = @[@(parentFitnesses[0]),
						@(totalParentFitness / populationSize),
						@(parentFitnesses[populationSize - 1])];
		[fitnessHistory addObject:fitnessInfo];
		
		// 2-a. End Judgement (SUCCESS)
		if (parents[0][n] == 0) { // no conflict, success
			memcpy(_currentColoring, parents[0], n * sizeof(int));
			break;
		}
		// 2-b. End Judgement (FAILURE)
		if (numberOfGeneration >= maxNumberOfGenerations) {
			// compare old color number and new color number
			if ([self numberOfConflictsWithColorNumbers:parents[0]] < [self numberOfConflicts]) { // improved
				memcpy(_currentColoring, children[0], n * sizeof(int));
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
					for (int i = 0; i < populationSize; i++) {
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
				for (int i = 0; i < populationSize; i++) {
					parentFitnesses[i] = pow(power, parentFitnesses[i]);
					totalParentFitness += parentFitnesses[i];
				}
				break;
			}
			default:
				break;
		}
		
		// 5-a. Generate crossover mask
		for (int i = 0; i < n; i++) { // initialize
			_crossoverMask[i] = 0;
		}
		switch (numberOfCrossovers) {
			case 0: // uniform crossover
				for (int i = 0; i < n; i++) {
					_crossoverMask[i] = 2.0 * (double)rand() / (RAND_MAX + 1.0); // 0 or 1
				}
				break;
			default: // n-time crossover
			{
				int crossover = 0;
				while (crossover != numberOfCrossovers) {
					int crossoverIndex = (int)((n - 1) * (double)rand() / (RAND_MAX + 1.0) + 1); // prevent 0
					if (_crossoverMask[crossoverIndex] == 0) {
						_crossoverMask[crossoverIndex] = 1;
						crossover++;
					};
				}
				int currentMask = _crossoverMask[0];
				for (int i = 1; i < n; i++) {
					if (_crossoverMask[i] == 1) { // change mask at this point
						if (_crossoverMask[i-1] == 0) {
							currentMask = 1;
						} else {
							_crossoverMask[i] = 0;
							currentMask = 0;
						}
					} else {
						_crossoverMask[i] = currentMask;
					}
				}
				break;
			}
		}
		
		// 4. Selection
		for (int i = numberOfElites; i < populationSize; i += 2) {
			double winValue1, winValue2;
			int winIndex1 = 0;
			int winIndex2 = 0;
			// if rouletteValue get greater than winvalue, the index at that time will be target index.
			double rouletteValue = 0.0;
			while (winIndex1 == winIndex2) {
				winValue1 = totalParentFitness * (double)rand() / (RAND_MAX + 1.0);
				winValue2 = totalParentFitness * (double)rand() / (RAND_MAX + 1.0);
				for (int j = 0; j < populationSize; j++) {
					rouletteValue += parentFitnesses[j];
					if (rouletteValue > winValue1) {
						winIndex1 = j;
						break;
					}
				}
				rouletteValue = 0.0;
				for (int j = 0; j < populationSize; j++) {
					rouletteValue += parentFitnesses[j];
					if (rouletteValue > winValue2) {
						winIndex2 = j;
						break;
					}
				}
			}
			
			// 5-b. Crossover
			for (int j = 0; j < n; j++) {
				if (i+1 >= populationSize) {
					if (_crossoverMask[i] == 0) {
						children[i][j] = parents[winIndex1][j];
					} else {
						children[i][j] = parents[winIndex2][j];
					}
				} else {
					if (_crossoverMask[i] == 0) {
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
		for (int i = numberOfElites; i < populationSize; i++) {
			for (int j = 0; j < n; j++) {
				if (((double)rand() / (RAND_MAX + 1.0)) < mutationRate) {
					// mutate
					int colorIncrement = (c - 1) * (double)rand() / (RAND_MAX + 1.0);
					children[i][j] = (children[i][j] + colorIncrement) % c; // change to different color
				}
			}
		}
		
		// 7. Insert elites
		for (int i = 0; i < numberOfElites; i++) {
			memcpy(children[i], parents[i], (n + 1) * sizeof(int));
		}
		
		// calculate conflict counts of children
		for (int i = numberOfElites; i < populationSize; i++) {
			children[i][n] = [self numberOfConflictsWithColorNumbers:children[i]];
		}
		
		// sort children by conflictCounts in ascending order.
		qsort(children, populationSize, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
		
		// change generation
		for (int i = 0; i < populationSize; i++) {
			memcpy(parents[i], children[i], (n + 1) * sizeof(int));
		}
		
		numberOfGeneration++;
	}
	
	// free memory
	for (int i = 0; i < populationSize; i++) {
		free(parents[i]);
		free(children[i]);
	}
	free(parentFitnesses);
	free(parents);
	free(children);
	
	return fitnessHistory;
}

- (NSArray *)solveInHGAWithPopulationSize:(int)populationSize
					   numberOfCrossovers:(int)numberOfCrossovers
							 mutationRate:(double)mutationRate
								  scaling:(UTGAScaling)scaling
						   numberOfElites:(int)numberOfElites
					numberOfChildrenForHC:(int)numberOfChildrenForHC
					   noImprovementLimit:(int)limit
				   maxNumberOfGenerations:(int)maxNumberOfGenerations
{
	if (numberOfElites > populationSize) {
		return nil;
	}
	NSMutableArray *fitnessHistory = [NSMutableArray array]; // data to return
	NSArray *fitnessInfo;
	int numberOfGeneration = 1;
	
	double *parentFitnesses	= calloc(populationSize, sizeof(double));
	int **parents	= calloc(populationSize, sizeof(int *));
	int **children	= calloc(populationSize, sizeof(int *));
	for (int i = 0; i < populationSize; i++) {
		parents[i]	= calloc(n + 1, sizeof(int)); // last element is conflictCount
	}
	for (int i = 0; i < populationSize; i++) {
		children[i]	= calloc(n + 1, sizeof(int)); // last element is conflictCount
	}
	BOOL eliteDidChange = YES;
	
	// 1. Initialize parents with random colors
	for (int i = 0; i < populationSize; i++) {
		for (int j = 0; j < n; j++) {
			parents[i][j] = c * (double)rand() / (RAND_MAX + 1.0);
		}
		parents[i][n] = [self numberOfConflictsWithColorNumbers:parents[i]]; // put conflictCount into the last element
	}
	// sort parents by conflictCounts in ascending order.
	qsort(parents, populationSize, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
	
	while (1) {
		// 3-a. Evaluate parents (Evaluate before end judgement so that it can save fitnessHistory for each generation)
		// calculate parentFitnesses
		double totalParentFitness = 0.0;
		for (int i = 0; i < populationSize; i++) {
			parentFitnesses[i] = 1.0 - ((double)(parents[i][n]) / m);
			totalParentFitness += parentFitnesses[i];
		}
		fitnessInfo = @[@(parentFitnesses[0]),
						@(totalParentFitness / populationSize),
						@(parentFitnesses[populationSize - 1])];
		[fitnessHistory addObject:fitnessInfo];
		
		// 2-a. End Judgement (SUCCESS)
		if (parents[0][n] == 0) { // no conflict, success
			memcpy(_currentColoring, parents[0], n * sizeof(int));
			break;
		}

		if (numberOfGeneration >= maxNumberOfGenerations
			|| eliteDidChange == NO) {
			// compare old color number and new color number
			if ([self numberOfConflictsWithColorNumbers:parents[0]] < [self numberOfConflicts]) { // improved
				memcpy(_currentColoring, children[0], n * sizeof(int));
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
					for (int i = 0; i < populationSize; i++) {
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
				for (int i = 0; i < populationSize; i++) {
					parentFitnesses[i] = pow(power, parentFitnesses[i]);
					totalParentFitness += parentFitnesses[i];
				}
				break;
			}
			default:
				break;
		}
		
		// 5-a. Generate crossover mask
		for (int i = 0; i < n; i++) { // initialize
			_crossoverMask[i] = 0;
		}
		switch (numberOfCrossovers) {
			case 0: // uniform crossover
				for (int i = 0; i < n; i++) {
					_crossoverMask[i] = 2.0 * (double)rand() / (RAND_MAX + 1.0); // 0 or 1
				}
				break;
			default: // n-time crossover
			{
				int crossover = 0;
				while (crossover != numberOfCrossovers) {
					int crossoverIndex = (int)((n - 1) * (double)rand() / (RAND_MAX + 1.0) + 1); // prevent 0
					if (_crossoverMask[crossoverIndex] == 0) {
						_crossoverMask[crossoverIndex] = 1;
						crossover++;
					};
				}
				int currentMask = _crossoverMask[0];
				for (int i = 1; i < n; i++) {
					if (_crossoverMask[i] == 1) { // change mask at this point
						if (_crossoverMask[i-1] == 0) {
							currentMask = 1;
						} else {
							_crossoverMask[i] = 0;
							currentMask = 0;
						}
					} else {
						_crossoverMask[i] = currentMask;
					}
				}
				break;
			}
		}
		
		// 4. Selection
		for (int i = numberOfElites; i < populationSize; i += 2) {
			double winValue1, winValue2;
			int winIndex1 = 0;
			int winIndex2 = 0;
			// if rouletteValue get greater than winvalue, the index at that time will be target index.
			double rouletteValue = 0.0;
			while (winIndex1 == winIndex2) {
				winValue1 = totalParentFitness * (double)rand() / (RAND_MAX + 1.0);
				winValue2 = totalParentFitness * (double)rand() / (RAND_MAX + 1.0);
				for (int j = 0; j < populationSize; j++) {
					rouletteValue += parentFitnesses[j];
					if (rouletteValue > winValue1) {
						winIndex1 = j;
						break;
					}
				}
				rouletteValue = 0.0;
				for (int j = 0; j < populationSize; j++) {
					rouletteValue += parentFitnesses[j];
					if (rouletteValue > winValue2) {
						winIndex2 = j;
						break;
					}
				}
			}
			
			// 5-b. Crossover
			for (int j = 0; j < n; j++) {
				if (i+1 >= populationSize) {
					if (_crossoverMask[i] == 0) {
						children[i][j] = parents[winIndex1][j];
					} else {
						children[i][j] = parents[winIndex2][j];
					}
				} else {
					if (_crossoverMask[i] == 0) {
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
		for (int i = numberOfElites; i < populationSize; i++) {
			for (int j = 0; j < n; j++) {
				if (((double)rand() / (RAND_MAX + 1.0)) < mutationRate) {
					// mutate
					int colorIncrement = (c - 1) * (double)rand() / (RAND_MAX + 1.0);
					children[i][j] = (children[i][j] + colorIncrement) % c; // change to different color
				}
			}
		}
		
		// 7. Insert elites
		for (int i = 0; i < numberOfElites; i++) {
			memcpy(children[i], parents[i], (n + 1) * sizeof(int));
		}
		
		// calculate conflict counts of children
		for (int i = numberOfElites; i < populationSize; i++) {
			children[i][n] = [self numberOfConflictsWithColorNumbers:children[i]];
		}
		// sort children by conflictCounts in ascending order.
		qsort(children, populationSize, sizeof(int *), (int(*)(const void *, const void *))compareConflicts);
		
		// 8. Apply Hill Climb method
		for (int i = 0; i < numberOfChildrenForHC; i++) {
			[self applyHCWithNoImprovementLimit:limit colorNumbers:children[i]];
			if (children[i][n] == 0) {
				memcpy(_currentColoring, children[i], n * sizeof(int));
				
				fitnessInfo = @[@1.0,
								@([fitnessInfo[1] doubleValue]),
								@([fitnessInfo[2] doubleValue])];
				[fitnessHistory addObject:fitnessInfo];
				
				for (int i = 0; i < populationSize; i++) {
					free(parents[i]);
					free(children[i]);
				}
				free(parentFitnesses);
				free(parents);
				free(children);
				
				return fitnessHistory;
			}
		}
		
		// change generation
		for (int i = 0; i < populationSize; i++) {
			memcpy(parents[i], children[i], (n + 1) * sizeof(int));
		}
		
		numberOfGeneration++;
	}
	
	// free memory
	for (int i = 0; i < populationSize; i++) {
		free(parents[i]);
		free(children[i]);
	}
	free(parentFitnesses);
	free(parents);
	free(children);
	
	return fitnessHistory;
}

- (NSArray *)applyHCWithNoImprovementLimit:(int)limit
						 colorNumbers:(int *)numbers

{
	int newColorNumbers[n + 1]; // the last element is new number of conflicts.
//	NSMutableArray *conflictHistory = [NSMutableArray array];
	int noImprovementCount = 0;
	int generation = 1;
	
	// 1. initialize newColorNumbers with numbers
	for (int i = 0; i < n + 1; i++) {
		newColorNumbers[i] = numbers[i];
	}
		
	// 2. end judgement
//	[conflictHistory addObject:[NSNumber numberWithUnsignedinteger:newColorNumbers[_n]]];
	while (newColorNumbers[n]) {
		// if noImprovementCount exceeds its limit, end HC.
		if (noImprovementCount > limit) { // fail to solve
//			return conflictHistory; // discard color changes
			return nil;
		}
		
		// 3. pick a conflict vertex
		[self updateConflictVertexFlagsWithColorNumbers:newColorNumbers];
		int numberOfConflictVertices = 0;
		for (int i = 0; i < n; i++) {
			numberOfConflictVertices += _conflictVertexFlags[i]; // count the number of conflict vetices.
		}
		int targetConflictVertexOrder = numberOfConflictVertices * (double)rand() / (RAND_MAX + 1.0) + 1;
		int targetConflictVertexIndex = 0;
		int conflictVertexOrder = 0;
		for (int i = 0; i < n; i++) {
			conflictVertexOrder += _conflictVertexFlags[i];
			if (conflictVertexOrder == targetConflictVertexOrder) { // did find target conflict vertex
				break;
			}
			targetConflictVertexIndex++;
		}
		
		// 4. change a vertex color to minimize the conflict count
		int minConflictCount = newColorNumbers[n];
		int unchangedColorConflictCount = newColorNumbers[n];
		int unchangedTargetColorNumber = newColorNumbers[targetConflictVertexIndex];
		int canditateColorNumbers[c - 1];
		for (int i = 0; i < c - 1; i++) {
			canditateColorNumbers[i] = -1; // initialize canditate color numbers with -1 (none)
		}
		int canditateColorNumberIndex = 0;
		int tempConflictCount;
		int canditateColorNumber = newColorNumbers[targetConflictVertexIndex]; // initialize canditate color number with current color number
		for (int i = 0; i < c - 1; i++) {
			canditateColorNumber = (canditateColorNumber + 1) % c; // next canditate color number
			newColorNumbers[targetConflictVertexIndex] = canditateColorNumber;
			tempConflictCount = [self numberOfConflictsWithColorNumbers:newColorNumbers];
			if (tempConflictCount < minConflictCount) {
				minConflictCount = tempConflictCount;
				for (int i = 0; i < c - 1; i++) {
					canditateColorNumbers[i] = -1; // reset canditate color numbers
				}
				canditateColorNumberIndex = 0;
				canditateColorNumbers[0] = canditateColorNumber; // set candiate color number
			} else if (tempConflictCount == minConflictCount) {
				canditateColorNumbers[canditateColorNumberIndex] = canditateColorNumber; // add new canditate color number
				canditateColorNumberIndex++;
			}
		}
		int numberOfCanditateColorNumbers = 0;
		if (minConflictCount >= unchangedColorConflictCount) { // no improvement...
			noImprovementCount++;
			// revert to unchanged color
			newColorNumbers[targetConflictVertexIndex] = unchangedTargetColorNumber;
		} else { // improved!
			noImprovementCount = 0;
			for (int i = 0; i < c - 1; i++) {
				if (canditateColorNumbers[i] != -1) {
					numberOfCanditateColorNumbers++; // count the number of canditate color numbers
				}
			}
			int newColorNumberIndex = numberOfCanditateColorNumbers * (double)rand() / (RAND_MAX + 1.0);
			int newColorNumber = canditateColorNumbers[newColorNumberIndex];
			newColorNumbers[targetConflictVertexIndex] = newColorNumber;
			newColorNumbers[n] = minConflictCount;
		}
		generation++;
//		[conflictHistory addObject:[NSNumber numberWithUnsignedinteger:newColorNumbers[_n]]];
	}
	
	// if succeeded, update colorNumbers
	for (int i = 0; i < n + 1; i++) {
		numbers[i] = newColorNumbers[i];
	}
//	printf("HC gen = %d\n", generation);
	
//	return conflictHistory;
	return nil;
}

- (BOOL)solving
{
	int editedAmount = 0;
	for (int i = 0; i < n; i++) {
		editedAmount += _currentColoring[i];
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
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			printf("%lu ", (unsigned long)A[i * n + j]);
		}
		printf("\n");
	}
	printf("\n");
}

- (void)dealloc
{
	free(A);
	free(_currentColoring);
	free(_conflictVertexFlags);
	free(_randomIndexMap);
	free(_crossoverMask);
}

@end
