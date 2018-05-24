//
//  TTBlueToothManager.m
//  TicTagSDK
//
//  Created by 陈宇 on 2018/3/20.
//  Copyright © 2018年 陈宇. All rights reserved.
//

#import "TTBlueToothManager.h"
#import "HBDemo-Prefix.pch"
#define FOTATIMEOUT 90
@interface TTBlueToothManager ()
{
    BabyBluetooth *baby;
}
@property (nonatomic, copy) BBDiscoverPeripheralsBlock blockOnDiscoverPeripherals;
@property (assign, nonatomic)__block int fotaTimeCount;
@property (assign, nonatomic)__block int retryTimes;
@property (nonatomic,assign)int lastClickTimes; //上次按了多少下

@end
@implementation TTBlueToothManager

+ (instancetype)shareTTBlueToothManager {
    static TTBlueToothManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[TTBlueToothManager alloc]init];
    });
    return share;
}

- (void)initSDK
{
    [HBBlueToothManager shareInstance];
    [IBeaconManager shareInstance];
    _ticTagState = State_DISCONNECTED;
    if (_changeState) {
        self.changeState(State_DISCONNECTED);
    }
    __weak typeof(self) weakSelf = self;
    [IBeaconManager shareInstance].isSystemLaunch = YES;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(fwUpdate:) name:FWUPDATENotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(hwUpdate:) name:HWUPDATENotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(beacomActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willKill:)
                                                 name:UIApplicationWillTerminateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(disBind) name:DisbindNotification object:nil];

    baby = [BabyBluetooth shareBabyBluetooth];
    [self babyDelegate];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(connectToBT:) name:BabyNotificationAtDidConnectPeripheral object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(disConnectToBT:) name:BabyNotificationAtDidDisconnectPeripheral object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(enterCar) name:EnterCarNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(leftCar) name:LeftCarNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChange)name:BlueToothPowerOffNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChange)name:BlueToothPowerOnNotification object:nil];
    GLobalRealReachability.pingTimeout = 3;
    GLobalRealReachability.hostForPing = @"www.baidu.com";
    [GLobalRealReachability startNotifier];
    [HBMQTTManager shareInstance];
   
    [[HBDBManager shareInstance]checkArrayCache];
    
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    
    if (BindperipheralName) {
        [[HBUploadManager shareInstance] postLogWithTopic:AliTopicOsapp andKey:@"LaunchingTime" andOperation:@"LaunchingTime"];
    }
    
    NSString *killtime = [[NSUserDefaults standardUserDefaults]objectForKey:@"killtime"];
    if (killtime) {
        [[HBUploadManager shareInstance] postLogWithTopic:AliTopicOsapp andKey:@"LastKillTime" andContent:killtime];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 *60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![FOTAUpDateManager shareInstance].isStart) {
            [HBHttpManager checkImgVersion];
        }
    });
    if ([FOTAUpDateManager shareInstance].isStart) {
        self.fotaTimeCount ++;
        if (self.fotaTimeCount > FOTATIMEOUT)
        {
            self.retryTimes++;
            [FOTAUpDateManager shareInstance].isStart = NO;
            [FOTAUpDateManager shareInstance].imgAready = NO;
            if (self.retryTimes >= 3) {
                [HBHttpManager reportResultCode:100999];
                self.retryTimes = 0;
            }
            else
            {
                [HBHttpManager checkImgVersion];
            }
            self.fotaTimeCount = 0;
        }
        return ;
    }
    else
    {
        _fotaTimeCount = 0;
    }

    __weak typeof(BabyBluetooth*) weakBaby = baby;
    [[IBeaconManager shareInstance]setIbeaconBlock:^(CLBeacon *ibeacon, NSString *electric, NSString *clickTimes, BOOL shouldConnect) {
        _electric = electric;
        _clickTimes = clickTimes;
        if (_iBeaconblock) {
            weakSelf.iBeaconblock(electric,clickTimes);
        }
        int key = [clickTimes intValue];
        if (key > 0 & key != _lastClickTimes) {
            if (_userAlertBlock) {
                weakSelf.userAlertBlock(clickTimes);
            }

        }
        if (shouldConnect) {
            if ([[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"]) {
                NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"];
                if (uuid) {
                    if (![HBBlueToothManager shareInstance].isConnected) {
                        [HBBlueToothManager shareInstance].currentPeripheral = [weakBaby retrievePeripheralWithUUIDString:uuid];
                        if ([[HBBlueToothManager shareInstance].currentPeripheral.name hasPrefix:@"TT_"]) {
                            weakBaby.having([HBBlueToothManager shareInstance].currentPeripheral).connectToPeripherals().discoverServices().discoverCharacteristics().begin();
                        }
                    }
                }
            }
            else
            {
                
            }
        }
        _lastClickTimes = key;

    }];
    
    [[HBEventManager shareInstance]setemergencyCountBlock:^(int emergencyCount) {
        NSString *times = [NSString stringWithFormat:@"%d",emergencyCount];
        if (_userAlertBlock) {
            weakSelf.userAlertBlock(times);
        }
    }];
    [[IBeaconManager shareInstance]setGPSBlock:^(NSString *nowtime, CGFloat longitude, CGFloat latitude) {
        if (_gpsCollectBlock) {
            weakSelf.gpsCollectBlock(nowtime, longitude, latitude);
        }
    }];
}

- (void)enterCar
{
    _ticTagState = State_Connected;
    
    if (_changeState) {
        self.changeState(State_Connected);
    }
}

- (void)leftCar
{
    _ticTagState = State_DISCONNECTED;
    if (_changeState) {
        self.changeState(State_DISCONNECTED);
    }
}

- (void)getiBeaconInfo:(void (^)(NSString* electric,NSString* clickTimes))iBeaconblock
{
    _iBeaconblock = iBeaconblock;
}

- (void)startSearchTicTagWithBlock:(void (^)(CBCentralManager *central,CBPeripheral *peripheral,NSDictionary *advertisementData, NSNumber *RSSI))block
{
    HBLog(@"Start searching TicTag……");
    _blockOnDiscoverPeripherals = block;
    baby.scanForPeripherals().begin();
}

- (void)bindTicTagWithPeripheral:(CBPeripheral*)peripheral
                withSuccessBlock:(successBlock)successBlock
                      andFailure:(failBlock)failBlock
{
    HBLog(@"Start connect %@",peripheral.name);

    _bindSuccessBlock = successBlock;
    _bindFailBlock = failBlock;
    [baby cancelScan];
    [self disBindTicTag];
    [HBBlueToothManager shareInstance].isBind = NO;
    baby.having(peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().begin();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_bindFailBlock && [HBBlueToothManager shareInstance].isBind == NO)
        {
            [baby cancelAllPeripheralsConnection];
            self.bindFailBlock();
            NSDate *date = [NSDate date];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            
            NSString *dateTime = [formatter stringFromDate:date];
            
            [[NSUserDefaults standardUserDefaults] setObject:dateTime forKey:@"BindTime"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (peripheral.name) {
                NSString *name = [NSString stringWithFormat:@"%@",peripheral.name];
                [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"BindperipheralName"];
                [[IBeaconManager shareInstance]setNewRegion];
            }
        }
        else
        {
//            if (_bindSuccessBlock) {
//                _bindSuccessBloc();
//            }
        }
    });

}

