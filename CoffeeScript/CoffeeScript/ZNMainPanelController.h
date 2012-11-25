//
//  ZNMainPanelController.h
//  CoffeeScript
//
//  Created by Zdenek Nemec on 11/23/12.
//  Copyright (c) 2012 zdne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZNCoffeeScriptOperation.h"
#import "YRKSpinningProgressIndicator.h"

@protocol ZNMainPanelControllerDelegate <NSObject>

- (void)displayInCoda:(NSString *)content;
- (void)goToLine:(NSUInteger)lineNumber;
- (void)stopAllUserOperationsAndReport:(BOOL)report;

@end

@interface ZNMainPanelController : NSWindowController <NSWindowDelegate>

@property (assign, nonatomic) id <ZNMainPanelControllerDelegate> delegate;

@property (strong) IBOutlet NSView *statusView;
@property (strong) IBOutlet YRKSpinningProgressIndicator *activityIndicator;
@property (strong) IBOutlet NSImageView *statusImageView;
@property (strong) IBOutlet NSTextField *singleStatusText;
@property (strong) IBOutlet NSTextField *extendedStatusHeaderText;
@property (strong) IBOutlet NSTextField *extendedStatusText;

@property (strong) IBOutlet NSScrollView *outputView;
@property (strong) IBOutlet NSTextView *outputTextView;

@property (strong) IBOutlet NSButton *actionButton;

- (IBAction)actionButtonPressed:(id)sender;

- (void)displayProgressForOperation:(ZNCoffeeScriptOperation *)operation;
- (void)updateProgressForOperation:(ZNCoffeeScriptOperation *)operation update:(NSString *)update;
- (void)displayCompletedOperation:(ZNCoffeeScriptOperation *)operation;

@end
