/*
 *  These implementations obtained from Metal By Example sample code.
 *
 *  Copyright (c) 2015 Warren Moore
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 */

#import <Foundation/Foundation.h>

#import "Utilities.h"

matrix_float4x4 matrix_float4x4_translation(vector_float3 t)
{
    vector_float4 X = {1.0f, 0.0f, 0.0f, 0.0f};
    vector_float4 Y = {0.0f, 1.0f, 0.0f, 0.0f};
    vector_float4 Z = {0.0f, 0.0f, 1.0f, 0.0f};
    vector_float4 W = {t.x,  t.y,  t.z,  1.0f};
    
    return (matrix_float4x4){X, Y, Z, W};
}

matrix_float4x4 matrix_float4x4_scale(float scale)
{
    vector_float4 X = {scale, 0.0f, 0.0f, 0.0f};
    vector_float4 Y = {0.0f, scale, 0.0f, 0.0f};
    vector_float4 Z = {0.0f, 0.0f, scale, 0.0f};
    vector_float4 W = {0.0f, 0.0f,  0.0f, 1.0f};
    
    return (matrix_float4x4){X, Y, Z, W};
}

matrix_float4x4 matrix_float4x4_rotation(vector_float3 axis, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    
    vector_float4 X;
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z * s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    vector_float4 Y;
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    vector_float4 Z;
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    vector_float4 W;
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

matrix_float4x4 matrix_float4x4_perspective(float aspect, float fovy, float near, float far)
{
    float yScale = 1 / tan(fovy * 0.5);
    float xScale = yScale / aspect;
    float zRange = far - near;
    float zScale = -(far + near) / zRange;
    float wzScale = -2 * far * near / zRange;

    vector_float4 P = { xScale, 0, 0, 0 };
    vector_float4 Q = { 0, yScale, 0, 0 };
    vector_float4 R = { 0, 0, zScale, -1 };
    vector_float4 S = { 0, 0, wzScale, 0 };

    matrix_float4x4 mat = { P, Q, R, S };
    return mat;
}
