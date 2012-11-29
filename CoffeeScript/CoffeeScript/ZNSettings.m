//
//  ZNSettings.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/28/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNSettings.h"

static NSString * const ZNEnvironmentKey = @"org.zdne.codaplugin.coffeescript.environment";
static NSString * const ZNCheckOnSaveKey = @"org.zdne.codaplugin.coffeescript.checkonsave";
static NSString * const ZNWorkingDirectoryKey = @"org.zdne.codaplugin.coffeescript.workingdir";

@implementation ZNSettings

+ (ZNSettings *)sharedSettings
{
    static ZNSettings *_settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _settings = [[ZNSettings alloc] init];
    });
    
    return _settings;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self load];
    }
    return self;
}

- (void)load
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:ZNEnvironmentKey]) {
        self.environment = [[NSUserDefaults standardUserDefaults] objectForKey:ZNEnvironmentKey];
    }
    else {
        self.environment = nil;
        // example:
        // self.environment = @{@"PATH" : @"/Users/zdenek/.nvm/v0.6.20/bin",
        //                      @"NODE_PATH" : @"/Users/zdenek/Codebase/Apiary/apiary/node_modules"};
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:ZNCheckOnSaveKey]) {
        self.checkOnSave = [[[NSUserDefaults standardUserDefaults] objectForKey:ZNCheckOnSaveKey] boolValue];
    }
    else {
        self.checkOnSave = YES;
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:ZNWorkingDirectoryKey]) {
        self.workingDirectory = [[NSUserDefaults standardUserDefaults] objectForKey:ZNWorkingDirectoryKey];
    }
    else {
        self.workingDirectory = nil;
    }
}

- (void)save
{
    if (self.environment) {
        [[NSUserDefaults standardUserDefaults] setObject:self.environment forKey:ZNEnvironmentKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZNEnvironmentKey];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:self.checkOnSave forKey:ZNCheckOnSaveKey];

    if ([self.workingDirectory length]) {
        [[NSUserDefaults standardUserDefaults] setObject:self.workingDirectory forKey:ZNWorkingDirectoryKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ZNWorkingDirectoryKey];
    }    
}

@end
