//
//  Element.m
//  HalfPipe
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "Element.h"

typedef void (*shapeFunction)(vector_double2, double*);
typedef void (*diffShapeFunction)(vector_double2, double*, double*);

static void evalSFQ81(vector_double2 coord, double* result);
static void evalLDSFQ81(vector_double2 coord, double* result0, double* result1);

@implementation Element
{
    @public
    NSUInteger      _integration_order;
    
    shapeFunction       _shape_function;
    diffShapeFunction   _local_diff_shape_function;
    
    NSUInteger      _number_of_nodes;
    NSUInteger      _order;
}

-(nonnull instancetype) init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _order = 8;
    
    _integration_order = _order + 1;
    
    _number_of_nodes = _integration_order * _integration_order;

    _shape_function = evalSFQ81;
    _local_diff_shape_function = evalLDSFQ81;
    
    return self;
}

- (nonnull id) copyWithZone: (nullable NSZone *) zone
{
    Element* result = [[Element alloc] init];
    if( nil == result)
        return nil;
    
    return result;
}

- (NSUInteger)numberOfNodes {
    return _number_of_nodes;
}


- (NSUInteger)order {
    return _order;
}

-(NSUInteger) dimensions
{
    return 2;
}

-(void) generateShapeValuesAtPoints: (vector_double2 const* __nonnull) points
                     numberOfPoints: (NSUInteger) numberOfPoints
                       shapeResults: (double* __nonnull) shapeResults
             localDiffShape1Results: (double* __nonnull) localDiffShape0Results
             localDiffShape2Results: (double* __nonnull) localDiffShape1Results
                     shapeRowStride: (NSUInteger) shapeRowStride
{
    for (NSUInteger i = 0; i < numberOfPoints; ++i)
    {
        double* SRow = shapeResults + i*shapeRowStride;
        double* LDSRow0 = localDiffShape0Results + i*shapeRowStride;
        double* LDSRow1 = localDiffShape1Results + i*shapeRowStride;
        
        _shape_function(points[i], SRow);
        _local_diff_shape_function(points[i], LDSRow0, LDSRow1);
    }
}

@end    // Element

