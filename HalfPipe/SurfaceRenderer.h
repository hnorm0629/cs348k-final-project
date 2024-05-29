//
//  SurfaceRenderer.h
//  HalfPipe
//

#ifndef SurfaceRenderer_h
#define SurfaceRenderer_h

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "FrameData.h"
#import "ViewController.h"

@interface SurfaceRenderer: NSObject<MTKViewDelegate>

@property (nonatomic, strong) NSTextField * _Nonnull errorLabel;
@property (nonatomic, strong) NSTextField * _Nonnull solutionLabel;
@property (nonatomic, strong) NSTextField * _Nonnull frameRateLabel;
@property (nonatomic, strong) NSTextField * _Nonnull elapsedTimeLabel;
@property (nonatomic, strong) ViewController * _Nonnull viewController;

@property (nonatomic, strong) NSMutableArray<FrameData *> * _Nullable frameDataArray;
@property (nonatomic) NSUInteger frameIndex;
@property (nonatomic) BOOL isPseudoSimMode;

@property (nonatomic) vector_float3 cameraPosition;
@property (nonatomic) vector_float3 cameraRotation;
@property (nonatomic) float cameraZoom;

- (nonnull instancetype) initWithMetalKitView: (MTKView* __nonnull) mtkView;
- (void)setRotation:(vector_float3)rotation;
- (void)setZoom:(float)zoom;

@end    // SurfaceRenderer


#endif /* SurfaceRenderer_h */
