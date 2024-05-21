//
//  ModelCoefficients.h
//  HalfPipe
//

#ifndef ModelCoefficients_h
#define ModelCoefficients_h

#define ARGS double const* __nonnull A,double const* __nonnull B,double const* __nonnull D,double const* __nonnull strain0,double const* __nonnull strain1,double const* __nonnull displacements,double const* __nonnull Ddisplacements0,double const* __nonnull Ddisplacements1,double const* __nonnull a1,double const* __nonnull a2,double const* __nonnull nhat,double const* __nonnull Dnhat0,double const* __nonnull Dnhat1

#define CARGS double const* __nonnull A, NSUInteger A_stride,double const* __nonnull B, NSUInteger B_stride,double const* __nonnull D, NSUInteger D_stride,double const* __nonnull strain0, NSUInteger strain0_stride,double const* __nonnull strain1, NSUInteger strain1_stride,double const* __nonnull disps, NSUInteger disps_stride,double const* __nonnull d_disps_0, NSUInteger d_disps_0_stride,double const* __nonnull d_disps_1, NSUInteger d_disps_1_stride,double const* __nonnull a1, NSUInteger a1_stride,double const* __nonnull a2, NSUInteger a2_stride,double const* __nonnull nhat, NSUInteger nhat_stride,double const* __nonnull d_nhat_0, NSUInteger d_nhat_0_stride,double const* __nonnull d_nhat_1, NSUInteger d_nhat_1_stride,NSUInteger N,double* __nonnull result, NSUInteger result_stride

double F1_1(ARGS);
double F1_2(ARGS);
double F1_3(ARGS);
double F2_1(ARGS);
double F2_2(ARGS);
double F2_3(ARGS);
double F3_1(ARGS);
double F3_2(ARGS);
double F3_3(ARGS);
double F4_1(ARGS);
double F4_2(ARGS);
double F4_3(ARGS);
double F5_1(ARGS);
double F5_2(ARGS);
double F5_3(ARGS);
double F6_1(ARGS);
double F6_2(ARGS);
double F6_3(ARGS);
double F7_1(ARGS);
double F7_2(ARGS);
double F7_3(ARGS);

void ComputeSubCoefficientF1(CARGS);
void ComputeSubCoefficientF2(CARGS);
void ComputeSubCoefficientF3(CARGS);

double K11_11(ARGS);
double K11_12(ARGS);
double K11_13(ARGS);
double K11_21(ARGS);
double K11_22(ARGS);
double K11_23(ARGS);
double K11_31(ARGS);
double K11_32(ARGS);
double K11_33(ARGS);

double K12_11(ARGS);
double K12_12(ARGS);
double K12_13(ARGS);
double K12_21(ARGS);
double K12_22(ARGS);
double K12_23(ARGS);
double K12_31(ARGS);
double K12_32(ARGS);
double K12_33(ARGS);

double K13_11(ARGS);
double K13_12(ARGS);
double K13_13(ARGS);
double K13_21(ARGS);
double K13_22(ARGS);
double K13_23(ARGS);
double K13_31(ARGS);
double K13_32(ARGS);
double K13_33(ARGS);

double K14_11(ARGS);
double K14_12(ARGS);
double K14_13(ARGS);
double K14_21(ARGS);
double K14_22(ARGS);
double K14_23(ARGS);
double K14_31(ARGS);
double K14_32(ARGS);
double K14_33(ARGS);

double K15_11(ARGS);
double K15_12(ARGS);
double K15_13(ARGS);
double K15_21(ARGS);
double K15_22(ARGS);
double K15_23(ARGS);
double K15_31(ARGS);
double K15_32(ARGS);
double K15_33(ARGS);

double K16_11(ARGS);
double K16_12(ARGS);
double K16_13(ARGS);
double K16_21(ARGS);
double K16_22(ARGS);
double K16_23(ARGS);
double K16_31(ARGS);
double K16_32(ARGS);
double K16_33(ARGS);

