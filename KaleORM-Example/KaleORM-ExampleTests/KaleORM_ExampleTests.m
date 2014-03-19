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

#import <XCTest/XCTest.h>
#import "KAFriendsDatabase.h"
#import "KAFriendship.h"

@interface KaleORM_ExampleTests : XCTestCase

@end

@implementation KaleORM_ExampleTests

- (void)test_0_createDatabase
{
    [KAFriendsDatabase wipeDatabase];
    [KAFriendsDatabase openOrCreateDBWithCompletion:nil];
    
    // Give the database some time to complete, XCTests doesn't support async operations. :|
    sleep(2);
    
    BOOL dbExists = [[NSFileManager defaultManager]
                     fileExistsAtPath:[[KAFriendsDatabase db] databasePath] isDirectory:NO];
    XCTAssertTrue(dbExists, "Database creation failed");
}

- (void)test_1_Insert
{
    KAPerson *person = [[KAPerson alloc] init];
    person.name = @"Martin Conte Mac Donell";
    person.age = 30;
    person.birthday = [NSDate dateWithTimeIntervalSince1970:425026800]; // :)
    person.phoneNumber = @"123-123-1234";
    person.address = @"742 Evergreen Terrace";
    [person persist];

    XCTAssertNotEqual([person id], 0, "Database INSERT didn't work (primary key is 0).");
}

- (void)test_2_Select
{
    KAPerson *person = [KAPerson objectForId:1];

    XCTAssertEqualObjects(person.name, @"Martin Conte Mac Donell",
                          "Database SELECT didn't get the right row.");
}


- (void)test_3_Update
{
    KAPerson *person = [KAPerson objectForId:1];
    NSInteger oldId = [person id];
    person.age = 31;
    [person persist];

    // Get the record again from the DB.
    person = [KAPerson objectForId:1];
    
    XCTAssertEqual(person.age, 31, "Database UPDATE didn't work (age isn't updated)");
    XCTAssertEqual(person.id, oldId, "IDs must be the same while updating a row");
}

- (void)test_4_ForeignKey
{
    // Create reference objects
    KAPerson *personA = [KAPerson objectForId:1];
    KAPerson *personB = [[KAPerson alloc] init];
    personB.name = @"Brendan Lim";
    personB.age = 29;
    personB.address = @"1234 Something Blv.";

    // Create relation object
    KAFriendship *friendship = [[KAFriendship alloc] init];
    friendship.personA = personA;
    friendship.personB = personB;
    friendship.frienshipDate = [NSDate dateWithTimeIntervalSince1970:1362124800];
    [friendship persist];

    // Check if the creation was done ok.
    friendship = [KAFriendship objectForId:1];
    
    XCTAssertEqual(friendship.personA.id, 1, "Couldn't find reference object");
    XCTAssertEqual(friendship.personB.id, 2, "Couldn't find reference object");
    XCTAssertEqualObjects(friendship.personB.name, @"Brendan Lim", "Reference object name doesn't"
                                                    " match inserted value");
}

- (void)test_5_Deletion
{
    KAPerson *person = [KAPerson objectForId:1];
    [person remove];
    
    XCTAssertNil([KAPerson objectForId:1], "Database DELETE didn't work, the row it's "
                                           "still present");
}

@end
