//
//  Model.m
//  HalfPipe
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "StressResultants.h"
#import "ModelCoefficients.h"
#import "Model.h"

#define ROUND_UP(N, B)  ((N + B - 1) & (~(B - 1)))

// Helper function for computing strains.
static void computeStrains(GeneralizedDisplacements u,
                           GeneralizedDisplacements du_d1,
                           GeneralizedDisplacements du_d2,
                           vector_double3 a1,
                           vector_double3 a2,
                           vector_double3 nhat,
                           vector_double3 dnhat_d1,
                           vector_double3 dnhat_d2,
                           CovariantStrains* __nonnull eps0,
                           CovariantStrains* __nonnull eps1)
{
    vector_double3 psi = u.psi * nhat;
    
    eps0[0].part0.x = simd_dot(du_d1.ubar, a1) + .5f*(simd_dot(du_d1.ubar, du_d1.ubar));
    eps0[0].part0.y = simd_dot(du_d2.ubar, a2) + .5f*(simd_dot(du_d2.ubar, du_d2.ubar));
    eps0[0].part0.z = simd_dot(u.phi, nhat) + .5f*(simd_dot(u.phi, u.phi));
    
    eps0[0].part0.w = simd_dot(du_d2.ubar, nhat) + simd_dot(a2, u.phi) + simd_dot(du_d2.ubar, u.phi);
    eps0[0].part1.x = simd_dot(du_d1.ubar, nhat) + simd_dot(a1, u.phi) + simd_dot(du_d1.ubar, u.phi);
    eps0[0].part1.y = simd_dot(du_d1.ubar, a2) + simd_dot(a1, du_d2.ubar) + simd_dot(du_d1.ubar, du_d2.ubar);
    
    eps1[0].part0.x = simd_dot(du_d1.ubar, dnhat_d1) + simd_dot(du_d1.phi, a1) + simd_dot(du_d1.ubar, du_d1.phi);
    eps1[0].part0.y = simd_dot(du_d2.ubar, dnhat_d2) + simd_dot(du_d2.phi, a2) + simd_dot(du_d2.ubar, du_d2.phi);
    eps1[0].part0.z = 2.0f * simd_dot(psi, nhat + u.phi);
    
    eps1[0].part0.w = simd_dot(du_d2.phi, nhat) + 2.0f * simd_dot(a2, psi) + simd_dot(dnhat_d2, u.phi) +
                      simd_dot(du_d2.phi, u.phi) + 2.0f * simd_dot(du_d2.ubar, psi);
    eps1[0].part1.x = simd_dot(du_d1.phi, nhat) + 2.0f * simd_dot(a1, psi) + simd_dot(dnhat_d1, u.phi) +
                      simd_dot(du_d1.phi, u.phi) + 2.0f * simd_dot(du_d1.ubar, psi);
    eps1[0].part1.y = simd_dot(du_d1.ubar, dnhat_d2) + simd_dot(du_d1.phi, a2) + simd_dot(a1, du_d2.phi) +
                      simd_dot(dnhat_d1, du_d2.ubar) + simd_dot(du_d1.ubar, du_d2.phi) + simd_dot(du_d2.ubar, du_d1.phi);
}

@implementation ModelState
{
    @public
    
    double* _a1;
    double* _a2;
    double* _nhat;
    double* _dnhat_dz;
    double* _dnhat_dn;
    NSUInteger      _g_cov_stride;
    
    
    double* _A;
    double* _B;
    double* _D;
    NSUInteger      _resultant_stride;
    
    NSUInteger      _number_of_points;
    NSUInteger      _dof;
    
    // Workspaces for computing strains.
    double*     _strain_0;
    double*     _strain_1;
    NSUInteger  _strain_stride;
}

