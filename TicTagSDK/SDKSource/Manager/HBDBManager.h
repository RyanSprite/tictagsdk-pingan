//
//  HBDBManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/10/20.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@interface HBDBManager : NSObject
{
    BOOL wlanEnable;
    dispatch_queue_t _queue;
}
@property (nonatomic,strong) NSMutableArray *needSendArray;
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic) BOOL callWasStarted;
+ (instancetype)shareInstance;

//打开
- (void)openSqlite;

//建表
- (void)createTable;

//insert
- (void)addMQTTBuffer:(NSData *)buffer;

//删除delete
- (void)deleteMQTTBufferMin;

- (NSMutableArray*)selectALLMQTTBuffer;

- (void)checkArrayCache;

- (void)queenSend;

@end
