//
//  ZNCoffeeScript.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNCoffeeScript.h"
#import "ZNShellTask.h"
#import "ZNSettings.h"

@interface ZNCoffeeScript ()

@property (copy, nonatomic) NSString *workingDirectory;
@property (strong, nonatomic) NSDictionary *coffeeEnvironment;
@property (copy, atomic) NSString *coffeeCommand;

@end

@implementation ZNCoffeeScript

+ (ZNCoffeeScript *)sharedCoffeeScript
{
    static ZNCoffeeScript *_sharedCoffeeScript = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCoffeeScript = [[ZNCoffeeScript alloc] init];
    });
    
    return _sharedCoffeeScript;
}

- (id)init
{
    self = [super init];
    if (self) {
    }

    return self;
}

- (void)loadCoffeeEnvironment
{
    NSMutableDictionary *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
    NSDictionary *userEnvironment = [[ZNSettings sharedSettings] environment];
    
    // merge user environment with process one
    [userEnvironment enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        if (!environment[key]) {
            environment[key] = obj;
        }
        else {
            NSString *processValue = environment[key];
            // asssuming ':' delimiter
            environment[key] = [NSString stringWithFormat:@"%@:%@", processValue, obj];
        }
    }];
    
    // find command
    self.coffeeEnvironment = environment;
    self.coffeeCommand = nil;
    __block ZNCoffeeScript *blockSelf = self;
    [ZNShellTask pathForCommand:@"coffee"
                    environment:self.coffeeEnvironment
                     completion:^(NSString *path) {
                         blockSelf.coffeeCommand = path;
                         NSLog(@"coffe command set to: %@", path);
                     }];
    
    // resolve working directory
    if ([[[ZNSettings sharedSettings] workingDirectory] length]) {
        self.workingDirectory = [[ZNSettings sharedSettings] workingDirectory];
    }
    else if (self.delegate) {
        self.workingDirectory = [self.delegate defaultWorkingDirectory];
    }
}

+ (ZNCoffeeScriptResult *)launchErrorResult
{
    ZNCoffeeScriptResult *result = [[ZNCoffeeScriptResult alloc] initWithTerminationReason:ZNCoffeeScriptTerminationReasonUndefined
                                                                                    status:ZNCoffeeScriptReturnStatusUndefined
                                                                            standardOutput:nil
                                                                             standardError:nil];
    return result;
}