//蓝牙网关初始化和委托方法设置
-(void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(BabyBluetooth*) weakBaby = baby;

    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"Find %@",peripheral.name);
        if (weakSelf.blockOnDiscoverPeripherals) {
            weakSelf.blockOnDiscoverPeripherals(central,peripheral,advertisementData,RSSI);
        }
    }];
    
    //设置发现设备的Services的委托
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        for (CBService *service in peripheral.services) {
            [HBBlueToothManager shareInstance].service = [[PeripheralInfo alloc]init];
            [[HBBlueToothManager shareInstance].service setServiceUUID:service.UUID];
        }
    }];
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        for (int row= (int)(service.characteristics.count - 1);row<service.characteristics.count;row--) {
            CBCharacteristic *characteristic = service.characteristics[row];
            NSLog(@"characteristic = %@",characteristic);
            [[HBBlueToothManager shareInstance].service.characteristics addObject:characteristic];
            if ([[characteristic.UUID UUIDString]isEqualToString:[UUID_NOTIFY_REQ_EVENT uppercaseString]]) {
                [HBBlueToothManager shareInstance].service.req_event_characteristics = characteristic;
                [weakSelf writeConfigValue];
            }
            if ([[characteristic.UUID UUIDString]isEqualToString:[UUID_NOTIFY_RESULT uppercaseString]]) {
                [HBBlueToothManager shareInstance].service.transmit_result_characteristics = characteristic;
            }
            if ([[characteristic.UUID UUIDString]isEqualToString:[UUID_NOTIFY_HAP_EVENT uppercaseString]]) {
                [HBBlueToothManager shareInstance].service.hap_event_characteristics = characteristic;

                [weakBaby notify:[HBBlueToothManager shareInstance].currentPeripheral
                  characteristic:[HBBlueToothManager shareInstance].service.hap_event_characteristics
                           block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                               NSString *value = [HBTools coverFromHexDataToStr:characteristics.value];
                               //                               NSLog(@"value = %@",value);
                               [HBEventManager shareInstance].currentEvent = value;
                               if ([HBEventManager shareInstance].lastEvent) {
                                   [weakSelf writeOverValue];
                                   [weakSelf writeStartValue];
                                   [HBEventManager shareInstance].totalEvent = [NSMutableString stringWithString:@""];
                                   
                               }
                               if ([value isEqualToString:@"17"]) {
                                   [weakSelf writeStartValue];
                               }
                           }];
            }
        }
    }];
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        //最常用的场景是查找某一个前缀开头的设备
        if ([peripheralName hasPrefix:@"TT_"] ) {
            return YES;
        }
        return NO;
    }];
    
    
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        HBLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
    }];
    
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        HBLog(@"setBlockOnCancelScanBlock");
    }];
    

    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];

}

