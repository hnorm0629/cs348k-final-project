//
//  ViewController.m
//  HalfPipe
//

#import "ViewController.h"
#import <MetalKit/MetalKit.h>
#import "SurfaceRenderer.h"

@implementation ViewController
{
    MTKView*                _view;
    SurfaceRenderer*        _renderer;
}

-(void) viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView*)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    
    _renderer = [[SurfaceRenderer alloc] initWithMetalKitView: _view];
    [_renderer mtkView: _view drawableSizeWillChange: _view.drawableSize];
    _renderer.viewController = self;
    
    _view.delegate = _renderer;
    _view.wantsLayer = YES;
    _view.allowedTouchTypes = NSTouchTypeMaskDirect | NSTouchTypeMaskIndirect;
    
    // error label
    self.errorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 100, 200, 20)];
    [self.errorLabel setBezeled:NO];
    [self.errorLabel setDrawsBackground:NO];
    [self.errorLabel setEditable:NO];
    [self.errorLabel setSelectable:NO];
    [self.view addSubview:self.errorLabel];
    
    // solution label
    self.solutionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 80, 200, 20)];
    [self.solutionLabel setBezeled:NO];
    [self.solutionLabel setDrawsBackground:NO];
    [self.solutionLabel setEditable:NO];
    [self.solutionLabel setSelectable:NO];
    [self.view addSubview:self.solutionLabel];
    
    // elapsed time label
    self.elapsedTimeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 60, 200, 20)];
    [self.elapsedTimeLabel setBezeled:NO];
    [self.elapsedTimeLabel setDrawsBackground:NO];
    [self.elapsedTimeLabel setEditable:NO];
    [self.elapsedTimeLabel setSelectable:NO];
    [self.elapsedTimeLabel setStringValue:@"Runtime: 0.0 sec"];
    [self.view addSubview:self.elapsedTimeLabel];
    
    // frame rate label
    self.frameRateLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 40, 200, 20)];
    [self.frameRateLabel setBezeled:NO];
    [self.frameRateLabel setDrawsBackground:NO];
    [self.frameRateLabel setEditable:NO];
    [self.frameRateLabel setSelectable:NO];
    [self.frameRateLabel setStringValue:@"Frame Rate: 0 FPS"];
    [self.view addSubview:self.frameRateLabel];
    
    // update labels in real time
    _renderer.errorLabel = self.errorLabel;
    _renderer.solutionLabel = self.solutionLabel;
    _renderer.frameRateLabel = self.frameRateLabel;
    _renderer.elapsedTimeLabel = self.elapsedTimeLabel;
    
    // frame slider
    self.frameSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 20, self.view.bounds.size.width - 20, 20)];
    self.frameSlider.minValue = 0;
    self.frameSlider.maxValue = 0;
    self.frameSlider.target = self;
    self.frameSlider.action = @selector(sliderValueChanged:);
    self.frameSlider.enabled = NO;
    [self.frameSlider setContinuous:YES];
    [self.frameSlider setAction:@selector(sliderValueChanged:)];
    [self.view addSubview:self.frameSlider];
    
    // add gesture recognizers
    [self addGestureRecognizers];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // update the view, if already loaded
}

- (void)sliderValueChanged:(NSSlider *)sender {
    NSUInteger frameIndex = (NSUInteger)sender.integerValue;
    _renderer.frameIndex = frameIndex;
}

- (void)addGestureRecognizers {
    // Add rotation gesture recognizer
    NSRotationGestureRecognizer *rotateGestureRecognizer = [[NSRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
    [self.view addGestureRecognizer:rotateGestureRecognizer];
    
    // Add pinch gesture recognizer for zoom
    NSMagnificationGestureRecognizer *pinchGesture = [[NSMagnificationGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
}

- (void)handleRotateGesture:(NSRotationGestureRecognizer *)gesture {
    if (gesture.state == NSGestureRecognizerStateChanged) {
        CGFloat rotation = gesture.rotation * 0.1;
        [_renderer setRotation:rotation];
    }
}

- (void)handlePinchGesture:(NSMagnificationGestureRecognizer *)gesture {
    if (gesture.state == NSGestureRecognizerStateChanged) {
        // Update camera zoom
        float zoom = 1.0;
        if (gesture.magnification < 0) {
            zoom = -1.0;
        }
         [_renderer setZoom:zoom];
    }
}


@end
