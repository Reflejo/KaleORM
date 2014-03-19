//
// Copyright (c) 2013 Kicksend (http://kicksend.com)
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
#import "KABaseField.h"

@implementation KABaseField

@synthesize fieldName=_fieldName;

/*
 * Creates a field instance. You can specify the options by OR'ing KAFieldOptions.
 */
+ (id)fieldWithOptions:(KAFieldOptions)theOptions
{
    KABaseField *field = [[self alloc] init];
    field->_options = theOptions;
    return field;
}

+ (id)field
{
    return [self fieldWithOptions:KAFieldOptionNone];
}

/*
 * Returns the full qualified column name including the tableName, for example:
 * person.name. This is used to safetly create JOINed queries with no row ambiguities.
 */
- (NSString *)fullQualifiedFieldName
{
    return [NSString stringWithFormat:@"%@.%@", [self tableName], [self fieldName]];
}

/*
 * The field name will be created based on the propertyName, by converting it from CamelCase to
 * snake case. For example: createdDate will be created_date.
 */
- (NSString *)fieldName
{
    if (!_fieldName)
        _fieldName = [self.propertyName underscoreString];
    
    return _fieldName;
}

/*
 * This method allows subclasses to specify the keyPath where the value is located while 
 * crafting queries. For example KAForeignKey uses this as "<field>.id" in order to use the actual
 * id on queries instead of the relation object.
 */
- (NSString *)propertyKeyPath
{
    return self.propertyName;
}

/*
 * Crafts and returns the field syntax for CREATE TABLE, including type and options.
 */
- (NSString *)rowSQL
{
    NSMutableString *strOptions = [NSMutableString string];
    if ((_options & KAFieldOptionUnique) > 0)
        [strOptions appendString:@" UNIQUE"];

    if ((_options & KAFieldOptionNotNull) > 0)
        [strOptions appendString:@" NOT NULL"];

    if ((_options & KAFieldOptionPrimaryKey) > 0)
        [strOptions appendString:@" PRIMARY KEY"];

    return [NSString stringWithFormat:@"%@ %@ %@",
            [self fieldName], [[self class] SQLType], strOptions];
}

/*
 * This methods allow subclasses to specify the right SQL type. For example KAIntegerField will
 * return "INTEGER" here for sqlite.
 *
 * You MUST override this method
 */
+ (NSString *)SQLType
{
    [NSException raise:NSObjectNotAvailableException
                format:@"method SQLType MUST be present on a KABaseField subclass"];
    return nil;
}

/*
 * This method returns the value based on a result set casted to the field type.
 *
 * You MUST override this method.
 */
- (id)valueOnSet:(FMResultSet *)set
{
    [NSException raise:NSObjectNotAvailableException
                format:@"valueOnSet: method MUST be present on field subclasses %@", [self class]];
    return nil;
}

@end
