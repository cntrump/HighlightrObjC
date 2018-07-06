//
//  Theme.h
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
typedef UIColor RPColor;
typedef UIFont RPFont;
typedef UIFontDescriptor RPFontDescriptor;
#else
#import <AppKit/AppKit.h>
typedef NSColor RPColor;
typedef NSFont RPFont;
typedef NSFontDescriptor RPFontDescriptor;
#endif

typedef NSMutableDictionary<NSString *, NSMutableDictionary<id<NSObject>,id> *> RPThemeDict;
typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> RPThemeStringDict;

@interface Theme : NSObject

@property(nonatomic,copy) NSString *theme;
@property(nonatomic,copy) NSString *lightTheme;

/// Regular font to be used by this theme
@property(nonatomic,strong) RPFont *codeFont;
/// Bold font to be used by this theme
@property(nonatomic,strong) RPFont *boldCodeFont;
/// Italic font to be used by this theme
@property(nonatomic,strong) RPFont *italicCodeFont;

/// Default background color for the current theme.
@property(nonatomic,strong) RPColor *themeBackgroundColor;


- (instancetype)initWithThemeString:(NSString *)themeString;

- (void)setCodeFont:(RPFont *)font;

- (NSAttributedString *)applyStyleToString:(NSString *)string styleList:(NSArray<NSString *> *)styleList;

@end
