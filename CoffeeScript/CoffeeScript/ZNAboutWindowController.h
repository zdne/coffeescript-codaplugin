//
//  ZNAboutWindowController.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZNAboutWindowController : NSWindowController

@property (strong) IBOutlet NSTextField *versionLabel;
@property (strong) IBOutlet NSTextField *coffeeScriptLabel;
@property (strong) IBOutlet NSProgressIndicator *coffeeScriptActivity;

@end
