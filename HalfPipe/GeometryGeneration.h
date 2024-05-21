//
//  GeometryGeneration.h
//  ShellKit
//

#ifndef GeometryGeneration_h
#define GeometryGeneration_h
#import <Foundation/Foundation.h>

NSUInteger getNodeCount(NSUInteger elementOrder,
                        NSUInteger nElemsX, NSUInteger nElemsTh,
                        NSUInteger* nBaseNodes);

void generateGeometry(NSUInteger elementOrder,
                      double length, double radius,
                      NSUInteger nElemsX, NSUInteger nElemsTh,
                      NSUInteger* nodes,
                      double* coordinates,
                      double* normals,
                      NSUInteger* fixedNodes);

#endif /* GeometryGeneration_h */
