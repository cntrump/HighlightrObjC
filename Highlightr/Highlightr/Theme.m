//
//  Theme.m
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import "Theme.h"

@interface Theme ()

@property(nonatomic,strong) RPThemeDict *themeDict;
@property(nonatomic,strong) RPThemeStringDict *strippedTheme;

@end

@implementation Theme

/**
 Initialize the theme with the given theme name.

 - parameter themeString: Theme to use.
 */
- (instancetype)initWithThemeString:(NSString *)themeString {
    self = [super init];
    if (self) {
        self.theme = themeString;
        [self setCodeFont:[RPFont fontWithName:@"Courier" size:14]];
        self.strippedTheme = [self stripTheme:themeString];
        self.lightTheme = [self strippedThemeToString:self.strippedTheme];
        self.themeDict = [self strippedThemeToTheme:self.strippedTheme];
        NSString *bkgColorHex = self.strippedTheme[@".hljs"][@"background"];

        if(!bkgColorHex) {
            bkgColorHex = self.strippedTheme[@".hljs"][@"background-color"];
        }

        if (bkgColorHex) {
            if ([bkgColorHex isEqualToString:@"white"]) {
                self.themeBackgroundColor = [RPColor whiteColor];
            } else if ([bkgColorHex isEqualToString:@"black"]) {
                self.themeBackgroundColor = [RPColor blackColor];
            } else {
                NSRange range = [bkgColorHex rangeOfString:@"#"];
                NSString *str = [bkgColorHex substringFromIndex:range.location];
                self.themeBackgroundColor = [self colorWithHexString:str];
            }
        } else {
            self.themeBackgroundColor = [RPColor whiteColor];
        }
    }

    return self;
}

/**
 Changes the theme font. This will try to automatically populate the codeFont, boldCodeFont and italicCodeFont properties based on the provided font.

 - parameter font: UIFont (iOS or tvOS) or NSFont (OSX)
 */
- (void)setCodeFont:(RPFont *)font {
    _codeFont = font;
#if TARGET_OS_OSX
    RPFontDescriptor *boldDescriptor = [RPFontDescriptor fontDescriptorWithFontAttributes:@{NSFontFamilyAttribute: font.familyName, NSFontFaceAttribute: @"Bold"}];
    RPFontDescriptor *italicDescriptor = [RPFontDescriptor fontDescriptorWithFontAttributes:@{NSFontFamilyAttribute: font.familyName, NSFontFaceAttribute: @"Italic"}];
    RPFontDescriptor *obliqueDescriptor = [RPFontDescriptor fontDescriptorWithFontAttributes:@{NSFontFamilyAttribute: font.familyName, NSFontFaceAttribute: @"Oblique"}];
#else
    RPFontDescriptor *boldDescriptor = [RPFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute: font.familyName, UIFontDescriptorFaceAttribute: @"Bold"}];
    RPFontDescriptor *italicDescriptor = [RPFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute: font.familyName, UIFontDescriptorFaceAttribute: @"Italic"}];
    RPFontDescriptor *obliqueDescriptor = [RPFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute: font.familyName, UIFontDescriptorFaceAttribute: @"Oblique"}];
#endif
    RPFont *boldCodeFont = [RPFont fontWithDescriptor:boldDescriptor size:font.pointSize];
    RPFont *italicCodeFont = [RPFont fontWithDescriptor:italicDescriptor size:font.pointSize];

    if (!italicCodeFont || ![italicCodeFont.familyName isEqualToString:font.familyName]) {
        italicCodeFont = [RPFont fontWithDescriptor:obliqueDescriptor size:font.pointSize];
    }

    if (!italicCodeFont) {
        italicCodeFont = font;
    }

    if (!boldCodeFont) {
        boldCodeFont = font;
    }

    if (self.themeDict) {
        self.themeDict = [self strippedThemeToTheme:self.strippedTheme];
    }
}

