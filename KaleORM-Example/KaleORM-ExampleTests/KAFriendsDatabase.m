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

#import "KAFriendsDatabase.h"
#import "KAFriendship.h"
#import "KAPerson.h"

@implementation KAFriendsDatabase

/*
 * Migrations to run. You MUST create a new item on the root array per schema version.
 *
 * NOTE: We use [*] as prefix when the result of the query is a row. In that case we'll use
 * -executeQuery: instead of -executeUpdate: because executing updates with a query that
 * results on a row really rustles FMDB's jimmies.
 */
- (NSArray *)migrations
{
    return @[
             
        /* Version 0 */
        @[
            @"[*] PRAGMA journal_mode = WAL",
            [KAPerson createSQL],
            [KAFriendship createSQL],
        ],
    ];
}

@end
