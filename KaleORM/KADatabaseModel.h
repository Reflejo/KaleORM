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

#import <Foundation/NSKeyValueCoding.h>
#import "KADatabaseManager.h"
#import "KATypes.h"

/* Notification types used when a database object is modified, inserted or removed */
extern NSString * const kKANotificationObjectRemoved;
extern NSString * const kKANotificationObjectInserted;
extern NSString * const kKANotificationObjectModified;

/* Keys used on the notification userInfo dictionary. */
extern NSString * const kKANotificationObjectExternalKey;
extern NSString * const kKANotificationObjectKey;
extern NSString * const kKANotificationObjectPropertiesKey;


@interface KADatabaseModel : NSObject

/*
 * Inserts or updates this object into the database. We decide whether to update or insert
 * according to self.id value (> 0 => INSERT, = 0 => UPDATE)
 */
- (void)persistInto:(FMDatabase *)db silent:(BOOL)silent;
- (void)persist;

/*
 * Removes current object from database.
 */
- (void)removeFrom:(FMDatabase *)db silent:(BOOL)silent;
- (void)remove;

/*
 * Runs ANALYZE query on the class table.
 */
+ (void)analyzeIn:(FMDatabase *)db;

/*
 * Returns the name of the table associated to this object. You MUST override this method.
 */
+ (NSString *)tableName;

/*
 * CREATE TABLE sql query. It's created based on fields from +[class schema] method.
 */
+ (NSString *)createSQL;

/*
 * Gets the object with the given primary key. Note that "the object" is the object that
 * is calling this instance, for example: [KAPerson objectForId:1] will returns the KAPerson
 * found with id = 1 (if any).
 */
+ (id)objectForId:(NSInteger)objectId from:(FMDatabase *)db;
+ (id)objectForId:(NSInteger)objectId;

/*
 * Creates an instance of the calling class by parsing every property following the +schema
 * definition.
 */
+ (id)objectFromResultSet:(FMResultSet *)set;

/*
 * Returns an array of normalized objects from a result set.
 */
+ (NSArray *)objectsFromResultSet:(FMResultSet *)set;

/*
 * This method is used when creating complex models that subclass other models. If you DON'T
 * want the subclass to be created as a table on the database, you must set this flag to YES.
 */
+ (BOOL)isAbstractClass;

/*
 * Returns a valid query for creating an INDEX on all the given properties, if the property is
 * prepended by "-", then the order of index for that property will be descending. Note that the
 * properties are not the database fields but the name of the property on the class.
 *
 * Example: properties: ["annualRate", "-id"] will create an index for (annual_rate ASC, id DESC).
 */
+ (NSString *)indexSQLForProperties:(NSArray *)properties isUnique:(BOOL)unique;
+ (NSString *)indexSQLForProperties:(NSArray *)properties;

@property (nonatomic, assign, readonly) NSInteger id;

@end
