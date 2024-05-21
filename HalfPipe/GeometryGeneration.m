//
//  GeometryGeneration.m
//

#import <Foundation/Foundation.h>

NSUInteger getNodeCount(NSUInteger elementOrder,
                        NSUInteger nElemsX, NSUInteger nElemsTh,
                        NSUInteger* nBaseNodes)
{
    NSUInteger p = elementOrder + 1;
    NSUInteger nElemNodes = p * p;
    NSUInteger nEdgeNodes = p;
    
    NSUInteger nLowerBodyNodes = nElemNodes - nEdgeNodes - (nEdgeNodes - 1);
    
    NSUInteger nNodes = nLowerBodyNodes * nElemsX * nElemsTh + (nEdgeNodes - 1) * nElemsX + (nEdgeNodes -1) * nElemsTh + 1;
    
    *nBaseNodes = (nEdgeNodes - 1) * nElemsTh + 1;
    
    return nNodes;
}

void generateGeometry(NSUInteger elementOrder,
                      double length, double radius,
                      NSUInteger nElemsX, NSUInteger nElemsTh,
                      NSUInteger* nodes,
                      double* coordinates,
                      double* normals,
                      NSUInteger* fixedNodes)
{
    NSUInteger p = elementOrder + 1;
    NSUInteger nElemNodes = p * p;
    NSUInteger nEdgeNodes = p;
    
    NSUInteger nThetaVerts = (nEdgeNodes - 1) * (nElemsTh - 1) + nEdgeNodes;
    NSUInteger nLengthVerts = (nEdgeNodes - 1) * (nElemsX - 1) + nEdgeNodes;
    
    NSUInteger* allIDs = (NSUInteger*)malloc(nThetaVerts * nLengthVerts * sizeof(NSUInteger));
    
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < nThetaVerts; ++i)
    {
        for (NSUInteger j = 0; j < nLengthVerts; ++j)
        {
            allIDs[i*nLengthVerts + j] = count++;
        }
    }
    
    for (NSUInteger i = 0; i < nElemsTh; ++i)
    {
        for (NSUInteger j = 0; j < nElemsX; ++j)
        {
            NSUInteger idx = i*nElemsX + j;
            
            NSUInteger vertexCount = 0;
            NSUInteger* elemIDs = allIDs + i*(nEdgeNodes - 1)*nLengthVerts + j*(nEdgeNodes - 1);
            for (NSUInteger k = 0; k < nEdgeNodes; ++k)
            {
                NSUInteger* rowIDs = elemIDs + k*nLengthVerts;
                for (NSUInteger l = 0; l < nEdgeNodes; ++l)
                {
                    nodes[idx*nElemNodes + vertexCount++] = rowIDs[l];
                }
                
            }
        }
    }
    
    
    double thetaIncr = M_PI / (double)(nThetaVerts - 1);
    double lengthIncr = length / (double)(nLengthVerts - 1);
    
    for (NSUInteger i = 0; i < nThetaVerts; ++i)
    {
        for (NSUInteger j = 0; j < nLengthVerts; ++j)
        {
            double theta = thetaIncr * (double)i;
            double x = lengthIncr * (double)j;
            
            NSUInteger idx = i*nLengthVerts + j;
            
            normals[3*idx + 0] = cos(theta);
            normals[3*idx + 1] = 0.0;
            normals[3*idx + 2] = sin(theta);
            
            coordinates[3*idx + 0] = radius * cos(theta);
            coordinates[3*idx + 1] = x;
            coordinates[3*idx + 2] = radius * sin(theta);
        }
    }
    
    NSUInteger nBaseNodes = (nEdgeNodes - 1) * nElemsTh + 1;
    for (NSUInteger i = 0; i < nBaseNodes; ++i)
    {
        fixedNodes[i] = allIDs[i*nLengthVerts + (nLengthVerts - 1)];
    }
    free(allIDs);
}
