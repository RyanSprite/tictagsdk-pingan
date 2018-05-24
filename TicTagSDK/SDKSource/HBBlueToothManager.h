//
//  HBBlueToothManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/20.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BabyBluetooth.h"
#import "PeripheralInfo.h"
@interface HBBlueToothManager : NSObject
@property (nonatomic,strong)    BabyBluetooth *baby;
@property (nonatomic,assign)    BOOL isConnected;
@property (nonatomic,assign)    BOOL isPowerOn;
@property (nonatomic,assign)    BOOL isBind;
@property (nonatomic,assign)    int btStamp;
@property (nonatomic, strong)   PeripheralInfo *service;
@property (nonatomic, strong)   CBPeripheral *currentPeripheral;
@property (nonatomic, strong)   CBPeripheral *bindPeripheral;


+ (instancetype)shareInstance;
- (NSString *)getCurrentPeripheralDeviceID;
- (void)disconnect;
- (void)connect;
@end
