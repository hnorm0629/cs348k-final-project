//
//  SurfaceRenderer.h
//  HalfPipe
//

#ifndef SurfaceRenderer_h
#define SurfaceRenderer_h

#import <MetalKit/MetalKit.h>

@interface SurfaceRenderer: NSObject<MTKViewDelegate>

@property (nonatomic, strong) NSTextField * _Nonnull frameRateLabel;
@property (nonatomic, strong) NSTextField * _Nonnull elapsedTimeLabel;

-(nonnull instancetype) initWithMetalKitView: (MTKView* __nonnull) mtkView;

@end    // SurfaceRenderer


#endif /* SurfaceRenderer_h */
