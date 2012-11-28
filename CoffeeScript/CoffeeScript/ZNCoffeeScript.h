//
//  ZNCoffeeScript.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZNShellTask.h"
#import "ZNCoffeeScriptResult.h"

@protocol ZNCoffeeScriptDelegate <NSObject>

// called when there is no working directory set in the settings
- (NSString *)defaultWorkingDirectory;

@end

@interface ZNCoffeeScript : NSObject

typedef void (^CoffeeScriptProgressUpdateHandler)(NSString *update);
typedef void (^CoffeeScriptCompletionHandler)(ZNCoffeeScriptResult *result);

@property (assign, nonatomic) id<ZNCoffeeScriptDelegate> delegate;

// Returns shared CoffeScript interface.
+ (ZNCoffeeScript *)sharedCoffeeScript;

// Has to be called explicitly prior first use!
- (void)loadCoffeeEnvironment;

// Queries the version of CoffeeScript.
- (ZNShellTask *)version:(CoffeeScriptCompletionHandler)completion;

// Runs compile CoffeeScript command.
- (ZNShellTask *)compile:(NSString *)input completion:(CoffeeScriptCompletionHandler)completion;

// Runs a CoffeeScript
- (ZNShellTask *)run:(NSString *)input
            progress:(CoffeeScriptProgressUpdateHandler)progress
          completion:(CoffeeScriptCompletionHandler)completion;

@end
