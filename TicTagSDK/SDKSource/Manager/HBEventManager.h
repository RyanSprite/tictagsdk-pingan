//
//  HBEventManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/26.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HBEventManagerBlock)(int emergencyCount);
@interface HBEventManager : NSObject

//当前接收的Value
@property(nonatomic,strong)NSString *currentEvent;

//上一个接收的Value
@property(nonatomic,strong)NSString *lastEvent;

//14开头的总和
@property(nonatomic,strong)NSString *totalSize;

//14开头的地址
@property(nonatomic,strong)NSString *address;

//所有累计的Value
@property(nonatomic,strong)NSMutableString *totalEvent;

//一次连接的所有事件
//@property(nonatomic,strong)NSMutableString *connectionEvent;


//紧急事件次数
@property(nonatomic,assign)int emergencyCount;

//是否启动
@property(nonatomic,assign)BOOL isEngineon;


@property (nonatomic,copy)HBEventManagerBlock block;

- (void)setemergencyCountBlock:(HBEventManagerBlock)block;

+ (instancetype)shareInstance ;

@end
