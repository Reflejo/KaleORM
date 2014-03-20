//
//  KADateField.h
//  KaleORM-Example
//
//  Created by Martin Conte Mac Donell on 3/18/14.
//  Copyright (c) 2014 Kicksend. All rights reserved.
//

#import "KABaseField.h"

@interface KADateField : KABaseField

/*
 * Creates a field instance and set defaultNow flag to TRUE so the CREATE TABLE SQL
 * includes the options to default the field to current_timestamp when NULL
 */
+ (id)fieldWithDefaultNow;

@property (nonatomic, assign) BOOL defaultNow;

@end
