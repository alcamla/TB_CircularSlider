//
//  TBHandleLayer.m
//  TB_CircularSlider
//
//  Created by camacholaverde on 7/28/14.
//  Copyright (c) 2014 Yari Dareglia. All rights reserved.
//

#import "TBHandleLayer.h"
#import "TBCircularSlider.h"


@implementation TBHandleLayer

-(id)init{
    if (self = [super init]) {
        NSLog(@"Initializing the Handle Layer");
    }
    return self;
}

-(id)initWithHandleCenter:(CGPoint)handleCenter angle:(int)angle visible:(BOOL)isVisible{
    if (self = [super init]) {
        NSLog(@"Initializing the Handle Layer");
        _angle = angle;
        _handleCenter = handleCenter;
        CGRect frame = CGRectMake(self.handleCenter.x, self.handleCenter.y, TB_LINE_WIDTH, TB_LINE_WIDTH);
        self.frame = frame;
        
    }
    return self;
}

//-(void)drawInContext:(CGContextRef)ctx
//{
//    CGContextSaveGState(ctx);
//    CGContextSetFillColorWithColor(ctx, [[UIColor greenColor] CGColor]);
//    CGRect boundingRect = CGContextGetClipBoundingBox(ctx);
//    //CGContextFillEllipseInRect(ctx, boundingRect);
//    
//    
//    //Draw the handle
//    double h = boundingRect.size.height, b = boundingRect.size.width;
//    UIBezierPath* polygonPath = UIBezierPath.bezierPath;
//    [polygonPath moveToPoint: CGPointMake(0, -h/2)];
//    [polygonPath addLineToPoint: CGPointMake(b/2, h/2)];
//    [polygonPath addLineToPoint: CGPointMake(-b/2, h/2)];
//    [polygonPath closePath];
//    [polygonPath stroke];
//    CGContextDrawPath(ctx, kCGPathFillStroke);
//
//    CGContextRestoreGState(ctx);
//
//    
//}




@end
