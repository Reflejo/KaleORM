//
// Copyright (c) 2014 Kicksend (http://kicksend.com)
//
// Created by Martin Conte Mac Donell (Reflejo@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
