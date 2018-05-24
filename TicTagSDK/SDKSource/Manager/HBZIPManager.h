//
//  HBZIPManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/12/28.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HBZIPManager : NSObject

@property (nonatomic,strong)NSMutableArray *imgArray;


+ (instancetype)shareInstance;

- (void)archiveData:(NSData*)data;

- (void)archiveExistData;

@end
