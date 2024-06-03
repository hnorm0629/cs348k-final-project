//
//  Model.h
//  HalfPipe
//

#ifndef Model_h
#define Model_h

#import <Foundation/Foundation.h>
#import <AdaptableFiniteElementKit/AdaptableFiniteElementKit.h>

/*
 *  A 7-parameter shell model as described in
 *
 *      G. S. Payette and J. N. Reddy, "A seven-parameter spectral/hp finite
 *      element formulation for isotropic, laminated composite and functionally
 *      graded shell structures", Computer Methods in Applied Mechanics and
 *      Engineering, 2014.
 */

// Material parameters.
typedef struct MaterialParameters
{
    double       youngsModulus;
    double       poissonsRatio;
    double       thickness;
} MaterialParameters;

// A struct to use for displacements in the 7-parameter shell model.
typedef struct GeneralizedDisplacements
{
    vector_double3  ubar;
    vector_double3  phi;
    double    psi;
} GeneralizedDisplacements;

// Covariant strain terms.  6 components.
typedef struct CovariantStrains
{
    vector_double4 part0;
    vector_double2 part1;
} CovariantStrains;

/*
 *  An object to hold model state for a given number of points
 */
@interface ModelState : NSObject

-(nonnull instancetype) initWithNumberOfPoints: (NSUInteger) numberOfPoints;

// Helper functions for computing strains.
-(double*_Nonnull) computeStrainsFromDisplacements: (double const* __nonnull) displacements
                           localDiffDisplacements0: (double const* __nonnull) localDiffDisplacements0
                           localDiffDisplacements1: (double const* __nonnull) localDiffDisplacements1;

-(void) computeStrainsFromDisplacements: (double const* __nonnull) displacements
                    displacementsStride: (NSUInteger) displacementsStride;

@end    // ModelState

// A 7-parameter shell model.
@interface Model : NSObject<AFEKModelSource2D>

@property (nonatomic, strong, nullable) ModelState *modelState;

-(nonnull instancetype) initWithMaterialParameters: (MaterialParameters) materialParameters;

@end    // Model

#endif /* Model_h */
