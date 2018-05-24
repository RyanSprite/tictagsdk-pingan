//
//  IBeaconManager.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/20.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#define MY_REGION_IDENTIFIER @""
#define MY_UUID @"585cde93-1b01-42cc-9a13-25009bedc65e"        //设备ibeaconUUID
#define MY_UUID_ADJUST @"FF5CDE93-1B01-FFFF-9A13-FF009BEDC6FF"  //设备校准ibeaconUUID
//#define MY_UUID @"10F86430-1346-11E4-9191-0800200C9A66"      //手机1ibeaconUUID
//#define MY_UUID @"A0961B72-8827-4C50-82E1-57E0E18206EE"      //手机2ibeaconUUID

typedef void(^IBeaconManagerBlock)(CLBeacon* ibeacon ,NSString * electric,NSString *clickTimes,BOOL shouldConnect);
typedef void(^GPSCollectBlock)(NSString* nowtime,CGFloat longitude,CGFloat latitude);
@interface IBeaconManager : NSObject<CLLocationManagerDelegate>
@property (nonatomic,strong)CLLocationManager *locationManager;
@property (nonatomic,strong)CLBeaconRegion *region;
@property (nonatomic,strong)CLBeaconRegion *region_adjust;
@property (nonatomic,strong)NSMutableArray *detectedBeacons;
@property (nonatomic,strong)NSTimer *timer;
@property (nonatomic,strong)NSTimer *killtimer;
@property (nonatomic,strong)CLLocation *lastLocation;
@property (nonatomic,strong)NSMutableData *queenData;
@property (nonatomic,copy)IBeaconManagerBlock block;
@property (nonatomic,copy)GPSCollectBlock timeblock;
@property (nonatomic,assign)CGFloat longitude; //经度
@property (nonatomic,assign)CGFloat latitude; //维度
@property (nonatomic,strong)NSString *collectTime; //采集时间
@property (nonatomic,assign)int collectTimeStamp; //采集时间戳
@property (nonatomic,assign)int firstCollectTimeStamp; //采集第一个时间戳
@property (nonatomic,assign)int logTimeStamp; //LOG时间戳
@property (nonatomic,assign)int ibeaconTimeStamp; //beacon时间戳
@property (nonatomic,assign)int lastClickTimes; //上次按了多少下
@property (nonatomic,assign)BOOL gpsIsStart; //GPS采集时间戳
@property (nonatomic,assign)int lastCollectTimeStamp; //上次GPS采集时间戳
@property (nonatomic,assign)int killTimeStamp; //KillTime
@property (nonatomic,assign)CGFloat speed; //速度
@property (nonatomic,assign)CGFloat speedLimit; //速度限制 m/s
@property (nonatomic,assign)CGFloat  accelerationLimit; //加速度限制 m/s²
@property (nonatomic,assign)CGFloat altitude; //海拔
@property (nonatomic,assign)CGFloat course; //方向
@property (nonatomic,assign)CGFloat localPower; //本地存储的电量
@property (nonatomic,assign)BOOL push; //推送
@property (nonatomic,assign)BOOL isInCar; //是否在车上 default NO
@property (nonatomic,assign)BOOL timerOn; //GPS计时器是否开启 default NO
@property (nonatomic,assign)BOOL isSystemLaunch; //是否系统唤醒
@property (nonatomic,assign)BOOL closeKillSelf; //不需要自杀 default NO
@property (nonatomic,assign)int nearCarTimeout;
@property (nonatomic,assign)int gpsUploadInterval;


//@property (nonatomic,strong)NSArray *detectedBeacons;
+ (instancetype)shareInstance;
- (void) startBeaconRanging;
- (void) stopBeaconRanging;
- (void) setIbeaconBlock:(IBeaconManagerBlock)block;
- (void) setGPSBlock:(GPSCollectBlock)block;
- (void) startGPSCollect;
- (void) setNewRegion;
//- (NSString *)detailsStringForBeacon;
@end
