//
//  SurfaceRenderer.m
//  HalfPipe
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import <Accelerate/Accelerate.h>

#include <stdatomic.h>

#import <AdaptableFiniteElementKit/AdaptableFiniteElementKit.h>

#import "SurfaceRenderer.h"
#import "GeometryGeneration.h"
#import "Utilities.h"

#import "Element.h"
#import "Model.h"

#import "TriangulateElement.h"


@implementation SurfaceRenderer
{
    id<MTLDevice>               _device;
    
    id<MTLRenderPipelineState>  _pipeline_state;
    
    id<MTLCommandQueue>         _command_queue;
    
    vector_uint2                _viewport_size;
    
    NSUInteger                  _num_vertices;
    NSUInteger                  _verts_per_elem;
    
    
    id<MTLBuffer>               _matrices;
    
    AFEKMesh*                    _solver_mesh;
    
    NSUInteger                  _mid_elem;
    
    double                      _load_increment;
    NSUInteger                  _max_load_steps;
    atomic_uint*                _load_step;
    
    NSUInteger                  _num_elems;
    NSUInteger*                 _elements;
    
    vector_float4*              _orig_render_verts;
    id<MTLBuffer>               _render_verts;
    id<MTLBuffer>               _render_triangles;
    NSUInteger                  _num_render_triangles;
    NSUInteger                  _rendering_verts_per_elem;
    
    double*                     _sf;
    
    // Temporary workspace arrays.
    double*                     _p_reordered_soln;
    double*                     _p_elem_nodal_soln;
    double*                     _p_elem_render_soln;
}
  
