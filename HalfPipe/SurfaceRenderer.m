//
//  SurfaceRenderer.m
//  HalfPipe
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import <Accelerate/Accelerate.h>
#import <AdaptableFiniteElementKit/AdaptableFiniteElementKit.h>

#import "SurfaceRenderer.h"
#import "GeometryGeneration.h"
#import "TriangulateElement.h"
#import "Utilities.h"
#import "Element.h"
#import "Model.h"

#include <stdatomic.h>

@implementation SurfaceRenderer
{
    id<MTLDevice>               _device;
    id<MTLRenderPipelineState>  _pipeline_state;
    id<MTLCommandQueue>         _command_queue;
    vector_uint2                _viewport_size;
    
    NSUInteger                  _num_vertices;
    NSUInteger                  _verts_per_elem;
    
    Model*                      _shell_model;
    AFEKMesh*                   _solver_mesh;
    
    double                      _offset;
    matrix_float4x4             _projection_matrix;
    matrix_float4x4             _mv_matrix;
    id<MTLBuffer>               _matrices;
        
    double                      _load_increment;
    atomic_uint*                _load_step;
    NSUInteger                  _max_load_steps;
    NSUInteger                  _mid_elem;
    NSUInteger                  _num_elems;
    NSUInteger*                 _elements;
    
    NSUInteger                  _strain_stride;
    NSUInteger                  _number_of_points;
    
    double*                     _sf;
    double*                     _ldsf0;
    double*                     _ldsf1;
    
    vector_float4*              _orig_render_verts;
    vector_float4*              _init_render_verts;
    id<MTLBuffer>               _render_verts;
    id<MTLBuffer>               _render_triangles;
    NSUInteger                  _num_render_triangles;
    NSUInteger                  _rendering_verts_per_elem;
    
    id<MTLBuffer>               _colors;
    MTLDepthStencilDescriptor * _depth_stencil_desc;
    id<MTLDepthStencilState>    _depth_stencil_state;
    id<MTLTexture>              _depth_texture;
    
    // temporary workspace arrays
    double*                     _p_reordered_soln;
    double*                     _p_elem_nodal_soln;
    double*                     _p_elem_render_soln;
    double*                     _p_elem_render_soln_diff0;
    double*                     _p_elem_render_soln_diff1;
    double*                     _strains;
    double*                     _stresses;
    
    // framerate and runtime
    int                         _frame_count;
    double                      _last_frame_timestamp;
    double                      _elapsed_time;
    double                      _total_runtime;
}

