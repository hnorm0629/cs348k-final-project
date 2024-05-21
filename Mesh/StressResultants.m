//
//  StressResultants.m
//  HalfPipe
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

#import "StressResultants.h"

double ContravariantIntegrand(ContravariantCArgs const* __nonnull cargs, double x)
{
    double scale = cargs->h / 2.0f;
    
    // Evaluate the Jacobian, its determinant, and its inverse.
    matrix_double3x3 J = simd_add(cargs->J_midplane, simd_mul(x*scale, cargs->J_thickness));
    
    double detJ = simd_determinant(J);
    matrix_double3x3 invJ = simd_inverse(J);
    matrix_double3x3 G = simd_mul(simd_transpose(invJ), invJ);
    
    // Evaluate contravariant components of C.
    NSUInteger i = cargs->i;
    NSUInteger j = cargs->j;
    NSUInteger k = cargs->k;
    NSUInteger l = cargs->l;
    
    double gij = G.columns[j][i];
    double gkl = G.columns[l][k];
    double gik = G.columns[k][i];
    double gjl = G.columns[l][j];
    double gil = G.columns[l][i];
    double gjk = G.columns[k][j];
    
    double C = cargs->lambda * gij * gkl + cargs->mu*(gik*gjl + gil*gjk);
    
    return C * detJ * scale;
}

void AIntegrand(void* __null_unspecified args,
                size_t n,
                double const* __nonnull x,
                double* __nonnull y)
{
    ContravariantCArgs* cargs = (ContravariantCArgs*)args;
    
    for (size_t i = 0; i < n; ++i)
        y[i] = ContravariantIntegrand(cargs, x[i]);
}

void BIntegrand(void* __null_unspecified args,
                size_t n,
                double const* __nonnull x,
                double* __nonnull y)
{
    ContravariantCArgs* cargs = (ContravariantCArgs*)args;
    
    double scale = cargs->h / 2.0f;
    for (size_t i = 0; i < n; ++i)
        y[i] = x[i] * scale * ContravariantIntegrand(cargs, x[i]);
}

void DIntegrand(void* __null_unspecified args,
                size_t n,
                double const* __nonnull x,
                double* __nonnull y)
{
    ContravariantCArgs* cargs = (ContravariantCArgs*)args;
    
    double scale = cargs->h / 2.0f;
    for (size_t i = 0; i < n; ++i)
        y[i] = pow(x[i] * scale, 2.0f) * ContravariantIntegrand(cargs, x[i]);
}

void GenerateStressResultants(double* __nonnull resultA,
                              double* __nonnull resultB,
                              double* __nonnull resultD,
                              double lambda, double mu,
                              NSUInteger i, NSUInteger j, NSUInteger k, NSUInteger l,
                              matrix_double3x3 J_mid, matrix_double3x3 J_t,
                              double h)
{
    ContravariantCArgs args = (ContravariantCArgs){
        .lambda = lambda,
        .mu = mu,
        
        // Indices taken from literature where 1-based indexing is used.
        .i = i - 1,
        .j = j - 1,
        .k = k - 1,
        .l = l - 1,
        .J_midplane = J_mid,
        .J_thickness = J_t,
        .h = h
    };
    
    quadrature_integrate_function f;
    f.fun = AIntegrand;
    f.fun_arg = (void*)&args;
    
    quadrature_integrate_options options = {
        .integrator = QUADRATURE_INTEGRATE_QAGS,
        .abs_tolerance = 1E-6,
        .rel_tolerance = 1E-4,
        .qag_points_per_interval = 0,
        .max_intervals = 1024
    };
    
    quadrature_status status;
    double error;
    
    // TODO: If status fails resort to high resolution Gaussian quadrature or QNG.
    double valA = quadrature_integrate(&f, -1.0f, 1.0f, &options, &status, &error, 0, NULL);
    NSCAssert(status == QUADRATURE_SUCCESS, @"Integration of A failed with error: %d", status);
    
    f.fun = BIntegrand;
    double valB = quadrature_integrate(&f, -1.0f, 1.0f, &options, &status, &error, 0, NULL);
    NSCAssert(status == QUADRATURE_SUCCESS, @"Integration of B failed with error: %d", status);
    
    f.fun = DIntegrand;
    double valD = quadrature_integrate(&f, -1.0f, 1.0f, &options, &status, &error, 0, NULL);
    NSCAssert(status == QUADRATURE_SUCCESS, @"Integration of D failed with error: %d", status);

    resultA[0] = (double)valA;
    resultB[0] = (double)valB;
    resultD[0] = (double)valD;
}