- (BOOL)coffeeReady:(CoffeeScriptCompletionHandler)completion
{
    if (![self.coffeeCommand length]) {
        NSLog(@"err: no coffee command");
        
        if (completion)
            completion([ZNCoffeeScript launchErrorResult]);
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Version

- (ZNShellTask *)version:(CoffeeScriptCompletionHandler)completion;
{
    if (![self coffeeReady:completion])
        return nil;
    
    // coffee --version
    ZNShellTask *task = [ZNShellTask launchWithLaunchPath:self.coffeeCommand
                                                arguments:@[@"--version"]
                                         workingDirectory:nil
                                              environment:self.coffeeEnvironment
                                                    stdIn:nil
                                                 progress:nil
                                               completion:^(NSTaskTerminationReason terminationReason, NSInteger status, NSString *standardOutput, NSString *standardError) {
                                                   if (completion) {
                                                       ZNCoffeeScriptResult *result = [ZNCoffeeScript parseVersionOutputWithTerminationReason:terminationReason
                                                                                                                                       status:status
                                                                                                                               standardOutput:standardOutput
                                                                                                                                standardError:standardError];
                                                       completion(result);
                                                   }
                                               }];
    
    return task;
}

+ (ZNCoffeeScriptResult *)parseVersionOutputWithTerminationReason:(NSTaskTerminationReason)terminationReason
                                                           status:(NSInteger)status
                                                   standardOutput:(NSString *)standardOutput
                                                    standardError:(NSString *)standardError
{
    ZNCoffeeScriptResult *result = [[ZNCoffeeScriptResult alloc] initWithTerminationReason:terminationReason
                                                                                    status:status
                                                                            standardOutput:standardOutput
                                                                             standardError:standardError];
    if (status == ZNCoffeeScriptReturnStatusOK) {
        result.parsedOutput = @{ZNCoffeeScriptVersionKey : standardOutput};
        return result;
    }
    
    return result;
}

#pragma mark - Compile

- (ZNShellTask *)compile:(NSString *)input completion:(CoffeeScriptCompletionHandler)completion
{
    if (![self coffeeReady:completion])
        return nil;
    
    // coffee -scp --bare
    ZNShellTask *task = [ZNShellTask launchWithLaunchPath:self.coffeeCommand
                                                arguments:@[@"-scbp"]
                                         workingDirectory:self.workingDirectory
                                              environment:self.coffeeEnvironment
                                                    stdIn:input
                                                 progress:nil
                                               completion:^(NSTaskTerminationReason terminationReason, NSInteger status, NSString *standardOutput, NSString *standardError) {
                                                   if (completion) {
                                                       ZNCoffeeScriptResult *result = [ZNCoffeeScript parseCompileOutputWithTerminationReason:terminationReason
                                                                                                                                       status:status
                                                                                                                               standardOutput:standardOutput
                                                                                                                                standardError:standardError];
                                                       completion(result);
                                                   }
                                               }];
    return task;
}

+ (ZNCoffeeScriptResult *)parseCompileOutputWithTerminationReason:(NSTaskTerminationReason)terminationReason
                                                           status:(NSInteger)status
                                                   standardOutput:(NSString *)standardOutput
                                                    standardError:(NSString *)standardError
{
    ZNCoffeeScriptResult *result = [[ZNCoffeeScriptResult alloc] initWithTerminationReason:terminationReason
                                                                                    status:status
                                                                            standardOutput:standardOutput
                                                                             standardError:standardError];
    if (status == ZNCoffeeScriptReturnStatusOK) {
        result.parsedOutput = @{ZNCompiledJavaScriptKey : standardOutput};
        return result;
    }
    
    result.error = [NSError errorWithDomain:ZNBundleErrorDomain
                                       code:status
                                   userInfo:[ZNCoffeeScript parseCompileErrorWithTerminationReason:terminationReason
                                                                                            status:status
                                                                                     standardError:standardError]];
    return result;
}

+ (NSDictionary *)parseCompileErrorWithTerminationReason:(NSTaskTerminationReason)terminationReason
                                                  status:(NSInteger)status
                                           standardError:(NSString *)standardError
{
    // process termination info
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{ZNErrorTerminationReasonKey : [NSNumber numberWithInt:terminationReason]}];

    // process stderr
    if ([standardError length]) {
        userInfo = [[NSMutableDictionary alloc] init];
        NSArray *errorLineComponents = [standardError componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString *errorLine = errorLineComponents[0];
        
        // error & error message
        NSRange range = [errorLine rangeOfString:@"[^:]*" options:NSRegularExpressionSearch];   // get leading text
        if (range.location != NSNotFound) {
            userInfo[ZNErrorNameKey] = [errorLine substringWithRange:range];
            NSUInteger skipToIndex = range.location + range.length + 2;
            if ([errorLine length] > skipToIndex)
                userInfo[ZNErrorMessageKey] = [errorLine substringFromIndex:skipToIndex];
        }
        
        // line number
        range = [errorLine rangeOfString:@"\\d+" options:NSRegularExpressionSearch];  // get line number digits
        if (range.location != NSNotFound) {
            NSString *numberString = [errorLine substringWithRange:range];
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            
            userInfo[ZNErrorLineNumberKey] = [formatter numberFromString:numberString];
        }
        
        // stack
        NSMutableArray *stack = [[NSMutableArray alloc] initWithCapacity:[errorLineComponents count]];
        for (NSUInteger i = 1; i < [errorLineComponents count]; i++) {
            NSString *stackFrame = errorLineComponents[i];
            
            NSRange range = [stackFrame rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];  // skip leading space
            NSString *cleanFrame = [stackFrame stringByReplacingCharactersInRange:range withString:@""];
            [stack addObject:cleanFrame];
        }
        
        userInfo[ZNErrorStackKey] = stack;
    }
    else if (terminationReason == NSTaskTerminationReasonExit && status == 1) {
        // if no stderr and yet the task failed we assume it was terminated
        userInfo[ZNErrorTerminationReasonKey] = [NSNumber numberWithInteger:ZNCoffeeScriptTerminationReasonTerminated];
    }

    return userInfo;
}

// Known CS compile errors
+ (NSArray *)compilerErrors
{
    static NSArray *_compilerErrors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _compilerErrors = @[@"Lexer.error", @"Object.parseError"];
    });
    
    return _compilerErrors;
}

