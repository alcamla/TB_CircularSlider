//
//  TBCircularSlider.m
//  TB_CircularSlider
//
//  Created by Yari Dareglia on 1/12/13.
//  Copyright (c) 2013 Yari Dareglia. All rights reserved.
//

#import "TBCircularSlider.h"
#import "Commons.h"

/** Helper Functions **/
#define ToRad(deg) 		( (M_PI * (deg)) / 180.0 )
#define ToDeg(rad)		( (180.0 * (rad)) / M_PI )
#define SQR(x)			( (x) * (x) )

/** Parameters **/
#define TB_SAFEAREA_PADDING 60


#pragma mark - Private -

@interface TBCircularSlider(){
    UITextField *_textField;
    int radius;
}
@end


#pragma mark - Implementation -

@implementation TBCircularSlider

-(id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if(self){
        self.opaque = NO;
        
        //Define the circle radius taking into account the safe area
        radius = self.frame.size.width/2 - TB_SAFEAREA_PADDING;
        
        //Initialize the Angle at 0
        self.angle = 225;
        
        
        //Define the Font
        UIFont *font = [UIFont fontWithName:TB_FONTFAMILY size:TB_FONTSIZE];
        //Calculate font size needed to display 3 numbers
        NSString *str = @"000";
        CGSize fontSize = [str sizeWithFont:font];
        
        //Using a TextField area we can easily modify the control to get user input from this field
        _textField = [[UITextField alloc]initWithFrame:CGRectMake((frame.size.width  - fontSize.width) /2,
                                                                  (frame.size.height - fontSize.height) /2,
                                                                  fontSize.width,
                                                                  fontSize.height)];
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor colorWithWhite:1 alpha:0.8];
        _textField.textAlignment = NSTextAlignmentCenter;
        _textField.font = font;
        //_textField.text = [NSString stringWithFormat:@"%d",self.angle];
        _textField.text = [NSString stringWithFormat:@"%d", 0];
        _textField.enabled = NO;
        
        [self addSubview:_textField];
    }
    
    return self;
}


#pragma mark - UIControl Override -

/** Tracking is started **/
-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super beginTrackingWithTouch:touch withEvent:event];
    
    //We need to track continuously
    return YES;
}

/** Track continuos touch event (like drag) **/
-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super continueTrackingWithTouch:touch withEvent:event];

    //Get touch location
    CGPoint lastPoint = [touch locationInView:self];
    
    // Find if the last point touched is in a valid angle
    //Get the center
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    //Calculate the direction from a center point and a arbitrary position.
    float currentAngle = AngleFromNorth(centerPoint, lastPoint, NO);
    int angle = 360 - floor(currentAngle);
    
    
    NSLog(@"Current Angle: %d", angle);
    
    if (angle>225 && angle<315) {
        //Stop tracking the movement
    } else {
        
        //Use the location to design the Handle
        [self movehandle:lastPoint];
        
        //Control value has changed, let's notify that
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        
        
        
    }
    return YES;
}

/** Track is finished **/
-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super endTrackingWithTouch:touch withEvent:event];
    
}


#pragma mark - Drawing Functions - 

//Use the draw rect to draw the Background, the Circle and the Handle 
-(void)drawRect:(CGRect)rect{
    
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
/** Draw the Background **/
    
    //Create the path
    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, radius, 0, M_PI *2, 0);
    
    //Set the stroke color to black
    [[UIColor blackColor]setStroke];
    
    //Define line width and cap
    CGContextSetLineWidth(ctx, TB_BACKGROUND_WIDTH);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    
    //draw it!
    CGContextDrawPath(ctx, kCGPathStroke);
    
   
