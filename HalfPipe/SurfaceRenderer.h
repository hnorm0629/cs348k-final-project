//
//  SurfaceRenderer.h
//  HalfPipe
//

#ifndef SurfaceRenderer_h
#define SurfaceRenderer_h

#import <MetalKit/MetalKit.h>
#import "FrameData.h"

@interface SurfaceRenderer: NSObject<MTKViewDelegate>

@property (nonatomic, strong) NSTextField * _Nonnull errorLabel;
@property (nonatomic, strong) NSTextField * _Nonnull solutionLabel;
@property (nonatomic, strong) NSTextField * _Nonnull frameRateLabel;
@property (nonatomic, strong) NSTextField * _Nonnull elapsedTimeLabel;

@property (nonatomic, strong) NSMutableArray<FrameData *> * _Nullable frameDataArray;
@property (nonatomic) NSUInteger currentFrameIndex;
@property (nonatomic) BOOL isPseudoSimMode;

- (nonnull instancetype) initWithMetalKitView: (MTKView* __nonnull) mtkView;
- (void)updatePseudoSimDataWithFrameData:(FrameData *_Nullable)frameData;
- (void)updateRealTimeFrameRate;

@end    // SurfaceRenderer


#endif /* SurfaceRenderer_h */
