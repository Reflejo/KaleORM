//
//  NSString+SQLHelpers.h
//  Test
//
//  Created by Martin Conte Mac Donell on 3/18/14.
//  Copyright (c) 2014 Kicksend. All rights reserved.
//

@interface NSString (SQLHelpers)

/*
 * Converts CamelCase string to snake_case. (example: KSAlbum would be converted to ks_album)
 */
- (NSString *)underscoreString;

@end