- (nonnull instancetype)initWithMetalKitView:(MTKView* __nonnull)mtkView
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _offset = 15.0;
    _frame_count = 0;
    _last_frame_timestamp = 0.0;
    _elapsed_time = 0.0;
    _total_runtime = 0.0;

    self.frameDataArray = [NSMutableArray array];
    self.isPseudoSimMode = NO;
    self.toggleHeatmap = NO;
    self.frameIndex = 0;
    self.cameraRotation = (vector_float3){0.0, 0.0, 0.0};
    self.cameraZoom = 1.0;
    
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
    pipeline_desc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    @autoreleasepool
    {
        NSError* error = nil;
        _pipeline_state = [_device newRenderPipelineStateWithDescriptor:pipeline_desc
                                                                  error:&error];
    }
    
    [pipeline_desc release];
    [library release];
    
    // initialize geometry
    _num_elems = num_elems_x * num_elems_y;
    
    NSUInteger num_bcs;
    _num_vertices = getNodeCount(elem_order, num_elems_x, num_elems_y, &num_bcs);
    
    NSUInteger verts_per_side = elem_order + 1;
    _verts_per_elem = verts_per_side * verts_per_side;
    
    _elements = (NSUInteger*)malloc(_num_elems * _verts_per_elem * sizeof(NSUInteger));
    double* positions = (double*)malloc(_num_vertices*3*sizeof(double));
    double* normals = (double*)malloc(_num_vertices*3*sizeof(double));
    
    NSUInteger* bc_verts = (NSUInteger*)malloc(num_bcs * sizeof(NSUInteger));
    generateGeometry(elem_order, length, radius, num_elems_x, num_elems_y, _elements, positions, normals, bc_verts);
    
    // initailize transformation matrices
    matrix_float4x4 rotate_x = matrix_float4x4_rotation((vector_float3){1.0, 0.0, 0.0}, 40.0*M_PI/180.0);
    matrix_float4x4 rotate_y = matrix_float4x4_rotation((vector_float3){0.0, 1.0, 0.0}, -M_PI/8.0);
    matrix_float4x4 model_matrix = matrix_multiply(rotate_y, rotate_x);
    matrix_float4x4 view_matrix = matrix_float4x4_translation((vector_float3){0.0, 0.0, -_offset});
    _projection_matrix = matrix_float4x4_perspective(1.0f, (2.0f * M_PI) / 5.0f, 1.0f, 100.0f);

    _mv_matrix = matrix_multiply(view_matrix, model_matrix);
    matrix_float4x4 mvp_matrix = matrix_multiply(_projection_matrix, _mv_matrix);
    
    _matrices = [_device newBufferWithLength:2*sizeof(matrix_float4x4)
                                     options:MTLResourceStorageModeShared];
    matrix_float4x4* p_matrices = (matrix_float4x4*)[_matrices contents];
    p_matrices[0] = mvp_matrix;
    p_matrices[1] = _mv_matrix;
    
    // initialize solver and model
    Element* q81_element = [[Element alloc] init];
    _shell_model = [[Model alloc] initWithMaterialParameters:material];
    _solver_mesh = [[AFEKMesh alloc] initWithElements:_elements
                                        elementStride:_verts_per_elem
                                          elementType:q81_element
                                          coordinates:positions
                                              normals:normals
                                     numberOfElements:_num_elems
                                     numberOfVertices:_num_vertices
                                                model:_shell_model
                                             dataType:AFEKDataTypeFloat64];
    
    // apply boundary conditions
    for (NSUInteger i = 0; i < num_bcs; ++i)
        [_solver_mesh fixNode:bc_verts[i]];
    
    // prepare rendering triangle mesh
    NSUInteger total_sqrs = rendering_triangles_per_side * rendering_triangles_per_side;
    NSUInteger total_tris = total_sqrs * 2;
    NSUInteger rendering_verts_per_side = rendering_triangles_per_side + 1;
    _rendering_verts_per_elem = rendering_verts_per_side * rendering_verts_per_side;
    
    vector_double2* elem_triangle_verts = (vector_double2*)malloc(_rendering_verts_per_elem*sizeof(vector_double2));
    NSUInteger* elem_triangles = (NSUInteger*)malloc(3*total_tris*sizeof(NSUInteger));
    
    _render_verts = [_device newBufferWithLength:2*_num_elems*_rendering_verts_per_elem*sizeof(vector_float4)
                                         options:MTLResourceStorageModeShared];
    _render_triangles = [_device newBufferWithLength:3*_num_elems*total_tris*sizeof(uint32_t)
                                             options:MTLResourceStorageModeShared];
    
    // initialize color buffer
    NSUInteger num_verts = _num_elems * _rendering_verts_per_elem;
    _colors = [_device newBufferWithLength:num_verts*sizeof(vector_float4)
                                   options:MTLResourceStorageModeShared];
    vector_float4* p_colors = (vector_float4*)[_colors contents];
    for (NSUInteger i = 0; i < num_verts; ++i) {
        // set default color to white
        p_colors[i] = (vector_float4){1.0, 1.0, 1.0, 1.0};
    }
    
    // create depth stencil descriptor
    _depth_stencil_desc = [[MTLDepthStencilDescriptor alloc] init];
    _depth_stencil_desc.depthCompareFunction = MTLCompareFunctionLess;
    _depth_stencil_desc.depthWriteEnabled = YES;
    _depth_stencil_state = [_device newDepthStencilStateWithDescriptor:_depth_stencil_desc];
    
    // initialize initial vertices
    _orig_render_verts = (vector_float4*)malloc(2*_num_elems*_rendering_verts_per_elem*sizeof(vector_float4));
    _init_render_verts = (vector_float4*)malloc(2*_num_elems*_rendering_verts_per_elem*sizeof(vector_float4));
    
    _num_render_triangles = _num_elems * total_tris;
    GenerateTriangles(rendering_triangles_per_side, 0, elem_triangle_verts, elem_triangles);
    
    // interpolating functions to get rendering vertices
    _sf = (double*)malloc(_rendering_verts_per_elem*_verts_per_elem*sizeof(double));
    _ldsf0 = (double*)malloc(_rendering_verts_per_elem*_verts_per_elem*sizeof(double));
    _ldsf1 = (double*)malloc(_rendering_verts_per_elem*_verts_per_elem*sizeof(double));
    [q81_element generateShapeValuesAtPoints:elem_triangle_verts
                              numberOfPoints:_rendering_verts_per_elem
                                shapeResults:_sf
                      localDiffShape1Results:_ldsf0
                      localDiffShape2Results:_ldsf1
                              shapeRowStride:_verts_per_elem];
    
    double* temp = (double*)malloc(_verts_per_elem*3*sizeof(double));
    double* temp2 = (double*)malloc(_rendering_verts_per_elem*3*sizeof(double));
    uint32_t* p_render_triangles = (uint32_t*)[_render_triangles contents];
    vector_float4* p_render_verts = (vector_float4*)[_render_verts contents];
    for (NSUInteger i = 0; i < _num_elems; ++i)
    {
        NSUInteger const* p_element = _elements + i*_verts_per_elem;
        vector_float4* p_rverts = p_render_verts + 2*i*_rendering_verts_per_elem;
        vector_float4* p_orig_rverts = _orig_render_verts + 2*i*_rendering_verts_per_elem;
        uint32_t* p_tris = p_render_triangles + 3*i*total_tris;
        uint32_t tri_elem_offset = (uint32_t)(i*_rendering_verts_per_elem);
        
        // collect nodal coordinates for element i
        for (NSUInteger j = 0; j < _verts_per_elem; ++j)
        {
            NSUInteger vert = p_element[j];
            temp[3*j + 0] = positions[3*vert + 0];
            temp[3*j + 1] = positions[3*vert + 1];
            temp[3*j + 2] = positions[3*vert + 2];
        }
        
        // interpolate to this element's rendering points
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
        
        // and normals
        for (NSUInteger j = 0; j < _verts_per_elem; ++j)
        {
            NSUInteger vert = p_element[j];
            temp[3*j + 0] = normals[3*vert + 0];
            temp[3*j + 1] = normals[3*vert + 1];
            temp[3*j + 2] = normals[3*vert + 2];
        }
        
        // interpolate to this element's rendering points
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
    
    free(elem_triangle_verts);
    free(elem_triangles);
    
    free(positions);
    free(normals);
    free(bc_verts);
    
    [q81_element release];
    
    // save initial render verts
    memcpy(_init_render_verts, [_render_verts contents], 2 * _num_elems * _rendering_verts_per_elem * sizeof(vector_float4));
    
    NSLog(@"Beginning simulation...");
    
    // apply a force
    _mid_elem = ((num_elems_y >> 1) - 1) * num_elems_x;
    [_solver_mesh applyPointForce: (vector_double3){0.0, 0.0, _load_increment}
                          element: _mid_elem
                         location: (vector_double3){-1.0, 1.0, 1.0}];
    
    _load_step = (atomic_uint*)malloc(sizeof(atomic_uint));
    atomic_store_explicit(_load_step, 1, memory_order_relaxed);
    
    _p_reordered_soln = (double*)malloc(_num_vertices*7*sizeof(double));
    _p_elem_nodal_soln = (double*)malloc(_verts_per_elem*7*sizeof(double));
    _p_elem_render_soln = (double*)malloc(_rendering_verts_per_elem*7*sizeof(double));
    _p_elem_render_soln_diff0 = (double*)malloc(_rendering_verts_per_elem*7*sizeof(double));
    _p_elem_render_soln_diff1 = (double*)malloc(_rendering_verts_per_elem*7*sizeof(double));
    
    _strain_stride = 8;
    _number_of_points = 81;
    _strains = (double*)malloc(_strain_stride * _number_of_points * sizeof(double));
    _stresses = (double*)malloc(_num_elems * _rendering_verts_per_elem * sizeof(double));
    
    return self;
}

