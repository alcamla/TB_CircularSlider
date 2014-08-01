//
//  TBHandleLayer.h
//  TB_CircularSlider
//
//  Created by camacholaverde on 7/28/14.
//  Copyright (c) 2014 Yari Dareglia. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface TBHandleLayer : CAShapeLayer

@property(nonatomic, assign) CGPoint handleCenter;
@property(nonatomic, assign) int angle;


-(id)initWithHandleCenter:(CGPoint)handleCenter angle:(int)angle visible:(BOOL)isVisible;

@end
