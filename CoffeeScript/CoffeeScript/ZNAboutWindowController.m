//
//  ZNAboutWindowController.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNAboutWindowController.h"
#import "ZNCoffeeScriptOperation.h"

@implementation ZNAboutWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSString *version = [NSString stringWithFormat:@"Version %@ (build #%@)",
                         [[NSBundle bundleForClass:[ZNAboutWindowController class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle bundleForClass:[ZNAboutWindowController class]] objectForInfoDictionaryKey:@"CFBundleVersion"]];

    [self.versionLabel setStringValue:version];
    
    [self.coffeeScriptActivity setUsesThreadedAnimation:YES];
    [self.coffeeScriptActivity startAnimation:self];

    ZNCoffeeScriptOperation *operation = [ZNCoffeeScriptOperation createOperation:ZNCoffeeScriptOperationTypeGetVersion
                                                                        withInput:nil];
    
    [operation runWithProgress:nil completion:^(ZNCoffeeScriptOperation *operation) {
        [self setCoffeeScriptVersion:operation.result];
    }];
}

- (void)setCoffeeScriptVersion:(ZNCoffeeScriptResult *)result
{
    if ([result.parsedOutput[ZNCoffeeScriptVersionKey] length]) {
        self.coffeeScriptLabel.stringValue = result.parsedOutput[ZNCoffeeScriptVersionKey];
    }
    else {
        self.coffeeScriptLabel.stringValue = @"CoffeeScript not found.";
        self.coffeeScriptLabel.textColor = [NSColor redColor];
    }
    
    [self.coffeeScriptLabel setHidden:NO];
    [self.coffeeScriptActivity stopAnimation:self];    
}

@end
