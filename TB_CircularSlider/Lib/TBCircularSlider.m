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
    int initialRadius;
    BOOL isVisible;
    BOOL ongoingAnimation;
    int numberOfIntervals;
    double statesMultiplier;
}

@property (nonatomic, strong) CAShapeLayer *handleLayer;
//@property (nonatomic, strong) TBHandleLayer *handleOriginalLayer;
@end

CABasicAnimation *makeRotateAnimation(float fromValue, float toValue) {
    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.fromValue = [NSNumber numberWithFloat:fromValue];
    rotate.toValue = [NSNumber numberWithFloat:toValue];
    rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotate.duration = 2.0;
    return rotate;
}

#pragma mark - Implementation -
@implementation TBCircularSlider

typedef void (^voidBlock)(void);
typedef float (^floatfloatBlock)(float);
typedef UIColor * (^floatColorBlock)(float);


#pragma mark - Initializers

/** 
Designated Initializer
 */
-(id)initWithFrame:(CGRect)frame buttonStates:(NSArray *)buttonStates{
    self = [super initWithFrame:frame];
    
    if(self){
        self.opaque = NO;
        //Define the circle radius taking into account the safe area
        radius = self.frame.size.width/2 - TB_SAFEAREA_PADDING;
        initialRadius = radius -50;
        isVisible = NO;
        ongoingAnimation = NO;
        self.buttonStates = buttonStates;
        
        //Configure the states of the button
        numberOfIntervals =  (int)[self.buttonStates count]-1;
        //Get the states multiplier
        statesMultiplier = TB_RANGE_FINAL_VALUE/numberOfIntervals;
        
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

-(id)initWithFrame:(CGRect)frame{
    return  [self initWithFrame:frame buttonStates:@[@0.2, @0.4, @0.8, @1, @1.2, @1.4, @1.6, @1.8, @2.0, @2.2, @2.4, @2.6]];
}

#pragma mark - Getters and Setters

-(CALayer *)handleLayer{
    
    if (!_handleLayer) {
        //_handleLayer = [CALayer layer];
        _handleLayer = [CAShapeLayer layer];
    }
    return _handleLayer;
}

#pragma mark - UIControl Override
/** Tracking is started **/
-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super beginTrackingWithTouch:touch withEvent:event];
    [self.handleLayer removeAllAnimations];
    self.startingPosition = [touch locationInView:self];
    [self drawHandleLayerForAnimation];
    ongoingAnimation = YES;
    [self animateAppereanceOfHandleWithOpacityEffect:self.handleLayer];
    isVisible = YES;
    [self setNeedsDisplay];
    
    //We need to track continuously
    return YES;
}

/** Track continuous touch event (like drag) **/
-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super continueTrackingWithTouch:touch withEvent:event];
    
    if (!ongoingAnimation) {
        //Get touch location
        CGPoint lastPoint = [touch locationInView:self];
        self.currentPosition = lastPoint;
        
        // Find if the last point touched is in a valid angle
        //Get the center
        CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        
        //Calculate the direction from a center point and a arbitrary position.
        float currentAngle = AngleFromNorth(centerPoint, lastPoint, NO);
        int angle = 360 - floor(currentAngle);
        
        if (angle>225 && angle<315) {
            if (angle>225 && angle<240) {
                angle = 360 -225;
                [self moveHandleToAngle:angle];
            } else if(angle>300 && angle<315){
                angle = 360-315;
                [self moveHandleToAngle:angle];
            }

        }
        else {
            //Use the location to design the Handle
            [self movehandleToLastPoint:self.currentPosition];
            
            //Control value has changed, let's notify that
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
    return YES;
}

/** Track is finished **/
-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super endTrackingWithTouch:touch withEvent:event];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animateDisappearanceOfHandleWithOpacityEffect:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:self.handleLayer,@"handle", nil] repeats:NO];
    
    [self drawHandleLayerForAnimation];
    
    //[self animateDisappearanceOfHandle:self.handleLayer];
    isVisible = NO;
    [self setNeedsDisplay];
}

#pragma mark - Sublayer Manipulation

