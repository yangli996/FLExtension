//
//  NSString+FLExtension.h
//  FLExtension
//
//  Created by 紫贝壳 on 15/8/11.
//  Copyright (c) 2015年 FL. All rights reserved.
//

#import <Foundation/Foundation.h>

///----------------------------------
///  @name 字符串NSString常用验证扩展
///----------------------------------
@interface NSString (FLExtension)

- (BOOL)empty;

- (BOOL)eq:(NSString *)other;

- (BOOL)isValueOf:(NSArray *)array;

- (BOOL)isValueOf:(NSArray *)array
       caseInsens:(BOOL)caseInsens;

- (BOOL)isNumber;

- (BOOL)isEmail;

- (BOOL)isUrl;

- (BOOL)isIPAddress;

- (NSString *)substringFromIndex:(NSUInteger)from
                     untilString:(NSString *)string;

@end
