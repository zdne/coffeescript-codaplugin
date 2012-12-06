//
//  ZNMainPanelController.m
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/23/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import "ZNMainPanelController.h"
#import "ZNCoffeeScriptOperation.h"

typedef enum ZNButtonAction : NSUInteger {
    ZNButtonActionOpen,
    ZNButtonActionGoTo,
    ZNButtonActionAbort,
    ZNButtonActionNotSpecified = 0xFFFF
} ZNButtonAction;

@interface ZNMainPanelController ()

@property (assign, nonatomic) ZNButtonAction buttonAction;
@property (strong, nonatomic) ZNCoffeeScriptOperation *operation;

@end

@implementation ZNMainPanelController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.buttonAction = ZNButtonActionNotSpecified;
    }
    
    return self;
}
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.window setHidesOnDeactivate:YES];
    self.window.delegate = self;
    
    // setup activity indicator
    self.activityIndicator.color = [NSColor whiteColor];
    self.activityIndicator.displayedWhenStopped = NO;
    self.activityIndicator.drawsBackground = NO;
}

- (void)displayProgressForOperation:(ZNCoffeeScriptOperation *)operation
{
    [self showWindow:nil];
    
    self.operation = operation;
    self.activityIndicator.hidden = NO;
    self.statusImageView.hidden = YES;
    [self.activityIndicator startAnimation:self];
    
    NSString *message = nil;
    switch (operation.type) {
        case ZNCoffeeScriptOperationTypeCompile:
            message = @"Compiling...";
            break;
            
        case ZNCoffeeScriptOperationTypeRun:
            message = @"Running...";
            break;
            
        default:
            break;
    }
    
    [self displayStatus:message details:nil output:nil];
    [self setButtonAction:ZNButtonActionAbort];
}

- (void)updateProgressForOperation:(ZNCoffeeScriptOperation *)operation update:(NSString *)update
{
    // basically just append to the output whatever we have
    NSRange range = NSMakeRange([[self.outputTextView string] length], 0);

    [self.outputTextView replaceCharactersInRange:range withString:update];
    
    NSTextStorage *outputStorage = self.outputTextView.textStorage;
    if (outputStorage) {
        [ZNMainPanelController applyOutputTextStorageAppearance:outputStorage];
    }

    range = NSMakeRange([[self.outputTextView string] length], 0);
    [self.outputTextView scrollRangeToVisible:range];    
}

- (void)displayCompletedOperation:(ZNCoffeeScriptOperation *)operation
{
    [self showWindow:nil];
    
    self.operation = operation;
    self.activityIndicator.hidden = YES;
    self.statusImageView.hidden = NO;
    [self.activityIndicator stopAnimation:self];
    
    NSBundle *bundle = [NSBundle bundleForClass:[ZNMainPanelController class]];
    if (operation.result.status == ZNCoffeeScriptReturnStatusOK) {
        // success
        self.statusImageView.image = [bundle imageForResource: @"OKMark"];
    }
    else {
        // failure
        self.statusImageView.image = [bundle imageForResource: @"ErrorMark"];
    }

    switch (operation.type) {
        case ZNCoffeeScriptOperationTypeCompile:
            [self displayAsCompletedCompileOperation];
            break;
        case ZNCoffeeScriptOperationTypeRun:
            [self displayAsCompletedRunOperation];
            break;
            
        default:
            break;
    }
}

#pragma mark - Compile

- (void)displayAsCompletedCompileOperation
{
    if (self.operation.result.status == ZNCoffeeScriptReturnStatusOK) {
        [self displayStatus:@"Success"
                    details:nil
                     output:self.operation.result.parsedOutput[ZNCompiledJavaScriptKey]];
        [self setButtonAction:ZNButtonActionOpen];
    }
    else {
        [self displayAsError];
    }
}

#pragma mark - Run

- (void)displayAsCompletedRunOperation
{
    if (self.operation.result.status == ZNCoffeeScriptReturnStatusOK) {
        [self displayStatus:@"Finished"
                    details:nil
                     output:self.operation.result.standardOutput];
        [self setButtonAction:ZNButtonActionNotSpecified];
    }
    else {
        [self displayAsError];
    }
}


