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

#import "KAProxyRelationModel.h"
#import "KADatabaseModel.h"

@implementation KAProxyRelationModel

/*
 * Creates a relation proxy for foreign key fields, this takes as parameters the relation
 * class and the pk of the specific object. We'll use this proxy to lazy query the information
 * we need.
 */
+ (id)relationProxyForClass:(Class)aClass pk:(NSInteger)pk
{
    NSAssert(pk > 0, @"You MUST specify a pk for the proxy relation on %@", aClass);
    
    KAProxyRelationModel *model = [[self alloc] init];
    [model setRelationClass:aClass];
    [model setId:pk];
    return model;
}

/*
 * All properties accesses are redirected to the proxied instance. If the instance doesn't exist
 * and a property is requested, we'll get the object from the database. Note that this doesn't
 * include the id, we already have the id here and that's never proxied.
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    // In order to ensure multi threading safety, if the current thread is not the main thread,
    // we have to create a new queue.
    if (!self.relationInstance)
    {
        if ([NSThread isMainThread])
        {
            self.relationInstance = [self.relationClass objectForId:self.id];
        }
        else
        {
            [[KADatabaseManager queue] inDatabase:^(FMDatabase *db)
            {
                self.relationInstance = [self.relationClass objectForId:self.id from:db];
            }];
        }
    }

    [anInvocation invokeWithTarget:self.relationInstance];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.relationClass instanceMethodSignatureForSelector:aSelector];
}

@end
