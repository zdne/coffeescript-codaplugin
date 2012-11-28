//
//  ZNSettingsWindowController.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/28/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNSettingsWindowController.h"
#import "ZNSettings.h"

@interface ZNSettingsWindowController ()

@end

@implementation ZNSettingsWindowController

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


#pragma mark - Actions

- (IBAction)addButtonPressed:(id)sender
{
}

- (IBAction)removeButtonPressed:(id)sender
{
}

- (IBAction)checkOnSaveCheckBoxPressed:(id)sender
{
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    [[ZNSettings sharedSettings] save];
}

@end