double K17_11(ARGS);
double K17_12(ARGS);
double K17_13(ARGS);
double K17_21(ARGS);
double K17_22(ARGS);
double K17_23(ARGS);
double K17_31(ARGS);
double K17_32(ARGS);
double K17_33(ARGS);

double K21_11(ARGS);
double K21_12(ARGS);
double K21_13(ARGS);
double K21_21(ARGS);
double K21_22(ARGS);
double K21_23(ARGS);
double K21_31(ARGS);
double K21_32(ARGS);
double K21_33(ARGS);

double K22_11(ARGS);
double K22_12(ARGS);
double K22_13(ARGS);
double K22_21(ARGS);
double K22_22(ARGS);
double K22_23(ARGS);
double K22_31(ARGS);
double K22_32(ARGS);
double K22_33(ARGS);

double K23_11(ARGS);
double K23_12(ARGS);
double K23_13(ARGS);
double K23_21(ARGS);
double K23_22(ARGS);
double K23_23(ARGS);
double K23_31(ARGS);
double K23_32(ARGS);
double K23_33(ARGS);

double K24_11(ARGS);
double K24_12(ARGS);
double K24_13(ARGS);
double K24_21(ARGS);
double K24_22(ARGS);
double K24_23(ARGS);
double K24_31(ARGS);
double K24_32(ARGS);
double K24_33(ARGS);

double K25_11(ARGS);
double K25_12(ARGS);
double K25_13(ARGS);
double K25_21(ARGS);
double K25_22(ARGS);
double K25_23(ARGS);
double K25_31(ARGS);
double K25_32(ARGS);
double K25_33(ARGS);

double K26_11(ARGS);
double K26_12(ARGS);
double K26_13(ARGS);
double K26_21(ARGS);
double K26_22(ARGS);
double K26_23(ARGS);
double K26_31(ARGS);
double K26_32(ARGS);
double K26_33(ARGS);

double K27_11(ARGS);
double K27_12(ARGS);
double K27_13(ARGS);
double K27_21(ARGS);
double K27_22(ARGS);
double K27_23(ARGS);
double K27_31(ARGS);
double K27_32(ARGS);
double K27_33(ARGS);

double K31_11(ARGS);
double K31_12(ARGS);
double K31_13(ARGS);
double K31_21(ARGS);
double K31_22(ARGS);
double K31_23(ARGS);
double K31_31(ARGS);
double K31_32(ARGS);
double K31_33(ARGS);

double K32_11(ARGS);
double K32_12(ARGS);
double K32_13(ARGS);
double K32_21(ARGS);
double K32_22(ARGS);
double K32_23(ARGS);
double K32_31(ARGS);
double K32_32(ARGS);
double K32_33(ARGS);

double K33_11(ARGS);
double K33_12(ARGS);
double K33_13(ARGS);
double K33_21(ARGS);
double K33_22(ARGS);
double K33_23(ARGS);
double K33_31(ARGS);
double K33_32(ARGS);
double K33_33(ARGS);

double K34_11(ARGS);
double K34_12(ARGS);
double K34_13(ARGS);
double K34_21(ARGS);
double K34_22(ARGS);
double K34_23(ARGS);
double K34_31(ARGS);
double K34_32(ARGS);
double K34_33(ARGS);

double K35_11(ARGS);
double K35_12(ARGS);
double K35_13(ARGS);
double K35_21(ARGS);
double K35_22(ARGS);
double K35_23(ARGS);
double K35_31(ARGS);
double K35_32(ARGS);
double K35_33(ARGS);

double K36_11(ARGS);
double K36_12(ARGS);
double K36_13(ARGS);
double K36_21(ARGS);
double K36_22(ARGS);
double K36_23(ARGS);
double K36_31(ARGS);
double K36_32(ARGS);
double K36_33(ARGS);

double K37_11(ARGS);
double K37_12(ARGS);
double K37_13(ARGS);
double K37_21(ARGS);
double K37_22(ARGS);
double K37_23(ARGS);
double K37_31(ARGS);
double K37_32(ARGS);
double K37_33(ARGS);

