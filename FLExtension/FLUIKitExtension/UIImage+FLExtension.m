//
//  UIImage+FLExtension.m
//  FLExtension
//
//  Created by 紫贝壳 on 15/8/11.
//  Copyright (c) 2015年 FL. All rights reserved.
//

#import "UIImage+FLExtension.h"
#import "UIColor+FLExtension.h"
#import <objc/runtime.h>
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180 / M_PI;};


CGSize sizeForSizeString(NSString *sizeString)
{
    NSArray *array = [sizeString componentsSeparatedByString:@"x"];
    if(array.count != 2) return CGSizeZero;
    
    return CGSizeMake([array[0] floatValue], [array[1] floatValue]);
}

UIColor *colorForColorString(NSString *colorString)
{
    if(!colorString)
    {
        return [UIColor lightGrayColor];
    }
    
    SEL colorSelector = NSSelectorFromString([colorString stringByAppendingString:@"Color"]);
    if([UIColor respondsToSelector:colorSelector])
    {
        return [UIColor performSelector:colorSelector];
    }
    else
    {
        return [UIColor colorWithHexString:colorString];
    }
}

@implementation UIImage (FLExtension)


+ (void)load
{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        [self exchangeClassMethod:@selector(imageNamed:) withMethod:@selector(dummy_imageNamed:)];
    });
}

+ (UIImage *)dummy_imageNamed:(NSString *)name
{
    if(!name) return nil;
    
    UIImage *result;
    
    NSArray *array = [name componentsSeparatedByString:@"."];
    if([[array[0] lowercaseString] isEqualToString:@"dummy"])
    {
        NSString *sizeString = array[1];
        if(!sizeString) return nil;
        
        NSString *colorString = nil;
        if(array.count >= 3)
        {
            colorString = array[2];
        }
        
        return [self dummyImageWithSize:sizeForSizeString(sizeString) color:colorForColorString(colorString)];
    }
    else
    {
        result = [self dummy_imageNamed:name];
    }
    
    return result;
}

+ (UIImage *)dummyImageWithSize:(CGSize)size color:(UIColor *)color
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
    
    [color setFill];
    CGContextFillRect(context, rect);
    
    [[UIColor blackColor] setFill];
    NSString *sizeString = [NSString stringWithFormat:@"%d x %d", (int)size.width, (int)size.height];
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes = @{NSParagraphStyleAttributeName : style};
        [sizeString drawInRect:rect withAttributes:attributes];
    }
    else
    {
        [sizeString drawInRect:rect withFont:[UIFont systemFontOfSize:12] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentCenter];
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return result;
}

+ (void)exchangeClassMethod:(SEL)selector1 withMethod:(SEL)selector2
{
    Method fromMethod = class_getClassMethod(self, selector1);
    Method toMethod = class_getClassMethod(self, selector2);
    method_exchangeImplementations(fromMethod, toMethod);
}


- (UIImage *)blendOverlay
{
    UIGraphicsBeginImageContext(CGSizeMake(self.size.width, self.size.height));
    [self drawInRect:CGRectMake(0.0, 0.0, self.size.width, self.size.height) blendMode:kCGBlendModeOverlay alpha:1];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)maskWithImage:(UIImage *)image andSize:(CGSize)size
{
    CGContextRef mainViewContentContext;
    CGColorSpaceRef colorSpace;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    mainViewContentContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if(mainViewContentContext == NULL) return NULL;
    
    CGContextClipToMask(mainViewContentContext, CGRectMake(0, 0, size.width, size.height), image.CGImage);
    CGContextDrawImage(mainViewContentContext, CGRectMake(0, 0, size.width, size.height), self.CGImage);
    CGImageRef mainViewContentBitmapContext = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    UIImage *returnImage = [UIImage imageWithCGImage:mainViewContentBitmapContext];
    CGImageRelease(mainViewContentBitmapContext);
    
    return returnImage;
}

- (UIImage *)maskWithImage:(UIImage *)image
{
    CGContextRef mainViewContentContext;
    CGColorSpaceRef colorSpace;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    mainViewContentContext = CGBitmapContextCreate(NULL, self.size.width, self.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if(mainViewContentContext == NULL) return NULL;
    
    CGContextClipToMask(mainViewContentContext, CGRectMake(0, 0, self.size.width, self.size.height), image.CGImage);
    CGContextDrawImage(mainViewContentContext, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
    CGImageRef mainViewContentBitmapContext = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    UIImage *returnImage = [UIImage imageWithCGImage:mainViewContentBitmapContext];
    CGImageRelease(mainViewContentBitmapContext);
    
    return returnImage;
}

- (UIImage *)imageAtRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *subImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return subImage;
}

- (BOOL)isRetina
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0 || [UIScreen mainScreen].scale == 3.0))
        return YES;
    else
        return NO;
}

- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    if([self isRetina])
    {
        CGSize retinaTargetSize = CGSizeMake(targetSize.width*2, targetSize.height*2);
        if(!CGSizeEqualToSize(imageSize, retinaTargetSize)) targetSize = retinaTargetSize;
    }
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if(CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor) thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        else if(widthFactor < heightFactor) thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
    }
    
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil);
    
    return newImage ;
}

