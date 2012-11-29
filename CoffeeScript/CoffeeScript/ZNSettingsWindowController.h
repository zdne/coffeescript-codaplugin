//
//  ZNSettingsWindowController.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/28/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZNSettingsWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSButton *addButton;
@property (strong) IBOutlet NSButton *removeButton;
@property (strong) IBOutlet NSTextField *workingDirectoryTextField;
@property (strong) IBOutlet NSButton *checkSyntaxCheckBox;

- (IBAction)addButtonPressed:(id)sender;
- (IBAction)removeButtonPressed:(id)sender;
- (IBAction)checkOnSaveCheckBoxPressed:(id)sender;


@end