/** This method changes the anchor point of a layer and updates the position of the layer to keep it in the same
 place it was. This is useful to do animations, specially rotations when the point to be the center of the rotation is an arbitrary point
 given in the superlayer.
*/
-(void)changeAnchorPointOfLayer:(CALayer*)aLayer toPoint:(CGPoint)aPoint
{

    CGFloat minX   = CGRectGetMinX(aLayer.frame);
    CGFloat minY   = CGRectGetMinY(aLayer.frame);
    CGFloat width  = CGRectGetWidth(aLayer.frame);
    CGFloat height = CGRectGetHeight(aLayer.frame);
    CGPoint anchorPoint =  CGPointMake((aPoint.x-minX)/width,
                                       (aPoint.y-minY)/height);
    
    //Changing the anchor point modifies the position of the handlelayer. Reposition the layer
    CGPoint newPoint = CGPointMake(aLayer.bounds.size.width * anchorPoint.x,
                                   aLayer.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(aLayer.bounds.size.width * aLayer.anchorPoint.x,
                                   aLayer.bounds.size.height * aLayer.anchorPoint.y);
    CGPoint position = aLayer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    //Update the anchor point and the position
    aLayer.position = position;
    aLayer.anchorPoint = anchorPoint;
}


/**This method retrives the corresponding position of a layer with a modified anchor point (different from 0.5,0.5)
when the layer is going to be moved to a point represented in the superlayer
*/
-(CGPoint)positionInLayerWithModifiedAnchorPoint:(CALayer*)aLayer withPointInSuperlayer:(CGPoint)aPoint
{
    CGPoint anchorPoint = aLayer.anchorPoint;
    CGRect bounds = aLayer.bounds;
    CGPoint newPosition;
    // 0.5, 0.5 is the default anchorPoint; calculate the difference
    //and multiply by the bounds of the view
    newPosition.x = (0.5 * bounds.size.width) + (anchorPoint.x - 0.5) * bounds.size.width;
    newPosition.x +=  aPoint.x;
    newPosition.y = (0.5 * bounds.size.height) + (anchorPoint.y - 0.5) * bounds.size.height;
    newPosition.y  += aPoint.y;
    
    return newPosition;
}


#pragma mark - Drawing Functions

//Use the draw rect to draw the Background, the Circle and the Handle 
-(void)drawRect:(CGRect)rect{
    
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self drawButtonCircle];

    
    /**Draw the level Indicator Circle **/
    //[self drawLevelIndicatorCircleInRect:rect usingContext:ctx];
    
    /** Draw the handle of the level indicator **/
    if (isVisible) {
        [self drawLevelIndicatorCircleInRect:rect usingContext:ctx];
        [self drawHandle:ctx];
        
    }
}

-(CGPoint) pointForTrapezoidWithAngle:(float)a andRadius:(float)r  forCenter:(CGPoint)p{
    return CGPointMake(p.x + r*cos(a), p.y + r*sin(a));
}

