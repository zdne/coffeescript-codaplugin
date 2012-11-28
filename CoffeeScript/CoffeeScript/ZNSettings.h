//
//  ZNSettings.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/28/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZNSettings : NSObject

@property (strong, nonatomic) NSDictionary *environment;
@property (assign, nonatomic) BOOL checkOnSave;
@property (copy, nonatomic) NSString *workingDirectory;

+ (ZNSettings *)sharedSettings;

- (void)load;
- (void)save;

@end