-(nonnull instancetype) initWithNumberOfPoints: (NSUInteger) numberOfPoints
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _number_of_points = numberOfPoints;
    
    _g_cov_stride = 4;
    
    _a1 = (double*)malloc(_g_cov_stride * numberOfPoints * sizeof(double));
    _a2 = (double*)malloc(_g_cov_stride * numberOfPoints * sizeof(double));
    _nhat = (double*)malloc(_g_cov_stride * numberOfPoints * sizeof(double));
    _dnhat_dz = (double*)malloc(_g_cov_stride * numberOfPoints * sizeof(double));
    _dnhat_dn = (double*)malloc(_g_cov_stride * numberOfPoints * sizeof(double));
    
    
    _resultant_stride = ROUND_UP(21, 4);
    _A = (double*)malloc(_resultant_stride * numberOfPoints * sizeof(double));
    _B = (double*)malloc(_resultant_stride * numberOfPoints * sizeof(double));
    _D = (double*)malloc(_resultant_stride * numberOfPoints * sizeof(double));
    

    _strain_stride = ROUND_UP(7, 4);
    _strain_0 = (double*)malloc(_strain_stride * numberOfPoints * sizeof(double));
    _strain_1 = (double*)malloc(_strain_stride * numberOfPoints * sizeof(double));
    
    return self;
}

// Helper function for computing strains.
-(void) computeStrainsFromDisplacements: (double const* __nonnull) displacements
                localDiffDisplacements0: (double const* __nonnull) localDiffDisplacements0
                localDiffDisplacements1: (double const* __nonnull) localDiffDisplacements1
                    displacementsStride: (NSUInteger) displacementsStride
{
    double const* disps = displacements;
    double const* ddisps_0 = localDiffDisplacements0;
    double const* ddisps_1 = localDiffDisplacements1;
    // Compute strains.
    for (NSUInteger i = 0; i < _number_of_points; ++i)
    {
        GeneralizedDisplacements u = {
            .ubar = (vector_double3){
                disps[i*displacementsStride + 0],
                disps[i*displacementsStride + 1],
                disps[i*displacementsStride + 2]},
            .phi = (vector_double3){
                disps[i*displacementsStride + 3],
                disps[i*displacementsStride + 4],
                disps[i*displacementsStride + 5]},
            .psi = disps[i*displacementsStride + 6]
        };
        
        GeneralizedDisplacements du_dz = {
            .ubar = (vector_double3){
                ddisps_0[i*displacementsStride + 0],
                ddisps_0[i*displacementsStride + 1],
                ddisps_0[i*displacementsStride + 2]},
            .phi = (vector_double3){
                ddisps_0[i*displacementsStride + 3],
                ddisps_0[i*displacementsStride + 4],
                ddisps_0[i*displacementsStride + 5]},
            .psi = ddisps_0[i*displacementsStride + 6]
        };
        
        GeneralizedDisplacements du_dn = {
            .ubar = (vector_double3){
                ddisps_1[i*displacementsStride + 0],
                ddisps_1[i*displacementsStride + 1],
                ddisps_1[i*displacementsStride + 2]},
            .phi = (vector_double3){
                ddisps_1[i*displacementsStride + 3],
                ddisps_1[i*displacementsStride + 4],
                ddisps_1[i*displacementsStride + 5]},
            .psi = ddisps_1[i*displacementsStride + 6]
        };
        
        vector_double3 a1 = (vector_double3){_a1[i*_g_cov_stride + 0], _a1[i*_g_cov_stride + 1], _a1[i*_g_cov_stride + 2]};
        vector_double3 a2 = (vector_double3){_a2[i*_g_cov_stride + 0], _a2[i*_g_cov_stride + 1], _a2[i*_g_cov_stride + 2]};
        vector_double3 nhat = (vector_double3){
            _nhat[i*_g_cov_stride + 0],
            _nhat[i*_g_cov_stride + 1],
            _nhat[i*_g_cov_stride + 2]};
        vector_double3 dnhat_dz = (vector_double3){
            _dnhat_dz[i*_g_cov_stride + 0],
            _dnhat_dz[i*_g_cov_stride + 1],
            _dnhat_dz[i*_g_cov_stride + 2]};
        vector_double3 dnhat_dn = (vector_double3){
            _dnhat_dn[i*_g_cov_stride + 0],
            _dnhat_dn[i*_g_cov_stride + 1],
            _dnhat_dn[i*_g_cov_stride + 2]};
        
        CovariantStrains e0, e1;
        
        computeStrains(u, du_dz, du_dn, a1, a2, nhat, dnhat_dz, dnhat_dn, &e0, &e1);
        
        _strain_0[i*_strain_stride + 0] = e0.part0.x;
        _strain_0[i*_strain_stride + 1] = e0.part0.y;
        _strain_0[i*_strain_stride + 2] = e0.part0.z;
        _strain_0[i*_strain_stride + 3] = e0.part0.w;
        _strain_0[i*_strain_stride + 4] = e0.part1.x;
        _strain_0[i*_strain_stride + 5] = e0.part1.y;
        _strain_1[i*_strain_stride + 0] = e1.part0.x;
        _strain_1[i*_strain_stride + 1] = e1.part0.y;
        _strain_1[i*_strain_stride + 2] = e1.part0.z;
        _strain_1[i*_strain_stride + 3] = e1.part0.w;
        _strain_1[i*_strain_stride + 4] = e1.part1.x;
        _strain_1[i*_strain_stride + 5] = e1.part1.y;
    }
    
}

