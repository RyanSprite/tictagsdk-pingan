//
//  FOTAUpDateManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/10/10.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FOTAUpDateManager : NSObject
@property(nonatomic,assign)BOOL imgAready;
@property(nonatomic,assign)BOOL isNewDevice;
@property(nonatomic,assign)BOOL isStart;
@property(nonatomic,assign)BOOL isNextImg;
@property(nonatomic,assign)int lastCode;
@property(nonatomic,assign)int imgIndex;
@property(nonatomic,assign)int needWaitTime;

@property(nonatomic,strong)NSMutableData *fileData;
@property(nonatomic,strong)NSMutableArray *imgArray;

+ (instancetype)shareInstance;
- (void)startFOTA;
@end
