//
//  ViewController.h
//  HalfPipe
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (nonatomic, strong) NSTextField *errorLabel;
@property (nonatomic, strong) NSTextField *solutionLabel;
@property (nonatomic, strong) NSTextField *runtimeLabel;
@property (nonatomic, strong) NSTextField *frameRateLabel;

@property (nonatomic, strong) NSButton *heatmapToggle;
@property (nonatomic, strong) NSSlider *frameSlider;

@property (nonatomic, strong) NSPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) NSMutableArray<NSNumber *> *errorValues;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *solutionValues;

@end

