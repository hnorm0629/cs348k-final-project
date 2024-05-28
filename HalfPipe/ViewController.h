//
//  ViewController.h
//  HalfPipe
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (nonatomic, strong) NSSlider *frameSlider;
@property (nonatomic, strong) NSTextField *errorLabel;
@property (nonatomic, strong) NSTextField *solutionLabel;
@property (nonatomic, strong) NSTextField *frameRateLabel;
@property (nonatomic, strong) NSTextField *elapsedTimeLabel;

@end