- (void)connectToBT:(NSNotification*)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [HBBlueToothManager shareInstance].isConnected = YES;
        //更新UI
        _ticTagState = State_DataSyncing;

        if (_changeState) {
            self.changeState(State_DataSyncing);
        }
        CBPeripheral *peripheral = [sender.object objectForKey:@"peripheral"];
        [[IBeaconManager shareInstance]startGPSCollect];

        [HBBlueToothManager shareInstance].currentPeripheral = peripheral;
        NSDate *date = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSString *dateTime = [formatter stringFromDate:date];
        
        HBLog(@"Info, Bluetooth connected, device ID = %@",peripheral.name);
        [[NSUserDefaults standardUserDefaults] setObject:[peripheral.identifier UUIDString] forKey:@"Bindperipheral"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSString *name = [NSString stringWithFormat:@"%@",peripheral.name];
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"BindperipheralName"];
        [[HBUploadManager shareInstance]postLogWithTopic:AliTopicBLEStatus andKey:AliLogKEYConnected andContent:dateTime];
        [HBBlueToothManager shareInstance].isConnected = YES;

        [HBEventManager shareInstance].emergencyCount = 0;
        [[IBeaconManager shareInstance]setNewRegion];
       
    });
    
    
    
    //读取服务
    //    baby.characteristicDetails(self.peripheral,[HBBlueToothManager shareInstance].service.req_event_characteristics);
    //    [self writeValue];
    
}

- (void)disConnectToBT:(NSNotification*)sender
{
    _ticTagState = State_Connected;
    
    if (_changeState) {
        self.changeState(State_Connected);
    }

    CBPeripheral *peripheral = [sender.object objectForKey:@"peripheral"];
    [HBBlueToothManager shareInstance].isConnected = NO;
    [HBBlueToothManager shareInstance].currentPeripheral = [sender.object objectForKey:@"peripheral"];
    HBLog(@"Info, Bluetooth disconnected, device ID = %@",peripheral.name);

}
//请求hw fw版本号
-(void)writeConfigValue{
    NSData *data = [HBTools coverToByteWithDataWithType:5];
    if ([HBBlueToothManager shareInstance].service.req_event_characteristics) {
        
        [[HBBlueToothManager shareInstance].currentPeripheral writeValue:data forCharacteristic:[HBBlueToothManager shareInstance].service.req_event_characteristics type:CBCharacteristicWriteWithResponse];
    }
}

//请求事件
-(void)writeStartValue{
    NSData *data = [HBTools coverToByteWithDataWithType:1];
    if ([HBBlueToothManager shareInstance].service.req_event_characteristics) {
        [[HBBlueToothManager shareInstance].currentPeripheral writeValue:data forCharacteristic:[HBBlueToothManager shareInstance].service.req_event_characteristics type:CBCharacteristicWriteWithResponse];
    }
    
}

//请求完成
- (void)writeOverValue
{
    NSData *data = [HBTools coverToByteWithDataEventSuccess];
    if ([HBBlueToothManager shareInstance].service.transmit_result_characteristics&&data) {
        [[HBBlueToothManager shareInstance].currentPeripheral writeValue:data forCharacteristic:[HBBlueToothManager shareInstance].service.transmit_result_characteristics type:CBCharacteristicWriteWithResponse];
    }
}

- (BOOL)disBindTicTag
{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"Bindperipheral"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"BindperipheralName"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"fwVersion"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"hwVersion"];
    [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"needUUID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [baby cancelAllPeripheralsConnection];
    [HBBlueToothManager shareInstance].isBind = NO;
    HBLog(@"Info, Unbind Success");
    return YES;
}

- (void)beacomActive:(id)sender
{
    [IBeaconManager shareInstance].isSystemLaunch = NO;
}

