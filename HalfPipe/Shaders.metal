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

#include <metal_stdlib>

using namespace metal;

struct Light
{
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Light light = {
    .direction = { 0.13, 0.72, 0.68 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct Material
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant Material material = {
    .ambientColor = { 0.9, 0.1, 0 },
    .diffuseColor = { 0.5, 0.5, 0.5 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};

struct VertexIn
{
    float4 position;
    float4 normal;
};

struct VertexOut
{
    float4 position [[position]];
    float3 eye;
    float3 normal;
    float4 color;
};


vertex VertexOut myVertexShader(const device VertexIn*  vertices    [[buffer(0)]],
                                constant float4x4*      uniforms    [[buffer(1)]],
                                constant float4*        colors      [[buffer(2)]],
                                uint                    vid         [[vertex_id]])
{
    VertexOut vertexOut;
    vertexOut.position = uniforms[0] * vertices[vid].position;
    vertexOut.eye = -(uniforms[1] * vertices[vid].position).xyz;
    
    float3x3 normalMatrix = float3x3(uniforms[1].columns[0].xyz, uniforms[1].columns[1].xyz, uniforms[1].columns[2].xyz);
    vertexOut.normal = normalMatrix * vertices[vid].normal.xyz;
    
    vertexOut.color = colors[vid];

    return vertexOut;
}

fragment float4 myFragmentShader(VertexOut vert [[stage_in]])
{
    float3 ambientTerm = light.ambientColor * material.ambientColor;
    
    float3 normal = normalize(vert.normal);
    float diffuseIntensity = saturate(dot(normal, light.direction));
    float3 diffuseTerm = light.diffuseColor * material.diffuseColor * diffuseIntensity;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway = normalize(light.direction + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specularTerm = light.specularColor * material.specularColor * specularFactor;
    }
    
    float3 finalColor = ambientTerm + diffuseTerm + specularTerm;
    return float4(finalColor, 1) * vert.color;
}