// Shape functions
static void evalSFQ81(vector_double2 coord, double* result)
{
    double z = coord.x;
    double n = coord.y;
    
    double t2 = n+1.0;
    double t3 = z+1.0;
    double t4 = n-1.0;
    double t5 = z-1.0;
    double t6 = n+1.0/2.0;
    double t7 = n+1.0/4.0;
    double t8 = n+3.0/4.0;
    double t9 = z+1.0/2.0;
    double t10 = z+1.0/4.0;
    double t11 = z+3.0/4.0;
    double t12 = n-1.0/2.0;
    double t13 = n-1.0/4.0;
    double t14 = n-3.0/4.0;
    double t15 = z-1.0/2.0;
    double t16 = z-1.0/4.0;
    double t17 = z-3.0/4.0;
    
    result[0] = n*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*2.641914840010078;
    result[1] = n*t3*t4*t5*t6*t7*t8*t9*t10*t12*t13*t14*t15*t16*t17*z*(-2.113531872008062e+1);
    result[2] = n*t3*t4*t5*t6*t7*t8*t10*t11*t12*t13*t14*t15*t16*t17*z*7.397361552028219e+1;
    result[3] = n*t3*t4*t5*t6*t7*t8*t9*t11*t12*t13*t14*t15*t16*t17*z*(-1.479472310405644e+2);
    result[4] = n*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*1.849340388007055e+2;
    result[5] = n*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t17*z*(-1.479472310405644e+2);
    result[6] = n*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t16*t17*z*7.397361552028219e+1;
    result[7] = n*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*z*(-2.113531872008062e+1);
    result[8] = n*t3*t4*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*2.641914840010078;
    result[9] = n*t2*t4*t5*t6*t7*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*(-2.113531872008062e+1);
    result[10] = n*t2*t3*t4*t5*t6*t7*t9*t10*t12*t13*t14*t15*t16*t17*z*1.69082549760645e+2;
    result[11] = n*t2*t3*t4*t5*t6*t7*t10*t11*t12*t13*t14*t15*t16*t17*z*(-5.917889241622575e+2);
    result[12] = n*t2*t3*t4*t5*t6*t7*t9*t11*t12*t13*t14*t15*t16*t17*z*1.183577848324515e+3;
    result[13] = n*t2*t3*t4*t5*t6*t7*t9*t10*t11*t12*t13*t14*t15*t16*t17*(-1.479472310405644e+3);
    result[14] = n*t2*t3*t4*t5*t6*t7*t9*t10*t11*t12*t13*t14*t15*t17*z*1.183577848324515e+3;
    result[15] = n*t2*t3*t4*t5*t6*t7*t9*t10*t11*t12*t13*t14*t16*t17*z*(-5.917889241622575e+2);
    result[16] = n*t2*t3*t4*t5*t6*t7*t9*t10*t11*t12*t13*t14*t15*t16*z*1.69082549760645e+2;
    result[17] = n*t2*t3*t4*t6*t7*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*(-2.113531872008062e+1);
    result[18] = n*t2*t4*t5*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*7.397361552028219e+1;
    result[19] = n*t2*t3*t4*t5*t7*t8*t9*t10*t12*t13*t14*t15*t16*t17*z*(-5.917889241622575e+2);
    result[20] = n*t2*t3*t4*t5*t7*t8*t10*t11*t12*t13*t14*t15*t16*t17*z*2.071261234567901e+3;
    result[21] = n*t2*t3*t4*t5*t7*t8*t9*t11*t12*t13*t14*t15*t16*t17*z*(-4.142522469135802e+3);
    result[22] = n*t2*t3*t4*t5*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*5.178153086419753e+3;
    result[23] = n*t2*t3*t4*t5*t7*t8*t9*t10*t11*t12*t13*t14*t15*t17*z*(-4.142522469135802e+3);
    result[24] = n*t2*t3*t4*t5*t7*t8*t9*t10*t11*t12*t13*t14*t16*t17*z*2.071261234567901e+3;
    result[25] = n*t2*t3*t4*t5*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*z*(-5.917889241622575e+2);
    result[26] = n*t2*t3*t4*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*7.397361552028219e+1;
    result[27] = n*t2*t4*t5*t6*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*(-1.479472310405644e+2);
    result[28] = n*t2*t3*t4*t5*t6*t8*t9*t10*t12*t13*t14*t15*t16*t17*z*1.183577848324515e+3;
    result[29] = n*t2*t3*t4*t5*t6*t8*t10*t11*t12*t13*t14*t15*t16*t17*z*(-4.142522469135802e+3);
    result[30] = n*t2*t3*t4*t5*t6*t8*t9*t11*t12*t13*t14*t15*t16*t17*z*8.285044938271605e+3;
    result[31] = n*t2*t3*t4*t5*t6*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*(-1.035630617283951e+4);
    result[32] = n*t2*t3*t4*t5*t6*t8*t9*t10*t11*t12*t13*t14*t15*t17*z*8.285044938271605e+3;
    result[33] = n*t2*t3*t4*t5*t6*t8*t9*t10*t11*t12*t13*t14*t16*t17*z*(-4.142522469135802e+3);
    result[34] = n*t2*t3*t4*t5*t6*t8*t9*t10*t11*t12*t13*t14*t15*t16*z*1.183577848324515e+3;
    result[35] = n*t2*t3*t4*t6*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*(-1.479472310405644e+2);
    result[36] = t2*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*1.849340388007055e+2;
    result[37] = t2*t3*t4*t5*t6*t7*t8*t9*t10*t12*t13*t14*t15*t16*t17*z*(-1.479472310405644e+3);
    result[38] = t2*t3*t4*t5*t6*t7*t8*t10*t11*t12*t13*t14*t15*t16*t17*z*5.178153086419753e+3;
    result[39] = t2*t3*t4*t5*t6*t7*t8*t9*t11*t12*t13*t14*t15*t16*t17*z*(-1.035630617283951e+4);
    result[40] = t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*1.294538271604938e+4;
    result[41] = t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t17*z*(-1.035630617283951e+4);
    result[42] = t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t16*t17*z*5.178153086419753e+3;
    result[43] = t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*z*(-1.479472310405644e+3);
    result[44] = t2*t3*t4*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*1.849340388007055e+2;
    result[45] = n*t2*t4*t5*t6*t7*t8*t9*t10*t11*t12*t14*t15*t16*t17*z*(-1.479472310405644e+2);
    result[46] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t12*t14*t15*t16*t17*z*1.183577848324515e+3;
    result[47] = n*t2*t3*t4*t5*t6*t7*t8*t10*t11*t12*t14*t15*t16*t17*z*(-4.142522469135802e+3);
    result[48] = n*t2*t3*t4*t5*t6*t7*t8*t9*t11*t12*t14*t15*t16*t17*z*8.285044938271605e+3;
    result[49] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t14*t15*t16*t17*(-1.035630617283951e+4);
    result[50] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t14*t15*t17*z*8.285044938271605e+3;
    result[51] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t14*t16*t17*z*(-4.142522469135802e+3);
    result[52] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t14*t15*t16*z*1.183577848324515e+3;
    result[53] = n*t2*t3*t4*t6*t7*t8*t9*t10*t11*t12*t14*t15*t16*t17*z*(-1.479472310405644e+2);
    result[54] = n*t2*t4*t5*t6*t7*t8*t9*t10*t11*t13*t14*t15*t16*t17*z*7.397361552028219e+1;
    result[55] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t13*t14*t15*t16*t17*z*(-5.917889241622575e+2);
    result[56] = n*t2*t3*t4*t5*t6*t7*t8*t10*t11*t13*t14*t15*t16*t17*z*2.071261234567901e+3;
    result[57] = n*t2*t3*t4*t5*t6*t7*t8*t9*t11*t13*t14*t15*t16*t17*z*(-4.142522469135802e+3);
    result[58] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t13*t14*t15*t16*t17*5.178153086419753e+3;
    result[59] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t13*t14*t15*t17*z*(-4.142522469135802e+3);
    result[60] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t13*t14*t16*t17*z*2.071261234567901e+3;
    result[61] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t13*t14*t15*t16*z*(-5.917889241622575e+2);
    result[62] = n*t2*t3*t4*t6*t7*t8*t9*t10*t11*t13*t14*t15*t16*t17*z*7.397361552028219e+1;
    result[63] = n*t2*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t15*t16*t17*z*(-2.113531872008062e+1);
    result[64] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t12*t13*t15*t16*t17*z*1.69082549760645e+2;
    result[65] = n*t2*t3*t4*t5*t6*t7*t8*t10*t11*t12*t13*t15*t16*t17*z*(-5.917889241622575e+2);
    result[66] = n*t2*t3*t4*t5*t6*t7*t8*t9*t11*t12*t13*t15*t16*t17*z*1.183577848324515e+3;
    result[67] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t15*t16*t17*(-1.479472310405644e+3);
    result[68] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t15*t17*z*1.183577848324515e+3;
    result[69] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t16*t17*z*(-5.917889241622575e+2);
    result[70] = n*t2*t3*t4*t5*t6*t7*t8*t9*t10*t11*t12*t13*t15*t16*z*1.69082549760645e+2;
    result[71] = n*t2*t3*t4*t6*t7*t8*t9*t10*t11*t12*t13*t15*t16*t17*z*(-2.113531872008062e+1);
    result[72] = n*t2*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*2.641914840010078;
    result[73] = n*t2*t3*t5*t6*t7*t8*t9*t10*t12*t13*t14*t15*t16*t17*z*(-2.113531872008062e+1);
    result[74] = n*t2*t3*t5*t6*t7*t8*t10*t11*t12*t13*t14*t15*t16*t17*z*7.397361552028219e+1;
    result[75] = n*t2*t3*t5*t6*t7*t8*t9*t11*t12*t13*t14*t15*t16*t17*z*(-1.479472310405644e+2);
    result[76] = n*t2*t3*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*1.849340388007055e+2;
    result[77] = n*t2*t3*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t17*z*(-1.479472310405644e+2);
    result[78] = n*t2*t3*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t16*t17*z*7.397361552028219e+1;
    result[79] = n*t2*t3*t5*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*z*(-2.113531872008062e+1);
    result[80] = n*t2*t3*t6*t7*t8*t9*t10*t11*t12*t13*t14*t15*t16*t17*z*2.641914840010078;
}

