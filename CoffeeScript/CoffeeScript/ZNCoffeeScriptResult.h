//
//  ZNCoffeeScriptResult.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/24/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Foundation/Foundation.h>

// parsed output keys, specific to taks type
extern NSString * const ZNCompiledJavaScriptKey;    // NSString - parsed JS
extern NSString * const ZNCoffeeScriptVersionKey;   // NSString - version info
extern NSString * const ZNResultOutputKey;          // NSString - version output

// error user info keys
extern NSString * const ZNErrorNameKey;             // NSString - error header
extern NSString * const ZNErrorMessageKey;          // NSString - error message
extern NSString * const ZNErrorLineNumberKey;       // NSNumber - compilation error line number
extern NSString * const ZNErrorStackKey;            // NSArray - array of compilation error callstack
extern NSString * const ZNErrorTerminationReasonKey;    // NSNumber - ZNCoffeeScriptTerminationReason

// error domain
extern NSString * const ZNBundleErrorDomain;

// coffee binary return statuses
typedef enum ZNCoffeeScriptReturnStatus : NSInteger {
    ZNCoffeeScriptReturnStatusOK = 0,
    ZNCoffeeScriptReturnStatusUndefined = -1
} ZNCoffeeScriptReturnStatus;

// translated task termination reasons
typedef enum ZNCoffeeScriptTerminationReason : NSInteger {
    ZNCoffeeScriptTerminationReasonExit = 1,
    ZNCoffeeScriptTerminationReasonUncaughtSignal = 2,
    ZNCoffeeScriptTerminationReasonTerminated = 0xFF
} ZNCoffeeScriptTerminationReason;

//
@interface ZNCoffeeScriptResult : NSObject

@property (assign, nonatomic) NSTaskTerminationReason terminationReason;
@property (assign, nonatomic) ZNCoffeeScriptReturnStatus status;
@property (copy, nonatomic) NSString *standardOutput;
@property (copy, nonatomic) NSString *standardError;
@property (strong, nonatomic) NSDictionary *parsedOutput;
@property (strong, nonatomic) NSError *error;

- (id)init;
- (id)initWithTerminationReason:(NSTaskTerminationReason)terminationReason
                         status:(ZNCoffeeScriptReturnStatus)status
                 standardOutput:(NSString *)standardOutput
                  standardError:(NSString *)standardError;

@end