-(nonnull instancetype) initWithMetalKitView: (MTKView* __nonnull) mtkView
{
    self = [super init];
    if (self == nil)
        return nil;
    
    NSUInteger const elem_order = 8;
    NSUInteger const num_elems_x = 8;
    NSUInteger const num_elems_y = 8;
    
    NSUInteger const rendering_triangles_per_side = 8;
    
    _load_increment = -15.0;
    
    _max_load_steps = 200;
    
    double const length = 10.35;
    double const radius = 4.953;
    
    MaterialParameters material = (MaterialParameters){
        .youngsModulus = 10.5E6,
        .poissonsRatio = .3125,
        .thickness = .094
    };
    
    
    _device = mtkView.device;
    
    _command_queue = [_device newCommandQueue];
    
    id<MTLLibrary> library = [_device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor* pipeline_desc = [MTLRenderPipelineDescriptor new];
    
    pipeline_desc.vertexFunction = [library newFunctionWithName: @"myVertexShader"];
    pipeline_desc.fragmentFunction = [library newFunctionWithName:@"myFragmentShader"];
    
    pipeline_desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipeline_desc.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    @autoreleasepool
    {
        NSError* error = nil;
        _pipeline_state = [_device newRenderPipelineStateWithDescriptor: pipeline_desc
                                                                 error: &error];
    }
    
    [pipeline_desc release];
    
    [library release];
    
    // Initialize geometry.
    _num_elems = num_elems_x * num_elems_y;
    
    NSUInteger num_bcs;
    _num_vertices = getNodeCount(elem_order, num_elems_x, num_elems_y, &num_bcs);
    
    NSUInteger verts_per_side = elem_order + 1;
    _verts_per_elem = verts_per_side * verts_per_side;
    
    _elements = (NSUInteger*)malloc(_num_elems * _verts_per_elem * sizeof(NSUInteger));
    double* positions = (double*)malloc(_num_vertices * 3 * sizeof(double));
    double* normals = (double*)malloc(_num_vertices * 3 * sizeof(double));
    
    NSUInteger* bc_verts = (NSUInteger*)malloc(num_bcs * sizeof(NSUInteger));
    generateGeometry(elem_order, length, radius, num_elems_x, num_elems_y, _elements, positions, normals, bc_verts);
    
    matrix_float4x4 rotate_x = matrix_float4x4_rotation((vector_float3){1.0, 0.0, 0.0}, 40.0*M_PI/180.0);
    matrix_float4x4 rotate_y = matrix_float4x4_rotation((vector_float3){0.0, 1.0, 0.0}, -M_PI/8.0);
    matrix_float4x4 model_matrix = matrix_multiply(rotate_y, rotate_x);
    matrix_float4x4 view_matrix = matrix_float4x4_translation((vector_float3){0, 0, -15});
    matrix_float4x4 projection_matrix = matrix_float4x4_perspective(1.0f, (2.0f * M_PI) / 5.0f, 1.0f, 100.0f);
    
    matrix_float4x4 mv_matrix = matrix_multiply(view_matrix, model_matrix);
    matrix_float4x4 mvp_matrix = matrix_multiply(projection_matrix, mv_matrix);
    
    _matrices = [_device newBufferWithLength: 2*sizeof(matrix_float4x4)
                                    options: MTLResourceStorageModeShared];
    
    matrix_float4x4* p_matrices = (matrix_float4x4*)[_matrices contents];
    p_matrices[0] = mvp_matrix;
    p_matrices[1] = mv_matrix;
    
    // Initialize the solver and model.
    Element* q81_element = [[Element alloc] init];
    
    Model*   shell_model = [[Model alloc] initWithMaterialParameters: material];
    
    _solver_mesh = [[AFEKMesh alloc] initWithElements: _elements
                                      elementStride: _verts_per_elem
                                        elementType: q81_element
                                        coordinates: positions
                                            normals: normals
                                   numberOfElements: _num_elems
                                   numberOfVertices: _num_vertices
                                              model: shell_model
                                             dataType: AFEKDataTypeFloat64];
    
    // Apply boundary conditions.
    for (NSUInteger i = 0; i < num_bcs; ++i)
        [_solver_mesh fixNode: bc_verts[i]];
    
    // Prepare a rendering triangle mesh.
    NSUInteger total_sqrs = rendering_triangles_per_side * rendering_triangles_per_side;
    NSUInteger total_tris = total_sqrs * 2;
    NSUInteger rendering_verts_per_side = rendering_triangles_per_side + 1;
    _rendering_verts_per_elem = rendering_verts_per_side * rendering_verts_per_side;
    
    vector_double2* elem_triangle_verts = (vector_double2*)malloc(_rendering_verts_per_elem * sizeof(vector_double2));
    NSUInteger* elem_triangles = (NSUInteger*)malloc(3 * total_tris * sizeof(NSUInteger));
    
    _render_verts = [_device newBufferWithLength: 2 * _num_elems * _rendering_verts_per_elem * sizeof(vector_float4)
                                         options: MTLResourceStorageModeShared];
    _render_triangles = [_device newBufferWithLength: 3 * _num_elems * total_tris * sizeof(uint32_t)
                                             options: MTLResourceStorageModeShared];
    
    _orig_render_verts = (vector_float4*)malloc(2*_num_elems*_rendering_verts_per_elem*sizeof(vector_float4));
    
    _num_render_triangles = _num_elems * total_tris;
    
    GenerateTriangles(rendering_triangles_per_side, 0, elem_triangle_verts, elem_triangles);
    
    // Interpolating functions to get the rendering vertices.
    _sf = (double*)malloc(_rendering_verts_per_elem * _verts_per_elem * sizeof(double));
    double* ldsf0 = (double*)malloc(_rendering_verts_per_elem * _verts_per_elem * sizeof(double));
    double* ldsf1 = (double*)malloc(_rendering_verts_per_elem * _verts_per_elem * sizeof(double));
    [q81_element generateShapeValuesAtPoints: elem_triangle_verts
                             numberOfPoints: _rendering_verts_per_elem
                               shapeResults: _sf
                     localDiffShape1Results: ldsf0
                     localDiffShape2Results: ldsf1
                             shapeRowStride: _verts_per_elem];
    
    double* temp = (double*)malloc(_verts_per_elem * 3 * sizeof(double));
    double* temp2 = (double*)malloc(_rendering_verts_per_elem * 3 * sizeof(double));
    uint32_t* p_render_triangles = (uint32_t*)[_render_triangles contents];
    vector_float4* p_render_verts = (vector_float4*)[_render_verts contents];
    for (NSUInteger i = 0; i < _num_elems; ++i)
    {
        NSUInteger const* p_element = _elements + i*_verts_per_elem;
        vector_float4* p_rverts = p_render_verts + 2*i*_rendering_verts_per_elem;
        vector_float4* p_orig_rverts = _orig_render_verts + 2*i*_rendering_verts_per_elem;
        uint32_t* p_tris = p_render_triangles + 3*i*total_tris;
        uint32_t tri_elem_offset = (uint32_t)(i*_rendering_verts_per_elem);
        
        // Collect nodal coordinates for element i.
        for (NSUInteger j = 0; j < _verts_per_elem; ++j)
        {
            NSUInteger vert = p_element[j];
            temp[3*j + 0] = positions[3*vert + 0];
            temp[3*j + 1] = positions[3*vert + 1];
            temp[3*j + 2] = positions[3*vert + 2];
        }
        
        // Interpolate to this element's rendering points.
        cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, (int)_rendering_verts_per_elem, 3, (int)_verts_per_elem, 1.0, _sf, (int)_verts_per_elem, temp, 3, 0.0, temp2, 3);
        
        for (NSUInteger j = 0; j < _rendering_verts_per_elem; ++j)
        {
            p_rverts[2*j + 0].x = temp2[3*j + 0];
            p_rverts[2*j + 0].y = temp2[3*j + 1];
            p_rverts[2*j + 0].z = temp2[3*j + 2];
            p_rverts[2*j + 0].w = 1.0f;
            
            p_orig_rverts[2*j + 0].x = temp2[3*j + 0];
            p_orig_rverts[2*j + 0].y = temp2[3*j + 1];
            p_orig_rverts[2*j + 0].z = temp2[3*j + 2];
            p_orig_rverts[2*j + 0].w = 1.0f;
        }
        
        // And normals
        for (NSUInteger j = 0; j < _verts_per_elem; ++j)
        {
            NSUInteger vert = p_element[j];
            temp[3*j + 0] = normals[3*vert + 0];
            temp[3*j + 1] = normals[3*vert + 1];
            temp[3*j + 2] = normals[3*vert + 2];
        }
        
        // Interpolate to this element's rendering points.
        cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, (int)_rendering_verts_per_elem, 3, (int)_verts_per_elem, 1.0, _sf, (int)_verts_per_elem, temp, 3, 0.0, temp2, 3);
        
        for (NSUInteger j = 0; j < _rendering_verts_per_elem; ++j)
        {
            p_rverts[2*j + 1].x = temp2[3*j + 0];
            p_rverts[2*j + 1].y = temp2[3*j + 1];
            p_rverts[2*j + 1].z = temp2[3*j + 2];
            p_rverts[2*j + 1].w = 1.0f;
            
            p_orig_rverts[2*j + 1].x = temp2[3*j + 0];
            p_orig_rverts[2*j + 1].y = temp2[3*j + 1];
            p_orig_rverts[2*j + 1].z = temp2[3*j + 2];
            p_orig_rverts[2*j + 1].w = 1.0f;
        }
        
        for (NSUInteger j = 0; j < total_tris; ++j)
        {
            p_tris[3*j + 0] = (uint32_t)elem_triangles[3*j + 0] + tri_elem_offset;
            p_tris[3*j + 1] = (uint32_t)elem_triangles[3*j + 1] + tri_elem_offset;
            p_tris[3*j + 2] = (uint32_t)elem_triangles[3*j + 2] + tri_elem_offset;
        }
    }
    free(temp);
    free(temp2);
    
    free(ldsf0);
    free(ldsf1);
    free(elem_triangle_verts);
    free(elem_triangles);
    
    
    free(positions);
    free(normals);
    free(bc_verts);
    
    [q81_element release];
    [shell_model release];
    
    // Apply a force.
    _mid_elem = ((num_elems_y >> 1) - 1) * num_elems_x;
    [_solver_mesh applyPointForce: (vector_double3){0.0, 0.0, _load_increment}
                         element: _mid_elem
                        location: (vector_double3){-1.0, 1.0, 1.0}];
    
    _load_step = (atomic_uint*)malloc(sizeof(atomic_uint));
    atomic_store_explicit(_load_step, 1, memory_order_relaxed);
    
    _p_reordered_soln = (double*)malloc(_num_vertices*7*sizeof(double));
    _p_elem_nodal_soln = (double*)malloc(_verts_per_elem * 7 * sizeof(double));
    _p_elem_render_soln = (double*)malloc(_rendering_verts_per_elem * 7 * sizeof(double));
    
    return self;
}

