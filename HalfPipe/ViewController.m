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
    
    // frame rate label
    self.frameRateLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, 200, 20)];
    [self.frameRateLabel setBezeled:NO];
    [self.frameRateLabel setDrawsBackground:NO];
    [self.frameRateLabel setEditable:NO];
    [self.frameRateLabel setSelectable:NO];
    [self.frameRateLabel setStringValue:@"Frame Rate: 0 FPS"];
    [self.view addSubview:self.frameRateLabel];
    
    // elapsed time label
    self.elapsedTimeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 40, 200, 20)];
    [self.elapsedTimeLabel setBezeled:NO];
    [self.elapsedTimeLabel setDrawsBackground:NO];
    [self.elapsedTimeLabel setEditable:NO];
    [self.elapsedTimeLabel setSelectable:NO];
    [self.elapsedTimeLabel setStringValue:@"Elapsed Time: 0.0 seconds"];
    [self.view addSubview:self.elapsedTimeLabel];
    
    // update labels in real time
    _renderer.frameRateLabel = self.frameRateLabel;
    _renderer.elapsedTimeLabel = self.elapsedTimeLabel;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