//** Draw the circle (using a clipped gradient) **/
    
    
    /** Create THE MASK Image **/
    UIGraphicsBeginImageContext(CGSizeMake(TB_SLIDER_SIZE,TB_SLIDER_SIZE));
    CGContextRef imageCtx = UIGraphicsGetCurrentContext();
    
    //CGContextAddArc(imageCtx, self.frame.size.width/2  , self.frame.size.height/2, radius, 0, ToRad(self.angle), 0);
    CGContextAddArc(imageCtx, self.frame.size.width/2, self.frame.size.height/2, radius, 225*M_PI/180, 315*M_PI/180, 1);
    [[UIColor redColor]set];
    
    //Use shadow to create the Blur effect
    CGContextSetShadowWithColor(imageCtx, CGSizeMake(0, 0), self.angle/20, [UIColor blackColor].CGColor);
    
    //define the path
    CGContextSetLineWidth(imageCtx, TB_LINE_WIDTH);
    
    CGContextDrawPath(imageCtx, kCGPathStroke);
    
    //save the context content into the image mask
    CGImageRef mask = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    UIGraphicsEndImageContext();
    
    

    /** Clip Context to the mask **/
    CGContextSaveGState(ctx);
    
    CGContextClipToMask(ctx, self.bounds, mask);
    CGImageRelease(mask);
    
    

    /** THE GRADIENT **/
    
//    //list of components
//    CGFloat components[8] = {
//        0.0, 0.0, 1.0, 1.0,     // Start color - Blue
//        1.0, 0.0, 1.0, 1.0 };   // End color - Violet
//    
//    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
//    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, components, NULL, 2);
//    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
//    
//    //Gradient direction
//    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
//    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
//    
//    //Draw the gradient
//    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
//    CGGradientRelease(gradient), gradient = NULL;
    
    //// Gradient Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat gradientLocations[] = {0, 0.58, 0.79};


    
    //// Color Declarations
    UIColor* stimulusColor = [UIColor colorWithRed: 0.842 green: 0.029 blue: 0.038 alpha: 1];
    //[UIColor colorWithRed: 0.342 green: 0.842 blue: 0.304 alpha: 1];
    
    CGFloat stimulusColorRGBA[4];
    [stimulusColor getRed: &stimulusColorRGBA[0] green: &stimulusColorRGBA[1] blue: &stimulusColorRGBA[2] alpha: &stimulusColorRGBA[3]];
    UIColor* topColor = [UIColor colorWithRed: (stimulusColorRGBA[0] * 0.6) green: (stimulusColorRGBA[1] * 0.6) blue: (stimulusColorRGBA[2] * 0.6) alpha: (stimulusColorRGBA[3] * 0.6 + 0.4)];
    UIColor* bottomColor = [UIColor colorWithRed: (stimulusColorRGBA[0] * 0.4 + 0.6) green: (stimulusColorRGBA[1] * 0.4 + 0.6) blue: (stimulusColorRGBA[2] * 0.4 + 0.6) alpha: (stimulusColorRGBA[3] * 0.4 + 0.6)];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)bottomColor.CGColor, (id)[UIColor colorWithRed: 0.471 green: 0.721 blue: 0.452 alpha: 1].CGColor, (id)topColor.CGColor], gradientLocations);
    
    CGAffineTransform ovalTransform = CGAffineTransformMakeRotation(60*(-M_PI/180));
    
    
    CGContextDrawLinearGradient(ctx, gradient,
                                CGPointApplyAffineTransform(CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)), ovalTransform),
                                CGPointApplyAffineTransform(CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)+40), ovalTransform),
                                0);
     CGGradientRelease(gradient), gradient = NULL;
    
    CGContextRestoreGState(ctx);
    
    
/** Add some light reflection effects on the background circle**/
    
    CGContextSetLineWidth(ctx, 1);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    //Draw the outside light
    CGContextBeginPath(ctx);
    CGContextAddArc(ctx, self.frame.size.width/2  , self.frame.size.height/2, radius+TB_BACKGROUND_WIDTH/2, 0, ToRad(-self.angle), 1);
    [[UIColor colorWithWhite:1.0 alpha:0.05]set];
    CGContextDrawPath(ctx, kCGPathStroke);
    
    //draw the inner light
    CGContextBeginPath(ctx);
    CGContextAddArc(ctx, self.frame.size.width/2  , self.frame.size.height/2, radius-TB_BACKGROUND_WIDTH/2, 0, ToRad(-self.angle), 1);
    [[UIColor colorWithWhite:1.0 alpha:0.05]set];
    CGContextDrawPath(ctx, kCGPathStroke);
    
    
