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

@class FMResultSet;

typedef NS_OPTIONS(NSInteger, KAFieldOptions)
{
    KAFieldOptionNone           = 0,
    KAFieldOptionPrimaryKey     = 1 << 1,
    KAFieldOptionNotNull        = 1 << 2,
    KAFieldOptionUnique         = 1 << 3,
};

@interface KABaseField : NSObject

/*
 * Creates a field instance. You can specify the options by OR'ing KAFieldOptions.
 */
+ (id)fieldWithOptions:(KAFieldOptions)options;
+ (id)field;

/*
 * Returns the full qualified column name including the tableName, for example:
 * person.name. This is used to safetly create JOINed queries with no row ambiguities.
 */
- (NSString *)fullQualifiedFieldName;

/*
 * Crafts and returns the field syntax for CREATE TABLE, including type and options.
 */
- (NSString *)rowSQL;

/*
 * This method returns the value based on a result set casted to the field type.
 *
 * You MUST override this method.
 */
- (id)valueFromSet:(FMResultSet *)set;

/*
 * This method allows subclasses to specify the keyPath where the value is located while
 * crafting queries. For example KAForeignKey uses this as "<field>.id" in order to use the actual
 * id on queries instead of the relation object.
 */
- (NSString *)propertyKeyPath;

@property (nonatomic, strong, readonly) NSString *fieldName;
@property (nonatomic, strong, readonly) NSString *ivarName;
@property (nonatomic, assign, readonly) KAFieldOptions options;

@property (nonatomic, assign) NSInteger columnIndex;
@property (nonatomic, strong) NSString *propertyName;
@property (nonatomic, assign) NSString *tableName;
@property (nonatomic, assign) BOOL isDirty;

@end