- (NSAttributedString *)applyStyleToString:(NSString *)string styleList:(NSArray<NSString *> *)styleList {
    NSAttributedString *returnString;

    if (styleList.count > 0) {
        NSMutableDictionary<NSAttributedStringKey, id> *attrs = [NSMutableDictionary dictionary];
        attrs[NSFontAttributeName] = self.codeFont;
        for (NSString *style in styleList) {
            NSMutableDictionary *themeStyle = self.themeDict[style];
            if (themeStyle) {
                [themeStyle enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull attrName, id  _Nonnull attrValue, BOOL * _Nonnull stop) {
                    attrs[attrName] = attrValue;
                }];
            }
        }

        returnString = [[NSAttributedString alloc] initWithString:string attributes:attrs];
    } else {
        returnString = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: self.codeFont}];
    }

    return returnString;
}

- (NSMutableDictionary *)stripTheme:(NSString *)themeString {
    NSString *objcString = themeString;
    NSRegularExpression *cssRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:(\\.[a-zA-Z0-9\\-_]*(?:[, ]\\.[a-zA-Z0-9\\-_]*)*)\\{([^\\}]*?)\\})" options:NSRegularExpressionCaseInsensitive error:NULL];

    NSArray<NSTextCheckingResult *> *results = [cssRegex matchesInString:themeString options:NSMatchingReportCompletion range:NSMakeRange(0, objcString.length)];

    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *resultDict = [NSMutableDictionary dictionary];

    for (NSTextCheckingResult *result in results) {
        if(result.numberOfRanges == 3) {
            NSMutableDictionary<NSString *, NSString *> *attributes = [NSMutableDictionary dictionary];
            NSArray<NSString *> *cssPairs = [[objcString substringWithRange:[result rangeAtIndex:2]] componentsSeparatedByString:@";"];

            for (NSString *pair in cssPairs) {
                NSArray<NSString *> *cssPropComp = [pair componentsSeparatedByString:@":"];
                if (cssPropComp.count == 2) {
                    attributes[cssPropComp[0]] = cssPropComp[1];
                }
            }

            if (attributes.count > 0) {
                resultDict[[objcString substringWithRange:[result rangeAtIndex:1]]] = attributes;
            }
        }
    }

    NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];

    [resultDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull keys, NSDictionary<NSString *,NSString *> * _Nonnull result, BOOL * _Nonnull stop) {
        NSArray<NSString *> *keyArray = [[keys stringByReplacingOccurrencesOfString:@" " withString:@","] componentsSeparatedByString:@","];

        for (NSString *key in keyArray) {
            NSMutableDictionary<NSString *, NSString *> *props = returnDict[key];
            if (!props) {
                props = [NSMutableDictionary dictionary];
            }

            [result enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull pName, NSString * _Nonnull pValue, BOOL * _Nonnull stop) {
                props[pName] = pValue;
            }];

            returnDict[key] = props;
        }
    }];

    return returnDict;
}

- (NSString *)strippedThemeToString:(RPThemeStringDict *)theme {
    __block NSString *resultString = @"";

    [theme enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,NSString *> * _Nonnull props, BOOL * _Nonnull stop) {
        resultString = [resultString stringByAppendingString:[key stringByAppendingString:@"{"]];

        [props enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull cssProp, NSString * _Nonnull val, BOOL * _Nonnull stop) {
            if (![key isEqualToString:@".hljs"] ||
                (![cssProp.lowercaseString isEqualToString:@"background-color"] && ![cssProp.lowercaseString isEqualToString:@"background"])) {
                resultString = [resultString stringByAppendingString:[NSString stringWithFormat:@"%@:%@", cssProp, val]];
            }
        }];

        resultString = [resultString stringByAppendingString:@"}"];
    }];

    return resultString;
}

