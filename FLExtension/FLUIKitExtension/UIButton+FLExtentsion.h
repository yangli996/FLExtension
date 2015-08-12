//
//  UIButton+FLExtentsion.h
//  FLExtension
//
//  Created by 紫贝壳 on 15/8/11.
//  Copyright (c) 2015年 FL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIFont+FLExtension.h"

@interface UIButton (FLExtentsion)

+ (id)initWithFrame:(CGRect)frame;

+ (id)initWithFrame:(CGRect)frame
              title:(NSString *)title;

+ (id)initWithFrame:(CGRect)frame
              title:(NSString *)title
    backgroundImage:(UIImage *)backgroundImage;

+ (id)initWithFrame:(CGRect)frame
              title:(NSString *)title
    backgroundImage:(UIImage *)backgroundImage
highlightedBackgroundImage:(UIImage *)highlightedBackgroundImage;


+ (id)initWithFrame:(CGRect)frame
              title:(NSString *)title
              color:(UIColor *)color;


+ (id)initWithFrame:(CGRect)frame
              title:(NSString *)title
              color:(UIColor *)color
   highlightedColor:(UIColor *)highlightedColor;


+ (id)initWithFrame:(CGRect)frame
              color:(UIColor *)color;


+ (id)initWithFrame:(CGRect)frame
              color:(UIColor *)color
   highlightedColor:(UIColor *)highlightedColor;


+ (id)initWithFrame:(CGRect)frame
              image:(UIImage *)image;


+ (id)initWithFrame:(CGRect)frame
              image:(UIImage *)image
   highlightedImage:(UIImage *)highlightedImage;


- (void)setTitleFont:(FontName)fontName
                size:(CGFloat)size;


- (void)setTitleColor:(UIColor *)color;


- (void)setTitleColor:(UIColor *)color
     highlightedColor:(UIColor *)highlightedColor;


-(void)setCornerRadius:(CGFloat)radius;

@end