- (UIImage *)imageByScalingProportionallyToMaximumSize:(CGSize)targetSize
{
    if([self isRetina])
    {
        CGSize retinaMaxtSize = CGSizeMake(targetSize.width*2, targetSize.height*2);
        if(!CGSizeEqualToSize(targetSize, retinaMaxtSize)) targetSize = retinaMaxtSize;
    }
    
    if((self.size.width > targetSize.width || targetSize.width == targetSize.height) && self.size.width > self.size.height)
    {
        float factor = (targetSize.width*100)/self.size.width;
        float newWidth = (self.size.width*factor)/100;
        float newHeight = (self.size.height*factor)/100;
        
        CGSize newSize = CGSizeMake(newWidth, newHeight);
        UIGraphicsBeginImageContext(newSize);
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }
    else if((self.size.height > targetSize.height || targetSize.width == targetSize.height) && self.size.width < self.size.height)
    {
        float factor = (targetSize.height*100)/self.size.height;
        float newWidth = (self.size.width*factor)/100;
        float newHeight = (self.size.height*factor)/100;
        
        CGSize newSize = CGSizeMake(newWidth, newHeight);
        UIGraphicsBeginImageContext(newSize);
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }
    else if((self.size.height > targetSize.height || self.size.width > targetSize.width ) && self.size.width == self.size.height)
    {
        float factor = (targetSize.height*100)/self.size.height;
        float newDimension = (self.size.height*factor)/100;
        
        CGSize newSize = CGSizeMake(newDimension, newDimension);
        UIGraphicsBeginImageContext(newSize);
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }
    else
    {
        CGSize newSize = CGSizeMake(self.size.width, self.size.height);
        UIGraphicsBeginImageContext(newSize);
        [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    }
    
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}


- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    if([self isRetina])
    {
        CGSize retinaTargetSize = CGSizeMake(targetSize.width*2, targetSize.height*2);
        if(!CGSizeEqualToSize(imageSize, retinaTargetSize)) targetSize = retinaTargetSize;
    }
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if(CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor < heightFactor) scaleFactor = widthFactor;
        else scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor < heightFactor) thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        else if(widthFactor > heightFactor) thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
    }
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil);
    
    return newImage ;
}


- (UIImage *)imageByScalingToSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil);
    
    return newImage ;
}


- (UIImage *)imageRotatedByRadians:(CGFloat)radians
{
    return [self imageRotatedByDegrees:RadiansToDegrees(radians)];
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (BOOL)hasAlpha
{
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    return (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
}

- (UIImage *)removeAlpha
{
    if(![self hasAlpha]) return self;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef mainViewContentContext = CGBitmapContextCreate(NULL, self.size.width, self.size.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(mainViewContentContext, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
    CGImageRef mainViewContentBitmapContext = CGBitmapContextCreateImage(mainViewContentContext);
    CGContextRelease(mainViewContentContext);
    UIImage *returnImage = [UIImage imageWithCGImage:mainViewContentBitmapContext];
    CGImageRelease(mainViewContentBitmapContext);
    
    return returnImage;
}

- (UIImage *)fillAlpha
{
    CGRect im_r;
    im_r.origin = CGPointZero;
    im_r.size = self.size;
    
    UIGraphicsBeginImageContext(self.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context,im_r);
    [self drawInRect:im_r];
    
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

- (UIImage *)fillAlphaWithColor:(UIColor *)color
{
    CGRect im_r;
    im_r.origin = CGPointZero;
    im_r.size = self.size;
    
    CGColorRef cgColor = [color CGColor];
    
    UIGraphicsBeginImageContext(self.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, cgColor);
    CGContextFillRect(context,im_r);
    [self drawInRect:im_r];
    
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

- (BOOL)isGrayscale
{
    CGImageRef imgRef = [self CGImage];
    CGColorSpaceModel clrMod = CGColorSpaceGetModel(CGImageGetColorSpace(imgRef));
    
    switch(clrMod)
    {
        case kCGColorSpaceModelMonochrome :
            return YES;
        default:
            return NO;
    }
}

- (UIImage *)imageToGrayscale
{
    CGSize size = self.size;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, rect, [self CGImage]);
    CGImageRef grayscale = CGBitmapContextCreateImage(context);
    UIImage *returnImage = [UIImage imageWithCGImage:grayscale];
    CGContextRelease(context);
    CGImageRelease(grayscale);
    
    return returnImage;
}

- (UIImage *)imageToBlackAndWhite
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, self.size.width, self.size.height, 8, self.size.width, colorSpace, kCGImageAlphaNone);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, self.size.width, self.size.height), [self CGImage]);
    
    CGImageRef bwImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *returnImage = [UIImage imageWithCGImage:bwImage];
    CGImageRelease(bwImage);
    
    return returnImage;
}

- (UIImage *)invertColors
{
    UIGraphicsBeginImageContext(self.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, self.size.width, self.size.height));
    
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

- (UIImage *)bloom:(float)radius intensity:(float)intensity
{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *image = [CIImage imageWithCGImage:[self CGImage]];
    CIFilter *filter = [CIFilter filterWithName:@"CIBloom"];
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:intensity] forKey:@"inputIntensity"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage];
    CFRelease(cgImage);
    
    return returnImage;
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)boxBlurImageWithBlur:(CGFloat)blur
{
    if(blur < 0.f || blur > 1.f)
    {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 50);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = self.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL);
        
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if(error)
        NSLog(@"Error from convolution %ld", error);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data, outBuffer.width, outBuffer.height, 8, outBuffer.rowBytes, colorSpace, kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}



@end
