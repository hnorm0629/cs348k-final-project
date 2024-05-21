//
//  Element.h
//  HalfPipe
//

#ifndef Element_h
#define Element_h

#import <Foundation/Foundation.h>
#import <AdaptableFiniteElementKit/AdaptableFiniteElementKit.h>

// An 8-th order Lagrangian square element.
@interface Element : NSObject <AFEKElementSource2D>
@end    // Element

#endif /* Element_h */