-(void) dealloc
{
    [_device release];
    [_command_queue release];
    [_pipeline_state release];
    
    [_matrices release];
    [_solver_mesh release];
    [_shell_model release];
    [_depth_stencil_desc release];
    [_depth_texture release];
    
    free(_load_step);
    
    [_render_verts release];
    [_render_triangles release];
    [_colors release];
    
    free(_elements);
    free(_sf);
    free(_ldsf0);
    free(_ldsf1);
    
    free(_orig_render_verts);
    free(_init_render_verts);
    free(_p_reordered_soln);
    free(_p_elem_nodal_soln);
    
    free(_p_elem_render_soln);
    free(_p_elem_render_soln_diff0);
    free(_p_elem_render_soln_diff1);
    
    free(_strains);
    free(_stresses);
    
    for (FrameData *frameData in _frameDataArray)
        [frameData release];
    [_frameDataArray release];
    _frameDataArray = nil;
    
    [super dealloc];
}

- (void)drawInMTKView:(nonnull MTKView*)view
{
    if (self.isPseudoSimMode == NO) {
        // if initial simulation run...
        if (atomic_load_explicit(_load_step, memory_order_relaxed) < _max_load_steps)
        {
            // run the simulation for a single iteration
            [_solver_mesh runIterationWithCompletionHandler:^(const void * _Nonnull ppsoln, const void * _Nonnull perr) {
                double const* psoln = (double const*)ppsoln;
                double err = ((double const*)perr)[0];
                
                // display solution and error values
                [self displaySoln:psoln err:err];
                
                if (err <= .01)
                {
                    [_solver_mesh applyPointForce:(vector_double3){0.0, 0.0, _load_increment}
                                          element:_mid_elem
                                         location:(vector_double3){-1.0, 1.0, 1.0}];
                    atomic_fetch_add_explicit(_load_step, 1, memory_order_relaxed);
                }
                
                vector_float4* p_render_verts = (vector_float4*)[_render_verts contents];
                
                for (NSUInteger i = 0; i < _num_elems; ++i)
                {
                    // collect displacements for this element
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
                    
                    // interpolate to this element's rendering points
                    // produces _p_elem_render_soln, the displacement values at the rendering points
                    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, (int)_rendering_verts_per_elem, 7, (int)_verts_per_elem, 1.0, _sf, (int)_verts_per_elem, _p_elem_nodal_soln, 7, 0.0, _p_elem_render_soln, 7);
                    
                    // generate derivatives of the displacements (_diff0 and _diff1)
                    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, (int)_rendering_verts_per_elem, 7, (int)_verts_per_elem, 1.0, _ldsf0, (int)_verts_per_elem, _p_elem_nodal_soln, 7, 0.0, _p_elem_render_soln_diff0, 7);
                    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, (int)_rendering_verts_per_elem, 7, (int)_verts_per_elem, 1.0, _ldsf1, (int)_verts_per_elem, _p_elem_nodal_soln, 7, 0.0, _p_elem_render_soln_diff1, 7);
                    
                    // calculate strains for element's verts
                    ModelState *modelState = _shell_model.modelState;
                    _strains = [modelState computeStrainsFromDisplacements:_p_elem_render_soln
                                                   localDiffDisplacements0:_p_elem_render_soln_diff0
                                                   localDiffDisplacements1:_p_elem_render_soln_diff1];
                    
                    // convert strains to stress components
                    for (NSUInteger j = 0; j < _number_of_points; ++j)
                    {
                        [self calculateStressFromStrains:i
                                                   point:j];
                    }
                    
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
                
                // update frame rate and total elapsed time
                NSDictionary *frameRateInfo = [self measureFrameRate];
                double fps = [frameRateInfo[@"fps"] doubleValue];
                double runtime = [frameRateInfo[@"runtime"] doubleValue];
                
                // Get solution and error values from the solver
                __block double solution = *psoln;
                __block double error = err;
                
                // get vertex, index, stress data
                vector_float4 *vertexData = (vector_float4 *)[_render_verts contents];
                uint32_t *indexData = (uint32_t *)[_render_triangles contents];
                double *stressData = _stresses;
                
                // get total number of triangles
                NSUInteger rendering_triangles_per_side = 8;
                NSUInteger total_sqrs = rendering_triangles_per_side * rendering_triangles_per_side;
                NSUInteger total_tris = total_sqrs * 2;
                
                // store frame data
                NSUInteger numVertices = 2 * _num_elems * _rendering_verts_per_elem;
                NSUInteger numIndexes = 3 * _num_elems * total_tris;
                FrameData *frameData = [[FrameData alloc] initWithVertexCount:numVertices
                                                                   indexCount:numIndexes
                                                                          fps:fps
                                                                      runtime:runtime
                                                                     solution:solution
                                                                        error:error];
                [frameData copyVertexData:vertexData];
                [frameData copyIndexData:indexData];
                [frameData copyStressData:stressData];
                
                [self.frameDataArray addObject:frameData];
            }];
        } else { // simulation has completed
            self.isPseudoSimMode = YES;
            [self simulationDidComplete];
        }
    } else { // enter pseudo-simulation mode
        (void)[self measureFrameRate];
    }
    
    @autoreleasepool
    {
        // create command buffer to store GPU commands
        id<MTLCommandBuffer> command_buffer = [_command_queue commandBuffer];
        
        // create pipeline descriptor that describes how to render geometry
        MTLRenderPassDescriptor* pass_descriptor = [view currentRenderPassDescriptor];
        
        // attach depth texture to pass descriptor
        pass_descriptor.depthAttachment.texture = _depth_texture;
        pass_descriptor.depthAttachment.loadAction = MTLLoadActionClear;
        pass_descriptor.depthAttachment.clearDepth = 1.0;
        pass_descriptor.depthAttachment.storeAction = MTLStoreActionStore;
        
        // encode render pass into command buffer
        id<MTLRenderCommandEncoder> command_encoder = [command_buffer renderCommandEncoderWithDescriptor:pass_descriptor];
        
        // configure rendering pass
        [command_encoder setRenderPipelineState:_pipeline_state];
        [command_encoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [command_encoder setCullMode:MTLCullModeNone];
        
        // set depth stencil state
        [command_encoder setDepthStencilState:_depth_stencil_state];
        
        // set viewport
        [command_encoder setViewport:(MTLViewport){0.0, 0.0, _viewport_size.x, _viewport_size.y, 0.0, 1.0}];
        
        // configure vertex buffer
        [command_encoder setVertexBuffer:_render_verts offset:0 atIndex:0];
        [command_encoder setVertexBuffer:_matrices offset:0 atIndex:1];
        [command_encoder setVertexBuffer:_colors offset:0 atIndex:2];
        
        // encode draw command
        [command_encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                    indexCount:3*_num_render_triangles
                                     indexType:MTLIndexTypeUInt32
                                   indexBuffer:_render_triangles
                             indexBufferOffset:0];
        
        // send endEncoding message to the command encoder
        [command_encoder endEncoding];
        
        // trigger display of drawable and commit the command buffer
        [command_buffer presentDrawable:view.currentDrawable];
        [command_buffer commit];
    }
}

- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size
{
    _viewport_size.x = size.width;
    _viewport_size.y = size.height;
    
    // release old depth texture
    if (_depth_texture) {
        [_depth_texture release];
    }
    
    // create new depth texture
    MTLTextureDescriptor *depth_texture_desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                                width:_viewport_size.x
                                                                                               height:_viewport_size.y
                                                                                            mipmapped:NO];
    depth_texture_desc.usage = MTLTextureUsageRenderTarget;
    _depth_texture = [_device newTextureWithDescriptor:depth_texture_desc];
}

- (void)calculateStressFromStrains:(NSUInteger)elemIdx point:(NSUInteger)pntIdx {
    NSUInteger i = elemIdx;
    NSUInteger j = pntIdx;
    
    double E = 10.5e6;
    double nu = 0.3125;

    double factor1 = E / (1.0 + nu);
    double factor2 = nu / (1.0 - 2.0 * nu);
    
    // strain and stress index for flattened arrays
    NSUInteger strainIndex = j * _strain_stride;
    double *strain = &_strains[strainIndex];

    // calculate trace of the strain tensor
    double traceStrain = strain[0] + strain[1] + strain[2];
    
    // calculate stress components
    double sigma11, sigma22, sigma33, sigma23, sigma13, sigma12;
    sigma11 = factor1 * (strain[0] + factor2 * traceStrain);   // sigma_11
    sigma22 = factor1 * (strain[1] + factor2 * traceStrain);   // sigma_22
    sigma33 = factor1 * (strain[2] + factor2 * traceStrain);   // sigma_33
    sigma23 = factor1 * (strain[3] / 2.0);                     // sigma_23
    sigma13 = factor1 * (strain[4] / 2.0);                     // sigma_13
    sigma12 = factor1 * (strain[5] / 2.0);                     // sigma_12
    
    // convert stress components to single stress value
    double vonMisesStress = sqrt(
        ((sigma11 - sigma22) * (sigma11 - sigma22) +
        (sigma22 - sigma33) * (sigma22 - sigma33) +
        (sigma33 - sigma11) * (sigma33 - sigma11) +
        6 * (sigma23 * sigma23 + sigma13 * sigma13 + sigma12 * sigma12)) / 2.0
    );
    NSUInteger stressIdx = i * _number_of_points + j;
    _stresses[stressIdx] = vonMisesStress;
}

