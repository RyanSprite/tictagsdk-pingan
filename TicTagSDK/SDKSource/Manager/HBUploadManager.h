//
//  HBUploadManager.h
//  BabyBluetoothAppDemo
//
//  Created by 陈宇 on 2017/10/18.
//  Copyright © 2017年 刘彦玮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AliyunLogObjc.h"
#import "HBDemo-Prefix.pch"

@interface HBUploadManager : NSObject
@property(nonatomic , strong)LogClient *client;
@property(nonatomic ,copy)NSString *lastExpiration;
@property(nonatomic ,assign)Log_status logStatus;
@property(nonatomic ,strong)NSTimer *timer;
//@property(nonatomic , strong)LogGroup *logGroup;
@property(nonatomic , strong)NSMutableArray *logGroupArray;
@property(nonatomic ,assign)BOOL isConnecting;

+ (instancetype)shareInstance ;

- (void)postLogWithTopic:(NSString*)topic andKey:(NSString*)key andDictionary:(NSDictionary*)dictionary;

- (void)postLogWithTopic:(NSString*)topic andKey:(NSString*)key andContent:(NSString*)content;

- (void)postLogWithTopic:(NSString*)topic andKey:(NSString*)key andOperation:(NSString*)operation;

- (void)reporTAtIntervals;
@end
