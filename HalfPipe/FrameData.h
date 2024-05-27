//
//  FrameData.h
//  HalfPipe
//
//  Created by Hannah Norman on 5/27/24.
//

#ifndef FrameData_h
#define FrameData_h

#import <Foundation/Foundation.h>
#import <simd/simd.h>

@interface FrameData : NSObject

@property (nonatomic) vector_float4 *vertices;
@property (nonatomic) NSUInteger vertexCount;
@property (nonatomic) matrix_float4x4 *matrices;
@property (nonatomic) NSUInteger matrixCount;
@property (nonatomic) uint32_t *indices;
@property (nonatomic) NSUInteger indexCount;

@property (nonatomic) double fps;
@property (nonatomic) double runtime;
@property (nonatomic) double solution;
@property (nonatomic) double error;

- (instancetype)initWithVertexCount:(NSUInteger)vertexCount
                        matrixCount:(NSUInteger)matrixCount
                         indexCount:(NSUInteger)indexCount
                                fps:(double)fps
                            runtime:(double)runtime
                           solution:(double)solution
                              error:(double)error;
- (void)copyVertexData:(vector_float4 *)vertexData;
- (void)copyMatrixData:(matrix_float4x4 *)matrixData;
- (void)copyIndexData:(uint32_t *)indexData;

@end

#endif /* FrameData_h */
