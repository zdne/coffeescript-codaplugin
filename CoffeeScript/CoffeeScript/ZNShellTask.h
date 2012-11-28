//
//  ZNShellTask.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZNShellTask : NSObject

typedef void (^ShellTaskProgressHandler)(NSString *standardOutputUpdate, NSString *standardErrorUpdate);
typedef void (^ShellTaskCompletionHandler)(NSTaskTerminationReason terminationReason, NSInteger status, NSString *standardOutput, NSString *standardError);

@property (readonly, nonatomic) NSTask *task;

// Launches given task.
+ (ZNShellTask *)launchWithLaunchPath:(NSString *)path
                            arguments:(NSArray *)arguments
                     workingDirectory:(NSString *)workingDirectory
                          environment:(NSDictionary *)environment
                                stdIn:(NSString *)input
                             progress:(ShellTaskProgressHandler)progress
                           completion:(ShellTaskCompletionHandler)completion;

// Query current user' shell for a path to a command.
+ (void)pathForCommand:(NSString *)command
           environment:(NSDictionary *)environment
            completion:(void (^)(NSString *path))completion;

@end
