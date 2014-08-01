//
//  TBCircularSlider.h
//  TB_CircularSlider
//
//  Created by Yari Dareglia on 1/12/13.
//  Copyright (c) 2013 Yari Dareglia. All rights reserved.
//

#import <UIKit/UIKit.h>

/** Parameters **/
#define TB_SLIDER_SIZE 320                          //The width and the heigth of the slider
#define TB_BACKGROUND_WIDTH 60                      //The width of the dark background
#define TB_LINE_WIDTH 40                            //The width of the active area (the gradient) and the width of the handle
#define TB_FONTSIZE 65                              //The size of the textfield font
#define TB_FONTFAMILY @"Futura-CondensedExtraBold"  //The font family of the textfield font
#define TB_RANGE_INITIAL_VALUE 0 //The initial value (degrees) of the range
#define TB_RANGE_FINAL_VALUE 270 //The final value (degrees) of the range

@interface TBCircularSlider : UIControl
@property (nonatomic,assign) int angle;
@property (nonatomic, assign) CGPoint startingPosition;
@property (nonatomic, assign) CGPoint currentPosition;
@property (nonatomic, strong) NSArray *buttonStates;
@end
