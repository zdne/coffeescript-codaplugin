//
//  ZNShellTask.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNShellTask.h"

@interface ZNShellTask ()

@property (strong, atomic) NSMutableData *stdoutBuffer;
@property (strong, atomic) NSMutableData *stderrBuffer;
@property (strong, nonatomic) NSFileHandle *standardInput;
@property (strong, nonatomic) NSFileHandle *standardOutput;
@property (strong, nonatomic) NSFileHandle *standardError;

@property (copy) ShellTaskProgressHandler progressHandler;
@property (copy) ShellTaskCompletionHandler completionHandler;

@end

@implementation ZNShellTask

+ (ZNShellTask *)launchWithLaunchPath:(NSString *)path
                            arguments:(NSArray *)arguments
                                stdIn:(NSString *)input
                          environment:(NSDictionary *)environment
                             progress:(ShellTaskProgressHandler)progress
                           completion:(ShellTaskCompletionHandler)completion;
{
    ZNShellTask *task = [[ZNShellTask alloc] initWithLaunchPath:path
                                                      arguments:arguments
                                                          stdIn:input
                                                    environment:environment
                                                       progress:progress
                                                     completion:completion];
    [task launch];

    if ([input length]) {
        NSData *stdinData = [input dataUsingEncoding:NSUTF8StringEncoding];
        [task.standardInput writeData:stdinData];
        [task.standardInput closeFile]; // EOF!
    }
    
    return task;
}

- initWithLaunchPath:(NSString *)path
           arguments:(NSArray *)arguments
               stdIn:(NSString *)input
         environment:(NSDictionary *)environment
            progress:(ShellTaskProgressHandler)progress
          completion:(ShellTaskCompletionHandler)completion
{
    self = [super init];
    if (self) {
        self.progressHandler = progress;
        self.completionHandler = completion;
        
        _task = [[NSTask alloc] init];
        self.task.launchPath = path;

        if (arguments)
            self.task.arguments = arguments;
        
        if (environment)
            self.task.environment = environment;

        // stdin
        if ([input length]) {
            NSPipe *standardInputPipe = [NSPipe pipe];
            self.standardInput = standardInputPipe.fileHandleForWriting;
            self.task.standardInput = standardInputPipe;
        }

        __block ZNShellTask *blockSelf = self;
        
        // stdout
        NSPipe *standardOutputPipe = [NSPipe pipe];
        self.standardOutput = standardOutputPipe.fileHandleForReading;
        self.task.standardOutput = standardOutputPipe;
        
        [self.standardOutput setReadabilityHandler:^(NSFileHandle *fileHandle) {
            [blockSelf readAvailableStandardOutput:fileHandle];
        }];
        
        // stderr
        NSPipe *standardErrorPipe = [NSPipe pipe];
        self.standardError = standardErrorPipe.fileHandleForReading;
        self.task.standardError = standardErrorPipe;
        
        [self.standardError setReadabilityHandler:^(NSFileHandle *fileHandle) {
            [blockSelf readAvailableStandardError:fileHandle];
        }];
        
        // termination handler        
        [self.task setTerminationHandler:^(NSTask *task) {
            [blockSelf handleTermination];
        }];
    }
    
    return self;
}

- (void)launch
{
    @try {
        [self.task launch];
    }
    @catch (NSException *exception) {
        NSLog(@"failed to launch task: %@", exception.reason);
    }
}

- (void)readAvailableStandardOutput:(NSFileHandle *)fileHandle
{
    NSData *data = [fileHandle availableData];
    if (!self.stdoutBuffer)
        self.stdoutBuffer = [[NSMutableData alloc] initWithData:data];
    else
        [self.stdoutBuffer appendData:data];
    
    if (self.progressHandler) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.progressHandler(dataString, nil);
    }
}

- (void)readAvailableStandardError:(NSFileHandle *)fileHandle
{
    NSData *data = [fileHandle availableData];
    if (!self.stderrBuffer)
        self.stderrBuffer = [[NSMutableData alloc] initWithData:data];
    else
        [self.stderrBuffer appendData:data];
    
    if (self.progressHandler) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.progressHandler(nil, dataString);
    }
}

- (void)finalizeReading
{
    self.standardOutput.readabilityHandler = nil;
    NSData *stdoutData = [self.standardOutput readDataToEndOfFile];
    if ([stdoutData length]) {
        if (!self.stdoutBuffer)
            self.stdoutBuffer = [[NSMutableData alloc] initWithData:stdoutData];
        else
            [self.stdoutBuffer appendData:stdoutData];
    }

    self.standardError.readabilityHandler = nil;
    NSData *stderrData = [self.standardError readDataToEndOfFile];
    if ([stderrData length]) {
        if (!self.stderrBuffer)
            self.stderrBuffer = [[NSMutableData alloc] initWithData:stderrData];
        else
            [self.stderrBuffer appendData:stderrData];
    }
}

- (void)handleTermination
{
    [self finalizeReading]; // eat any leftovers
    
    if (self.completionHandler) {
        NSString *stdoutString = [[NSString alloc] initWithData:self.stdoutBuffer encoding:NSUTF8StringEncoding];
        NSString *stderrString = [[NSString alloc] initWithData:self.stderrBuffer encoding:NSUTF8StringEncoding];
        self.completionHandler(self.task.terminationReason, self.task.terminationStatus, stdoutString, stderrString);
    }
}

#pragma mark - Shell Support

+ (NSString *)userShell
{
    NSString *userShell = [[NSProcessInfo processInfo] environment][@"SHELL"];
    
    // check whether shell is a valid one (by Andrey Tarantsov)
    NSString *shells = [NSString stringWithContentsOfFile:@"/etc/shells"
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    NSArray *availableShells = [shells componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *validShell in availableShells) {
        NSString *shell = [validShell stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([shell isEqualToString:userShell])
            return userShell;
    }
    
    return nil;
}

+ (void)pathForCommand:(NSString *)command
           environment:(NSDictionary *)environment
            completion:(void (^)(NSString *path))completion
{
    NSString *userShell = [ZNShellTask userShell];
    if (![userShell length])
        return;
    
    NSString *whichCommand = [NSString stringWithFormat:@"which %@", command];
    [ZNShellTask launchWithLaunchPath:userShell
                            arguments:@[@"-c", whichCommand]
                                stdIn:nil
                          environment:environment
                             progress:nil
                           completion:^(NSTaskTerminationReason terminationReason, NSInteger status, NSString *standardOutput, NSString *standardError) {
                               if (completion) {
                                   NSString *path = nil;
                                   if (terminationReason == NSTaskTerminationReasonExit &&
                                       status == 0)
                                       path = [standardOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

                                   completion(path);
                               }
                           }];
}

@end
