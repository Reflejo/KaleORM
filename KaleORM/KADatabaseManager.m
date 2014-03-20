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
#import "KADatabaseManager.h"

#define kTraceDatabaseQueries   YES

@interface KADatabaseManager () {
    FMDatabase *db;
    FMDatabaseQueue *dbQueue;
    BOOL isOpened;
}

@property (nonatomic, strong) NSString *dbPath;

@end

@implementation KADatabaseManager

/*
 * Singleton implementation of ALAsset library. We always keep an instance of the
 * assets library live.
 */
+ (id)defaultManager
{
    static KADatabaseManager *instance = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        instance = [[super alloc] init];
        NSURL *dir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask] lastObject];

        // The class names will usually looks like <PREFIX><DatabaseName>Manager, so we'll convert
        // that format to prefix_databasename.
        NSString *databaseName = [NSStringFromClass([self class]) mutableCopy];
        databaseName = [databaseName stringByReplacingOccurrencesOfString:@"Manager"
                                                               withString:@""];

        databaseName = [NSString stringWithFormat:@"%@.sql", [databaseName underscoreString]];
        [instance setDbPath:[[dir URLByAppendingPathComponent:databaseName] path]];
    });
    
    return instance;
}

/*
 * Migrations to run. You SHOULD create a new item on the root array per schema version.
 *
 * NOTE: We use [*] as prefix when the result of the query is a row. In that case we'll use
 * -executeQuery: instead of -executeUpdate: because executing updates with a query that 
 * results on a row really rustles FMDB's jimmies.
 */
- (NSArray *)migrations
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-string-concatenation"
    return @[
             
        /* Version 0 */
        @[
            @"[*] PRAGMA journal_mode = WAL"
        ],
    ];
#pragma clang diagnostic pop
}

#pragma mark -
#pragma mark ------------------------------------------------------------
#pragma mark Database initializations
#pragma mark ------------------------------------------------------------
/*
 * Creates database if it doesn't exist or open it if it does. We'll run all needed
 * migrations (if any) right after opening the database.
 */
+ (void)openOrCreateDBWithCompletion:(void (^)(BOOL success))completionBlock
{
    KADatabaseManager *manager = [self defaultManager];
    manager->db = [FMDatabase databaseWithPath:[manager dbPath]];
    [manager->db setTraceExecution:kTraceDatabaseQueries];
    [manager reopen];
    [manager migrateToLatestSchemaWithCompletion:completionBlock];
}

/*
 * Gets current database schema version and executes needed migrations to be fully updated.
 */
- (void)migrateToLatestSchemaWithCompletion:(void (^)(BOOL success))completionBlock
{
    NSAssert(isOpened, @"Database MUST be opened before running migrations.");
    
    FMResultSet *res = [db executeQuery:@"PRAGMA user_version"];
    if (![res next])
    {
        // This is a catastrophic failure. There is nothing we can do to fix this state.
        [NSException raise:NSInternalInconsistencyException
                    format:@"Cannot read database version"];
    }

    NSArray *migrations = [self migrations];
    NSInteger toVersion = [migrations count];
    NSInteger fromVersion = [res intForColumnIndex:0];

#ifdef kTraceDatabaseQueries
    NSLog(@"Migrating from %d to %d", (int)fromVersion, (int)toVersion);
    NSLog(@"Database path: %@", [self dbPath]);
#endif

    if (fromVersion == toVersion)
        // Yay! Nothing to do.
        return completionBlock ? completionBlock(YES): nil;

    [res close];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        __block BOOL success = YES;
        [[[self class] queue] inTransaction:^(FMDatabase *_db, BOOL *rollback)
        {
            for (NSInteger i = fromVersion; i < toVersion; i++)
            {
                for (NSString *migration in migrations[i])
                {
                    if ([migration hasPrefix:@"[*]"])
                        success = success && [_db executeQuery:[migration substringFromIndex:3]];
                    else
                        success = success && [_db executeUpdate:migration];
                }
            }
            
            // Update schama version to database
            NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %ld",
                               (long)toVersion];
            success = success && [_db executeUpdate:query];

            *rollback = !success;
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self reopen];
            
            if (completionBlock)
                completionBlock(success);
        });
    });
}

#pragma mark -
#pragma mark ------------------------------------------------------------
#pragma mark Database helpers
#pragma mark ------------------------------------------------------------
/*
 * Removes database and creates a new one.
 */
+ (void)wipeDatabase
{
    KADatabaseManager *manager = [self defaultManager];
    [[self db] executeUpdate:@"PRAGMA user_version = 0"];
    [manager close];
    
    // Remove database file.
    [[NSFileManager defaultManager] removeItemAtPath:[manager dbPath] error:nil];
}

/*
 * Creates a new FMDatabaseQueue object to use on concurrent environments.
 * To perform queries and updates on multiple threads, you'll want to use this.
 */
+ (FMDatabaseQueue *)queue
{
    KADatabaseManager *manager = [self defaultManager];
    if (!manager->dbQueue)
        manager->dbQueue = [KADatabaseQueue databaseQueueWithPath:[manager dbPath]];
    
    return manager->dbQueue;
}

/*
 * Tries to open database. Raise an exception on error.
 */
- (void)reopen
{
    [self close];

    db = [FMDatabase databaseWithPath:self.dbPath];
    [db setTraceExecution:kTraceDatabaseQueries];
    if (![db open])
        [NSException raise:NSInternalInconsistencyException format:@"Cannot open database"];

    isOpened = YES;
}

/*
 * Closes database and keep a flag on instance.
 */
- (void)close
{
    [db close];
    isOpened = NO;
}

/*
 * Returns the opened database to use on application queries. The database MUST be opened before
 * calling this method and this method is NOT thread safe.
 */
+ (FMDatabase *)db
{
    NSAssert([NSThread isMainThread], @"You cannot execute queries on a different thread. "\
             @"For that you MUST use queue method");
    
    KADatabaseManager *manager = [self defaultManager];
    if (!manager->isOpened)
       [manager reopen];

    return manager->db;
}

@end

/*
 * We are overriding FMDatabaseQueue in order to enable/disable traces on queries accross 
 * all methods.
 */
@implementation KADatabaseQueue

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags
{
    self = [super initWithPath:aPath flags:openFlags];
    [self->_db setTraceExecution:kTraceDatabaseQueries];
    return self;
}

@end
