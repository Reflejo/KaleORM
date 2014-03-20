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

#import "KAProxyRelationModel.h"
#import "KAForeignKey.h"

@implementation KAForeignKey

@synthesize propertyName=_propertyName;

/*
 * Foreigns fields are created by sending a relation Class.
 * For example, [KAForeignKey fieldWithRelation:[KAPerson class]].
 */
+ (id)fieldWithRelation:(Class)relationClass
{
    KAForeignKey *field = [[KAForeignKey alloc] init];
    field->_relation = relationClass;
    return field;
}

/*
 * Gets the primary key value from the set, and if it's not null we create an empty proxy model
 * which will be in charge of lazy query the database when properties are accesed.
 */
- (id)valueFromSet:(FMResultSet *)set
{
    NSInteger pk = [set intForColumnIndex:(int)self.columnIndex];
    return pk > 0 ? [KAProxyRelationModel relationProxyForClass:self.relation pk:pk]: nil;
}

/*
 * For queries (INSERTs, UPDATEs and SELECTs) we need to use the id of the relation.
 */
- (NSString *)propertyKeyPath
{
    return [NSString stringWithFormat:@"%@.id", _propertyName];
}

/*
 * Field name on relations are created as <field>_id on the table, we'll query the related table
 * as needed when properties are accesed.
 */
- (NSString *)fieldName
{
    return [NSString stringWithFormat:@"%@_id", [super fieldName]];
}

/*
 * We'll create the field as integer and add the reference as indicated on:
 * https://www.sqlite.org/foreignkeys.html
 */
- (NSString *)rowSQL
{
    return [NSString stringWithFormat:@"%@ INTEGER REFERENCES %@",
            [self fieldName], [(id)self.relation tableName]];
}

@end
