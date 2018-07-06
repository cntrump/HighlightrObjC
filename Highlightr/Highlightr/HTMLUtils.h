//
//  HTMLUtils.h
//  HighlightrObjC
//
//  Created by vvveiii on 2018/7/5.
//  Copyright © 2018年 vvveiii. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTMLUtils : NSObject

@property(class,nonatomic,strong,readonly) NSDictionary<NSString*,NSString*> *characterEntities;

+ (NSString *)decode:(NSString *)entity;

@end