-(double*_Nonnull) computeStrainsFromDisplacements: (double const* __nonnull) displacements
                           localDiffDisplacements0: (double const* __nonnull) localDiffDisplacements0
                           localDiffDisplacements1: (double const* __nonnull) localDiffDisplacements1
{
    double const* disps = displacements;
    double const* ddisps_0 = localDiffDisplacements0;
    double const* ddisps_1 = localDiffDisplacements1;
    NSUInteger displacementsStride = 8; // or 81?
        
    // Compute strains. Called 64 times per draw iteration (once per element).
    for (NSUInteger i = 0; i < _number_of_points; ++i)
    {
        GeneralizedDisplacements u = {
            .ubar = (vector_double3){
                disps[i*displacementsStride + 0],
                disps[i*displacementsStride + 1],
                disps[i*displacementsStride + 2]},
            .phi = (vector_double3){
                disps[i*displacementsStride + 3],
                disps[i*displacementsStride + 4],
                disps[i*displacementsStride + 5]},
            .psi = disps[i*displacementsStride + 6]
        };
        
        GeneralizedDisplacements du_dz = {
            .ubar = (vector_double3){
                ddisps_0[i*displacementsStride + 0],
                ddisps_0[i*displacementsStride + 1],
                ddisps_0[i*displacementsStride + 2]},
            .phi = (vector_double3){
                ddisps_0[i*displacementsStride + 3],
                ddisps_0[i*displacementsStride + 4],
                ddisps_0[i*displacementsStride + 5]},
            .psi = ddisps_0[i*displacementsStride + 6]
        };
        
        GeneralizedDisplacements du_dn = {
            .ubar = (vector_double3){
                ddisps_1[i*displacementsStride + 0],
                ddisps_1[i*displacementsStride + 1],
                ddisps_1[i*displacementsStride + 2]},
            .phi = (vector_double3){
                ddisps_1[i*displacementsStride + 3],
                ddisps_1[i*displacementsStride + 4],
                ddisps_1[i*displacementsStride + 5]},
            .psi = ddisps_1[i*displacementsStride + 6]
        };
        
        vector_double3 a1 = (vector_double3){_a1[i*_g_cov_stride + 0], _a1[i*_g_cov_stride + 1], _a1[i*_g_cov_stride + 2]};
        vector_double3 a2 = (vector_double3){_a2[i*_g_cov_stride + 0], _a2[i*_g_cov_stride + 1], _a2[i*_g_cov_stride + 2]};
        vector_double3 nhat = (vector_double3){
            _nhat[i*_g_cov_stride + 0],
            _nhat[i*_g_cov_stride + 1],
            _nhat[i*_g_cov_stride + 2]};
        vector_double3 dnhat_dz = (vector_double3){
            _dnhat_dz[i*_g_cov_stride + 0],
            _dnhat_dz[i*_g_cov_stride + 1],
            _dnhat_dz[i*_g_cov_stride + 2]};
        vector_double3 dnhat_dn = (vector_double3){
            _dnhat_dn[i*_g_cov_stride + 0],
            _dnhat_dn[i*_g_cov_stride + 1],
            _dnhat_dn[i*_g_cov_stride + 2]};
        
        CovariantStrains e0, e1;
        
        computeStrains(u, du_dz, du_dn, a1, a2, nhat, dnhat_dz, dnhat_dn, &e0, &e1);
        
        _strain_0[i*_strain_stride + 0] = e0.part0.x;
        _strain_0[i*_strain_stride + 1] = e0.part0.y;
        _strain_0[i*_strain_stride + 2] = e0.part0.z;
        _strain_0[i*_strain_stride + 3] = e0.part0.w;
        _strain_0[i*_strain_stride + 4] = e0.part1.x;
        _strain_0[i*_strain_stride + 5] = e0.part1.y;
    }
    
    return _strain_0;
}

