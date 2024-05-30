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
    
    // set up labels
    self.errorLabel = [self createLabelWithFrame:NSMakeRect(20, 120, 200, 20) text:nil];
    self.solutionLabel = [self createLabelWithFrame:NSMakeRect(20, 100, 200, 20) text:nil];
    self.runtimeLabel = [self createLabelWithFrame:NSMakeRect(20, 80, 200, 20) text:@"Runtime: 0.0 sec"];
    self.frameRateLabel = [self createLabelWithFrame:NSMakeRect(20, 60, 200, 20) text:@"Frame Rate: 0 FPS"];
    
    // add labels to view
    [self.view addSubview:self.errorLabel];
    [self.view addSubview:self.solutionLabel];
    [self.view addSubview:self.runtimeLabel];
    [self.view addSubview:self.frameRateLabel];

    // update labels in real time
    _renderer.errorLabel = self.errorLabel;
    _renderer.solutionLabel = self.solutionLabel;
    _renderer.frameRateLabel = self.frameRateLabel;
    _renderer.elapsedTimeLabel = self.runtimeLabel;

    // set up heatmap toggle
    self.heatmapToggle = [[NSButton alloc] initWithFrame:NSMakeRect(20, 40, 200, 24)];
    self.heatmapToggle.title = @"Show Displacement Heatmap";
    self.heatmapToggle.target = self;
    self.heatmapToggle.enabled = NO;
    [self.heatmapToggle setButtonType:NSButtonTypeSwitch];
    [self.heatmapToggle setAction:@selector(heatmapToggleChecked:)];
    [self.view addSubview:self.heatmapToggle];
    
    // set up frame slider
    self.frameSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 20, self.view.bounds.size.width - 20, 20)];
    self.frameSlider.minValue = 0;
    self.frameSlider.maxValue = 0;
    self.frameSlider.target = self;
    self.frameSlider.enabled = NO;
    [self.frameSlider setContinuous:YES];
    [self.frameSlider setAction:@selector(sliderValueChanged:)];
    [self.view addSubview:self.frameSlider];
    
    // add gesture recognizers
    [self addGestureRecognizers];
}

- (void) setRepresentedObject:(id) representedObject {
    [super setRepresentedObject:representedObject];
}

- (NSTextField *) createLabelWithFrame:(NSRect) frame text:(NSString *) text {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    if (text) [label setStringValue:text];
    return label;
}

- (void) sliderValueChanged:(NSSlider *) sender {
    NSUInteger frameIndex = (NSUInteger)sender.integerValue;
    _renderer.frameIndex = frameIndex;
}

- (void) heatmapToggleChecked:(NSButton *) sender {
    BOOL isChecked = [sender state] == NSControlStateValueOn;
    _renderer.toggleHeatmap = isChecked;
}

- (void) addGestureRecognizers {
    // add rotation gesture recognizer
    NSRotationGestureRecognizer *rotateGestureRecognizer = [[NSRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
    [self.view addGestureRecognizer:rotateGestureRecognizer];
    
    // add pinch gesture recognizer (for zoom)
    NSMagnificationGestureRecognizer *pinchGesture = [[NSMagnificationGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
}

- (void) handleRotateGesture:(NSRotationGestureRecognizer *) gesture {
    if (gesture.state == NSGestureRecognizerStateChanged) {
        // rotate mesh
        CGFloat rotation = gesture.rotation * 0.1;
        [_renderer setRotation:rotation];
    }
}

- (void) handlePinchGesture:(NSMagnificationGestureRecognizer *) gesture {
    if (gesture.state == NSGestureRecognizerStateChanged) {
        // zoom camera
        float zoom = (gesture.magnification >= 0) ? 1.0 : -1.0;
        [_renderer setZoom:zoom];
    }
}

@end
