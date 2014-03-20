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

#import <objc/runtime.h>

#import "KAProxyRelationModel.h"
#import "NSString+SQLHelpers.h"
#import "KADatabaseModel.h"

NSString * const kKANotificationObjectRemoved = @"kKANotificationObjectRemoved";
NSString * const kKANotificationObjectInserted = @"kKANotificationObjectInserted";
NSString * const kKANotificationObjectModified = @"kKANotificationObjectModified";

NSString * const kKANotificationObjectExternalKey = @"kKANotificationObjectKeyExternal";
NSString * const kKANotificationObjectKey = @"kKANotificationObjectKey";

@implementation KADatabaseModel {
    BOOL ignoreFieldChanges;
}

+ (void)initialize
{
    [super initialize];
    
    BOOL isValidClass = ![[NSStringFromClass(self) substringToIndex:5] isEqualToString:@"NSKVO"];
    BOOL isPrepared = [objc_getAssociatedObject(self, "_isPrepared") boolValue];
    if (self != [KADatabaseModel class] && isValidClass && !isPrepared &&
        ([self superclass] == [KADatabaseModel class] || ![self isAbstractClass]))
    {
        // Prepares fields and column indexes on schema
        NSDictionary *schema = [[self class] _schema];
        NSInteger columnIdx = 0;
        for (NSString *propertyName in schema)
        {
            KABaseField *field = schema[propertyName];
            [field setPropertyName:propertyName];
            [field setColumnIndex:columnIdx++];
            [field setTableName:[self tableName]];
        }
        objc_setAssociatedObject(self, "_isPrepared", @YES, OBJC_ASSOCIATION_RETAIN);
    }
}

/*
 * This method is used when creating complex models that subclass other models. If you DON'T 
 * want the subclass to be created as a table on the database, you must set this flag to YES.
 */
+ (BOOL)isAbstractClass
{
    return NO;
}

/*
 * Initializes the object by adding KVO to all the properties. We'll keep track of what columns
 * changed for UPDATEs. Also, we are using method swizzling for foreign keys. We are doing this
 * because foreign keys are lazy loaded only when needed.
 */
- (id)init
{
    if (self = [super init])
    {
        NSDictionary *schema = [[self class] _schema];
        for (NSString *propertyName in schema)
        {
            [self addObserver:self
                   forKeyPath:propertyName
                      options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                      context:nil];
        }
    }
    
    return self;
}

/*
 * Removes all KVO from instance properties.
 */
- (void)dealloc
{
    for (NSString *propertyName in [[self class] _schema])
    {
        [self removeObserver:self forKeyPath:propertyName];
    }
}

#pragma mark -
#pragma mark ------------------------------------------------------------
#pragma mark Helper methods
#pragma mark ------------------------------------------------------------

/*
 * Observes if some property has changed. In which case the modified property is mark as dirty.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([change[NSKeyValueChangeOldKey] isEqual:change[NSKeyValueChangeNewKey]])
        return;

    NSDictionary *schema = [[self class] _schema];
    [schema[keyPath] setIsDirty:!ignoreFieldChanges];
}

/* 
 * Returns an ordered rows list, as an string separated by commas.
 */
+ (NSString *)sqlRows
{
    NSDictionary *schema = [self _schema];
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity:[schema count]];
    for (KABaseField *field in [schema allValues])
    {
        [fields addObject:[field fullQualifiedFieldName]];
    }

    return [fields componentsJoinedByString:@","];
}

/*
 * Creates an instance of the calling class by parsing every property following the +schema
 * definition.
 */
+ (id)objectFromResultSet:(FMResultSet *)set
{
    KADatabaseModel *object = [[self alloc] init];
    NSDictionary *schema = [[self class] _schema];

    object->ignoreFieldChanges = YES;
    for (NSString *propertyName in schema)
    {
        KABaseField *field = schema[propertyName];
        [object setValue:[field valueFromSet:set] forKey:propertyName];
    }
    object->ignoreFieldChanges = NO;

    return object;
}

/*
 * Notifies that the instance was either removed, modified or created. We'll send this
 * notification to the instance class.
 */
- (void)notifyObjectChange:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *_userInfo = [userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    _userInfo[kKANotificationObjectKey] = self;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:[self class]
                                                      userInfo:_userInfo];
}

/*
 * Returns an array of normalized objects from a result set.
 */