-(void)drawGradientInContext:(CGContextRef)ctx  startingAngle:(float)a endingAngle:(float)b intRadius:(floatfloatBlock)intRadiusBlock outRadius:(floatfloatBlock)outRadiusBlock withGradientBlock:(floatColorBlock)colorBlock withSubdiv:(int)subdivCount withCenter:(CGPoint)center withScale:(float)scale
{
    float angleDelta = (b-a)/subdivCount;
    float fractionDelta = 1.0/subdivCount;
    
    CGPoint p0,p1,p2,p3, p4,p5;
    float currentAngle=a;
    p4=p0 = [self pointForTrapezoidWithAngle:currentAngle andRadius:intRadiusBlock(0) forCenter:center];
    p5=p3 = [self pointForTrapezoidWithAngle:currentAngle andRadius:outRadiusBlock(0) forCenter:center];
    CGMutablePathRef innerEnveloppe=CGPathCreateMutable(),
    outerEnveloppe=CGPathCreateMutable();
    
    CGPathMoveToPoint(outerEnveloppe, 0, p3.x, p3.y);
    CGPathMoveToPoint(innerEnveloppe, 0, p0.x, p0.y);
    CGContextSaveGState(ctx);
    
    CGContextSetLineWidth(ctx, 1);
    
    for (int i=0;i<subdivCount;i++)
    {
        float fraction = (float)i/subdivCount;
        currentAngle=a+fraction*(b-a);
        CGMutablePathRef trapezoid = CGPathCreateMutable();
        
        p1 = [self pointForTrapezoidWithAngle:currentAngle+angleDelta andRadius:intRadiusBlock(fraction+fractionDelta) forCenter:center];
        p2 = [self pointForTrapezoidWithAngle:currentAngle+angleDelta andRadius:outRadiusBlock(fraction+fractionDelta) forCenter:center];
        
        CGPathMoveToPoint(trapezoid, 0, p0.x, p0.y);
        CGPathAddLineToPoint(trapezoid, 0, p1.x, p1.y);
        CGPathAddLineToPoint(trapezoid, 0, p2.x, p2.y);
        CGPathAddLineToPoint(trapezoid, 0, p3.x, p3.y);
        CGPathCloseSubpath(trapezoid);
        
        CGPoint centerofTrapezoid = CGPointMake((p0.x+p1.x+p2.x+p3.x)/4, (p0.y+p1.y+p2.y+p3.y)/4);
        
        CGAffineTransform t = CGAffineTransformMakeTranslation(-centerofTrapezoid.x, -centerofTrapezoid.y);
        CGAffineTransform s = CGAffineTransformMakeScale(scale, scale);
        CGAffineTransform concat = CGAffineTransformConcat(t, CGAffineTransformConcat(s, CGAffineTransformInvert(t)));
        CGPathRef scaledPath = CGPathCreateCopyByTransformingPath(trapezoid, &concat);
        
        CGContextAddPath(ctx, scaledPath);
        CGContextSetFillColorWithColor(ctx,colorBlock(fraction).CGColor);
        CGContextSetStrokeColorWithColor(ctx, colorBlock(fraction).CGColor);
        CGContextSetMiterLimit(ctx, 0);
        
        CGContextDrawPath(ctx, kCGPathFillStroke);
        
        CGPathRelease(trapezoid);
        p0=p1;
        p3=p2;
        
        CGPathAddLineToPoint(outerEnveloppe, 0, p3.x, p3.y);
        CGPathAddLineToPoint(innerEnveloppe, 0, p0.x, p0.y);
    }
    CGContextSetLineWidth(ctx, 10);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextAddPath(ctx, outerEnveloppe);
    CGContextAddPath(ctx, innerEnveloppe);
    CGContextMoveToPoint(ctx, p0.x, p0.y);
    CGContextAddLineToPoint(ctx, p3.x, p3.y);
    CGContextMoveToPoint(ctx, p4.x, p4.y);
    CGContextAddLineToPoint(ctx, p5.x, p5.y);
    CGContextStrokePath(ctx);
}

-(void)drawButtonCircle
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //Create the path
    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, radius -TB_LINE_WIDTH/2, 0, M_PI *2, 0);
    
    //Set the stroke color to black
    [[UIColor grayColor]setStroke];
    
    //Define line width and cap

    CGContextSetLineCap(ctx, kCGLineCapButt);
    
    //draw it!
    [[UIColor grayColor] setFill];
    CGContextDrawPath(ctx, kCGPathEOFillStroke);
    
    
}


