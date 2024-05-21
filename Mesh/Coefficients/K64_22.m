#import <Foundation/Foundation.h>
typedef double RealType;

RealType K64_22(RealType const* __nonnull A,
		RealType const* __nonnull B,
		RealType const* __nonnull D,
		RealType const* __nonnull strain0,
		RealType const* __nonnull strain1,
		RealType const* __nonnull displacements,
		RealType const* __nonnull d_displacements0,
		RealType const* __nonnull d_displacements1,
		RealType const* __nonnull a1,
		RealType const* __nonnull a2,
		RealType const* __nonnull nhat,
		RealType const* __nonnull dnhat0,
		RealType const* __nonnull dnhat1)
{
    RealType A1_1 = A[0];
    RealType A1_2 = A[1];
    RealType A1_3 = A[2];
    RealType A1_4 = A[3];
    RealType A1_5 = A[4];
    RealType A1_6 = A[5];
    RealType A2_2 = A[6];
    RealType A2_3 = A[7];
    RealType A2_4 = A[8];
    RealType A2_5 = A[9];
    RealType A2_6 = A[10];
    RealType A3_3 = A[11];
    RealType A3_4 = A[12];
    RealType A3_5 = A[13];
    RealType A3_6 = A[14];
    RealType A4_4 = A[15];
    RealType A4_5 = A[16];
    RealType A4_6 = A[17];
    RealType A5_5 = A[18];
    RealType A5_6 = A[19];
    RealType A6_6 = A[20];
    RealType B1_1 = B[0];
    RealType B1_2 = B[1];
    RealType B1_3 = B[2];
    RealType B1_4 = B[3];
    RealType B1_5 = B[4];
    RealType B1_6 = B[5];
    RealType B2_2 = B[6];
    RealType B2_3 = B[7];
    RealType B2_4 = B[8];
    RealType B2_5 = B[9];
    RealType B2_6 = B[10];
    RealType B3_3 = B[11];
    RealType B3_4 = B[12];
    RealType B3_5 = B[13];
    RealType B3_6 = B[14];
    RealType B4_4 = B[15];
    RealType B4_5 = B[16];
    RealType B4_6 = B[17];
    RealType B5_5 = B[18];
    RealType B5_6 = B[19];
    RealType B6_6 = B[20];
    RealType D1_1 = D[0];
    RealType D1_2 = D[1];
    RealType D1_3 = D[2];
    RealType D1_4 = D[3];
    RealType D1_5 = D[4];
    RealType D1_6 = D[5];
    RealType D2_2 = D[6];
    RealType D2_3 = D[7];
    RealType D2_4 = D[8];
    RealType D2_5 = D[9];
    RealType D2_6 = D[10];
    RealType D3_3 = D[11];
    RealType D3_4 = D[12];
    RealType D3_5 = D[13];
    RealType D3_6 = D[14];
    RealType D4_4 = D[15];
    RealType D4_5 = D[16];
    RealType D4_6 = D[17];
    RealType D5_5 = D[18];
    RealType D5_6 = D[19];
    RealType D6_6 = D[20];
    RealType eps_11_0 = strain0[0];
    RealType eps_22_0 = strain0[1];
    RealType eps_33_0 = strain0[2];
    RealType gam_23_0 = strain0[3];
    RealType gam_13_0 = strain0[4];
    RealType gam_12_0 = strain0[5];
    RealType eps_11_1 = strain1[0];
    RealType eps_22_1 = strain1[1];
    RealType eps_33_1 = strain1[2];
    RealType gam_23_1 = strain1[3];
    RealType gam_13_1 = strain1[4];
    RealType gam_12_1 = strain1[5];
    RealType u = displacements[0];
    RealType v = displacements[1];
    RealType w = displacements[2];
    RealType phi1 = displacements[3];
    RealType phi2 = displacements[4];
    RealType phi3 = displacements[5];
    RealType theta = displacements[6];
    RealType dubar_dz1 = d_displacements0[0];
    RealType dubar_dz2 = d_displacements0[1];
    RealType dubar_dz3 = d_displacements0[2];
    RealType dphi_dz1 = d_displacements0[3];
    RealType dphi_dz2 = d_displacements0[4];
    RealType dphi_dz3 = d_displacements0[5];
    RealType dubar_dn1 = d_displacements1[0];
    RealType dubar_dn2 = d_displacements1[1];
    RealType dubar_dn3 = d_displacements1[2];
    RealType dphi_dn1 = d_displacements1[3];
    RealType dphi_dn2 = d_displacements1[4];
    RealType dphi_dn3 = d_displacements1[5];
    RealType a11 = a1[0];
    RealType a12 = a1[1];
    RealType a13 = a1[2];
    RealType a21 = a2[0];
    RealType a22 = a2[1];
    RealType a23 = a2[2];
    RealType nhat1 = nhat[0];
    RealType nhat2 = nhat[1];
    RealType nhat3 = nhat[2];
    RealType dnhat_dz1 = dnhat0[0];
    RealType dnhat_dz2 = dnhat0[1];
    RealType dnhat_dz3 = dnhat0[2];
    RealType dnhat_dn1 = dnhat1[0];
    RealType dnhat_dn2 = dnhat1[1];
    RealType dnhat_dn3 = dnhat1[2];

    RealType   t0 = (a13+dubar_dz3)*(D1_1*(a11+dubar_dz1)+D1_6*(a21+dubar_dn1)+D1_5*(nhat1+phi1))+(a23+dubar_dn3)*(D1_6*(a11+dubar_dz1)+D6_6*(a21+dubar_dn1)+D5_6*(nhat1+phi1))+(nhat3+phi3)*(D1_5*(a11+dubar_dz1)+D5_6*(a21+dubar_dn1)+D5_5*(nhat1+phi1));

    return t0;
}
