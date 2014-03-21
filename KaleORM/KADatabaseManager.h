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

#import "FMDatabaseQueue.h"
#import "FMDatabase.h"

@interface KADatabaseManager : NSObject

/*
 * Creates database if it doesn't exist or open it if it does. We'll run all needed
 * migrations (if any) right after opening the database.
 */
+ (void)openOrCreateDBWithCompletion:(void (^)(BOOL success))completionBlock;

/*
 * Creates a new FMDatabaseQueue object to use on concurrent environments.
 * To perform queries and updates on multiple threads, you'll want to use this.
 */
+ (FMDatabaseQueue *)queue;

/*
 * Returns the opened database to use on application queries. The database MUST be opened before
 * calling this method and this method is NOT thread safe.
 */
+ (FMDatabase *)db;

/*
 * Removes database and creates a new one.
 */
+ (void)wipeDatabase;

@end


@interface KADatabaseQueue : FMDatabaseQueue

@end