-(void)drawLevelIndicatorCircleInRect:(CGRect)rect usingContext:(CGContextRef)ctx
{
    /** Draw the Background **/
    
    
    //** Draw the circle that indicates the level (using a clipped gradient) **/
    
    /** Create THE MASK Image **/
    UIGraphicsBeginImageContext(CGSizeMake(TB_SLIDER_SIZE,TB_SLIDER_SIZE));
    CGContextRef imageCtx = UIGraphicsGetCurrentContext();
    
    //CGContextAddArc(imageCtx, self.frame.size.width/2  , self.frame.size.height/2, radius, 0, ToRad(self.angle), 0);
    CGContextAddArc(imageCtx, self.frame.size.width/2, self.frame.size.height/2, radius, 225*M_PI/180, 315*M_PI/180, 1);
    [[UIColor redColor]set];
    
    
    //define the path
    CGContextSetLineWidth(imageCtx, TB_LINE_WIDTH);
    CGContextSetLineCap(imageCtx, kCGLineCapRound);
    
    CGContextDrawPath(imageCtx, kCGPathStroke);
    
    //save the context content into the image mask
    CGImageRef mask = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    UIGraphicsEndImageContext();
    
    /** Clip Context to the mask **/
    CGContextSaveGState(ctx);
    
    CGContextClipToMask(ctx, self.bounds, mask);
    CGImageRelease(mask);
    
    /** THE GRADIENT **/
    /*
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
    */
//    [self drawGradientInContext:ctx  startingAngle:M_PI/16 endingAngle:2*M_PI-M_PI/16 intRadius:^float(float f) {
//        //        return 0*f + radius/2*(1-f);
//        return 200+10*sin(M_PI*2*f*7);
//        //        return 50+sqrtf(f)*200;
//        //        return radius/2;
//    } outRadius:^float(float f) {
//        //         return radius *f + radius/2*(1-f);
//        return radius;
//        //        return 300+10*sin(M_PI*2*f*17);
//    } withGradientBlock:^UIColor *(float f) {
//        
//        //        return [UIColor colorWithHue:f saturation:1 brightness:1 alpha:1];
//        float sr=90, sg=54, sb=255;
//        float er=218, eg=0, eb=255;
//        return [UIColor colorWithRed:(f*sr+(1-f)*er)/255. green:(f*sg+(1-f)*eg)/255. blue:(f*sb+(1-f)*eb)/255. alpha:1];
//        
//    } withSubdiv:256 withCenter:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)) withScale:1];

    
    CGContextRestoreGState(ctx);
    
}

-(void)drawLevelIndicatorCircleOriginalVersionInRect:(CGRect)rect usingContext:(CGContextRef)ctx
{
    /** Draw the Background **/
    
    //Create the path
    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, radius, 0, M_PI *2, 0);
    
    //Set the stroke color to black
    [[UIColor grayColor]setStroke];
    
    //Define line width and cap
    CGContextSetLineWidth(ctx, TB_BACKGROUND_WIDTH);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    
    //draw it!
    CGContextDrawPath(ctx, kCGPathStroke);
    
    //** Draw the circle that indicates the level (using a clipped gradient) **/
    
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
    /* *** Original strategy *****
     //list of components
     CGFloat components[8] = {
     0.0, 0.0, 1.0, 1.0,     // Start color - Blue
     1.0, 0.0, 1.0, 1.0 };   // End color - Violet
     
     CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
     CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, components, NULL, 2);
     CGColorSpaceRelease(baseSpace), baseSpace = NULL;
     
     //Gradient direction
     CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
     CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
     
     //Draw the gradient
     CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
     CGGradientRelease(gradient), gradient = NULL;
     */
    
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
    
}

/** Draw a white knob over the circle **/
-(void) drawTheHandleOriginalVersion:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    
    //I Love shadows
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3, [UIColor blackColor].CGColor);
    
    //Get the handle position
    CGPoint handleCenter =  [self handleInitialCenterPoint];

    
    //Draw It!
    
    [[UIColor colorWithWhite:1.0 alpha:0.7]set];
    CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, TB_LINE_WIDTH, TB_LINE_WIDTH));
    
}

/** Draw a white triangle over the circle, that keeps pointing perperdicularly to the circle **/
-(void) drawTheTriangleHandle:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    
    //I Love shadows
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3, [UIColor blackColor].CGColor);
    
    //Get the handle position
    CGPoint handleCenter =  [self handleInitialCenterPoint];
    
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
    
    CGContextRestoreGState(ctx);
}

/** Draw a white knob over the circle **/
-(void) drawHandle:(CGContextRef)ctx
{
    //Set the positioning of the handleLayer in it superlayer
    CGPoint handleInitialCenterPoint = [self handleInitialCenterPoint];
    CGRect frame = CGRectMake(handleInitialCenterPoint.x, handleInitialCenterPoint.y, TB_LINE_WIDTH, TB_LINE_WIDTH);
    [self.handleLayer setFrame:frame];
    self.handleLayer.path = [[self circularPathWithFrame:frame] CGPath];
    //Change the background color, for developing version only
    //self.handleLayer.backgroundColor = [[UIColor redColor] CGColor];
    self.handleLayer.fillColor = [[UIColor colorWithWhite:1.0 alpha:0.7] CGColor];
    //self.handleLayer.fillColor = [[UIColor blueColor] CGColor];
    
    if (isVisible) {
        CGContextSaveGState(ctx);
        
        //Get the handle position
        CGPoint handleCenter =  [self handleInitialCenterPoint];
        
        //Draw It!
        [[UIColor colorWithWhite:1.0 alpha:0.7]set];
        CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, TB_LINE_WIDTH, TB_LINE_WIDTH));
        
        CGContextRestoreGState(ctx);
    }

}

