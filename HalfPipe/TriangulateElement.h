//
//  TriangulateElement.h
//  HalfPipe
//

#ifndef TriangulateElement_h
#define TriangulateElement_h

#import <Foundation/Foundation.h>
#import <simd/simd.h>

// Triangulate a square element.
void GenerateTriangles(NSUInteger N, NSUInteger startIdx, vector_double2* vertices, NSUInteger* triangles);


#endif /* TriangulateElement_h */