-(void) computeStrainsFromDisplacements: (double const* __nonnull) displacements
                    displacementsStride: (NSUInteger) displacementsStride
{
    NSUInteger disp_slice_stride = displacementsStride * _number_of_points;
    double const* disps = displacements + 0*disp_slice_stride;
    double const* ddisps_0 = displacements + 1*disp_slice_stride;
    double const* ddisps_1 = displacements + 2*disp_slice_stride;
    
    [self computeStrainsFromDisplacements: disps
                  localDiffDisplacements0: ddisps_0
                  localDiffDisplacements1: ddisps_1
                      displacementsStride: displacementsStride];
}

-(void) dealloc
{
    free(_a1);
    free(_a2);
    free(_nhat);
    free(_dnhat_dz);
    free(_dnhat_dn);
    
    free(_A);
    free(_B);
    free(_D);
    
    free(_strain_0);
    free(_strain_1);
    
    [super dealloc];
}
@end    // SKModelState


@implementation Model
{
    @public
    
    NSUInteger                  _degrees_of_freedom;
    MaterialParameters          _material_params;
}

-(NSUInteger) degreesOfFreedom { return _degrees_of_freedom; }

-(nonnull instancetype) initWithMaterialParameters: (MaterialParameters) materialParameters
{
    self = [super init];
    if (self == nil)
        return nil;
    self.modelState = nil;
    
    _degrees_of_freedom = 7;
    _material_params = materialParameters;

    return self;
}

- (nonnull id) copyWithZone: (nullable NSZone *) zone
{
    Model* result = [[Model alloc] initWithMaterialParameters: _material_params];
    return result;
}

