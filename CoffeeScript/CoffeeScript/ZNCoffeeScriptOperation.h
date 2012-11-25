//
//  ZNCoffeeScriptOperation.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/24/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZNCoffeeScriptResult.h"

@interface ZNCoffeeScriptOperation : NSObject

typedef enum ZNCoffeeScriptOperationType : NSUInteger {
    ZNCoffeeScriptOperationTypeRun,
    ZNCoffeeScriptOperationTypeCompile,
    ZNCoffeeScriptOperationTypeGetVersion
} ZNCoffeeScriptOperationType;

typedef void (^RunProgressHandler)(ZNCoffeeScriptOperation *operation, NSString *update);
typedef void (^RunCompletionHandler)(ZNCoffeeScriptOperation *operation);

+ (ZNCoffeeScriptOperation *)createOperation:(ZNCoffeeScriptOperationType)type withInput:(NSString *)input;

@property (readonly, nonatomic) ZNCoffeeScriptOperationType type;
@property (readonly, nonatomic) NSString *input;
@property (readonly, nonatomic) ZNCoffeeScriptResult *result;

// Runs the operation. Completion handler is always called on main thread.
- (void)runWithProgress:(RunProgressHandler)progress completion:(RunCompletionHandler)completion;

// Returns YES if the operation is running NO otherwise.
- (BOOL)isRunning;

// Terminates the underlying task, if running
- (void)terminate;


@end
