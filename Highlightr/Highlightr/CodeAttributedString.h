//
//  CodeAttributedString.h
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

@class Highlightr;

@protocol HighlightDelegate <NSObject>

@optional

/**
 If this method returns *false*, the highlighting process will be skipped for this range.

 - parameter range: NSRange

 - returns: Bool
 */
- (BOOL)shouldHighlight:(NSRange)range;

/**
 Called after a range of the string was highlighted, if there was an error **success** will be *false*.

 - parameter range:   NSRange
 - parameter success: Bool
 */
- (BOOL)didHighlight:(NSRange)range success:(BOOL)success;

@end

@interface CodeAttributedString : NSTextStorage

/// Highlightr instace used internally for highlighting. Use this for configuring the theme.
@property(nonatomic,strong) Highlightr *highlightr;

/// This object will be notified before and after the highlighting.
@property(nonatomic,weak) id<HighlightDelegate> highlightrDelegate;

/// Language syntax to use for highlighting. Providing nil will disable highlighting.
@property(nonatomic,copy) NSString *language;


- (instancetype)initWithHighlightr:(Highlightr *)highlightr;

@end
