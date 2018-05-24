/*
 *******************************************************************************
 *
 * Copyright (C) 2016 Dialog Semiconductor, unpublished work. This computer
 * program includes Confidential, Proprietary Information and is a Trade
 * Secret of Dialog Semiconductor. All use, disclosure, and/or reproduction
 * is prohibited unless authorized in writing. All Rights Reserved.
 *
 * bluetooth.support@diasemi.com
 *
 *******************************************************************************
 */

#import "ParameterStorage.h"

@implementation ParameterStorage

static ParameterStorage* sharedParameterStorage = nil;

+ (ParameterStorage*) getInstance {
    if (sharedParameterStorage == nil) {
        sharedParameterStorage = [[ParameterStorage alloc] init];
    }
    return sharedParameterStorage;
}

- (id) init {
    if (self = [super init]) {
    }
    return self;
}

@end
