//
//  KAFriendsDatabase.m
//  KaleORM-Example
//
//  Created by Martin Conte Mac Donell on 3/18/14.
//  Copyright (c) 2014 Kicksend. All rights reserved.
//

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