#pragma mark -

- (void)displayStatus:(NSString *)status details:(NSString *)details output:(NSString *)output
{
    [self.statusView setHidden:NO];
    if (![details length]) {
        // one line status
        self.singleStatusText.hidden = NO;
        self.singleStatusText.stringValue = [status length] ? status : @"";
        
        self.extendedStatusText.hidden = YES;
        self.extendedStatusHeaderText.hidden = YES;
        
        self.outputTextView.string = [output length] ? output : @"";
    }
    else {
        // two line status
        self.extendedStatusHeaderText.hidden = NO;
        self.extendedStatusHeaderText.stringValue = [status length] ? status : @"";;
        
        self.extendedStatusText.hidden = NO;
        self.extendedStatusText.stringValue = details;
        
        self.singleStatusText.hidden = YES;
        
        self.outputTextView.string = [output length] ? output : @"";
    }
    
    NSTextStorage *outputStorage = self.outputTextView.textStorage;
    if (outputStorage) {
        // enforce appearance
        [ZNMainPanelController applyOutputTextStorageAppearance:outputStorage];

        // scroll to top
        [[self.outputView documentView] scrollPoint:NSZeroPoint];
    }
}

- (void)displayAsError
{
    NSError *error = self.operation.result.error;
    if (error) {
        if ([error.userInfo[ZNErrorTerminationReasonKey] integerValue] == ZNCoffeeScriptTerminationReasonTerminated) {
            // terminated
            [self displayStatus:@"Terminated"
                        details:nil
                         output:self.operation.result.standardOutput];
        }
        else {
            // failed
            NSString *errorName = [error.userInfo[ZNErrorNameKey] length] ? error.userInfo[ZNErrorNameKey] : @"Error";
            [self displayStatus:errorName
                        details:error.userInfo[ZNErrorMessageKey]
                         output:self.operation.result.standardError];
        }
        
        if (self.operation.result.error.userInfo[ZNErrorLineNumberKey])
            [self setButtonAction:ZNButtonActionGoTo];
        else
            [self setButtonAction:ZNButtonActionNotSpecified];
    }
    else {
        [self displayStatus:@"Undisclosed Error" details:nil output:self.operation.result.standardError];
        [self setButtonAction:ZNButtonActionNotSpecified];
    }
}

#pragma mark - Action Button

- (void)setButtonAction:(ZNButtonAction)buttonAction
{
    _buttonAction = buttonAction;
    switch (buttonAction) {
        case ZNButtonActionOpen:
            self.actionButton.title = @"Open in Coda";
            [self.actionButton setHidden:NO];            
            break;
            
        case ZNButtonActionGoTo:
            self.actionButton.title = @"Go to Line";
            [self.actionButton setHidden:NO];
            break;
            
        case ZNButtonActionAbort:
            self.actionButton.title = @"Stop";
            [self.actionButton setHidden:NO];
            break;
            
        default:
            [self.actionButton setHidden:YES];
            break;
    }
}

- (IBAction)actionButtonPressed:(id)sender
{
    if (!self.delegate)
        return;
    
    switch (self.buttonAction) {
        case ZNButtonActionOpen:
            [self.delegate displayInCoda:self.operation.result.parsedOutput[ZNCompiledJavaScriptKey]];
            break;
            
        case ZNButtonActionGoTo:
            [self.delegate goToLine:[self.operation.result.error.userInfo[ZNErrorLineNumberKey] unsignedIntegerValue]];
            break;
            
        case ZNButtonActionAbort:
            [self.delegate stopAllUserOperationsAndReport:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    if (self.delegate)
        [self.delegate stopAllUserOperationsAndReport:NO];
    
    [self.activityIndicator stopAnimation:self];
    self.statusImageView.hidden = YES;
    self.actionButton.hidden = YES;
    
    [self displayStatus:@"" details:nil output:nil];
}

#pragma mark - Appearance

+ (void)applyOutputTextStorageAppearance:(NSTextStorage *)storage
{
    storage.foregroundColor = [NSColor lightGrayColor];
    storage.font = [NSFont userFixedPitchFontOfSize:12.0];
}

@end
