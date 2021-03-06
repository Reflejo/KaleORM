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

#import "KADateField.h"
#import "FMResultSet.h"

@implementation KADateField

/*
 * Creates a field instance and set defaultNow flag to TRUE so the CREATE TABLE SQL
 * includes the options to default the field to current_timestamp when NULL
 */
+ (id)fieldWithDefaultNow
{
    KADateField *field = [super field];
    [field setDefaultNow:YES];
    return field;
}

/*
 * This method returns the value based on a result set casted to NSDate.
 */
- (NSDate *)valueFromSet:(FMResultSet *)set
{
    return [set dateForColumnIndex:(int)self.columnIndex];
}

/*
 * Crafts and returns the field syntax for CREATE TABLE, including type and options.
 */
- (NSString *)rowSQL
{
    NSString *now = self.defaultNow ? @" DEFAULT current_timestamp": @"";
    return [NSString stringWithFormat:@"%@%@", [super rowSQL], now];
}
/*
 * SQLite datetime type according to http://www.sqlite.org/datatype3.html.
 */
+ (NSString *)SQLType
{
    return @"DATETIME";
}

@end