- (NSDictionary *)measureFrameRate {
    // get current time
    CFTimeInterval currentTimestamp = CACurrentMediaTime();
    if (_last_frame_timestamp == 0) {
        _last_frame_timestamp = currentTimestamp;
        return @{@"fps": @0.0, @"runtime": @0.0};
    }
    
    // increment frame and elapsed time
    _frame_count++;
    _elapsed_time += (currentTimestamp - _last_frame_timestamp);
    _total_runtime += (currentTimestamp - _last_frame_timestamp);
    _last_frame_timestamp = currentTimestamp;
    
    // calculate frame rate
    double fps = 0.0;
    if (_elapsed_time >= 1.0) {
        fps = _frame_count / _elapsed_time;
        if (self.frameRateLabel != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.frameRateLabel.stringValue = [NSString stringWithFormat:@"Frame Rate: %.2f FPS", fps];
            });
        }
        _frame_count = 0;
        _elapsed_time = 0.0;
    }
    
    // calculate total elapsed time
    if (!self.isPseudoSimMode && self.elapsedTimeLabel != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.elapsedTimeLabel.stringValue = [NSString stringWithFormat:@"Runtime: %.2f sec", _total_runtime];
        });
    }
    
    return @{@"fps": @(fps), @"runtime": @(_total_runtime)};
}