-(void)drawHandleLayerForAnimation{
    [self.layer addSublayer:self.handleLayer];
}

- (UIBezierPath *)circularPathWithFrame:(CGRect)frame
{
    CGPoint center = CGPointMake(frame.size.width/2,frame.size.height/2);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:frame.size.width/2 startAngle:0 endAngle:ToRad(360) clockwise:YES];
    return path;
}

- (UIBezierPath *)triangularPathWithFrame:(CGRect)frame
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    double h = frame.size.height, w = frame.size.width;
    [path moveToPoint: CGPointMake(w/2, 0)];
    [path addLineToPoint: CGPointMake(0, h)];
    [path addLineToPoint: CGPointMake(w, h)];

    [path closePath];
    return path;
}

-(CGPoint)handleInitialCenterPoint{
    CGPoint handleInitialCenterPoint;
    handleInitialCenterPoint =  [self pointFromAngle:self.angle toRadius:radius];
    return handleInitialCenterPoint;
}

#pragma mark - Animation

-(void)animateAppearanceOfHandleWithChangeInPositionEffect:(CAShapeLayer *)handleLayer
{
    /** Apply the moving animation to the handle **/
    //Get the initial point and final points of the animation
    //CGPoint initialPoint  = [self pointFromAngle:self.angle toRadius:initialRadius];
    CGPoint initialPoint = CGPointMake(self.frame.size.width/2 , self.frame.size.height/2);
    CGPoint finalPoint = handleLayer.position;
    NSLog(@"The angle is: %d",self.angle);
    NSLog(@"Radius: %d", radius);
    NSLog(@"Initial Radius: %d",initialRadius);

    NSLog(@"Initial Position Appear animation :(%f,%f)", initialPoint.x, initialPoint.y);
    NSLog(@"Final   Position Appear animation :(%f,%f)", finalPoint.x, finalPoint.y);
    //finalPoint =  [self positionInLayerWithModifiedAnchorPoint:self.handleLayer withPointInSuperlayer:finalPoint];
    //Create the animation
    CABasicAnimation *translateHandleAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    translateHandleAnimation.fromValue = [NSValue valueWithCGPoint:initialPoint];
    translateHandleAnimation.toValue = [NSValue valueWithCGPoint:finalPoint];
    translateHandleAnimation.duration = .001;
    [translateHandleAnimation setValue:handleLayer forKey:@"animationLayer"];
    
    handleLayer.position = finalPoint;
    
    [handleLayer addAnimation:translateHandleAnimation forKey:@"position"];
}


-(void)animateDisappearanceOfHandleWithChangeInPositionEffect:(NSTimer *)theTimer {
    
    CALayer *handleLayer = [theTimer.userInfo objectForKey:@"handle"];
    /** Apply the moving animation to the handle **/
    NSLog(@"The angle is: %d",self.angle);
    //Get the initial point and final points of the animation
    CGPoint initialPoint = handleLayer.position;
    CGPoint finalPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    //Create the animation
    NSLog(@"Initial Position Disappear animation: (%f,%f)", initialPoint.x, initialPoint.y);
    NSLog(@"Final   Position Disappear animation: (%f,%f)", finalPoint.x, finalPoint.y);
    
    CABasicAnimation *translateHandleAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    translateHandleAnimation.fromValue = [NSValue valueWithCGPoint:initialPoint];
    translateHandleAnimation.toValue = [NSValue valueWithCGPoint:finalPoint];
    translateHandleAnimation.duration = 1;
    [translateHandleAnimation setValue:handleLayer forKey:@"animationLayer"];
    
    handleLayer.position = finalPoint;
    
    [handleLayer addAnimation:translateHandleAnimation forKey:@"position"];
}


