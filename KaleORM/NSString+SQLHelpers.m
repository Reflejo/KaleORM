//
//  NSString+SQLHelpers.m
//  Test
//
//  Created by Martin Conte Mac Donell on 3/18/14.
//  Copyright (c) 2014 Kicksend. All rights reserved.
//

#import "NSString+SQLHelpers.h"

@implementation NSString (SQLHelpers)

/*
 * Converts CamelCase string to snake_case. (example: KSAlbum would be converted to ks_album)
 */
- (NSString *)underscoreString
{
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"(.)([A-Z][a-z]+)"
                                                  options:0 error:nil];
    
    NSString *string = [regex stringByReplacingMatchesInString:self
                                                       options:0
                                                         range:NSMakeRange(0, [self length] - 0)
                                                  withTemplate:@"$1_$2"];
    
    regex = [NSRegularExpression regularExpressionWithPattern:@"([a-z0-9])([A-Z])"
                                                      options:0 error:nil];
    
    return [[regex stringByReplacingMatchesInString:string
                                            options:0
                                              range:NSMakeRange(1, [string length]-1)
                                       withTemplate:@"$1_$2"] lowercaseString];
    
}

@end
