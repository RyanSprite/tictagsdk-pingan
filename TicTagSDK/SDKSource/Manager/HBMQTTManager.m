//
//  HBMQTTManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/28.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBMQTTManager.h"
#import "HBDemo-Prefix.pch"
#import <MQTTLog.h>
@implementation HBMQTTManager
+ (instancetype)shareInstance {
    static HBMQTTManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBMQTTManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *clientID = [UIDevice currentDevice].identifierForVendor.UUIDString;

        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = HBMQTTHost;
        transport.port = HBMQTTPort.intValue;
        //创建一个任务
        self.session = [[MQTTSession alloc] init];
        //设置任务的传输类型
        self.session.transport = transport;
        //设置任务的代理为当前类
        self.session.delegate = self;
        //设置登录账号
        self.session.clientId = clientID;
        [MQTTLog setLogLevel: DDLogLevelOff];
        self.session.cleanSessionFlag = false;
        BOOL isSucess =   [self.session connectAndWaitTimeout:60];  //this is part of the synchronous API
        
            if (isSucess)
            {
//                HBLog(@"服务器启动成功");
                HBLog(@"Info, MQTT server startup successful");

            }
            else
            {
                HBLog(@"Info, MQTT server startup failed");
//                [SVProgressHUD showInfoWithStatus:@"服务器启动失败"];
            }
//        }
    }
    return self;
}

- (int)sendMessageData:(NSData*)data
{
//    @try {
        if (data.length == 0) {
            return 0;
        }
        NSString *message =[HBTools coverFromDataToHexStr:data];
        NSString *eventType = [message substringWithRange:NSMakeRange(6, 2)];
        int interval = [[NSDate date] timeIntervalSince1970];
        HBLog(@"Info, SDK-SaaS event uploading finished, timestamp == %d ",interval);
        //GPS批量上传或者用户报警
        if (eventType.intValue == 13 || eventType.intValue == 32)
        {
            NSMutableString *muString = [NSMutableString stringWithString:message];
            [muString replaceCharactersInRange:NSMakeRange(16, 8) withString:[HBTools getNowHexTimeSpam]];
            NSData *tripGroupData =[HBTools coverFromHexStrToData:muString];
            
            [[HBUploadManager shareInstance]postLogWithTopic:AliTopicMQTT andKey:@"mqttData" andDictionary:@{@"eventType":eventType,
                                                                                                             @"mesaage":message
                                                                                                             }];
            if (_isDevelop) {
              return  [self.session publishData:tripGroupData onTopic:CLIENT_TOPIC_Test retain:NO qos:2];
                
            }
            else
            {
              return [self.session publishData:tripGroupData onTopic:CLIENT_TOPIC retain:NO qos:2];
            }
        }
        else
        {
            
            [[HBUploadManager shareInstance]postLogWithTopic:AliTopicMQTT andKey:@"mqttData" andDictionary:@{@"eventType":eventType,
                                                                                                             @"mesaage":message
                                                                                                             }];
            if (_isDevelop) {
              return  [self.session publishData:data onTopic:CLIENT_TOPIC_Test retain:NO qos:2];

            }
            else
            {
              return  [self.session publishData:data onTopic:CLIENT_TOPIC retain:NO qos:2];

            }
        }


//    } @catch (NSException *exception) {
//        HBLog(@"%@",exception);
//    } @finally {
//
//    }
//    [self.session subscribeToTopic:CLIENT_TOPIC atLevel:2 subscribeHandler:^(NSError *error, NSArray<NSNumber *> *gQoss){
//        
//        if (error) {
//            
//            HBLog(@"Subscription failed %@", error.localizedDescription);
//            
//        } else {
//            
//            HBLog(@"Subscription sucessfull! Granted Qos: %@", gQoss);
//            
//        }
//    }];
//    self.publishHandlers = [self.client valueForKey:@"publishHandlers"];
//    [self.client publishData:data
//                     toTopic:CLIENT_TOPIC
//                     withQos:ExactlyOnce
//                      retain:YES
//           completionHandler:^(int mid) {
//               HBLog(@"发送成功 mid = %d",mid);
//               int count = mid - _clientMid;
//               while (count) {
//                   [[HBDBManager shareInstance]deleteMQTTBufferMin];
//                   count --;
//               }
//               _clientMid = mid;
//               NSArray *array1 = [[HBDBManager shareInstance]selectALLMQTTBuffer];
//               HBLog(@"缓存数组 : %@",array1);
//           }];
//    NSArray *array1 = [[HBDBManager shareInstance]selectALLMQTTBuffer];
//    HBLog(@"缓存数组 : %@",array1);
}

- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid

{
    
//    HBLog(@"data=%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
    
    //    HBLog(@"%@",[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
    
    
    
}
- (void)sendMessage:(NSString*)message
{
    NSData *messageData = [HBTools coverToByteWithMessage:message];

    [[HBDBManager shareInstance]addMQTTBuffer:messageData];

//    [self sendMessageData:messageData];
}
// 连接成功
//- (void)connected:(MQTTSession *)session {
////    if (_shouldConnct == YES) { // 需要断线重连
////        _shouldConnct = NO;
////    }
//}
//// 连接断开
//- (void)connectionClosed:(MQTTSession *)session {
////    if ( _shouldConnct == YES) { // 如果是断线的情况
////        _shouldConnct = YES; // 则需要重连
//        [session connect];
////    }
//}

- (void)setIsDevelop:(BOOL)isDevelop
{
    _isDevelop = isDevelop;
    if (_isDevelop)
    {
        NSString *clientID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = HBMQTTHost_Test;
        transport.port = HBMQTTPort_Test.intValue;
        //创建一个任务
        self.session = [[MQTTSession alloc] init];
        //设置任务的传输类型
        self.session.transport = transport;
        //设置任务的代理为当前类
        self.session.delegate = self;
        //设置登录账号
        self.session.clientId = clientID;
        self.session.userName = CLIENT_userName;
        self.session.password = CLIENT_password;

        BOOL isSucess =   [self.session connectAndWaitTimeout:1];  //this is part of the synchronous API
        
        if (isSucess)
        {
            HBLog(@"服务器启动成功");
        }
        else
        {
            HBLog(@"服务器启动失败")
//            [SVProgressHUD showInfoWithStatus:@"服务器启动失败"];
        }
    }
    else
    {
        NSString *clientID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
        transport.host = HBMQTTHost;
        transport.port = HBMQTTPort.intValue;
        //创建一个任务
        self.session = [[MQTTSession alloc] init];
        //设置任务的传输类型
        self.session.transport = transport;
        //设置任务的代理为当前类
        self.session.delegate = self;
        //设置登录账号
        self.session.clientId = clientID;
        
        BOOL isSucess =   [self.session connectAndWaitTimeout:60];  //this is part of the synchronous API
        
        if (isSucess)
        {
            //                HBLog(@"服务器启动成功");
            HBLog(@"Info, MQTT server startup successful");
            
        }
        else
        {
            HBLog(@"Info, MQTT server startup failed");
            //                [SVProgressHUD showInfoWithStatus:@"服务器启动失败"];
        }
    }
}
/*连接状态回调*/
-(void)handleEvent:(MQTTSession *)session event:(MQTTSessionEvent)eventCode error:(NSError *)error{
//    NSDictionary *events = @{
//                             @(MQTTSessionEventConnected): @"connected",
//                             @(MQTTSessionEventConnectionRefused): @"connection refused",
//                             @(MQTTSessionEventConnectionClosed): @"connection closed",
//                             @(MQTTSessionEventConnectionError): @"connection error",
//                             @(MQTTSessionEventProtocolError): @"protocoll error",
//                             @(MQTTSessionEventConnectionClosedByBroker): @"connection closed by broker"
//                             };
//    [self.mqttStatus setStatusCode:eventCode];
//    [self.mqttStatus setStatusInfo:[events objectForKey:@(eventCode)]];
//    if (self.delegate&&[self.delegate respondsToSelector:@selector(didMQTTReceiveServerStatus:)]) {
//        [self.delegate didMQTTReceiveServerStatus:self.mqttStatus];
//    }
    if (eventCode == MQTTSessionEventConnected) {
        [[NSNotificationCenter defaultCenter]postNotificationName:MQTTConnected object:nil];
        [[HBUploadManager shareInstance]postLogWithTopic:AliTopicMQTT andKey:@"connected" andContent:[HBTools getNowTimeString]];
    }
    else
    {
        [[HBUploadManager shareInstance]postLogWithTopic:AliTopicMQTT andKey:@"disConnected" andContent:[HBTools getNowTimeString]];

    }
}
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
//                        change:(NSDictionary *)change context:(void *)context
//{
//    HBLog(@"change = %@",change);
//}
@end