-(void)animateDisappearanceOfHandleWithOpacityEffect:(NSTimer *)theTimer{
    CALayer *handleLayer = [theTimer.userInfo objectForKey:@"handle"];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.6;
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.additive = NO;
    [animation setValue:handleLayer forKey:@"animationLayer"];
    [animation setValue:[NSNumber numberWithInt:0] forKey:@"animationProcess"];
    animation.delegate = self;
    [handleLayer addAnimation:animation forKey:@"opacityOUT"];
}


-(void)animateAppereanceOfHandleWithOpacityEffect:(CAShapeLayer *)handleLayer{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.1;
    animation.fromValue = [NSNumber numberWithFloat:0.0f];
    animation.toValue = [NSNumber numberWithFloat:1.0f];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    animation.additive = NO;
    [animation setValue:handleLayer forKey:@"animationLayer"];
    [animation setValue:[NSNumber numberWithInt:1] forKey:@"animationProcess"];
    animation.delegate = self;
    [handleLayer addAnimation:animation forKey:@"opacityIN"];
}


-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    CALayer *layer = [anim valueForKey:@"animationLayer"];
    int animationProcess = (int)[[anim valueForKey:@"animationProcess"] integerValue];
    if ([layer isEqual:self.handleLayer]) {
        if (animationProcess ==1) {
            //Appearing of the handle
            isVisible = YES;
        } else{
            isVisible = NO;
        }
        [self.handleLayer removeFromSuperlayer];
        ongoingAnimation = NO;
        [self setNeedsDisplay];
    }
}

-(void)animationDidStart:(CAAnimation *)anim{
  
}


#pragma mark - Math -

/** Move the Handle **/
-(void)movehandleToLastPoint:(CGPoint)lastPoint{
    //Get the center
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    //Calculate the direction from a center point and a arbitrary position.
    float currentAngle = AngleFromNorth(centerPoint, lastPoint, NO);
    int angleInt = floor(currentAngle);
    
    //Store the new angle
    self.angle = 360 - angleInt;
    double value = [self calculateButtonValueForAngle:self.angle];
    //Update the textfield
    _textField.text = [NSString stringWithFormat:@"%.01f", value];
    //Redraw
    [self setNeedsDisplay];
    [self calculateButtonValueForAngle:self.angle];
}


-(void)moveHandleToAngle:(int)angle{
    //Store the new angle
    self.angle = 360 - angle;
    //Update the textfield
    double value = [self calculateButtonValueForAngle:self.angle];
    //Update the textfield
    _textField.text = [NSString stringWithFormat:@"%.01f", value];
    //Redraw
    [self setNeedsDisplay];
    [self calculateButtonValueForAngle:self.angle];
}

-(int)linearizeAngleInRange225_315:(int)angle{
    int value = 0;
    if (angle >=0 && angle<= 225){
        value = 225-angle;
    }
    else if(angle>=315 && angle<=360){
        value = 225+(360-angle);
    }
    return value;
}


-(double)calculateButtonValueForAngle:(int)angle{
    double buttonValue = 0;
    int currentState =[self linearizeAngleInRange225_315:angle];
    int indexOfCurrentButtonState = round(currentState /statesMultiplier);
    buttonValue = [(NSNumber*)[self.buttonStates objectAtIndex:indexOfCurrentButtonState]doubleValue];
    NSLog(@"The button value to set is => %.01f", buttonValue);
    return  buttonValue;
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

/** Given the angle, get the point position on circumference **/
-(CGPoint)pointFromAngle:(int)angleInt toRadius:(int)aRadius{
    
    //Center of the handle. (if the default anchor point is used, this is the position value);
    CGPoint centerPoint;
    
    if (aRadius == radius) {
        centerPoint = CGPointMake(self.frame.size.width/2 - TB_LINE_WIDTH/2, self.frame.size.height/2 - TB_LINE_WIDTH/2);
    } else {
        centerPoint =CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    }
    
    
    
    //The point position on the circumference
    CGPoint result;
    result.y = round(centerPoint.y + aRadius * sin(ToRad(-angleInt))) ;
    result.x = round(centerPoint.x + aRadius * cos(ToRad(-angleInt)));
    
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