+ (NSArray *)objectsFromResultSet:(FMResultSet *)set
{
    NSMutableArray *objects = [NSMutableArray array];
    while ([set next])
    {
        [objects addObject:[self objectFromResultSet:set]];
    }
    return objects;
}

/*
 * When inserting a row into the database we are using "INSERT OR REPLACE" if this flag is true
 * or INSERT OR IGNORE otherwise. You COULD override this method.
 */
- (BOOL)enableInsertOrReplace
{
    return YES;
}

#pragma mark -
#pragma mark ------------------------------------------------------------
#pragma mark SQL craft & queries
#pragma mark ------------------------------------------------------------

/*
 * CREATE TABLE sql query. It's created based on fields from +[class schema] method.
 */
+ (NSString *)createSQL
{
    NSDictionary *schema = [self _schema];
    NSMutableArray *rows = [NSMutableArray array];
    for (NSString *propertyName in schema)
    {
        [rows addObject:[schema[propertyName] rowSQL]];
    }

    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",
            [self tableName], [rows componentsJoinedByString:@","]];
}

/*
 * Gets the object with the given primary key. Note that "the object" is the object that 
 * is calling this instance, for example: [KAPerson objectForId:1] will returns the KAPerson
 * found with id = 1 (if any).
 */
+ (id)objectForId:(NSInteger)objectId from:(FMDatabase *)db
{
    NSString *q = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE id = %%d",
                   [self sqlRows], [[self class] tableName]];
    
    db = db ?: [KADatabaseManager db];
    FMResultSet *set = [db executeQueryWithFormat:q, objectId];
    return [set next] ? [self objectFromResultSet:set]: nil;
}

+ (id)objectForId:(NSInteger)objectId
{
    return [self objectForId:objectId from:nil];
}

/*
 * Inserts or updates this object into the database. We decide whether to update or insert
 * according to self.id value (> 0 => INSERT, = 0 => UPDATE)
 */
- (void)persistInto:(FMDatabase *)db silent:(BOOL)silent
{
    // If the id column is already set, that means we should update, not insert.
    BOOL isUpdating = self.id > 0;

    // Choose default database if none is given.
    db = db ?: [KADatabaseManager db];

    // Prepare cols and fields involved on this db operation.
    NSDictionary *schema = [[self class] _schema];
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:[schema count]];
    NSMutableArray *questionMarks = [NSMutableArray arrayWithCapacity:[schema count]];
    NSMutableArray *cols = [NSMutableArray arrayWithCapacity:[schema count]];
    for (NSString *propertyName in schema)
    {
        // Do not include fields that hasn't been modified when UPDATing.
        KABaseField *field = schema[propertyName];
        BOOL isDirty = [field isDirty];
        [field setIsDirty:NO];
        if (([field options] & KAFieldOptionPrimaryKey) > 0 || (!isDirty && isUpdating))
            continue;

        // Insert or update relations.
        id object = [self valueForKeyPath:propertyName];
        if ([field isKindOfClass:[KAForeignKey class]])
            [object persistInto:db silent:silent];
            
        [args addObject:[self valueForKeyPath:[field propertyKeyPath]] ?: [NSNull null]];
        [questionMarks addObject:@"?"];
        [cols addObject:[field fieldName]];
    }

    // Check if we have something to do (does any row actually change??)
    if ([cols count] == 0)
        return; // Yay! Nothing to do
    
    if (isUpdating)
    {
        NSString *query = [NSString stringWithFormat:@"UPDATE %@ SET %@=? WHERE id = %d",
                           [[self class] tableName], [cols componentsJoinedByString:@"=?, "],
                           (int)self.id];
        
        if ([db executeUpdate:query withArgumentsInArray:args] && !silent)
            [self notifyObjectChange:kKANotificationObjectModified userInfo:nil];
    }
    else
    {
        NSString *orReplace = self.enableInsertOrReplace ? @"OR REPLACE": @"OR IGNORE";
        NSString *query = [NSMutableString stringWithFormat:@"INSERT %@ INTO %@ (%@) VALUES(%@)",
                           orReplace, [[self class] tableName],
                           [cols componentsJoinedByString:@", "],
                           [questionMarks componentsJoinedByString:@", "]];
        
        if ([db executeUpdate:query withArgumentsInArray:args])
        {
            self->_id = (long)[db lastInsertRowId];
            
            if (!silent)
                [self notifyObjectChange:kKANotificationObjectInserted userInfo:nil];
        }
    }
}

