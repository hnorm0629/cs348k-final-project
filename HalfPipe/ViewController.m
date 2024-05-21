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
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
