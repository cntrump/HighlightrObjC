//
//  CodeAttributedString.m
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import "CodeAttributedString.h"
#import "Highlightr.h"

@interface CodeAttributedString () <NSCopying, NSMutableCopying>

/// Internal Storage
@property(nonatomic,strong) NSTextStorage *stringStorage;

@end

@implementation CodeAttributedString

/**
 Initialize the CodeAttributedString

 - parameter highlightr: The highlightr instance to use. Defaults to `Highlightr()`.

 */
- (instancetype)initWithHighlightr:(Highlightr *)highlightr {
    self = [super init];
    if (self) {
        self.highlightr = highlightr ? highlightr : [[Highlightr alloc] init];
        [self setupListeners];
    }

    return self;
}

/// Initialize the CodeAttributedString
- (instancetype)init {
    self = [super init];
    if (self) {
        self.highlightr = [[Highlightr alloc] init];
        [self setupListeners];
    }

    return self;
}

/// Initialize the CodeAttributedString
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.highlightr = [[Highlightr alloc] init];
        [self setupListeners];
    }

    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    CodeAttributedString *model = [[CodeAttributedString allocWithZone:zone] init];
    model.stringStorage = self.stringStorage;
    model.highlightrDelegate = self.highlightrDelegate;
    model.language = self.language;

    return model;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    CodeAttributedString *model = [[CodeAttributedString allocWithZone:zone] init];
    model.stringStorage = self.stringStorage;
    model.highlightrDelegate = self.highlightrDelegate;
    model.language = self.language;
    
    return model;
}

- (NSTextStorage *)stringStorage {
    if (!_stringStorage) {
        _stringStorage = [[NSTextStorage alloc] init];
    }

    return _stringStorage;
}

- (void)setLanguage:(NSString *)language {
    _language = language;
    [self highlight:NSMakeRange(0, self.stringStorage.length)];
}

/// Returns a standard String based on the current one.
- (NSString *)string {
    return self.stringStorage.string;
}

/**
 Returns the attributes for the character at a given index.

 - parameter location: Int
 - parameter range:    NSRangePointer

 - returns: Attributes
 */
- (NSDictionary<NSAttributedStringKey, id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [self.stringStorage attributesAtIndex:location effectiveRange:range];
}

/**
 Replaces the characters at the given range with the provided string.

 - parameter range: NSRange
 - parameter str:   String
 */
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self.stringStorage replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:str.length - range.length];
}

/**
 Sets the attributes for the characters in the specified range to the given attributes.

 - parameter attrs: [String : AnyObject]
 - parameter range: NSRange
 */
- (void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self.stringStorage setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

/// Called internally everytime the string is modified.
- (void)processEditing {
    [super processEditing];

    if (self.language) {
        if (self.editedMask & NSTextStorageEditedCharacters) {
            NSString *string = self.string;
            NSRange range = [string paragraphRangeForRange:self.editedRange];
            [self highlight:range];
        }
    }
}

- (void)highlight:(NSRange)range {
    if (!self.language) {
        return;
    }

    if (self.highlightrDelegate) {
        BOOL shouldHighlight = NO;
        if ([self.highlightrDelegate respondsToSelector:@selector(shouldHighlight:)]) {
            shouldHighlight = [self.highlightrDelegate shouldHighlight:range];
        }

        if (!shouldHighlight) {
            return;
        }
    }

    NSString *string = self.string;
    NSString *line = [string substringWithRange:range];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAttributedString *tmpStrg = [self.highlightr highlight:line as:self.language fastRender:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            //Checks to see if this highlighting is still valid.
            if ((range.location + range.length) > self.stringStorage.length) {
                if ([self.highlightrDelegate respondsToSelector:@selector(didHighlight:success:)]) {
                    [self.highlightrDelegate didHighlight:range success:NO];
                }

                return;
            }

            if (![tmpStrg.string isEqualToString:[self.stringStorage attributedSubstringFromRange:range].string]) {
                if ([self.highlightrDelegate respondsToSelector:@selector(didHighlight:success:)]) {
                    [self.highlightrDelegate didHighlight:range success:NO];
                }

                return;
            }

            [self beginEditing];
            [tmpStrg enumerateAttributesInRange:NSMakeRange(0, tmpStrg.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange locRange, BOOL * _Nonnull stop) {
                NSRange fixedRange = NSMakeRange(range.location+locRange.location, locRange.length);
                fixedRange.length = (fixedRange.location + fixedRange.length < string.length) ? fixedRange.length : string.length-fixedRange.location;
                fixedRange.length = (fixedRange.length >= 0) ? fixedRange.length : 0;
                [self.stringStorage setAttributes:attrs range:fixedRange];
            }];
            [self endEditing];
            [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];

            if ([self.highlightrDelegate respondsToSelector:@selector(didHighlight:success:)]) {
                [self.highlightrDelegate didHighlight:range success:YES];
            }
        });
    });
}

- (void)setupListeners {
    __weak typeof(self) wself = self;
    self.highlightr.themeChanged = ^(Theme *theme) {
        [wself highlight:NSMakeRange(0, wself.stringStorage.length)];
    };
}

@end