- (RPThemeDict *)strippedThemeToTheme:(RPThemeStringDict *)theme {
    RPThemeDict *returnTheme = [RPThemeDict dictionary];

    [theme enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull className, NSMutableDictionary<NSString *,NSString *> * _Nonnull props, BOOL * _Nonnull stop) {
        NSMutableDictionary<NSAttributedStringKey,id> *keyProps = [NSMutableDictionary dictionary];

        [props enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull prop, BOOL * _Nonnull stop) {
            if ([key isEqualToString:@"color"]) {
                keyProps[[self attributeForCSSKey:key]] = [self colorWithHexString:prop];
            } else if ([key isEqualToString:@"font-style"]) {
                keyProps[[self attributeForCSSKey:key]] = [self fontForCSSStyle:prop];
            } else if ([key isEqualToString:@"font-weight"]) {
                keyProps[[self attributeForCSSKey:key]] = [self fontForCSSStyle:prop];
            } else if ([key isEqualToString:@"background-color"]) {
                keyProps[[self attributeForCSSKey:key]] = [self colorWithHexString:prop];
            }
        }];

        if (keyProps.count > 0) {
            NSString *key = [className stringByReplacingOccurrencesOfString:@"." withString:@""];
            returnTheme[key] = keyProps;
        }
    }];

    return returnTheme;
}

- (RPFont *)fontForCSSStyle:(NSString *)fontStyle {
    if ([fontStyle isEqualToString:@"bold"] ||
        [fontStyle isEqualToString:@"bolder"] ||
        [fontStyle isEqualToString:@"600"] ||
        [fontStyle isEqualToString:@"700"] ||
        [fontStyle isEqualToString:@"800"] ||
        [fontStyle isEqualToString:@"900"]) {
        return self.boldCodeFont;
    } else if ([fontStyle isEqualToString:@"italic"] ||
               [fontStyle isEqualToString:@"oblique"]) {
        return self.italicCodeFont;
    }

    return self.codeFont;
}

- (NSAttributedStringKey)attributeForCSSKey:(NSString *)key {
    NSAttributedStringKey returnKey = NSFontAttributeName;

    if ([key isEqualToString:@"color"]) {
        returnKey = NSForegroundColorAttributeName;
    } else if ([key isEqualToString:@"font-style"]) {
        returnKey = NSFontAttributeName;
    } else if ([key isEqualToString:@"font-weight"]) {
        returnKey = NSFontAttributeName;
    } else if ([key isEqualToString:@"background-color"]) {
        returnKey = NSBackgroundColorAttributeName;
    }

    return returnKey;
}

- (RPColor *)colorWithHexString:(NSString *)hex {
    NSString *cString = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    } else {
        if ([cString isEqualToString:@"white"]) {
            return [RPColor whiteColor];
        } else if ([cString isEqualToString:@"black"]) {
            return [RPColor blackColor];
        } else if ([cString isEqualToString:@"red"]) {
            return [RPColor redColor];
        } else if ([cString isEqualToString:@"green"]) {
            return [RPColor greenColor];
        } else if ([cString isEqualToString:@"blue"]) {
            return [RPColor blueColor];
        }

        return [RPColor grayColor];
    }

    if (cString.length != 6 && cString.length != 3) {
        return [RPColor grayColor];
    }

    unsigned r = 0, g = 0, b = 0;
    CGFloat divisor;

    if (cString.length == 6 ) {
        NSString *rString = [cString substringToIndex:2];
        NSString *gString = [[cString substringFromIndex:2] substringToIndex:2];
        NSString *bString = [[cString substringFromIndex:4] substringToIndex:2];

        [[NSScanner scannerWithString:rString] scanHexInt:&r];
        [[NSScanner scannerWithString:gString] scanHexInt:&g];
        [[NSScanner scannerWithString:bString] scanHexInt:&b];

        divisor = 255.0;

    } else {
        NSString *rString = [cString substringToIndex:1];
        NSString *gString = [[cString substringFromIndex:1] substringToIndex:1];
        NSString *bString = [[cString substringFromIndex:2] substringToIndex:1];

        [[NSScanner scannerWithString:rString] scanHexInt:&r];
        [[NSScanner scannerWithString:gString] scanHexInt:&g];
        [[NSScanner scannerWithString:bString] scanHexInt:&b];

        divisor = 15.0;
    }

    return [RPColor colorWithRed:(CGFloat)r/divisor green:(CGFloat)g/divisor blue:(CGFloat)b/divisor alpha:1];
}

@end
