//
//  ViewController.m
//  HighlightrSample
//
//  Created by vvveiii on 2018/7/6.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import "ViewController.h"
#import <Highlightr/Highlightr.h>
#import <Highlightr/CodeAttributedString.h>
#import "ActionSheetStringPicker.h"

@interface ViewController ()

@property(nonatomic,weak) UINavigationBar *navBar;
@property(nonatomic,strong) UIToolbar *textToolbar;
@property(nonatomic,strong) UILabel *titleLabel;

@property(nonatomic,strong) Highlightr *highlightr;
@property(nonatomic,copy) CodeAttributedString *textStorage;
@property(nonatomic,strong) UITextView *textView;
@property(nonatomic,copy) NSString *themeName;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.navBar = self.navigationController.navigationBar;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Theme", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pickTheme:)];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 44)];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = self.titleLabel;

    self.themeName = @"xcode";
    self.textStorage = [[CodeAttributedString alloc] init];
    [self.textStorage.highlightr setThemeTo:self.themeName.lowercaseString];
    self.textStorage.language = @"swift";

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [self.textStorage addLayoutManager:layoutManager];

    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
    [layoutManager addTextContainer:textContainer];

    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds textContainer:textContainer];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.textColor = [UIColor colorWithWhite:0.8 alpha:1];

    self.textToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *languagebarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Language", nil) style:UIBarButtonItemStylePlain target:self action:@selector(pickLanguage:)];
    [self.textToolbar setItems:@[flexibleSpace, languagebarButton]];
    self.textView.inputAccessoryView = self.textToolbar;

    [self.view addSubview:self.textView];

    NSString *code = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sampleCode" ofType:@"txt"] encoding:NSUTF8StringEncoding error:NULL];
    self.textView.text = code;

    self.highlightr = self.textStorage.highlightr;
    [self updateColors];
}

- (void)pickLanguage:(id)sender {
    NSArray *languages = [[self.highlightr supportedLanguages] sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj1 options:NSNumericSearch];
    }];

    NSInteger index = [languages indexOfObject:self.textStorage.language];
    index = index == NSNotFound ? 0 : index;

    [ActionSheetStringPicker showPickerWithTitle:NSLocalizedString(@"Pick a Language", nil) rows:languages initialSelection:index doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        NSString *language = selectedValue;
        self.textStorage.language = language;
        NSString *snippetPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"txt" inDirectory:[@"Samples/" stringByAppendingString:language]];
        NSString *snippet = [NSString stringWithContentsOfFile:snippetPath encoding:NSUTF8StringEncoding error:NULL];
        self.textView.text = snippet;
        [self updateColors];
    } cancelBlock:nil origin:self.textToolbar];
}

- (void)pickTheme:(id)sender {
    [self hideKeyboard:nil];
    NSArray *themes = [self.highlightr availableThemes];
    NSInteger index = [themes indexOfObject:self.themeName.lowercaseString];
    index = index == NSNotFound ? 0 : index;

    [ActionSheetStringPicker showPickerWithTitle:NSLocalizedString(@"Pick a Theme", nil) rows:themes initialSelection:index doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        NSString *theme = selectedValue;
        [self.textStorage.highlightr setThemeTo:theme];
        self.themeName = theme;
        [self updateColors];
    } cancelBlock:nil origin:self.textToolbar];
}

- (void)hideKeyboard:(id)sender {
    [self.textView resignFirstResponder];
}

- (void)updateColors {
    UIColor *backgroundColor = self.highlightr.theme.themeBackgroundColor;
    self.textView.backgroundColor = backgroundColor;
    self.navBar.barTintColor = backgroundColor;
    self.navBar.tintColor = [self invertColor:backgroundColor];
    self.textToolbar.barTintColor = self.navBar.barTintColor;
    self.textToolbar.tintColor = self.navBar.tintColor;

    NSString *language = self.textStorage.language;
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:language]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:self.themeName.capitalizedString]];
    [title addAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Courier" size:15], NSForegroundColorAttributeName: self.navBar.tintColor} range:NSMakeRange(0, language.length)];
    [title addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [self.navBar.tintColor colorWithAlphaComponent:0.5]} range:NSMakeRange(title.length - self.themeName.length, self.themeName.length)];
    self.titleLabel.attributedText = title;
}

- (UIColor *)invertColor:(UIColor *)color {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [color getRed:&r green:&g blue:&b alpha:&a];

    return [UIColor colorWithRed:1 - r green:1 - g blue:1 - g alpha:a];
}

@end