- (void)persist
{
    [self persistInto:nil silent:NO];
}

/*
 * Removes current object from database.
 */
- (void)removeFrom:(FMDatabase *)db silent:(BOOL)silent
{
    // Choose default database if none is given.
    db = db ?: [KADatabaseManager db];
    
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = %%d",
                       [[self class] tableName]];
    
    if ([db executeUpdateWithFormat:query, self.id] && !silent)
        [self notifyObjectChange:kKANotificationObjectRemoved userInfo:nil];
}

- (void)remove
{
    [self removeFrom:nil silent:NO];
}


/*
 * Runs ANALYZE query to improve performance for queries.
 */
+ (void)analyzeIn:(FMDatabase *)db
{
    db = db ?: [KADatabaseManager db];
    [db executeUpdate:[NSString stringWithFormat:@"ANALYZE %@", self.tableName]];
}

/*
 * Returns a valid query for creating an INDEX on all the given properties, if the property is
 * prepended by "-", then the order of index for that property will be descending. Note that the
 * properties are not the database fields but the name of the property on the class. 
 *
 * Example: properties: ["annualRate", "-id"] will create an index for (annual_rate ASC, id DESC).
 */
+ (NSString *)indexSQLForProperties:(NSArray *)properties
{
    NSDictionary *schema = [self _schema];
    
    NSMutableArray *fields = [NSMutableArray arrayWithCapacity:[properties count]];
    NSMutableString *indexName = [NSMutableString stringWithString:[self tableName]];
    for (NSString *property in properties)
    {
        char indexOrder = [property characterAtIndex:0];
        BOOL isDESC = (indexOrder == '-');

        NSString *_property = property;
        if (indexOrder == '-' || indexOrder == '+')
            _property = [property substringFromIndex:1];

        NSString *fieldName = [schema[_property] fieldName];

        [indexName appendFormat:@"_%@_%@", fieldName, isDESC ? @"desc": @"asc"];
        [fields addObject:[NSString stringWithFormat:@"%@ %@",
                           fieldName, isDESC ? @"DESC": @"ASC"]];
    }

    return [NSString stringWithFormat:@"CREATE INDEX %@ ON %@(%@)",
            indexName, [self tableName], [fields componentsJoinedByString:@","]];
}

#pragma mark -
#pragma mark ------------------------------------------------------------
#pragma mark "Abstract" methods, subclasses MUST implement these methods.
#pragma mark ------------------------------------------------------------

/*
 * Returns the map of all instance properties to fields, for example:
 * {"id": [KAIntegerField field], "name": [KSTextField field]}. You MUST override this method.
 */
+ (NSDictionary *)schema
{
    [NSException raise:NSObjectNotAvailableException
                format:@"You MUST override schema on %@.", self];
    return nil;
}

#pragma mark -
#pragma mark ------------------------------------------------------------
#pragma mark Table schema methods
#pragma mark ------------------------------------------------------------

/*
 * Returns the name of the table associated to this object.
 */
+ (NSString *)tableName
{
    NSString *_tableName = objc_getAssociatedObject(self, "_tableName");
    if (!_tableName)
    {
        _tableName = [NSStringFromClass([self class]) underscoreString];
        objc_setAssociatedObject(self, "_tableName", _tableName, OBJC_ASSOCIATION_RETAIN);
    }
    
    return _tableName;
}

/*
 * We use this method internally, to cache the subclass schema and add the primary key.
 */
+ (NSDictionary *)_schema
{
    NSDictionary *_schema = objc_getAssociatedObject(self, "_schema");
    if (!_schema)
    {
        NSMutableDictionary *schema = [[self schema] mutableCopy];
        schema[@"id"] = [KAIntegerField fieldWithOptions:KAFieldOptionPrimaryKey];

        _schema = schema;
        objc_setAssociatedObject(self, "_schema", _schema, OBJC_ASSOCIATION_RETAIN);
    }
    return _schema;
}

/*
 * Checks whether the table is in a "dirty" state. When this is true, it means that the
 * current state of the instance is different from the database row.
 */
- (BOOL)isDirty
{
    NSDictionary *schema = [[self class] _schema];
    for (NSString *propertyName in schema)
    {
        if ([schema[propertyName] isDirty])
            return YES;
    }
    
    return NO;
}

@end
