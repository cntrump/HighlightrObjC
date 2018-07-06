//
//  Highlightr.m
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import "Highlightr.h"
#import "HTMLUtils.h"

@interface Highlightr ()

@property(nonatomic,strong) JSValue *hljs;

@property(nonatomic,strong) NSBundle *bundle;
@property(nonatomic,copy) NSString *htmlStart;
@property(nonatomic,copy) NSString *spanStart;
@property(nonatomic,copy) NSString *spanStartClose;
@property(nonatomic,copy) NSString *spanEnd;
@property(nonatomic,strong) NSRegularExpression *htmlEscape;

@end

@implementation Highlightr

- (NSString *)htmlStart {
    if (!_htmlStart) {
        _htmlStart = @"<";
    }

    return _htmlStart;
}

- (NSString *)spanStart {
    if (!_spanStart) {
        _spanStart = @"span class=\"";
    }

    return _spanStart;
}

- (NSString *)spanStartClose {
    if (!_spanStartClose) {
        _spanStartClose = @"\">";
    }

    return _spanStartClose;
}

- (NSString *)spanEnd {
    if (!_spanEnd) {
        _spanEnd = @"/span>";
    }

    return _spanEnd;
}

- (NSRegularExpression *)htmlEscape {
    if (!_htmlEscape) {
        _htmlEscape = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9]+?;" options:NSRegularExpressionCaseInsensitive error:NULL];
    }

    return _htmlEscape;
}

/**
 Default init method.

 - parameter highlightPath: The path to `highlight.min.js`. Defaults to `Highlightr.framework/highlight.min.js`

 - returns: Highlightr instance.
 */
- (instancetype)initWithHighlightPath:(NSString *)highlightPath {
    self = [super init];
    if (self) {
        JSContext *jsContext = [[JSContext alloc] init];
        JSValue *window = [JSValue valueWithNewObjectInContext:jsContext];
        [jsContext setObject:window forKeyedSubscript:@"window"];

        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        self.bundle = bundle;
        NSString *hgPath = highlightPath;
        if (!hgPath) {
            hgPath = [bundle pathForResource:@"highlight.min" ofType:@"js"];
        }

        if (!hgPath) {
            return nil;
        }

        NSString *hgJs = [[NSString alloc] initWithContentsOfFile:hgPath encoding:NSUTF8StringEncoding error:NULL];
        JSValue *value = [jsContext evaluateScript:hgJs];
        if (!value.toBool) {
            return nil;
        }

        JSValue *hljs = window[@"hljs"];

        if (!hljs) {
            return nil;
        }

        self.hljs = hljs;

        if (![self setThemeTo:@"pojoaque"]) {
            return nil;
        }
    }

    return self;
}

- (instancetype)init {
    return [self initWithHighlightPath:nil];
}

- (void)setTheme:(Theme *)theme {
    _theme = theme;

    if (self.themeChanged) {
        self.themeChanged(theme);
    }
}

/**
 Set the theme to use for highlighting.

 - parameter to: Theme name

 - returns: true if it was possible to set the given theme, false otherwise
 */
- (BOOL)setThemeTo:(NSString *)name {
    NSString *defTheme = [self.bundle pathForResource:[name stringByAppendingString:@".min"] ofType:@"css"];
    if (!defTheme) {
        return NO;
    }

    NSString *themeString = [[NSString alloc] initWithContentsOfFile:defTheme encoding:NSUTF8StringEncoding error:NULL];
    self.theme =  [[Theme alloc] initWithThemeString:themeString];

    return YES;
}

/**
 Takes a String and returns a NSAttributedString with the given language highlighted.

 - parameter code:           Code to highlight.
 - parameter languageName:   Language name or alias. Set to `nil` to use auto detection.
 - parameter fastRender:     Defaults to true - When *true* will use the custom made html parser rather than Apple's solution.

 - returns: NSAttributedString with the detected code highlighted.
 */
