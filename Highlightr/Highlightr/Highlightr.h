//
//  Highlightr.h
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import "Theme.h"
#import "CodeAttributedString.h"

/// Utility class for generating a highlighted NSAttributedString from a String.
@interface Highlightr : NSObject

/// Returns the current Theme.
@property(nonatomic,strong) Theme *theme;

/// This block will be called every time the theme changes.
@property(nonatomic,copy) void (^themeChanged)(Theme *theme);

/// Defaults to `false` - when `true`, forces highlighting to finish even if illegal syntax is detected.
@property(nonatomic,assign) BOOL ignoreIllegals;


- (instancetype)initWithHighlightPath:(NSString *)highlightPath;

- (BOOL)setThemeTo:(NSString *)name;

- (NSAttributedString *)highlight:(NSString *)code as:(NSString *)languageName fastRender:(BOOL)fastRender;

- (NSArray<NSString *> *)availableThemes;

- (NSArray<NSString *> *)supportedLanguages;

@end