-(nullable id) prepareStateForCoordinates: (vector_double3 const* __nonnull) coordinates
                    localDiffCoordinates1: (vector_double3 const* __nonnull) localDiffCoordinates0
                    localDiffCoordinates2: (vector_double3 const* __nonnull) localDiffCoordinates1
                                  normals: (vector_double3 const* __nonnull) normals
                        localDiffNormals1: (vector_double3 const* __nonnull) localDiffNormals0
                        localDiffNormals2: (vector_double3 const* __nonnull) localDiffNormals1
                           numberOfPoints: (NSUInteger) numberOfPoints
{
    self.modelState = [[ModelState alloc] initWithNumberOfPoints: numberOfPoints];
    ModelState* result = self.modelState;
    
    vector_double3 const* pA1 = localDiffCoordinates0;
    vector_double3 const* pA2 = localDiffCoordinates1;
    
    // Normal and derivatives of normals are also required.
    vector_double3 const* pNHat = normals;
    vector_double3 const* pDNHat_dz = localDiffNormals0;
    vector_double3 const* pDNHat_dn = localDiffNormals1;
    
    // Copy into local storage for later use.
    for (NSUInteger i = 0; i < numberOfPoints; ++i)
    {
        result->_a1[i*result->_g_cov_stride + 0] = pA1[i].x;
        result->_a1[i*result->_g_cov_stride + 1] = pA1[i].y;
        result->_a1[i*result->_g_cov_stride + 2] = pA1[i].z;
        
        result->_a2[i*result->_g_cov_stride + 0] = pA2[i].x;
        result->_a2[i*result->_g_cov_stride + 1] = pA2[i].y;
        result->_a2[i*result->_g_cov_stride + 2] = pA2[i].z;
        
        result->_nhat[i*result->_g_cov_stride + 0] = pNHat[i].x;
        result->_nhat[i*result->_g_cov_stride + 1] = pNHat[i].y;
        result->_nhat[i*result->_g_cov_stride + 2] = pNHat[i].z;
        
        result->_dnhat_dz[i*result->_g_cov_stride + 0] = pDNHat_dz[i].x;
        result->_dnhat_dz[i*result->_g_cov_stride + 1] = pDNHat_dz[i].y;
        result->_dnhat_dz[i*result->_g_cov_stride + 2] = pDNHat_dz[i].z;
        
        result->_dnhat_dn[i*result->_g_cov_stride + 0] = pDNHat_dn[i].x;
        result->_dnhat_dn[i*result->_g_cov_stride + 1] = pDNHat_dn[i].y;
        result->_dnhat_dn[i*result->_g_cov_stride + 2] = pDNHat_dn[i].z;
    }
    
    // Get the Lame parameters.
    double const E = _material_params.youngsModulus;
    double const nu = _material_params.poissonsRatio;
    
    double const lambda = (nu * E) / ((1.0f + nu) * (1.0f - 2.0f * nu));
    double const mu = E / (2.0f * (1.0f + nu));
    
    double const thickness = _material_params.thickness;
    
    for (NSUInteger gpt = 0; gpt < numberOfPoints; ++gpt)
    {
        double const* g00 = result->_a1 + result->_g_cov_stride*gpt;
        double const* g10 = result->_a2 + result->_g_cov_stride*gpt;
        double const* g20 = result->_nhat + result->_g_cov_stride*gpt;
        double const* g01 = result->_dnhat_dz + result->_g_cov_stride*gpt;
        double const* g11 = result->_dnhat_dn + result->_g_cov_stride*gpt;
        
        // Prepare Jacobians for this Gauss point and element.
        matrix_double3x3 J_mid = (matrix_double3x3){
            .columns = {
                (vector_double3){
                    g00[0],
                    g10[0],
                    g20[0]
            },
                (vector_double3){
                    g00[1],
                    g10[1],
                    g20[1]
                },
                (vector_double3){
                    g00[2],
                    g10[2],
                    g20[2]
                }
            }
        };
        
        matrix_double3x3 J_t = (matrix_double3x3){
            .columns = {
                (vector_double3){
                    g01[0],
                    g11[0],
                    0.0f
            },
                (vector_double3){
                    g01[1],
                    g11[1],
                    0.0f
                },
                (vector_double3){
                    g01[2],
                    g11[2],
                    0.0f
                }
            }
        };
        
        NSUInteger idx = gpt*result->_resultant_stride;
        
        GenerateStressResultants(result->_A + idx + 0, result->_B + idx + 0, result->_D + idx + 0,
                                 lambda, mu,
                                 1, 1, 1, 1,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 1, result->_B + idx + 1, result->_D + idx + 1,
                                 lambda, mu,
                                 1, 1, 2, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 2, result->_B + idx + 2, result->_D + idx + 2,
                                 lambda, mu,
                                 1, 1, 3, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 3, result->_B + idx + 3, result->_D + idx + 3,
                                 lambda, mu,
                                 1, 1, 2, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 4, result->_B + idx + 4, result->_D + idx + 4,
                                 lambda, mu,
                                 1, 1, 1, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 5, result->_B + idx + 5, result->_D + idx + 5,
                                 lambda, mu,
                                 1, 1, 1, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 6, result->_B + idx + 6, result->_D + idx + 6,
                                 lambda, mu,
                                 2, 2, 2, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 7, result->_B + idx + 7, result->_D + idx + 7,
                                 lambda, mu,
                                 2, 2, 3, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 8, result->_B + idx + 8, result->_D + idx + 8,
                                 lambda, mu,
                                 2, 2, 2, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 9, result->_B + idx + 9, result->_D + idx + 9,
                                 lambda, mu,
                                 2, 2, 1, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 10, result->_B + idx + 10, result->_D + idx + 10,
                                 lambda, mu,
                                 2, 2, 1, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 11, result->_B + idx + 11, result->_D + idx + 11,
                                 lambda, mu,
                                 3, 3, 3, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 12, result->_B + idx + 12, result->_D + idx + 12,
                                 lambda, mu,
                                 3, 3, 2, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 13, result->_B + idx + 13, result->_D + idx + 13,
                                 lambda, mu,
                                 3, 3, 1, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 14, result->_B + idx + 14, result->_D + idx + 14,
                                 lambda, mu,
                                 3, 3, 1, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 15, result->_B + idx + 15, result->_D + idx + 15,
                                 lambda, mu,
                                 2, 3, 2, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 16, result->_B + idx + 16, result->_D + idx + 16,
                                 lambda, mu,
                                 2, 3, 1, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 17, result->_B + idx + 17, result->_D + idx + 17,
                                 lambda, mu,
                                 2, 3, 1, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 18, result->_B + idx + 18, result->_D + idx + 18,
                                 lambda, mu,
                                 1, 3, 1, 3,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 19, result->_B + idx + 19, result->_D + idx + 19,
                                 lambda, mu,
                                 1, 3, 1, 2,
                                 J_mid, J_t, thickness);
        GenerateStressResultants(result->_A + idx + 20, result->_B + idx + 20, result->_D + idx + 20,
                                 lambda, mu,
                                 1, 2, 1, 2,
                                 J_mid, J_t, thickness);
    }
    
    return result.autorelease;
}