double K41_11(ARGS);
double K41_12(ARGS);
double K41_13(ARGS);
double K41_21(ARGS);
double K41_22(ARGS);
double K41_23(ARGS);
double K41_31(ARGS);
double K41_32(ARGS);
double K41_33(ARGS);

double K42_11(ARGS);
double K42_12(ARGS);
double K42_13(ARGS);
double K42_21(ARGS);
double K42_22(ARGS);
double K42_23(ARGS);
double K42_31(ARGS);
double K42_32(ARGS);
double K42_33(ARGS);

double K43_11(ARGS);
double K43_12(ARGS);
double K43_13(ARGS);
double K43_21(ARGS);
double K43_22(ARGS);
double K43_23(ARGS);
double K43_31(ARGS);
double K43_32(ARGS);
double K43_33(ARGS);

double K44_11(ARGS);
double K44_12(ARGS);
double K44_13(ARGS);
double K44_21(ARGS);
double K44_22(ARGS);
double K44_23(ARGS);
double K44_31(ARGS);
double K44_32(ARGS);
double K44_33(ARGS);

double K45_11(ARGS);
double K45_12(ARGS);
double K45_13(ARGS);
double K45_21(ARGS);
double K45_22(ARGS);
double K45_23(ARGS);
double K45_31(ARGS);
double K45_32(ARGS);
double K45_33(ARGS);

double K46_11(ARGS);
double K46_12(ARGS);
double K46_13(ARGS);
double K46_21(ARGS);
double K46_22(ARGS);
double K46_23(ARGS);
double K46_31(ARGS);
double K46_32(ARGS);
double K46_33(ARGS);

double K47_11(ARGS);
double K47_12(ARGS);
double K47_13(ARGS);
double K47_21(ARGS);
double K47_22(ARGS);
double K47_23(ARGS);
double K47_31(ARGS);
double K47_32(ARGS);
double K47_33(ARGS);

double K51_11(ARGS);
double K51_12(ARGS);
double K51_13(ARGS);
double K51_21(ARGS);
double K51_22(ARGS);
double K51_23(ARGS);
double K51_31(ARGS);
double K51_32(ARGS);
double K51_33(ARGS);

double K52_11(ARGS);
double K52_12(ARGS);
double K52_13(ARGS);
double K52_21(ARGS);
double K52_22(ARGS);
double K52_23(ARGS);
double K52_31(ARGS);
double K52_32(ARGS);
double K52_33(ARGS);

double K53_11(ARGS);
double K53_12(ARGS);
double K53_13(ARGS);
double K53_21(ARGS);
double K53_22(ARGS);
double K53_23(ARGS);
double K53_31(ARGS);
double K53_32(ARGS);
double K53_33(ARGS);

double K54_11(ARGS);
double K54_12(ARGS);
double K54_13(ARGS);
double K54_21(ARGS);
double K54_22(ARGS);
double K54_23(ARGS);
double K54_31(ARGS);
double K54_32(ARGS);
double K54_33(ARGS);

double K55_11(ARGS);
double K55_12(ARGS);
double K55_13(ARGS);
double K55_21(ARGS);
double K55_22(ARGS);
double K55_23(ARGS);
double K55_31(ARGS);
double K55_32(ARGS);
double K55_33(ARGS);

double K56_11(ARGS);
double K56_12(ARGS);
double K56_13(ARGS);
double K56_21(ARGS);
double K56_22(ARGS);
double K56_23(ARGS);
double K56_31(ARGS);
double K56_32(ARGS);
double K56_33(ARGS);

double K57_11(ARGS);
double K57_12(ARGS);
double K57_13(ARGS);
double K57_21(ARGS);
double K57_22(ARGS);
double K57_23(ARGS);
double K57_31(ARGS);
double K57_32(ARGS);
double K57_33(ARGS);

double K61_11(ARGS);
double K61_12(ARGS);
double K61_13(ARGS);
double K61_21(ARGS);
double K61_22(ARGS);
double K61_23(ARGS);
double K61_31(ARGS);
double K61_32(ARGS);
double K61_33(ARGS);

