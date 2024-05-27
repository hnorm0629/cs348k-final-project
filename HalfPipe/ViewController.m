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
    _view.delegate = _renderer;
    
    // error label
    self.errorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 80, 200, 20)];
    [self.errorLabel setBezeled:NO];
    [self.errorLabel setDrawsBackground:NO];
    [self.errorLabel setEditable:NO];
    [self.errorLabel setSelectable:NO];
    [self.view addSubview:self.errorLabel];
    
    // solution label
    self.solutionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 60, 200, 20)];
    [self.solutionLabel setBezeled:NO];
    [self.solutionLabel setDrawsBackground:NO];
    [self.solutionLabel setEditable:NO];
    [self.solutionLabel setSelectable:NO];
    [self.view addSubview:self.solutionLabel];
    
    // elapsed time label
    self.elapsedTimeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 40, 200, 20)];
    [self.elapsedTimeLabel setBezeled:NO];
    [self.elapsedTimeLabel setDrawsBackground:NO];
    [self.elapsedTimeLabel setEditable:NO];
    [self.elapsedTimeLabel setSelectable:NO];
    [self.elapsedTimeLabel setStringValue:@"Runtime: 0.0 sec"];
    [self.view addSubview:self.elapsedTimeLabel];
    
    // frame rate label
    self.frameRateLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, 200, 20)];
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
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
