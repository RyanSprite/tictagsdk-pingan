//
//  TTBlueToothManager.h
//  TicTagSDK
//
//  Created by 陈宇 on 2018/3/20.
//  Copyright © 2018年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "TTDefines.h"

@interface TTBlueToothManager : NSObject

@property (nonatomic,copy) successBlock bindSuccessBlock;
@property (nonatomic,copy) failBlock bindFailBlock;
@property (nonatomic,copy) iBeaconBlock iBeaconblock;
@property (nonatomic,copy) disBindBlock disBindBlock;
@property (nonatomic,copy) userAlertBlock userAlertBlock;
@property (nonatomic,copy) gpsCollectBlock gpsCollectBlock;
@property (nonatomic,copy) changeState changeState;



/**
 Current device isBind
 */
@property (nonatomic,readonly) BOOL isBind;

/**
 iphone bluetooth is power on
 */
@property (nonatomic,readonly) BOOL isPowerOn;

/**
 Current device name
 */
@property (nonatomic,readonly) NSString *name;

/**
 Current device UUID
 */
@property (nonatomic,readonly) NSString *uuid;

/**
 Current device Bind time
 */
@property (nonatomic,readonly) NSString *bindTime;

/**
 Current device power Range:0~100%
 */
@property (nonatomic,readonly) NSString *electric;

/**
 Current clickTimes Range:0~15
 */
@property (nonatomic,readonly) NSString *clickTimes;


/**
 Current  TicTag hardwareVersion IP type
 */
@property (nonatomic,readonly) NSString *hardwareVersion;


/**
 Current  TicTag firmwareVersion IP type
 */
@property (nonatomic,readonly) NSString *firmwareVersion;

/**
 Current  TicTag info
 */
@property (nonatomic,readonly) CBPeripheral *currentPeripheral;

/**
 Current  TicTag state
 */
@property (nonatomic,readonly) TicTagState ticTagState;

/**
 nearCarTimeout info
 */
@property (nonatomic,assign) int nearCarTimeout;

/**
 nearCarTimeout info
 */
@property (nonatomic,assign) int gpsUploadInterval;

/**
 powerSavingMode Can save you a lot of electricity ,default is 1,if you want to close it,please set 0
 */
@property (nonatomic,assign) BOOL powerSaving;


+ (instancetype)shareTTBlueToothManager;

- (void)initSDK;

/**
 找到TicTag的block |  when find TicTag
 */
- (void)startSearchTicTagWithBlock:(void (^)(CBCentralManager *central,CBPeripheral *peripheral,NSDictionary *advertisementData, NSNumber *RSSI))block;



/**
 停止搜索TicTag |  when find TicTag
 */
- (void)stopSearchTicTag;

/**
 绑定指定TicTag的block |  when bind TicTag
 */
- (void)bindTicTagWithPeripheral:(CBPeripheral*)peripheral
                       withSuccessBlock:(successBlock)successBlock
                      andFailure:(failBlock)failBlock;

/**
 获取TicTag的电量和按键次数 block |  when bind TicTag
 */
- (void)getiBeaconInfo:(void (^)(NSString* electric,NSString* clickTimes))iBeaconblock;

/**
 TicTag APP主动解绑 |  when disbind TicTag
 */
- (BOOL)disBindTicTag;

/**
 TicTag 设备主动解绑回调 block |  when disbind TicTag
 */
- (void)ticTagDisBind:(disBindBlock)disbindBlock;

/**
  TicTag 用户报警block |  when bind TicTag
 */
- (void)receiveUserAlert:(userAlertBlock)userAlertBlock;

/**
 TicTag GPS 回调 block |  when bind TicTag
 */
- (void)receiveGPSBlock:(gpsCollectBlock)gpsBlock;

/**
 TicTag StateChange 回调 block |  when bind TicTag
 */
- (void)stateChanged:(changeState)changeBlock;


@end
