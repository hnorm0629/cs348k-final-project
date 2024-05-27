//
//  FrameData.m
//  HalfPipe
//
//  Created by Hannah Norman on 5/27/24.
//

#import <Foundation/Foundation.h>
#import "FrameData.h"

@implementation FrameData

- (instancetype)initWithVertexCount:(NSUInteger)vertexCount
                        matrixCount:(NSUInteger)matrixCount
                         indexCount:(NSUInteger)indexCount {
    self = [super init];
    if (self) {
        _vertexCount = vertexCount;
        _vertices = (vector_float4 *)malloc(sizeof(vector_float4) * vertexCount);
        
        _matrixCount = matrixCount;
        _matrices = (matrix_float4x4 *)malloc(sizeof(matrix_float4x4) * matrixCount);
        
        _indexCount = indexCount;
        _indices = (uint32_t *)malloc(sizeof(uint32_t) * indexCount);
    }
    return self;
}

- (void)dealloc {
    free(_vertices);
    free(_matrices);
    free(_indices);
}

- (void)copyVertexData:(vector_float4 *)vertexData {
    memcpy(_vertices, vertexData, sizeof(vector_float4) * _vertexCount);
}

- (void)copyMatrixData:(matrix_float4x4 *)matrixData {
    memcpy(_matrices, matrixData, sizeof(matrix_float4x4) * _matrixCount);
}

- (void)copyIndexData:(uint32_t *)indexData {
    memcpy(_indices, indexData, sizeof(uint32_t) * _indexCount);
}

@end