- (void)displaySoln:(double const*)psoln err:(double)err {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.errorLabel.stringValue = [NSString stringWithFormat:@"Error: %.4f", err];
        self.solutionLabel.stringValue = [NSString stringWithFormat:@"Solution: %.4f", *psoln];
    });
}

- (void)simulationDidComplete {
    NSLog(@"Simulation complete!");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.viewController.frameSlider.maxValue = self.frameDataArray.count - 1;
        self.viewController.frameSlider.doubleValue = self.frameDataArray.count - 1;
        self.viewController.stressmapToggle.enabled = YES;
        self.viewController.heatmapToggle.enabled = YES;
        self.viewController.frameSlider.enabled = YES;
    });
}

- (void)updateFrameData {
    FrameData *frameData = self.frameDataArray[self.frameIndex];
    
    // populate buffer contents with frame data
    memcpy([_render_verts contents], frameData.vertices, sizeof(vector_float4) * frameData.vertexCount);
    memcpy([_render_triangles contents], frameData.indices, sizeof(uint32_t) * frameData.indexCount);
    // memcpy(_stresses, frameData.stresses, sizeof(double) * frameData.vertexCount);
    
    // update labels (not fps)
    self.errorLabel.stringValue = [NSString stringWithFormat:@"Error: %.4f", frameData.error];
    self.solutionLabel.stringValue = [NSString stringWithFormat:@"Solution: %.4f", frameData.solution];
    self.elapsedTimeLabel.stringValue = [NSString stringWithFormat:@"Runtime: %.2f sec", frameData.runtime];
}

