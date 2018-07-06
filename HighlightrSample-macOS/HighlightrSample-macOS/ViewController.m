//
//  ViewController.m
//  HighlightrSample-macOS
//
//  Created by vvveiii on 2018/7/6.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import "ViewController.h"
#import <Highlightr/Highlightr.h>
#import <Highlightr/CodeAttributedString.h>

@interface ViewController ()

@property(nonatomic,strong) Highlightr *highlightr;
@property(nonatomic,copy) CodeAttributedString *textStorage;
@property(nonatomic,copy) NSString *themeName;

@property(nonatomic,strong) NSTextView *textView;

@end

@implementation ViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 550, 780)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    self.themeName = @"xcode";
    self.textStorage = [[CodeAttributedString alloc] init];
    [self.textStorage.highlightr setThemeTo:self.themeName.lowercaseString];
    self.textStorage.language = @"swift";

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [self.textStorage addLayoutManager:layoutManager];

    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
    [layoutManager addTextContainer:textContainer];

    // Setting Up the Scroll View
    NSScrollView *scrollview = [[NSScrollView alloc] initWithFrame:self.view.frame];
    NSSize contentSize = scrollview.contentSize;
    scrollview.borderType = NSNoBorder;
    scrollview.hasVerticalScroller = YES;
    scrollview.hasHorizontalScroller = NO;
    scrollview.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    // Setting Up the Text View
    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height) textContainer:textContainer];
    self.textView.minSize = NSMakeSize(0.0, contentSize.height);
    self.textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
    self.textView.verticallyResizable = YES;
    self.textView.horizontallyResizable = NO;
    self.textView.autoresizingMask = NSViewWidthSizable;
    self.textView.textContainer.containerSize = NSMakeSize(contentSize.width, FLT_MAX);
    self.textView.textContainer.widthTracksTextView = YES;

    scrollview.documentView = self.textView;
    [self.view addSubview:scrollview];

    NSString *code = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sampleCode" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
    self.textView.string = code;

    self.highlightr = self.textStorage.highlightr;
    [self updateColors];
}

- (void)updateColors {
    NSColor *backgroundColor = self.highlightr.theme.themeBackgroundColor;
    self.textView.backgroundColor = backgroundColor;
}

@end
