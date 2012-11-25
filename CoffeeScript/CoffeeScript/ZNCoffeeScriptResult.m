//
//  ZNCoffeeScriptResult.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/24/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNCoffeeScriptResult.h"

NSString * const ZNCompiledJavaScriptKey = @"CompiledJavaScript";
NSString * const ZNCoffeeScriptVersionKey = @"CoffeeScriptVersion";
NSString * const ZNResultOutputKey = @"ResultOutput";

NSString * const ZNErrorNameKey = @"ErrorName";
NSString * const ZNErrorMessageKey = @"ErrorMessage";
NSString * const ZNErrorLineNumberKey = @"ErrorLineNumber";
NSString * const ZNErrorStackKey = @"ErrorStack";
NSString * const ZNErrorTerminationReasonKey = @"ErrorTerminationReason";

NSString * const ZNBundleErrorDomain = @"org.zdne.codaplugin.coffeescript";

@implementation ZNCoffeeScriptResult

- (id)init
{
    self = [super init];
    if (self) {
        _terminationReason = -1;
        _status = ZNCoffeeScriptReturnStatusUndefined;
     }
    
    return self;
}

- (id)initWithTerminationReason:(NSTaskTerminationReason)terminationReason
                         status:(ZNCoffeeScriptReturnStatus)status
                 standardOutput:(NSString *)standardOutput
                  standardError:(NSString *)standardError
{
    self = [super init];
    if (self) {
        _terminationReason = terminationReason;
        _status = status;
        self.standardOutput = standardOutput;
        self.standardError = standardError;
    }
    return self;
}

@end