- (void)setFrameIndex:(NSUInteger)frameIndex {
    if (frameIndex < self.frameDataArray.count) {
        _frameIndex = frameIndex;
        [self updateFrameData];
        if (self.toggleHeatmap) [self updateHeatmap];
        if (self.toggleStressmap) [self updateStressmap];
    }
}

- (void)setToggleHeatmap:(BOOL)toggleHeatmap {
    if (_isPseudoSimMode == YES) {
        _toggleHeatmap = toggleHeatmap;
        if (toggleHeatmap == YES && _toggleStressmap == YES) {
            _toggleStressmap = NO;
            self.viewController.stressmapToggle.state = NSControlStateValueOff;
        }
        [self updateHeatmap];
    }
}

- (void)updateHeatmap {
    vector_float4* init_verts = _init_render_verts;
    vector_float4* curr_verts = (vector_float4 *)[_render_verts contents];
    vector_float4* colors = (vector_float4*)[_colors contents];
    
    NSUInteger num_idxs = 2 * _num_elems * _rendering_verts_per_elem;
    NSUInteger num_verts = _num_elems * _rendering_verts_per_elem;
    
    // create displacement magnitudes array
    double displacementMagnitudes[5184] = {0.0};
    double maxDisplacement = 0.0;

    // for each vertex position (alternates with vertex norm)
    for (NSUInteger v = 0; v < num_idxs; v += 2) {
        vector_float4 currentPos = curr_verts[v];
        vector_float4 displacement = currentPos - init_verts[v];
        double displacementMagnitude = simd_length(displacement.xyz);
        NSUInteger d = v / 2;
        displacementMagnitudes[d] = displacementMagnitude;
        
        // update maximum displacement
        if (displacementMagnitude > maxDisplacement) {
            maxDisplacement = displacementMagnitude;
        }
    }

    // apply heatmap based on toggle
    for (NSUInteger v = 0; v < num_verts; ++v)
    {
        vector_float4 vertexColor = (vector_float4){1.0, 1.0, 1.0, 1.0};
        if (self.toggleHeatmap == YES) {
            NSColor *ns_color = [self mapDisplacementToColor:displacementMagnitudes[v]
                                         withMaxDisplacement:maxDisplacement];
            vertexColor = (vector_float4){
                ns_color.redComponent,
                ns_color.greenComponent,
                ns_color.blueComponent,
                ns_color.alphaComponent};
        }
        
        // populate vertex color buffer
        colors[v] = vertexColor;
    }
}


- (void)setToggleStressmap:(BOOL)toggleStressmap {
    if (_isPseudoSimMode == YES) {
        _toggleStressmap = toggleStressmap;
        if (toggleStressmap == YES && _toggleHeatmap == YES) {
            _toggleHeatmap = NO;
            self.viewController.heatmapToggle.state = NSControlStateValueOff;
        }
        [self updateStressmap];
    }
}

- (void)updateStressmap {
    double* stresses = _stresses;
    vector_float4* colors = (vector_float4*)[_colors contents];
    
    NSUInteger num_verts = _num_elems * _rendering_verts_per_elem;
    
    // find max stress
    double maxStress = 0.0;

    // for each vertex position (alternates with vertex norm)
    for (NSUInteger v = 0; v < num_verts; ++v) {
        double currStress = stresses[v];
        if (currStress > maxStress) {
            maxStress = currStress;
        }
    }

    // apply heatmap based on toggle
    for (NSUInteger v = 0; v < num_verts; ++v)
    {
        vector_float4 vertexColor = (vector_float4){1.0, 1.0, 1.0, 1.0};
        if (self.toggleStressmap == YES) {
            NSColor *ns_color = [self mapDisplacementToColor:stresses[v]
                                         withMaxDisplacement:maxStress];
            vertexColor = (vector_float4){
                ns_color.redComponent,
                ns_color.greenComponent,
                ns_color.blueComponent,
                ns_color.alphaComponent};
        }
        
        // populate vertex color buffer
        colors[v] = vertexColor;
    }
}

