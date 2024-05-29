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
                         indexCount:(NSUInteger)indexCount
                                fps:(double)fps
                            runtime:(double)runtime
                           solution:(double)solution
                              error:(double)error {
    self = [super init];
    if (self) {
        _vertexCount = vertexCount;
        _vertices = (vector_float4 *)malloc(sizeof(vector_float4) * vertexCount);
        
        _indexCount = indexCount;
        _indices = (uint32_t *)malloc(sizeof(uint32_t) * indexCount);
        
        _fps = fps;
        _runtime = runtime;
        _solution = solution;
        _error = error;
    }
    return self;
}

- (void)dealloc {
    free(_vertices);
    free(_indices);
    
    [super dealloc];
}

- (void)copyVertexData:(vector_float4 *)vertexData {
    memcpy(_vertices, vertexData, sizeof(vector_float4) * _vertexCount);
}

- (void)copyIndexData:(uint32_t *)indexData {
    memcpy(_indices, indexData, sizeof(uint32_t) * _indexCount);
}

@end
