//
//  TTDefines.h
//  TicTagSDK
//
//  Created by 陈宇 on 2018/3/29.
//  Copyright © 2018年 陈宇. All rights reserved.
//

#ifndef TTDefines_h
#define TTDefines_h

#define FWUPDATE @"HBFWUPDATE"
#define HWUPDATE @"HBHWUPDATE"
#define BlueToothStateChange @"BlueToothStateChange"

typedef enum : NSUInteger {
    State_Unbind,
    State_Connected,
    State_DataSyncing,
    State_DISCONNECTED,
} TicTagState;

typedef void(^gpsCollectBlock)(NSString* nowtime,CGFloat longitude,CGFloat latitude);
typedef void(^iBeaconBlock)(NSString * electric,NSString *clickTimes);
typedef void(^successBlock)(void);
typedef void (^failBlock)(void);
typedef void(^disBindBlock)(void);
typedef void(^userAlertBlock)(NSString *clickTimes);
typedef void(^changeState)(TicTagState state);


#endif /* TTDefines_h */
