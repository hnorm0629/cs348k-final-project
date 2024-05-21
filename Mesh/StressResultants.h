//
//  StressResultants.h
//  HalfPipe
//

#ifndef StressResultants_h
#define StressResultants_h

#import <Foundation/Foundation.h>
#import <simd/simd.h>

// Evaluate contravariant components of the constitutive matrix.
typedef struct ContravariantCArgs
{
    double        lambda;
    double        mu;
    
    NSUInteger      i;
    NSUInteger      j;
    NSUInteger      k;
    NSUInteger      l;
    
    matrix_double3x3      J_midplane;
    matrix_double3x3      J_thickness;
    double        h;
} ContravariantCArgs;

double ContravariantIntegrand(ContravariantCArgs const* __nonnull cargs, double x);

// Evaluate stress resultants.
void AIntegrand(void* __null_unspecified args,
                size_t n,
                double const* __nonnull x,
                double* __nonnull y);
void BIntegrand(void* __null_unspecified args,
                size_t n,
                double const* __nonnull x,
                double* __nonnull y);
void DIntegrand(void* __null_unspecified args,
                size_t n,
                double const* __nonnull x,
                double* __nonnull y);

void GenerateStressResultants(double* __nonnull resultA,
                              double* __nonnull resultB,
                              double* __nonnull resultD,
                              double lambda, double mu,
                              NSUInteger i, NSUInteger j, NSUInteger k, NSUInteger l,
                              matrix_double3x3 J_mid, matrix_double3x3 J_t,
                              double h);

#endif /* StressResultants_h */