static void evalLDSFQ81(vector_double2 coord, double* result0, double* result1)
{
    double z = coord.x;
    double n = coord.y;
    
    double t2 = n+1.0;
    double t3 = z+1.0;
    double t4 = n-1.0;
    double t5 = z-1.0;
    double t6 = n+1.0/2.0;
    double t7 = n+1.0/4.0;
    double t8 = n+3.0/4.0;
    double t9 = z+1.0/2.0;
    double t10 = z+1.0/4.0;
    double t11 = z+3.0/4.0;
    double t12 = n-1.0/2.0;
    double t13 = n-1.0/4.0;
    double t14 = n-3.0/4.0;
    double t15 = z-1.0/2.0;
    double t16 = z-1.0/4.0;
    double t17 = z-3.0/4.0;
    double t18 = n*t2*t4*t6*t7*t8*t13*4.551111111111111e+1;
    double t19 = n*t2*t4*t6*t7*t8*t14*4.551111111111111e+1;
    double t20 = n*t2*t4*t6*t7*t8*t12*9.102222222222222e+1;
    double t21 = n*t2*t4*t6*t7*t8*t14*9.102222222222222e+1;
    double t22 = t3*t5*t9*t10*t11*t16*z*4.551111111111111e+1;
    double t23 = t3*t5*t9*t10*t11*t17*z*4.551111111111111e+1;
    double t24 = t3*t5*t9*t10*t11*t15*z*9.102222222222222e+1;
    double t25 = t3*t5*t9*t10*t11*t17*z*9.102222222222222e+1;
    double t26 = n*t2*t4*t7*t8*t12*t13*4.551111111111111e+1;
    double t27 = n*t2*t4*t6*t7*t13*t14*4.551111111111111e+1;
    double t28 = n*t2*t4*t7*t8*t12*t14*4.551111111111111e+1;
    double t29 = n*t2*t4*t6*t8*t13*t14*4.551111111111111e+1;
    double t30 = n*t2*t4*t7*t8*t13*t14*4.551111111111111e+1;
    double t31 = n*t2*t4*t6*t8*t12*t13*9.102222222222222e+1;
    double t32 = n*t2*t4*t6*t7*t12*t14*9.102222222222222e+1;
    double t33 = n*t2*t4*t6*t8*t12*t14*9.102222222222222e+1;
    double t34 = n*t2*t4*t7*t8*t12*t14*9.102222222222222e+1;
    double t35 = n*t2*t4*t6*t8*t13*t14*9.102222222222222e+1;
    double t36 = n*t2*t4*t6*t7*t8*t12*1.30031746031746e+1;
    double t37 = n*t2*t4*t6*t7*t8*t13*1.30031746031746e+1;
    double t38 = t3*t5*t10*t11*t15*t16*z*4.551111111111111e+1;
    double t39 = t3*t5*t9*t10*t16*t17*z*4.551111111111111e+1;
    double t40 = t3*t5*t10*t11*t15*t17*z*4.551111111111111e+1;
    double t41 = t3*t5*t9*t11*t16*t17*z*4.551111111111111e+1;
    double t42 = t3*t5*t10*t11*t16*t17*z*4.551111111111111e+1;
    double t43 = t3*t5*t9*t11*t15*t16*z*9.102222222222222e+1;
    double t44 = t3*t5*t9*t10*t15*t17*z*9.102222222222222e+1;
    double t45 = t3*t5*t9*t11*t15*t17*z*9.102222222222222e+1;
    double t46 = t3*t5*t10*t11*t15*t17*z*9.102222222222222e+1;
    double t47 = t3*t5*t9*t11*t16*t17*z*9.102222222222222e+1;
    double t48 = t3*t5*t9*t10*t11*t15*z*1.30031746031746e+1;
    double t49 = t3*t5*t9*t10*t11*t16*z*1.30031746031746e+1;
    double t50 = n*t2*t4*t7*t12*t13*t14*4.551111111111111e+1;
    double t51 = n*t2*t4*t8*t12*t13*t14*4.551111111111111e+1;
    double t52 = n*t2*t6*t7*t8*t13*t14*4.551111111111111e+1;
    double t53 = n*t2*t4*t6*t12*t13*t14*9.102222222222222e+1;
    double t54 = n*t2*t4*t8*t12*t13*t14*9.102222222222222e+1;
    double t55 = n*t2*t6*t7*t8*t12*t14*9.102222222222222e+1;
    double t56 = n*t2*t4*t6*t7*t12*t13*1.30031746031746e+1;
    double t57 = n*t2*t4*t6*t8*t12*t13*1.30031746031746e+1;
    double t58 = n*t2*t4*t6*t7*t12*t14*1.30031746031746e+1;
    double t59 = n*t2*t4*t7*t8*t12*t13*1.30031746031746e+1;
    double t60 = n*t2*t4*t6*t7*t13*t14*1.30031746031746e+1;
    double t61 = t3*t5*t10*t15*t16*t17*z*4.551111111111111e+1;
    double t62 = t3*t5*t11*t15*t16*t17*z*4.551111111111111e+1;
    double t63 = t3*t9*t10*t11*t16*t17*z*4.551111111111111e+1;
    double t64 = t3*t5*t9*t15*t16*t17*z*9.102222222222222e+1;
    double t65 = t3*t5*t11*t15*t16*t17*z*9.102222222222222e+1;
    double t66 = t3*t9*t10*t11*t15*t17*z*9.102222222222222e+1;
    double t67 = t3*t5*t9*t10*t15*t16*z*1.30031746031746e+1;
    double t68 = t3*t5*t9*t11*t15*t16*z*1.30031746031746e+1;
    double t69 = t3*t5*t9*t10*t15*t17*z*1.30031746031746e+1;
    double t70 = t3*t5*t10*t11*t15*t16*z*1.30031746031746e+1;
    double t71 = t3*t5*t9*t10*t16*t17*z*1.30031746031746e+1;
    double t72 = n*t2*t6*t7*t8*t12*t13*(5.12e+2/3.15e+2);
    double t73 = n*t2*t6*t7*t8*t12*t14*(5.12e+2/3.15e+2);
    double t74 = n*t2*t6*t7*t8*t13*t14*(5.12e+2/3.15e+2);
    double t75 = n*t4*t6*t7*t8*t13*t14*4.551111111111111e+1;
    double t76 = n*t2*t7*t8*t12*t13*t14*4.551111111111111e+1;
    double t77 = n*t4*t6*t7*t8*t12*t14*9.102222222222222e+1;
    double t78 = n*t2*t6*t8*t12*t13*t14*9.102222222222222e+1;
    double t79 = n*t2*t4*t6*t12*t13*t14*1.30031746031746e+1;
    double t80 = n*t2*t4*t7*t12*t13*t14*1.30031746031746e+1;
    double t81 = n*t2*t6*t7*t8*t12*t13*1.30031746031746e+1;
    double t82 = t3*t9*t10*t11*t15*t16*z*(5.12e+2/3.15e+2);
    double t83 = t3*t9*t10*t11*t15*t17*z*(5.12e+2/3.15e+2);
    double t84 = t3*t9*t10*t11*t16*t17*z*(5.12e+2/3.15e+2);
    double t85 = t5*t9*t10*t11*t16*t17*z*4.551111111111111e+1;
    double t86 = t3*t10*t11*t15*t16*t17*z*4.551111111111111e+1;
    double t87 = t5*t9*t10*t11*t15*t17*z*9.102222222222222e+1;
    double t88 = t3*t9*t11*t15*t16*t17*z*9.102222222222222e+1;
    double t89 = t3*t5*t9*t15*t16*t17*z*1.30031746031746e+1;
    double t90 = t3*t5*t10*t15*t16*t17*z*1.30031746031746e+1;
    double t91 = t3*t9*t10*t11*t15*t16*z*1.30031746031746e+1;
    double t92 = n*t4*t6*t7*t8*t12*t13*(5.12e+2/3.15e+2);
    double t93 = n*t2*t6*t7*t12*t13*t14*(5.12e+2/3.15e+2);
    double t94 = n*t4*t6*t7*t8*t12*t14*(5.12e+2/3.15e+2);
    double t95 = n*t2*t6*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t96 = n*t4*t6*t7*t8*t13*t14*(5.12e+2/3.15e+2);
    double t97 = n*t2*t7*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t98 = n*t4*t7*t8*t12*t13*t14*4.551111111111111e+1;
    double t99 = n*t4*t6*t8*t12*t13*t14*9.102222222222222e+1;
    double t100 = n*t4*t6*t7*t8*t12*t13*1.30031746031746e+1;
    double t101 = n*t2*t6*t7*t12*t13*t14*1.30031746031746e+1;
    double t102 = t5*t9*t10*t11*t15*t16*z*(5.12e+2/3.15e+2);
    double t103 = t3*t9*t10*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t104 = t5*t9*t10*t11*t15*t17*z*(5.12e+2/3.15e+2);
    double t105 = t3*t9*t11*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t106 = t5*t9*t10*t11*t16*t17*z*(5.12e+2/3.15e+2);
    double t107 = t3*t10*t11*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t108 = t5*t10*t11*t15*t16*t17*z*4.551111111111111e+1;
    double t109 = t5*t9*t11*t15*t16*t17*z*9.102222222222222e+1;
    double t110 = t5*t9*t10*t11*t15*t16*z*1.30031746031746e+1;
    double t111 = t3*t9*t10*t15*t16*t17*z*1.30031746031746e+1;
    double t112 = t3*t5*t9*t10*t11*t15*t16*1.137777777777778e+2;
    double t113 = t3*t5*t9*t10*t11*t15*t17*1.137777777777778e+2;
    double t114 = t3*t5*t9*t10*t11*t16*t17*1.137777777777778e+2;
    double t115 = t3*t5*t9*t10*t11*t16*t17*4.551111111111111e+1;
    double t116 = t3*t5*t9*t10*t11*t15*t17*9.102222222222222e+1;
    double t117 = n*t4*t6*t7*t12*t13*t14*(5.12e+2/3.15e+2);
    double t118 = n*t4*t6*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t119 = n*t4*t7*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t120 = n*t4*t6*t7*t12*t13*t14*1.30031746031746e+1;
    double t121 = t5*t9*t10*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t122 = t5*t9*t11*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t123 = t5*t10*t11*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t124 = t5*t9*t10*t15*t16*t17*z*1.30031746031746e+1;
    double t125 = t2*t4*t6*t7*t8*t12*t13*1.137777777777778e+2;
    double t126 = t2*t4*t6*t7*t8*t12*t14*1.137777777777778e+2;
    double t127 = t2*t4*t6*t7*t8*t13*t14*1.137777777777778e+2;
    double t128 = t2*t4*t6*t7*t8*t13*t14*4.551111111111111e+1;
    double t129 = t2*t4*t6*t7*t8*t12*t14*9.102222222222222e+1;
    double t130 = t3*t5*t9*t10*t15*t16*t17*1.137777777777778e+2;
    double t131 = t3*t5*t9*t11*t15*t16*t17*1.137777777777778e+2;
    double t132 = t3*t5*t10*t11*t15*t16*t17*1.137777777777778e+2;
    double t133 = t3*t5*t10*t11*t15*t16*t17*4.551111111111111e+1;
    double t134 = t3*t5*t9*t11*t15*t16*t17*9.102222222222222e+1;
    double t135 = t3*t5*t9*t10*t11*t15*t16*1.30031746031746e+1;
    double t136 = n*t6*t7*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t137 = t9*t10*t11*t15*t16*t17*z*(5.12e+2/3.15e+2);
    double t138 = t2*t4*t6*t7*t12*t13*t14*1.137777777777778e+2;
    double t139 = t2*t4*t6*t8*t12*t13*t14*1.137777777777778e+2;
    double t140 = t2*t4*t7*t8*t12*t13*t14*1.137777777777778e+2;
    double t141 = t2*t4*t7*t8*t12*t13*t14*4.551111111111111e+1;
    double t142 = t2*t4*t6*t8*t12*t13*t14*9.102222222222222e+1;
    double t143 = t2*t4*t6*t7*t8*t12*t13*1.30031746031746e+1;
    double t144 = t3*t9*t10*t11*t15*t16*t17*1.137777777777778e+2;
    double t145 = t3*t5*t9*t10*t15*t16*t17*1.30031746031746e+1;
    double t146 = t2*t6*t7*t8*t12*t13*t14*1.137777777777778e+2;
    double t147 = t2*t4*t6*t7*t12*t13*t14*1.30031746031746e+1;
    double t148 = t3*t9*t10*t11*t15*t16*t17*(5.12e+2/3.15e+2);
    double t149 = t5*t9*t10*t11*t15*t16*t17*1.137777777777778e+2;
    double t150 = t2*t6*t7*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t151 = t4*t6*t7*t8*t12*t13*t14*1.137777777777778e+2;
    double t152 = t5*t9*t10*t11*t15*t16*t17*(5.12e+2/3.15e+2);
    double t153 = t4*t6*t7*t8*t12*t13*t14*(5.12e+2/3.15e+2);
    double t154 = t22+t23+t39+t41+t42+t63+t85+t115;
    double t155 = t24+t25+t44+t45+t46+t66+t87+t116;
    double t156 = t18+t19+t27+t29+t30+t52+t75+t128;
    double t157 = t20+t21+t32+t33+t34+t55+t77+t129;
    double t158 = t38+t40+t42+t61+t62+t86+t108+t133;
    double t159 = t43+t45+t47+t64+t65+t88+t109+t134;
    double t160 = t26+t28+t30+t50+t51+t76+t98+t141;
    double t161 = t31+t33+t35+t53+t54+t78+t99+t142;
    double t162 = t48+t49+t67+t68+t70+t91+t110+t135;
    double t163 = t36+t37+t56+t57+t59+t81+t100+t143;
    double t164 = t67+t69+t71+t89+t90+t111+t124+t145;
    double t165 = t56+t58+t60+t79+t80+t101+t120+t147;
    double t166 = t82+t83+t84+t103+t105+t107+t137+t148;
    double t167 = t72+t73+t74+t93+t95+t97+t136+t150;
    double t168 = t102+t104+t106+t121+t122+t123+t137+t152;
    double t169 = t92+t94+t96+t117+t118+t119+t136+t153;
    double t170 = t125+t126+t127+t138+t139+t140+t146+t151;
    double t171 = t112+t113+t114+t130+t131+t132+t144+t149;
    
    result0[0] = t14*t92*t168;
    result1[0] = t17*t102*t169;
    result0[1] = n*t4*t6*t7*t8*t12*t13*t14*t164*(-5.12e+2/3.15e+2);
    result1[1] = t3*t5*t9*t10*t15*t16*t17*t169*z*(-1.30031746031746e+1);
    result0[2] = t14*t92*t158;
    result1[2] = t17*t38*t169;
    result0[3] = n*t4*t6*t7*t8*t12*t13*t14*t159*(-5.12e+2/3.15e+2);
    result1[3] = t3*t5*t9*t11*t15*t16*t17*t169*z*(-9.102222222222222e+1);
    result0[4] = t14*t92*t171;
    result1[4] = t17*t112*t169;
    result0[5] = n*t4*t6*t7*t8*t12*t13*t14*t155*(-5.12e+2/3.15e+2);
    result1[5] = t3*t5*t9*t10*t11*t15*t17*t169*z*(-9.102222222222222e+1);
    result0[6] = t14*t92*t154;
    result1[6] = t17*t22*t169;
    result0[7] = n*t4*t6*t7*t8*t12*t13*t14*t162*(-5.12e+2/3.15e+2);
    result1[7] = t3*t5*t9*t10*t11*t15*t16*t169*z*(-1.30031746031746e+1);
    result0[8] = t14*t92*t166;
    result1[8] = t17*t82*t169;
    result0[9] = n*t2*t4*t6*t7*t12*t13*t14*t168*(-1.30031746031746e+1);
    result1[9] = t5*t9*t10*t11*t15*t16*t17*t165*z*(-5.12e+2/3.15e+2);
    result0[10] = t14*t56*t164;
    result1[10] = t17*t67*t165;
    result0[11] = n*t2*t4*t6*t7*t12*t13*t14*t158*(-1.30031746031746e+1);
    result1[11] = t3*t5*t10*t11*t15*t16*t17*t165*z*(-4.551111111111111e+1);
    result0[12] = t14*t56*t159;
    result1[12] = t17*t43*t165;
    result0[13] = n*t2*t4*t6*t7*t12*t13*t14*t171*(-1.30031746031746e+1);
    result1[13] = t3*t5*t9*t10*t11*t15*t16*t17*t165*(-1.137777777777778e+2);
    result0[14] = t14*t56*t155;
    result1[14] = t17*t24*t165;
    result0[15] = n*t2*t4*t6*t7*t12*t13*t14*t154*(-1.30031746031746e+1);
    result1[15] = t3*t5*t9*t10*t11*t16*t17*t165*z*(-4.551111111111111e+1);
    result0[16] = t14*t56*t162;
    result1[16] = t16*t48*t165;
    result0[17] = n*t2*t4*t6*t7*t12*t13*t14*t166*(-1.30031746031746e+1);
    result1[17] = t3*t9*t10*t11*t15*t16*t17*t165*z*(-5.12e+2/3.15e+2);
    result0[18] = t14*t26*t168;
    result1[18] = t17*t102*t160;
    result0[19] = n*t2*t4*t7*t8*t12*t13*t14*t164*(-4.551111111111111e+1);
    result1[19] = t3*t5*t9*t10*t15*t16*t17*t160*z*(-1.30031746031746e+1);
    result0[20] = t14*t26*t158;
    result1[20] = t17*t38*t160;
    result0[21] = n*t2*t4*t7*t8*t12*t13*t14*t159*(-4.551111111111111e+1);
    result1[21] = t3*t5*t9*t11*t15*t16*t17*t160*z*(-9.102222222222222e+1);
    result0[22] = t14*t26*t171;
    result1[22] = t17*t112*t160;
    result0[23] = n*t2*t4*t7*t8*t12*t13*t14*t155*(-4.551111111111111e+1);
    result1[23] = t3*t5*t9*t10*t11*t15*t17*t160*z*(-9.102222222222222e+1);
    result0[24] = t14*t26*t154;
    result1[24] = t17*t22*t160;
    result0[25] = n*t2*t4*t7*t8*t12*t13*t14*t162*(-4.551111111111111e+1);
    result1[25] = t3*t5*t9*t10*t11*t15*t16*t160*z*(-1.30031746031746e+1);
    result0[26] = t14*t26*t166;
    result1[26] = t17*t82*t160;
    result0[27] = n*t2*t4*t6*t8*t12*t13*t14*t168*(-9.102222222222222e+1);
    result1[27] = t5*t9*t10*t11*t15*t16*t17*t161*z*(-5.12e+2/3.15e+2);
    result0[28] = t14*t31*t164;
    result1[28] = t17*t67*t161;
    result0[29] = n*t2*t4*t6*t8*t12*t13*t14*t158*(-9.102222222222222e+1);
    result1[29] = t3*t5*t10*t11*t15*t16*t17*t161*z*(-4.551111111111111e+1);
    result0[30] = t14*t31*t159;
    result1[30] = t17*t43*t161;
    result0[31] = n*t2*t4*t6*t8*t12*t13*t14*t171*(-9.102222222222222e+1);
    result1[31] = t3*t5*t9*t10*t11*t15*t16*t17*t161*(-1.137777777777778e+2);
    result0[32] = t14*t31*t155;
    result1[32] = t17*t24*t161;
    result0[33] = n*t2*t4*t6*t8*t12*t13*t14*t154*(-9.102222222222222e+1);
    result1[33] = t3*t5*t9*t10*t11*t16*t17*t161*z*(-4.551111111111111e+1);
    result0[34] = t14*t31*t162;
    result1[34] = t16*t48*t161;
    result0[35] = n*t2*t4*t6*t8*t12*t13*t14*t166*(-9.102222222222222e+1);
    result1[35] = t3*t9*t10*t11*t15*t16*t17*t161*z*(-5.12e+2/3.15e+2);
    result0[36] = t14*t125*t168;
    result1[36] = t17*t102*t170;
    result0[37] = t2*t4*t6*t7*t8*t12*t13*t14*t164*(-1.137777777777778e+2);
    result1[37] = t3*t5*t9*t10*t15*t16*t17*t170*z*(-1.30031746031746e+1);
    result0[38] = t14*t125*t158;
    result1[38] = t17*t38*t170;
    result0[39] = t2*t4*t6*t7*t8*t12*t13*t14*t159*(-1.137777777777778e+2);
    result1[39] = t3*t5*t9*t11*t15*t16*t17*t170*z*(-9.102222222222222e+1);
    result0[40] = t14*t125*t171;
    result1[40] = t17*t112*t170;
    result0[41] = t2*t4*t6*t7*t8*t12*t13*t14*t155*(-1.137777777777778e+2);
    result1[41] = t3*t5*t9*t10*t11*t15*t17*t170*z*(-9.102222222222222e+1);
    result0[42] = t14*t125*t154;
    result1[42] = t17*t22*t170;
    result0[43] = t2*t4*t6*t7*t8*t12*t13*t14*t162*(-1.137777777777778e+2);
    result1[43] = t3*t5*t9*t10*t11*t15*t16*t170*z*(-1.30031746031746e+1);
    result0[44] = t14*t125*t166;
    result1[44] = t17*t82*t170;
    result0[45] = n*t2*t4*t6*t7*t8*t12*t14*t168*(-9.102222222222222e+1);
    result1[45] = t5*t9*t10*t11*t15*t16*t17*t157*z*(-5.12e+2/3.15e+2);
    result0[46] = t14*t20*t164;
    result1[46] = t17*t67*t157;
    result0[47] = n*t2*t4*t6*t7*t8*t12*t14*t158*(-9.102222222222222e+1);
    result1[47] = t3*t5*t10*t11*t15*t16*t17*t157*z*(-4.551111111111111e+1);
    result0[48] = t14*t20*t159;
    result1[48] = t17*t43*t157;
    result0[49] = n*t2*t4*t6*t7*t8*t12*t14*t171*(-9.102222222222222e+1);
    result1[49] = t3*t5*t9*t10*t11*t15*t16*t17*t157*(-1.137777777777778e+2);
    result0[50] = t14*t20*t155;
    result1[50] = t17*t24*t157;
    result0[51] = n*t2*t4*t6*t7*t8*t12*t14*t154*(-9.102222222222222e+1);
    result1[51] = t3*t5*t9*t10*t11*t16*t17*t157*z*(-4.551111111111111e+1);
    result0[52] = t14*t20*t162;
    result1[52] = t16*t48*t157;
    result0[53] = n*t2*t4*t6*t7*t8*t12*t14*t166*(-9.102222222222222e+1);
    result1[53] = t3*t9*t10*t11*t15*t16*t17*t157*z*(-5.12e+2/3.15e+2);
    result0[54] = t14*t18*t168;
    result1[54] = t17*t102*t156;
    result0[55] = n*t2*t4*t6*t7*t8*t13*t14*t164*(-4.551111111111111e+1);
    result1[55] = t3*t5*t9*t10*t15*t16*t17*t156*z*(-1.30031746031746e+1);
    result0[56] = t14*t18*t158;
    result1[56] = t17*t38*t156;
    result0[57] = n*t2*t4*t6*t7*t8*t13*t14*t159*(-4.551111111111111e+1);
    result1[57] = t3*t5*t9*t11*t15*t16*t17*t156*z*(-9.102222222222222e+1);
    result0[58] = t14*t18*t171;
    result1[58] = t17*t112*t156;
    result0[59] = n*t2*t4*t6*t7*t8*t13*t14*t155*(-4.551111111111111e+1);
    result1[59] = t3*t5*t9*t10*t11*t15*t17*t156*z*(-9.102222222222222e+1);
    result0[60] = t14*t18*t154;
    result1[60] = t17*t22*t156;
    result0[61] = n*t2*t4*t6*t7*t8*t13*t14*t162*(-4.551111111111111e+1);
    result1[61] = t3*t5*t9*t10*t11*t15*t16*t156*z*(-1.30031746031746e+1);
    result0[62] = t14*t18*t166;
    result1[62] = t17*t82*t156;
    result0[63] = n*t2*t4*t6*t7*t8*t12*t13*t168*(-1.30031746031746e+1);
    result1[63] = t5*t9*t10*t11*t15*t16*t17*t163*z*(-5.12e+2/3.15e+2);
    result0[64] = t13*t36*t164;
    result1[64] = t17*t67*t163;
    result0[65] = n*t2*t4*t6*t7*t8*t12*t13*t158*(-1.30031746031746e+1);
    result1[65] = t3*t5*t10*t11*t15*t16*t17*t163*z*(-4.551111111111111e+1);
    result0[66] = t13*t36*t159;
    result1[66] = t17*t43*t163;
    result0[67] = n*t2*t4*t6*t7*t8*t12*t13*t171*(-1.30031746031746e+1);
    result1[67] = t3*t5*t9*t10*t11*t15*t16*t17*t163*(-1.137777777777778e+2);
    result0[68] = t13*t36*t155;
    result1[68] = t17*t24*t163;
    result0[69] = n*t2*t4*t6*t7*t8*t12*t13*t154*(-1.30031746031746e+1);
    result1[69] = t3*t5*t9*t10*t11*t16*t17*t163*z*(-4.551111111111111e+1);
    result0[70] = t13*t36*t162;
    result1[70] = t16*t48*t163;
    result0[71] = n*t2*t4*t6*t7*t8*t12*t13*t166*(-1.30031746031746e+1);
    result1[71] = t3*t9*t10*t11*t15*t16*t17*t163*z*(-5.12e+2/3.15e+2);
    result0[72] = t14*t72*t168;
    result1[72] = t17*t102*t167;
    result0[73] = n*t2*t6*t7*t8*t12*t13*t14*t164*(-5.12e+2/3.15e+2);
    result1[73] = t3*t5*t9*t10*t15*t16*t17*t167*z*(-1.30031746031746e+1);
    result0[74] = t14*t72*t158;
    result1[74] = t17*t38*t167;
    result0[75] = n*t2*t6*t7*t8*t12*t13*t14*t159*(-5.12e+2/3.15e+2);
    result1[75] = t3*t5*t9*t11*t15*t16*t17*t167*z*(-9.102222222222222e+1);
    result0[76] = t14*t72*t171;
    result1[76] = t17*t112*t167;
    result0[77] = n*t2*t6*t7*t8*t12*t13*t14*t155*(-5.12e+2/3.15e+2);
    result1[77] = t3*t5*t9*t10*t11*t15*t17*t167*z*(-9.102222222222222e+1);
    result0[78] = t14*t72*t154;
    result1[78] = t17*t22*t167;
    result0[79] = n*t2*t6*t7*t8*t12*t13*t14*t162*(-5.12e+2/3.15e+2);
    result1[79] = t3*t5*t9*t10*t11*t15*t16*t167*z*(-1.30031746031746e+1);
    result0[80] = t14*t72*t166;
    result1[80] = t17*t82*t167;

}
