//
//  HBUtil.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/22.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#ifndef HBUtil_h
#define HBUtil_h


#define COLOR_WITH_HEX(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16)) / 255.0 green:((float)((hexValue & 0xFF00) >> 8)) / 255.0 blue:((float)(hexValue & 0xFF)) / 255.0 alpha:1.0f]
#define CURR_LANG                        ([[NSLocale preferredLanguages] objectAtIndex:0])
#define HBLocalizedString(translation_key,a) \
({\
NSString * s = NSLocalizedString(translation_key, nil);\
if (![CURR_LANG isEqual:@"en"] && ![CURR_LANG containsString:@"zh"]) {\
NSString * path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];\
NSBundle * languageBundle = [NSBundle bundleWithPath:path];\
s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];\
}\
(s);\
})
#endif /* HBUtil_h */
