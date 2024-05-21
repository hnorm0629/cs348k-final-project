//
//  TriangulateElement.m
//  HalfPipe
//

#import <Foundation/Foundation.h>

#import "TriangulateElement.h"

void GenerateTriangles(NSUInteger N, NSUInteger startIdx, vector_double2* vertices, NSUInteger* triangles)
{
    double length = 2.0 / (double)N;
    
    vector_double2* vert_start = vertices + startIdx;
    NSUInteger* tri_start = triangles + startIdx*3;
    
    for (NSUInteger j = 0; j < N + 1; ++j)
    {
        double y_coord = (double)j * length - 1.0;
        for (NSUInteger i = 0; i < N + 1; ++i)
        {
            double x_coord = (double)i * length - 1.0;
            
            NSUInteger idx = j * (N + 1) + i;
            
            vert_start[idx] = (vector_double2){x_coord, y_coord};
        }
    }
    
    for (NSUInteger j = 0; j < N; ++j)
    {
        for (NSUInteger i = 0; i < N; ++i)
        {
            NSUInteger square_idx = j * (N + 1) + i;
            
            NSUInteger lower_triangle_vert_0 = square_idx;
            NSUInteger lower_triangle_vert_1 = lower_triangle_vert_0 + 1;
            NSUInteger lower_triangle_vert_2 = lower_triangle_vert_1 + (N + 1);
            
            NSUInteger upper_triangle_vert_0 = square_idx;
            NSUInteger upper_triangle_vert_1 = upper_triangle_vert_0 + 1 + (N + 1);
            NSUInteger upper_triangle_vert_2 = upper_triangle_vert_1 - 1;
            
            tri_start[i*2*3 + 0] = lower_triangle_vert_0;
            tri_start[i*2*3 + 1] = lower_triangle_vert_1;
            tri_start[i*2*3 + 2] = lower_triangle_vert_2;
            
            tri_start[i*2*3 + 3] = upper_triangle_vert_0;
            tri_start[i*2*3 + 4] = upper_triangle_vert_1;
            tri_start[i*2*3 + 5] = upper_triangle_vert_2;
        }
        
        tri_start += N*2*3;
    }
}
