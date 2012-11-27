//
//  ZNCoffeeScriptPlugin.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/22/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNCoffeeScriptPlugin.h"
#import "ZNCoffeeScript.h"
#import "ZNAboutWindowController.h"
#import "ZNMainPanelController.h"
#import "ZNCoffeeScriptOperation.h"

@interface ZNCoffeeScriptPlugin ()

@property (strong, nonatomic) CodaPlugInsController *codaPluginController;
@property (strong, nonatomic) ZNAboutWindowController *aboutWindowController;
@property (strong, nonatomic) ZNMainPanelController *mainPanelController;

@property (strong, nonatomic) ZNCoffeeScriptOperation *userOperation;   // an operation that is presented to user
@property (assign, nonatomic) BOOL didFailedSaveCheck; 

@end

@implementation ZNCoffeeScriptPlugin

- (NSString *)name
{
    return @"CoffeeScript";
}

- (id)initWithPlugInController:(CodaPlugInsController *)controller bundle:(NSBundle *)bundle
{
    return [self initWithController:controller];    //Coda 2.0 and lower
}

- (id)initWithPlugInController:(CodaPlugInsController *)controller plugInBundle:(NSObject<CodaPlugInBundle> *)bundle
{
    return [self initWithController:controller];    // Coda 2.0.1 and higher
}

- (id)initWithController:(CodaPlugInsController *)codaPluginController
{
    self = [super init];
    if (self) {
        self.didFailedSaveCheck = NO;
        self.codaPluginController = codaPluginController;

        [self.codaPluginController registerActionWithTitle:@"Run"
                                     underSubmenuWithTitle:nil
                                                    target:self
                                                  selector:@selector(run:)
                                         representedObject:nil
                                             keyEquivalent:@"@U"                   // rUn
                                                pluginName:[self name]];
        
        [self.codaPluginController registerActionWithTitle:@"Compile"
                                     underSubmenuWithTitle:nil
                                                    target:self
                                                  selector:@selector(compile:)
                                         representedObject:nil
                                             keyEquivalent:@"@M"                   // coMpile
                                                pluginName:[self name]];
        
        [self.codaPluginController registerActionWithTitle:@"About"
                                                    target:self
                                                  selector:@selector(about:)];
        
        // init the coffee script component
        [ZNCoffeeScript sharedCoffeeScript];
        
        // init main panel
        self.mainPanelController = [[ZNMainPanelController alloc] initWithWindowNibName:@"ZNMainPanel"];
        self.mainPanelController.delegate = self;
	}
    
	return self;
}

- (void)textViewWillSave:(CodaTextView *)textView
{
    NSString *path = [textView path];
    if ([path length]) {
        NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
        if ([[url pathExtension] isEqualToString:@"coffee"]) {
            //NSLog(@"coda will save a coffe file: %@", path);
            
            NSString *editorText = [textView string];
            
            ZNCoffeeScriptOperation *operation = [ZNCoffeeScriptOperation createOperation:ZNCoffeeScriptOperationTypeCompile
                                                                                withInput:editorText];
            [operation runWithProgress:nil completion:^(ZNCoffeeScriptOperation *operation) {
                [self checkFileBeingSaved:operation];
            }];
        }
    }
}

#pragma mark - User Operation Management

- (void)commenceUserOperation:(ZNCoffeeScriptOperation *)operation
{
    [self stopAllUserOperationsAndReport:NO];
    
    self.userOperation = operation;
    [self userOperationStarted:operation];
    
    [operation runWithProgress:^(ZNCoffeeScriptOperation *operation, NSString *update) {
        [self userOperationUpdated:operation update:update];
    }
                    completion:^(ZNCoffeeScriptOperation *operation) {
                        [self userOperationCompleted:operation];
                    }];
}

- (void)userOperationStarted:(ZNCoffeeScriptOperation *)operation
{
    [self.mainPanelController displayProgressForOperation:operation];
}

- (void)userOperationUpdated:(ZNCoffeeScriptOperation *)operation update:(NSString *)update
{
    [self.mainPanelController updateProgressForOperation:operation update:update];
}

- (void)userOperationCompleted:(ZNCoffeeScriptOperation *)operation
{
    [self.mainPanelController displayCompletedOperation:operation];
    self.userOperation = nil;
}

#pragma mark - Compile Action

- (void)compile:(id)sender
{
    ZNCoffeeScriptOperation *operation = [ZNCoffeeScriptOperation createOperation:ZNCoffeeScriptOperationTypeCompile
                                                                        withInput:[self textInputFromCoda]];
    [self commenceUserOperation:operation];
}

- (NSString *)textInputFromCoda
{
    CodaTextView *codaTextView = [self.codaPluginController focusedTextView:self];
    if (!codaTextView)
        return nil;
    
    NSString *textInput = [codaTextView selectedText];
    if (![textInput length])
        textInput = [codaTextView string];
    
    return textInput;
}

#pragma mark - Run Action

- (void)run:(id)sender
{
    ZNCoffeeScriptOperation *operation = [ZNCoffeeScriptOperation createOperation:ZNCoffeeScriptOperationTypeRun
                                                                        withInput:[self textInputFromCoda]];
    [self commenceUserOperation:operation];
}

#pragma mark - About Action

- (void)about:(id)sender
{
    if (!self.aboutWindowController) {
        self.aboutWindowController = [[ZNAboutWindowController alloc] initWithWindowNibName:@"ZNAboutWindow"];
    }
    
    [self.aboutWindowController showWindow:self];
}

#pragma mark - On Save Check

- (void)checkFileBeingSaved:(ZNCoffeeScriptOperation *)operation
{
    if (operation.result.status != ZNCoffeeScriptReturnStatusOK) {
        self.didFailedSaveCheck = YES;
        [self.mainPanelController displayCompletedOperation:operation];
        
        [self goToLine:[operation.result.error.userInfo[ZNErrorLineNumberKey] unsignedIntegerValue]];
    }
    else {
        if (self.didFailedSaveCheck && 
            [self.mainPanelController.window isVisible]) {
            [self.mainPanelController.window orderOut:self];
            self.didFailedSaveCheck = NO;
        }
    }
}

#pragma mark - ZNMainPanelControllerDelegate

- (void)displayInCoda:(NSString *)content
{
    if ([content length]) {
        CodaTextView *codaTextView = [self.codaPluginController makeUntitledDocument];
        [codaTextView insertText:content];
    }
}

- (void)goToLine:(NSUInteger)lineNumber
{
    CodaTextView *codaTextView = [self.codaPluginController focusedTextView:self];
    [codaTextView goToLine:lineNumber column:0];
    [codaTextView.window makeKeyAndOrderFront:self];
}

- (void)stopAllUserOperationsAndReport:(BOOL)report;
{
    // TODO: report suppression
    if (self.userOperation && self.userOperation.isRunning) {
        [self.userOperation terminate];
    }
}

@end
