//
//  UTGCPGenerator.h
//  EAExplorer
//
//  Created by Yusuke IWAMA on 10/14/13.
//  Copyright (c) 2013 College of Information Science, University of Tsukuba. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (readonly) BOOL solved;


/** 
 designated initializer
 
 @param v number of vertices
 @param c number of colors
 */
- (id)initWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c;

+ (id)GCPWithNumberOfVertices:(NSUInteger)v numberOfEdges:(NSUInteger)e numberOfColors:(NSUInteger)c;

- (BOOL)verify;

- (NSUInteger)conflictCount;

- (BOOL)solving;

- (void)printMatrix;

@end


/*
 リファクタリング
 UTGCPクラスは、
 ・クラスメソッドとしてUTGCPインスタンスを返す問題ジェネレータとしての機能
 ・クラスメソッドとしてUTGCPインスタンスを解く問題ソルバーとしての機能
 を備えたものとする。つまり、現状のUTGCPとUTGCPSolverを一つのクラスにまとめる。
 全体として、GraphColoringProblemの生成から解決まで一手に担えるようなクラスにまとめる。
 
 実装したいことリスト
 平面性判定
 ゲーム化（スコア
 何色使っているか
 */