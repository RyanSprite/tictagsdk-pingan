//
//  HBMQTTManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/28.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTClient.h"

@interface HBMQTTManager : NSObject<MQTTSessionDelegate>
{
    BOOL _shouldConnct;
}
@property (nonatomic, strong) MQTTSession *session;
@property (nonatomic, copy) NSMutableDictionary *publishHandlers;
@property (nonatomic, assign) int clientMid;
@property (nonatomic, assign) BOOL isDevelop;
+ (instancetype)shareInstance;
- (int)sendMessageData:(NSData*)data;

- (void)sendMessage:(NSString*)message;
@end