- (NSColor *)mapDisplacementToColor:(double)displacement withMaxDisplacement:(double)maxDisplacement {
    double normalizedDisplacement = displacement / maxDisplacement;
    
    // map displacement magnitude to color
    NSColor *color;
    if (normalizedDisplacement < 0.25) {
        // interpolate between blue and green
        color = [self interpolateColorFrom:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0]
                                         to:[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0]
                                 withFactor:(normalizedDisplacement / 0.25)];
    } else if (normalizedDisplacement < 0.5) {
        // interpolate between green and yellow
        color = [self interpolateColorFrom:[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0]
                                       to:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0]
                               withFactor:((normalizedDisplacement - 0.25) / 0.25)];
    } else if (normalizedDisplacement < 0.75) {
        // interpolate between yellow and red
        color = [self interpolateColorFrom:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0]
                                       to:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0]
                               withFactor:((normalizedDisplacement - 0.5) / 0.25)];
    } else {
        // interpolate between yellow and red
        color = [self interpolateColorFrom:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0]
                                       to:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0]
                               withFactor:((normalizedDisplacement - 0.5) / 0.25)];
    }
    
    return color;
}

- (NSColor *)interpolateColorFrom:(NSColor *)color1 to:(NSColor *)color2 withFactor:(double)factor {
    // calculate red, green, and blue components
    double red = color1.redComponent + (color2.redComponent - color1.redComponent) * factor;
    double green = color1.greenComponent + (color2.greenComponent - color1.greenComponent) * factor;
    double blue = color1.blueComponent + (color2.blueComponent - color1.blueComponent) * factor;
    NSColor *interpolated_color = [NSColor colorWithCalibratedRed:red
                                                            green:green
                                                             blue:blue
                                                            alpha:1.0];
    return interpolated_color;
}

- (void)setRotation:(vector_float3)rotation {
    // only rotate mesh if simulation done
    if (_isPseudoSimMode == YES) {
        self.cameraRotation = rotation;
        [self rotateCamera];
    }
}

- (void)setZoom:(float)zoom {
    // only zoom if simulation done
    if (_isPseudoSimMode == YES) {
        self.cameraZoom = zoom;
        [self zoomCamera];
    }
}

- (void)rotateCamera {
    // translation matrices
    matrix_float4x4 translation_to_origin = matrix_float4x4_translation((vector_float3){0.0, 0.0, _offset});
    matrix_float4x4 translation_back = matrix_float4x4_translation((vector_float3){0.0, 0.0, -_offset});

    // rotation matrix around y axis
    matrix_float4x4 rotation_matrix = matrix_float4x4_rotation((vector_float3){0.0, 1.0, 0.0}, self.cameraRotation.y);
    
    // apply transformations: move to origin, rotate, then move back
    matrix_float4x4 transformation_matrix = matrix_multiply(translation_back, matrix_multiply(rotation_matrix, translation_to_origin));
    
    [self updateCamera: transformation_matrix];
}

- (void)zoomCamera {
    double newOffset = _offset - self.cameraZoom;
    if (newOffset >= 13 && newOffset <= 90) {
        // translate mesh toward camera to approximate zoom
        _offset = newOffset;
        matrix_float4x4 transformation_matrix = matrix_float4x4_translation((vector_float3){0.0, 0.0, self.cameraZoom});
        [self updateCamera: transformation_matrix];
    }
}

- (void)updateCamera:(matrix_float4x4) transformation_matrix {
    // update mv and mvp matrices
    _mv_matrix = matrix_multiply(transformation_matrix, _mv_matrix);
    matrix_float4x4 mvp_matrix = matrix_multiply(_projection_matrix, _mv_matrix);
    
    // update matrix buffer
    matrix_float4x4* p_matrices = (matrix_float4x4*)[_matrices contents];
    p_matrices[0] = mvp_matrix;
    p_matrices[1] = _mv_matrix;
}

@end    // SurfaceRenderer