-(void) dealloc
{
    [_device release];
    [_command_queue release];
    
    [_pipeline_state release];
    
    [_matrices release];
    
    [_solver_mesh release];
    
    free(_load_step);
    
    [_render_verts release];
    [_render_triangles release];
    
    free(_elements);
    free(_sf);
    
    free(_orig_render_verts);
    
    free(_p_reordered_soln);
    free(_p_elem_nodal_soln);
    free(_p_elem_render_soln);
    
    [super dealloc];
}

-(void)drawInMTKView: (nonnull MTKView*) view
{
    // Run the simulation for a single iteration.
    if (atomic_load_explicit(_load_step, memory_order_relaxed) < _max_load_steps)
    {
        [_solver_mesh runIterationWithCompletionHandler:^(const void * _Nonnull ppsoln, const void * _Nonnull perr) {
            double const* psoln = (double const*)ppsoln;
            double err = ((double const*)perr)[0];
            if (err <= .01)
            {
                [_solver_mesh applyPointForce: (vector_double3){0.0, 0.0, _load_increment}
                                     element: _mid_elem
                                    location: (vector_double3){-1.0, 1.0, 1.0}];
                atomic_fetch_add_explicit(_load_step, 1, memory_order_relaxed);
            }
            
//            [_solver_mesh permuteArray: psoln
//                              AStride: 7
//                               result: _p_reordered_soln
//                              BStride: 7
//                              columns: 7];
            
            vector_float4* p_render_verts = (vector_float4*)[_render_verts contents];
            
            for (NSUInteger i = 0; i < _num_elems; ++i)
            {
                // Collect displacements for this element.
                NSUInteger const* p_elem = _elements + i*_verts_per_elem;
                for (NSUInteger j = 0; j < _verts_per_elem; ++j)
                {
                    NSUInteger global_idx = p_elem[j];
                    _p_elem_nodal_soln[j*7 + 0] = psoln[global_idx*7 + 0];
                    _p_elem_nodal_soln[j*7 + 1] = psoln[global_idx*7 + 1];
                    _p_elem_nodal_soln[j*7 + 2] = psoln[global_idx*7 + 2];
                    _p_elem_nodal_soln[j*7 + 3] = psoln[global_idx*7 + 3];
                    _p_elem_nodal_soln[j*7 + 4] = psoln[global_idx*7 + 4];
                    _p_elem_nodal_soln[j*7 + 5] = psoln[global_idx*7 + 5];
                    _p_elem_nodal_soln[j*7 + 6] = psoln[global_idx*7 + 6];
                }
                
                // Interpolate to this element's rendering points.
                cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, (int)_rendering_verts_per_elem, 7, (int)_verts_per_elem, 1.0, _sf, (int)_verts_per_elem, _p_elem_nodal_soln, 7, 0.0, _p_elem_render_soln, 7);
                
                vector_float4* p_rverts = p_render_verts + 2*i*_rendering_verts_per_elem;
                vector_float4* p_orig_rverts = _orig_render_verts + 2*i*_rendering_verts_per_elem;
                for (NSUInteger j = 0; j < _rendering_verts_per_elem; ++j)
                {
                    p_rverts[2*j + 0].x = p_orig_rverts[2*j + 0].x + _p_elem_render_soln[7*j + 0];
                    p_rverts[2*j + 0].y = p_orig_rverts[2*j + 0].y + _p_elem_render_soln[7*j + 1];
                    p_rverts[2*j + 0].z = p_orig_rverts[2*j + 0].z + _p_elem_render_soln[7*j + 2];
                    
                    p_rverts[2*j + 1].x = p_orig_rverts[2*j + 1].x + _p_elem_render_soln[7*j + 3];
                    p_rverts[2*j + 1].y = p_orig_rverts[2*j + 1].y + _p_elem_render_soln[7*j + 4];
                    p_rverts[2*j + 1].z = p_orig_rverts[2*j + 1].z + _p_elem_render_soln[7*j + 5];

                    p_rverts[2*j + 1].xyz = simd_normalize(p_rverts[2*j + 1].xyz);
                }
            }
            
            @autoreleasepool
            {
                // create command buffer to store GPU commands
                id<MTLCommandBuffer> command_buffer = [_command_queue commandBuffer];
                
                // create pipeline descriptor that describes how to render geometry
                MTLRenderPassDescriptor* pass_descriptor = [view currentRenderPassDescriptor];
                
                // encode render pass into command buffer
                id<MTLRenderCommandEncoder> command_encoder = [command_buffer renderCommandEncoderWithDescriptor: pass_descriptor];
                
                // configure rendering pass
                [command_encoder setRenderPipelineState: _pipeline_state];
                [command_encoder setFrontFacingWinding: MTLWindingCounterClockwise];
                [command_encoder setCullMode: MTLCullModeNone];
                
                // configure vertex buffer
                [command_encoder setVertexBuffer: _render_verts offset: 0 atIndex: 0];
                [command_encoder setVertexBuffer: _matrices offset: 0 atIndex: 1];
                
                // encode draw command
                [command_encoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle
                                       indexCount: 3*_num_render_triangles
                                        indexType: MTLIndexTypeUInt32
                                      indexBuffer: _render_triangles
                                indexBufferOffset: 0];
                
                // send endEncoding message to the command encoder
                [command_encoder endEncoding];
                                
                // trigger display of drawable and commit the command buffer
                [command_buffer presentDrawable: view.currentDrawable];
                [command_buffer commit];
            }
        }];
        
//        [_solver_mesh waitUntilCompleted];
//        double const* pSoln = [_solver_mesh solutionContents];
    }
}

-(void)mtkView: (nonnull MTKView*) view drawableSizeWillChange: (CGSize) size
{
    _viewport_size.x = size.width;
    _viewport_size.y = size.height;
}

@end    // SurfaceRenderer