-(void) computeCoefficientsFromDisplacements: (double const* __nonnull) displacements
                     localDiffDisplacements1: (double const* __nonnull) localDiffDisplacements0
                     localDiffDisplacements2: (double const* __nonnull) localDiffDisplacements1
                         displacementsStride: (NSUInteger) displacementsStride
                           forceCoefficients: (double* __nonnull) forceCoefficients
                     forceCoefficientsStride: (NSUInteger) forceCoefficientsStride
                       stiffnessCoefficients: (double* __nonnull) stiffnessCoefficients
                 stiffnessCoefficientsStride: (NSUInteger) stiffnessCoefficientsStride
                                       state: (ModelState* __nullable) state
                              numTotalPoints: (NSUInteger) numTotalPoints
                                  startPoint: (NSUInteger) startPoint
                                   numPoints: (NSUInteger) numPoints
{
    if (state)
        NSAssert(state->_number_of_points == numTotalPoints, @"error");
    
    NSAssert((startPoint + numPoints) <= numTotalPoints, @"error");
    
    [state computeStrainsFromDisplacements: displacements
                       displacementsStride: displacementsStride];
    
    double const* disps = displacements + startPoint*displacementsStride;
    double const* ddisps_0 = localDiffDisplacements0 + startPoint*displacementsStride;
    double const* ddisps_1 = localDiffDisplacements1 + startPoint*displacementsStride;
    
    NSUInteger forceOffset = forceCoefficientsStride*numTotalPoints;
    NSUInteger stiffOffset = stiffnessCoefficientsStride*numTotalPoints;
    
    double const* start_A = state->_A + startPoint*state->_resultant_stride;
    double const* start_B = state->_B + startPoint*state->_resultant_stride;
    double const* start_D = state->_D + startPoint*state->_resultant_stride;
    
    double const* start_strain_0 = state->_strain_0 + startPoint*state->_strain_stride;
    double const* start_strain_1 = state->_strain_1 + startPoint*state->_strain_stride;
    
    double const* start_a1 = state->_a1 + startPoint*state->_g_cov_stride;
    double const* start_a2 = state->_a2 + startPoint*state->_g_cov_stride;
    double const* start_nhat = state->_nhat + startPoint*state->_g_cov_stride;
    double const* start_dnhat_dz = state->_dnhat_dz + startPoint*state->_g_cov_stride;
    double const* start_dnhat_dn = state->_dnhat_dn + startPoint*state->_g_cov_stride;
    
    ComputeSubCoefficientF1(start_A, state->_resultant_stride,
                            start_B, state->_resultant_stride,
                            start_D, state->_resultant_stride,
                            start_strain_0, state->_strain_stride,
                            start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                            numPoints,
                            forceCoefficients + 0*forceOffset + startPoint*forceCoefficientsStride, forceCoefficientsStride);
    
    ComputeSubCoefficientF2(start_A, state->_resultant_stride,
                            start_B, state->_resultant_stride,
                            start_D, state->_resultant_stride,
                            start_strain_0, state->_strain_stride,
                            start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                            numPoints,
                            forceCoefficients + 1*forceOffset + startPoint*forceCoefficientsStride, forceCoefficientsStride);
    
    ComputeSubCoefficientF3(start_A, state->_resultant_stride,
                            start_B, state->_resultant_stride,
                            start_D, state->_resultant_stride,
                            start_strain_0, state->_strain_stride,
                            start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                            numPoints,
                            forceCoefficients + 2*forceOffset + startPoint*forceCoefficientsStride, forceCoefficientsStride);
    
    ComputeSubCoefficientK11(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                            start_strain_0, state->_strain_stride,
                            start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 0*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    
    ComputeSubCoefficientK12(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                             start_a1, state->_g_cov_stride,
                             start_a2, state->_g_cov_stride,
                             start_nhat, state->_g_cov_stride,
                             start_dnhat_dz, state->_g_cov_stride,
                             start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 1*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    

    ComputeSubCoefficientK13(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                       disps, displacementsStride,
                       ddisps_0, displacementsStride,
                       ddisps_1, displacementsStride,
                       start_a1, state->_g_cov_stride,
                       start_a2, state->_g_cov_stride,
                       start_nhat, state->_g_cov_stride,
                       start_dnhat_dz, state->_g_cov_stride,
                       start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 2*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    ComputeSubCoefficientK21(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 3*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    ComputeSubCoefficientK22(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 4*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    ComputeSubCoefficientK23(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 5*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    ComputeSubCoefficientK31(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 6*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    ComputeSubCoefficientK32(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 7*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
    ComputeSubCoefficientK33(start_A, state->_resultant_stride,
                             start_B, state->_resultant_stride,
                             start_D, state->_resultant_stride,
                             start_strain_0, state->_strain_stride,
                             start_strain_1, state->_strain_stride,
                            disps, displacementsStride,
                            ddisps_0, displacementsStride,
                            ddisps_1, displacementsStride,
                            start_a1, state->_g_cov_stride,
                            start_a2, state->_g_cov_stride,
                            start_nhat, state->_g_cov_stride,
                            start_dnhat_dz, state->_g_cov_stride,
                            start_dnhat_dn, state->_g_cov_stride,
                             numPoints,
                             stiffnessCoefficients + 8*stiffOffset + startPoint*stiffnessCoefficientsStride, stiffnessCoefficientsStride);
    
}

-(void) computeForceAtCoordinate: (vector_double3) coordinate
            localDiffCoordinate1: (vector_double3) localDiffCoordinate0
            localDiffCoordinate2: (vector_double3) localDiffCoordinate1
                          normal: (vector_double3) normal
                localDiffNormal1: (vector_double3) localDiffNormal0
                localDiffNormal2: (vector_double3) localDiffNormal1
                    appliedForce: (vector_double3) appliedForce
                          result: (double* __nonnull) result
{
    double scale = _material_params.thickness / 2.0f;
    double scale2 = scale * scale;
    
//    scale = isTop ? scale : -1.0f * scale;
    
    vector_double3 nhat = normal;
    
    result[0] = appliedForce.x;
    result[1] = appliedForce.y;
    result[2] = appliedForce.z;
    
    result[3] = scale * appliedForce.x;
    result[4] = scale * appliedForce.y;
    result[5] = scale * appliedForce.z;
    
    result[6] = scale2 * simd_dot(nhat, appliedForce);
}

@end    // SKModel;
