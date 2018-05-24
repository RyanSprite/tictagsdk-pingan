//
//  PeripheralInfo.h
//  BabyBluetoothAppDemo
//
//  Created by 刘彦玮 on 15/8/6.
//  Copyright (c) 2015年 刘彦玮. All rights reserved.
//
//#define UUID_NOTIFY_REQ_EVENT @"2d86686a-53dc-25b3-0c4a-f0e10c8dee20"
////event happen
//#define UUID_NOTIFY_HAP_EVENT @"15005991-b131-3396-014c-664c9867b917"
////data request
//#define UUID_NOTIFY_REQ_DATA @"87444368-648c-05a3-2d86-686a53dc25b3"
////data block
//#define UUID_NOTIFY_DATA_BLOCK @"90116709-ea21-3143-ccad-6fef7757eda5"
////transmit result
//#define UUID_NOTIFY_RESULT @"8e404254-81d1-e009-8c12-327833aa4358"
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@interface PeripheralInfo : NSObject

@property (nonatomic,strong) CBUUID *serviceUUID;
@property (nonatomic,strong) NSMutableArray *characteristics;
@property (nonatomic,strong) CBCharacteristic *req_event_characteristics;
@property (nonatomic,strong) CBCharacteristic *data_request_characteristics;
@property (nonatomic,strong) CBCharacteristic *transmit_result_characteristics;
@property (nonatomic,strong) CBCharacteristic *hap_event_characteristics;

@end