- (void)enterBackground:(id)sender
{
    NSLog(@"进入后台");
    UIApplication *app = [UIApplication sharedApplication];
    __block  UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (bgTask != UIBackgroundTaskInvalid){
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid){
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
    [[IBeaconManager shareInstance].locationManager startUpdatingLocation];
}

- (void)willKill:(id)sender
{
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSSS"];
    
    NSString *dateTime = [formatter stringFromDate:date];
    
    [[NSUserDefaults standardUserDefaults]setObject:dateTime forKey:@"killtime"];
    if([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        [[IBeaconManager shareInstance].locationManager stopUpdatingLocation];
        [[IBeaconManager shareInstance].locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)setPowerSaving:(BOOL)powerSaving
{
    _powerSaving = powerSaving;
    if (_powerSaving)
    {
        [IBeaconManager shareInstance].closeKillSelf = NO;
    }
    else
    {
        [IBeaconManager shareInstance].closeKillSelf = YES;
    }
}

- (NSString*)hardwareVersion
{

  
    NSString *hwVersion = [[NSUserDefaults standardUserDefaults]objectForKey:@"hwVersion"];
    if (hwVersion) {
        return hwVersion;
    }
    else
    {
        HBLog(@"Info, hardwareVersion is nil");
        return nil;
    }
}

- (NSString*)firmwareVersion
{
    
    NSString *fwVersion = [[NSUserDefaults standardUserDefaults]objectForKey:@"fwVersion"];
    if (fwVersion) {
        return fwVersion;
    }
    else
    {
        HBLog(@"Info, firmwareVersion is nil");
        return nil;
    }
}

- (CBPeripheral*)currentPeripheral
{
    CBPeripheral *peripheral = [HBBlueToothManager shareInstance].currentPeripheral;
    if (peripheral) {
        return peripheral;
    }
    else
    {
        HBLog(@"Info, currentPeripheral is nil");
        return nil;
    }
}
- (void)disBind
{
    [self disBindTicTag];
    if (_disBindBlock) {
        self.disBindBlock();
    }
    _ticTagState = State_Unbind;
    
    if (_changeState) {
        self.changeState(State_Unbind);
    }
    
}

- (void)ticTagDisBind:(disBindBlock)disbindBlock
{
    _disBindBlock = disbindBlock;
}

- (void)receiveUserAlert:(userAlertBlock)userAlertBlock
{
    _userAlertBlock = userAlertBlock;
}

- (void)fwUpdate:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter]postNotificationName:FWUPDATE object:notification.object];

}

- (void)hwUpdate:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter]postNotificationName:HWUPDATE object:notification.object];
    
    if ([HBBlueToothManager shareInstance].isBind == NO) {
        NSDate *date = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSString *dateTime = [formatter stringFromDate:date];
        
        [HBBlueToothManager shareInstance].isBind = YES;
        
        [[NSUserDefaults standardUserDefaults] setObject:dateTime forKey:@"BindTime"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
            if (_bindSuccessBlock) {
                self.bindSuccessBlock();
            }

    }
    else
    {
        
    }
    [HBBlueToothManager shareInstance].isBind = YES;
}

- (void)receiveGPSBlock:(gpsCollectBlock)gpsBlock
{
    _gpsCollectBlock = gpsBlock;
}

- (NSString *)name
{
    NSString *name = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    if (name) {
        return name;
    }
    else
    {
        HBLog(@"Info, currentPeripheral name is nil");
        return nil;
    }
}

- (NSString *)uuid
{
    NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"];
    if (uuid) {
        return uuid;
    }
    else
    {
        HBLog(@"Info, currentPeripheral uuid is nil");
        return nil;
    }
}

- (void)stopSearchTicTag
{
    [baby cancelScan];
}

- (void)setGpsUploadInterval:(int)gpsUploadInterval
{
    if (gpsUploadInterval != 0) {
        _gpsUploadInterval = gpsUploadInterval;
        [IBeaconManager shareInstance].gpsUploadInterval = gpsUploadInterval;
    }
    else
    {
        HBLog(@"Info, gpsUploadInterval can't be 0");

    }
}

- (void)setNearCarTimeout:(int)nearCarTimeout
{
    if (_nearCarTimeout != 0) {
        _nearCarTimeout = nearCarTimeout;
        [IBeaconManager shareInstance].nearCarTimeout = nearCarTimeout;

    }
    else
    {
        HBLog(@"Info, nearCarTimeout can't be 0");

    }

}

- (void)stateChanged:(changeState)changeBlock
{
    _changeState = changeBlock;
}

- (NSString*)bindTime
{
    NSString *bindtime = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindTime"];
    if (bindtime) {
        return bindtime;
    }
    else
    {
        HBLog(@"Info, TicTag didn't bind");
        return nil;
    }
}

- (BOOL)isBind
{
    if ([self uuid]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)isPowerOn
{
    return [HBBlueToothManager shareInstance].isPowerOn;
}

- (void)stateChange
{
    [[NSNotificationCenter defaultCenter]postNotificationName:BlueToothStateChange object:nil];
}
@end