- (NSAttributedString *)highlight:(NSString *)code as:(NSString *)languageName fastRender:(BOOL)fastRender {
    JSValue *ret;
    if (languageName) {
        ret = [self.hljs invokeMethod:@"highlight" withArguments:@[languageName, code, @(self.ignoreIllegals)]];
    } else {
        // language auto detection
        ret = [self.hljs invokeMethod:@"highlightAuto" withArguments:@[code]];
    }

    JSValue *res = ret[@"value"];
    NSString *string = res.toString;
    if (!string) {
        return nil;
    }

    __block NSAttributedString *returnString;
    if (fastRender) {
        returnString = [self processHTMLString:string];
    } else {
        string = [NSString stringWithFormat:@"<style>%@</style><pre><code class=\"hljs\">%@</code></pre>", self.theme.lightTheme, string];
        NSDictionary<NSAttributedStringDocumentReadingOptionKey, id> *opt = @{
                                                                              NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
                                                                              NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding)
                                                                              };
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self safeMainSync:^ {
            returnString = [[NSMutableAttributedString alloc] initWithData:data options:opt documentAttributes:nil error:NULL];
        }];
    }

    return returnString;
}

/**
 Returns a list of all the available themes.

 - returns: Array of Strings
 */
- (NSArray<NSString *> *)availableThemes {
    NSArray<NSString *> *paths = [self.bundle pathsForResourcesOfType:@"css" inDirectory:nil];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *path in paths) {
        [result addObject:[path.lastPathComponent stringByReplacingOccurrencesOfString:@".min.css" withString:@""]];
    }

    return result;
}

/**
 Returns a list of all supported languages.

 - returns: Array of Strings
 */
- (NSArray<NSString *> *)supportedLanguages {
    JSValue *res = [self.hljs invokeMethod:@"listLanguages" withArguments:@[]];

    return res.toArray;
}

/**
 Execute the provided block in the main thread synchronously.
 */
- (void)safeMainSync:(dispatch_block_t)block {
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (NSAttributedString *)processHTMLString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    NSString *scannedString;
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSMutableArray *propStack = [NSMutableArray arrayWithObject:@"hljs"];

    while (!scanner.isAtEnd) {
        BOOL ended = NO;

        if ([scanner scanUpToString:self.htmlStart intoString:&scannedString]) {
            if (scanner.isAtEnd) {
                ended = YES;
            }
        }

        if (scannedString && scannedString.length > 0) {
            NSAttributedString *attrScannedString = [self.theme applyStyleToString:scannedString styleList:propStack];
            [resultString appendAttributedString:attrScannedString];
            if (ended) {
                continue;
            }
        }

        scanner.scanLocation += 1;

        NSString *string = scanner.string;
        NSString *nextChar = [string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
        if ([nextChar isEqualToString:@"s"]) {
            scanner.scanLocation += self.spanStart.length;
            [scanner scanUpToString:self.spanStartClose intoString:&scannedString];
            scanner.scanLocation += self.spanStartClose.length;
            [propStack addObject:scannedString];
        } else if ([nextChar isEqualToString:@"/"]) {
            scanner.scanLocation += self.spanEnd.length;
            [propStack removeLastObject];
        } else {
            NSAttributedString *attrScannedString = [self.theme applyStyleToString:@"<" styleList:propStack];
            [resultString appendAttributedString:attrScannedString];
            scanner.scanLocation += 1;
        }

        scannedString = nil;
    }

    NSArray<NSTextCheckingResult *> *results = [self.htmlEscape matchesInString:resultString.string options:NSMatchingReportCompletion range:NSMakeRange(0, resultString.length)];

    NSInteger locOffset = 0;
    for (NSTextCheckingResult *result in results) {
        NSRange fixedRange = NSMakeRange(result.range.location-locOffset, result.range.length);
        NSString *entity = [resultString.string substringWithRange:fixedRange];
        NSString *decodedEntity = [HTMLUtils decode:entity];
        if (decodedEntity) {
            [resultString replaceCharactersInRange:fixedRange withString:decodedEntity];
            locOffset += result.range.length-1;
        }
    }

    return resultString;
}

@end
