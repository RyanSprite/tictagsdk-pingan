//
//  HBHttpManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/11/29.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
typedef void(^HBMessageHandleCallBack)(id result, id data);

@interface HBHttpManager : NSObject
@property(nonatomic,copy)NSDictionary *header;
@property(nonatomic,copy)NSString *rid;
@property(nonatomic,copy)NSString *did;
@property(nonatomic,copy)NSString *crc;
@property(nonatomic,copy)NSString *serverFwVersion;

+ (instancetype)shareInstance;
//+ (void)vs_sendAPI:(NSString*)apiUrl
//              parm:(NSDictionary*)parm
//      successBlock:(HBMessageHandleCallBack)successed
//       failedBlock:(HBMessageHandleCallBack)failed
//     completeBlock:(HBMessageHandleCallBack)completed;

+ (void)getAliAccessSuccessBlock:(HBMessageHandleCallBack)successed
         failedBlock:(HBMessageHandleCallBack)failed;
+ (void)checkImgVersion;

//+ (NSString *)convertToJsonData:(NSDictionary *)dict;


+ (void)downloadImg:(NSDictionary*)dic;

+ (void)reportResultCode:(int)code;

@end
