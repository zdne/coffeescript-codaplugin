//
//  ZNCoffeeScriptOperation.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/24/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNCoffeeScriptOperation.h"
#import "ZNCoffeeScript.h"

@interface ZNCoffeeScriptOperation ()

@property (strong, nonatomic) ZNShellTask *shellTask;
@property (copy, nonatomic) RunProgressHandler progressHandler;
@property (copy, nonatomic) RunCompletionHandler completionHandler;

@end

@implementation ZNCoffeeScriptOperation

+ (ZNCoffeeScriptOperation *)createOperation:(ZNCoffeeScriptOperationType)type withInput:(NSString *)input
{
    return [[ZNCoffeeScriptOperation alloc] initWithType:type input:input];
}

- (id)initWithType:(ZNCoffeeScriptOperationType)type input:(NSString *)input
{
    self = [super self];
    if (self) {
        _type = type;
        if ([input length]) {
            _input = [input copy];
        }
    }
    return self;
}

- (void)runWithProgress:(RunProgressHandler)progress completion:(RunCompletionHandler)completion
{
    self.progressHandler = progress;
    self.completionHandler = completion;
    
    switch (self.type) {
        case ZNCoffeeScriptOperationTypeRun:
        {
            self.shellTask = [[ZNCoffeeScript sharedCoffeeScript] run:self.input
                                                             progress:^(NSString *update) {
                                                                 [self updateProgress:update];
                                                             }
                                                               completion:^(ZNCoffeeScriptResult *result) {
                                                                   [self completeOperationWithResult:result];
                                                               }];
        }
            break;
        
        case ZNCoffeeScriptOperationTypeCompile:
        {
            self.shellTask = [[ZNCoffeeScript sharedCoffeeScript] compile:self.input
                                                               completion:^(ZNCoffeeScriptResult *result) {
                                                                   [self completeOperationWithResult:result];
                                                               }];
        }
            break;
            
        case ZNCoffeeScriptOperationTypeGetVersion:
        {
            self.shellTask = [[ZNCoffeeScript sharedCoffeeScript] version:^(ZNCoffeeScriptResult *result) {
                [self completeOperationWithResult:result];
            }];
        }
            break;
            
        default:
            break;
    }
}

- (void)updateProgress:(NSString *)update
{
    if (self.progressHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressHandler(self, update);
        });
    }
}

- (void)completeOperationWithResult:(ZNCoffeeScriptResult *)result
{
    _result = result;
    if (self.completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler(self);
        });
    }
}

- (BOOL)isRunning
{
    return self.shellTask.task.isRunning;
}

- (void)terminate
{
    [self.shellTask.task terminate];
}

@end
