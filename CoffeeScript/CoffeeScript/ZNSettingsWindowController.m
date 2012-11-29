//
//  ZNSettingsWindowController.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/28/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNSettingsWindowController.h"
#import "ZNSettings.h"
#import "ZNCoffeeScript.h"

static NSString * const TableColumnVariableIdentifier = @"variable";
static NSString * const TableColumnValueIdentifier = @"value";

@interface ZNSettingsWindowController ()

@property (strong, nonatomic) NSMutableArray *orderedShellVariableKeys;
@property (strong, nonatomic) NSMutableDictionary *shellVariables;
@property (assign, nonatomic) BOOL settingsLoaded;

@end

@implementation ZNSettingsWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.settingsLoaded = NO;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.orderedShellVariableKeys count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *key = [self.orderedShellVariableKeys objectAtIndex:row];
    
    if ([tableColumn.identifier isEqualToString:TableColumnVariableIdentifier]) {
        return key;
    }
    else if ([tableColumn.identifier isEqualToString:TableColumnValueIdentifier]) {
        NSString *value = [self.shellVariables objectForKey:key];
        return value;
    }
    else {
        return @"";
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *key = [self.orderedShellVariableKeys objectAtIndex:row];
    
    if ([tableColumn.identifier isEqualToString:TableColumnVariableIdentifier]) {
        // key name change
        if ([self keyExists:object]) {
            NSLog(@"won't set key name - it already exists");
            return;
        }
        
        NSString *value = [self.shellVariables objectForKey:key];
        self.orderedShellVariableKeys[row] = object;
        [self.shellVariables setObject:value forKey:object];
        [self.shellVariables removeObjectForKey:key];
    }
    else if ([tableColumn.identifier isEqualToString:TableColumnValueIdentifier]) {
        self.shellVariables[key] = object;
    }
}

#pragma mark - NSTableViewDelegate


#pragma mark - Actions

- (IBAction)addButtonPressed:(id)sender
{
    NSString *newKey = @"MY_VARIABLE";
    if ([self keyExists:newKey])
        return;

    [self.tableView beginUpdates];
    
    [self.orderedShellVariableKeys insertObject:newKey atIndex:0];
    [self.shellVariables setObject:@"some value" forKey:newKey];

    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0] withAnimation:NSTableViewAnimationSlideLeft];
    [self.tableView endUpdates];
}

- (IBAction)removeButtonPressed:(id)sender
{
    if ([self.tableView.selectedRowIndexes count]) {
        NSIndexSet *selectedIndexes = [self.tableView.selectedRowIndexes copy];
        
        [self.tableView beginUpdates];

        [self.tableView removeRowsAtIndexes:self.tableView.selectedRowIndexes withAnimation:NSTableViewAnimationEffectFade];

        NSArray *keysToRemove = [self.orderedShellVariableKeys objectsAtIndexes:selectedIndexes];
        for (NSString *key in keysToRemove) {
            [self.shellVariables removeObjectForKey:key];
        }
        
        [self.orderedShellVariableKeys removeObjectsAtIndexes:selectedIndexes];
        
        [self.tableView endUpdates];
    }
}

- (IBAction)checkOnSaveCheckBoxPressed:(id)sender
{
}

- (BOOL)keyExists:(NSString *)key
{
    for (NSString *existingKey in self.orderedShellVariableKeys) {
        if ([key isEqualToString:existingKey])
            return YES;
    }
    return NO;
}

#pragma mark - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    if (!self.settingsLoaded)
        [self load];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self save];
    self.settingsLoaded = NO;
}

#pragma mark - Serialization

- (void)load
{
    // Variables
    if ([[ZNSettings sharedSettings] environment]) {
        self.shellVariables = [[[ZNSettings sharedSettings] environment] mutableCopy];
    }
    else {
        self.shellVariables = [NSMutableDictionary dictionaryWithDictionary:@{@"PATH" : @""}]; // to point user
    }
    
    self.orderedShellVariableKeys = [[NSMutableArray alloc] initWithCapacity:[self.shellVariables count]];
    [self.shellVariables enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [self.orderedShellVariableKeys addObject:key];
    }];
    
    
    // Working directory
    if ([[[ZNSettings sharedSettings] workingDirectory] length]) {
        [self.workingDirectoryTextField setStringValue:[[ZNSettings sharedSettings] workingDirectory]];
    }
    else {
        [self.workingDirectoryTextField setStringValue:@""];
    }
    
    // Check state
    [self.checkSyntaxCheckBox setState:([[ZNSettings sharedSettings] checkOnSave]) ? NSOnState : NSOffState ];
    
    self.settingsLoaded = YES;
    [self.tableView reloadData];
}

- (void)save
{
    // Variables
    if (self.shellVariables) {
        __block NSMutableDictionary *environment = [[NSMutableDictionary alloc] init];
        for (NSString *key in self.orderedShellVariableKeys) {
            [environment setObject:self.shellVariables[key] forKey:key];
        }
        
        if ([environment count]) {
            [[ZNSettings sharedSettings] setEnvironment:environment];
        }
        else {
            [[ZNSettings sharedSettings] setEnvironment:nil];
        }
    }
    else {
        [[ZNSettings sharedSettings] setEnvironment:nil];
    }
    
    // Working Directory
    if ([[self.workingDirectoryTextField stringValue] length]) {
        [[ZNSettings sharedSettings] setWorkingDirectory:[self.workingDirectoryTextField stringValue]];
    }
    else {
        [[ZNSettings sharedSettings] setWorkingDirectory:nil];
    }
    
    // Check state
    [[ZNSettings sharedSettings] setCheckOnSave:(self.checkSyntaxCheckBox.state == NSOnState)];
    
    [[ZNSettings sharedSettings] save];
    [[ZNCoffeeScript sharedCoffeeScript] loadCoffeeEnvironment]; // inject new settings
}


@end