/** Draw the handle **/
    [self drawTheHandle:ctx];
    
}

/** Draw a white knob over the circle **/
-(void) drawTheHandle:(CGContextRef)ctx{
    
    CGContextSaveGState(ctx);
    
    //I Love shadows
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3, [UIColor blackColor].CGColor);
    
    //Get the handle position
    CGPoint handleCenter =  [self pointFromAngle: self.angle];
    
    //Translate the center of the context
    CGContextTranslateCTM(ctx, handleCenter.x + TB_LINE_WIDTH/2, handleCenter.y+TB_LINE_WIDTH/2);
    //Rotate the context
    CGContextRotateCTM(ctx, 90.0* M_PI/180);
    CGContextRotateCTM(ctx, -self.angle*M_PI/180);
    
    //Draw the handle
    double h = TB_LINE_WIDTH, b = TB_LINE_WIDTH;
    UIBezierPath* polygonPath = UIBezierPath.bezierPath;
    [polygonPath moveToPoint: CGPointMake(0, -h/2)];
    [polygonPath addLineToPoint: CGPointMake(b/2, h/2)];
    [polygonPath addLineToPoint: CGPointMake(-b/2, h/2)];
    [polygonPath closePath];
    [[UIColor colorWithWhite:1.0 alpha:0.7] set];
    [polygonPath fill];
    
    
    //Draw It!
    /**
    [[UIColor colorWithWhite:1.0 alpha:0.7]set];
    CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, TB_LINE_WIDTH, TB_LINE_WIDTH));
    */
    
    CGContextRestoreGState(ctx);
}


#pragma mark - Math -

/** Move the Handle **/
-(void)movehandle:(CGPoint)lastPoint{
    
    //Get the center
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    //Calculate the direction from a center point and a arbitrary position.
    float currentAngle = AngleFromNorth(centerPoint, lastPoint, NO);
    int angleInt = floor(currentAngle);
    
    //Store the new angle
    self.angle = 360 - angleInt;
    //Update the textfield 
    //_textField.text =  [NSString stringWithFormat:@"%d", self.angle];
    if (self.angle >=0 && self.angle<= 225){
        _textField.text = [NSString stringWithFormat:@"%d", 225-self.angle];
    }
    else if (self.angle >=315 && self.angle<=360){
        _textField.text =  [NSString stringWithFormat:@"%d", 225+(360-self.angle)];
    }

    
    //Redraw
    [self setNeedsDisplay];
}


/** Given the angle, get the point position on circumference **/
-(CGPoint)pointFromAngle:(int)angleInt{
    
    //Circle center
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2 - TB_LINE_WIDTH/2, self.frame.size.height/2 - TB_LINE_WIDTH/2);
    
    //The point position on the circumference
    CGPoint result;
    result.y = round(centerPoint.y + radius * sin(ToRad(-angleInt))) ;
    result.x = round(centerPoint.x + radius * cos(ToRad(-angleInt)));
    
    return result;
}

//Sourcecode from Apple example clockControl 
//Calculate the direction in degrees from a center point to an arbitrary position.
static inline float AngleFromNorth(CGPoint p1, CGPoint p2, BOOL flipped) {
    CGPoint v = CGPointMake(p2.x-p1.x,p2.y-p1.y);
    float vmag = sqrt(SQR(v.x) + SQR(v.y)), result = 0;
    v.x /= vmag;
    v.y /= vmag;
    double radians = atan2(v.y,v.x);
    result = ToDeg(radians);
    return (result >=0  ? result : result + 360.0);
}
@end