+ (BOOL)isCompilerError:(NSString *)standardError
{
    for (NSString *error in [ZNCoffeeScript compilerErrors]) {
         if ([standardError rangeOfString:error].location != NSNotFound)
             return YES;
    }
   
    return NO;
}

#pragma mark - Run

- (ZNShellTask *)run:(NSString *)input
            progress:(CoffeeScriptProgressUpdateHandler)progress
          completion:(CoffeeScriptCompletionHandler)completion;

{
    if (![self coffeeReady:completion])
        return nil;
    
    // coffee -s
    ZNShellTask *task = [ZNShellTask launchWithLaunchPath:self.coffeeCommand
                                                arguments:@[@"-s"]
                                         workingDirectory:self.workingDirectory 
                                              environment:self.coffeeEnvironment
                                                    stdIn:input
                                                 progress:^(NSString *standardOutputUpdate, NSString *standardErrorUpdate) {
                                                     if (progress) {
                                                         progress([standardOutputUpdate length] ? standardOutputUpdate : standardErrorUpdate);
                                                     }
                                                 }
                                               completion:^(NSTaskTerminationReason terminationReason, NSInteger status, NSString *standardOutput, NSString *standardError) {
                                                   if (completion) {
                                                       ZNCoffeeScriptResult *result = [ZNCoffeeScript parseRunOutputWithTerminationReason:terminationReason
                                                                                                                                   status:status
                                                                                                                           standardOutput:standardOutput
                                                                                                                            standardError:standardError];
                                                       completion(result);
                                                   }
                                               }];
    return task;
}


+ (ZNCoffeeScriptResult *)parseRunOutputWithTerminationReason:(NSTaskTerminationReason)terminationReason
                                                       status:(NSInteger)status
                                               standardOutput:(NSString *)standardOutput
                                                standardError:(NSString *)standardError
{
    ZNCoffeeScriptResult *result = [[ZNCoffeeScriptResult alloc] initWithTerminationReason:terminationReason
                                                                                    status:status
                                                                            standardOutput:standardOutput
                                                                             standardError:standardError];
    if (status == ZNCoffeeScriptReturnStatusOK) {
        result.parsedOutput = @{ZNResultOutputKey : standardOutput};
        return result;
    }
    
    NSDictionary *userInfo = nil;
    if ([ZNCoffeeScript isCompilerError:standardError]) {
        // seems like a coffee script compiler output
        userInfo = [ZNCoffeeScript parseCompileErrorWithTerminationReason:terminationReason
                                                                   status:status
                                                            standardError:standardError];
    }
    else {
        // parse coffeescript' javascript runtime output
        userInfo = [ZNCoffeeScript parseRunErrorUserInfo:terminationReason
                                                  status:status
                                           standardError:standardError];
    }

    result.error = [NSError errorWithDomain:ZNBundleErrorDomain
                                       code:status
                                   userInfo:userInfo];
    return result;
}


+ (NSDictionary *)parseRunErrorUserInfo:(NSTaskTerminationReason)terminationReason
                                 status:(NSInteger)status
                          standardError:(NSString *)standardError

{
    // use same parsing omit any possible line number
    NSDictionary *userInfo = [ZNCoffeeScript parseCompileErrorWithTerminationReason:terminationReason
                                                                             status:status
                                                                      standardError:standardError];
    if (userInfo[ZNErrorLineNumberKey]) {
        userInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        [(NSMutableDictionary*)userInfo removeObjectForKey:ZNErrorLineNumberKey];
    }
    
    return userInfo;
}

@end