double K62_11(ARGS);
double K62_12(ARGS);
double K62_13(ARGS);
double K62_21(ARGS);
double K62_22(ARGS);
double K62_23(ARGS);
double K62_31(ARGS);
double K62_32(ARGS);
double K62_33(ARGS);

double K63_11(ARGS);
double K63_12(ARGS);
double K63_13(ARGS);
double K63_21(ARGS);
double K63_22(ARGS);
double K63_23(ARGS);
double K63_31(ARGS);
double K63_32(ARGS);
double K63_33(ARGS);

double K64_11(ARGS);
double K64_12(ARGS);
double K64_13(ARGS);
double K64_21(ARGS);
double K64_22(ARGS);
double K64_23(ARGS);
double K64_31(ARGS);
double K64_32(ARGS);
double K64_33(ARGS);

double K65_11(ARGS);
double K65_12(ARGS);
double K65_13(ARGS);
double K65_21(ARGS);
double K65_22(ARGS);
double K65_23(ARGS);
double K65_31(ARGS);
double K65_32(ARGS);
double K65_33(ARGS);

double K66_11(ARGS);
double K66_12(ARGS);
double K66_13(ARGS);
double K66_21(ARGS);
double K66_22(ARGS);
double K66_23(ARGS);
double K66_31(ARGS);
double K66_32(ARGS);
double K66_33(ARGS);

double K67_11(ARGS);
double K67_12(ARGS);
double K67_13(ARGS);
double K67_21(ARGS);
double K67_22(ARGS);
double K67_23(ARGS);
double K67_31(ARGS);
double K67_32(ARGS);
double K67_33(ARGS);

double K71_11(ARGS);
double K71_12(ARGS);
double K71_13(ARGS);
double K71_21(ARGS);
double K71_22(ARGS);
double K71_23(ARGS);
double K71_31(ARGS);
double K71_32(ARGS);
double K71_33(ARGS);

double K72_11(ARGS);
double K72_12(ARGS);
double K72_13(ARGS);
double K72_21(ARGS);
double K72_22(ARGS);
double K72_23(ARGS);
double K72_31(ARGS);
double K72_32(ARGS);
double K72_33(ARGS);

double K73_11(ARGS);
double K73_12(ARGS);
double K73_13(ARGS);
double K73_21(ARGS);
double K73_22(ARGS);
double K73_23(ARGS);
double K73_31(ARGS);
double K73_32(ARGS);
double K73_33(ARGS);

double K74_11(ARGS);
double K74_12(ARGS);
double K74_13(ARGS);
double K74_21(ARGS);
double K74_22(ARGS);
double K74_23(ARGS);
double K74_31(ARGS);
double K74_32(ARGS);
double K74_33(ARGS);

double K75_11(ARGS);
double K75_12(ARGS);
double K75_13(ARGS);
double K75_21(ARGS);
double K75_22(ARGS);
double K75_23(ARGS);
double K75_31(ARGS);
double K75_32(ARGS);
double K75_33(ARGS);

double K76_11(ARGS);
double K76_12(ARGS);
double K76_13(ARGS);
double K76_21(ARGS);
double K76_22(ARGS);
double K76_23(ARGS);
double K76_31(ARGS);
double K76_32(ARGS);
double K76_33(ARGS);

double K77_11(ARGS);
double K77_12(ARGS);
double K77_13(ARGS);
double K77_21(ARGS);
double K77_22(ARGS);
double K77_23(ARGS);
double K77_31(ARGS);
double K77_32(ARGS);
double K77_33(ARGS);


void ComputeSubCoefficientK11(CARGS);
void ComputeSubCoefficientK12(CARGS);
void ComputeSubCoefficientK13(CARGS);
void ComputeSubCoefficientK21(CARGS);
void ComputeSubCoefficientK22(CARGS);
void ComputeSubCoefficientK23(CARGS);
void ComputeSubCoefficientK31(CARGS);
void ComputeSubCoefficientK32(CARGS);
void ComputeSubCoefficientK33(CARGS);

#endif /* ModelCoefficients_h */
