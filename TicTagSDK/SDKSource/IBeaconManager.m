//
//  IBeaconManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/20.
//  Copyright © 2017年 陈宇. All rights reserved.
//
//#define TimeOut 35
#define BleToothOutputTimeOut 180 - TimeOut
#define TimeCollectInterveal 5
//#define TimeUploadInterveal 300
#define KillTimeOut 300
#define SpeedLimit 10 //km/h
#define HeaderLength 12
#import "IBeaconManager.h"
#import <AVFoundation/AVFoundation.h>
#import "HBDemo-Prefix.pch"

@implementation IBeaconManager
+ (instancetype)shareInstance {
    static IBeaconManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[IBeaconManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (_gpsUploadInterval == 0) {
            _gpsUploadInterval = 300;
        }
        if (_nearCarTimeout == 0) {
            _nearCarTimeout = 35;
        }
            [self initLocationManager];
            [self initBeaconRegion];
            [self initDetectedBeaconsList];
            [self startBeaconRanging];
            self.killTimeStamp = [[NSDate new]timeIntervalSince1970];
            _killtimer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(killOption) userInfo:nil repeats:YES];
            [self.timer setFireDate:[NSDate distantPast]];
    }
    return self;
}

- (void)killOption
{
    if (_closeKillSelf == YES) {
        return ;
    }
        int now = [[NSDate new]timeIntervalSince1970];
        if (_killTimeStamp!= 0 && now - _killTimeStamp >= KillTimeOut ) {
            
            if (self.timerOn) {
                [self.timer setFireDate:[NSDate distantFuture]];
                _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
                self.timerOn = NO;
            }
            [self uploadQueen];
            
            if ([HBDBManager shareInstance].needSendArray.count > 0) {
                [[HBDBManager shareInstance] queenSend];
                HBLog(@"ReSend ALL");
                return ;
            }
            NSDate *date = [NSDate date];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            
            NSString *dateTime = [formatter stringFromDate:date];
            
            //                AppDelegate *delegate =(AppDelegate*)[UIApplication sharedApplication].delegate;
            if (self.isSystemLaunch) {
                [[HBUploadManager shareInstance] postLogWithTopic:AliTopiciBeacon andKey:@"KillSelf" andContent:dateTime];
                [[HBUploadManager shareInstance] reporTAtIntervals];
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
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
            }
            else
            {
                [[HBUploadManager shareInstance] postLogWithTopic:AliTopiciBeacon andKey:@"PausesLocationUpdatesEnable" andContent:dateTime];
                _locationManager.pausesLocationUpdatesAutomatically = YES;
                _killTimeStamp = 0;
            }
            
        }
        else
        {
//            HBLog(@"now = %d",now);
//            HBLog(@"killTimeStamp = %d",_killTimeStamp);
        }
}

#pragma mark Init Beacons
- (void) initLocationManager{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        //??这样的顺序，将导致bug：第一次启动程序后，系统将只请求?的权限，?的权限系统不会请求，只会在下一次启动应用时请求?
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
            //[_locationManager requestWhenInUseAuthorization];//?只在前台开启定位
            [_locationManager requestAlwaysAuthorization];//?在后台也可定位
        }
        // 5.iOS9新特性：将允许出现这种场景：同一app中多个location manager：一些只能在前台定位，另一些可在后台定位（并可随时禁止其后台定位）。
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
            _locationManager.allowsBackgroundLocationUpdates = YES;
        }
        // 6. 更新用户位置
        [_locationManager startUpdatingLocation];
        [_locationManager startUpdatingHeading];
        _locationManager.distanceFilter = 80;
        [self checkLocationAccessForRanging];
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:TimeInterveal target:self selector:@selector(collectGPS) userInfo:nil repeats:YES];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:_gpsUploadInterval target:self selector:@selector(uploadQueen) userInfo:nil repeats:YES];
        self.speedLimit = 50;
        self.accelerationLimit = 19.8;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [_locationManager startUpdatingLocation];
}

//- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
//
//{
//
//    if (status == kCLAuthorizationStatusAuthorizedAlways) {
//
//        [self.locationManager startMonitoringForRegion:self.region];
//
//    }
//
//}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
//    if (![self validateLocation:locations.lastObject]) {
//        return ;
//    }
    // 1.获取用户位置的对象
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D coordinate = location.coordinate;
    if (_lastLocation == nil && _isInCar)
    {
        NSDate *date = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        
        
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSString *dateTime = [formatter stringFromDate:date];
        
        if (_timeblock && _longitude > 0 ) {
                self.timeblock(dateTime,_longitude,_latitude);
        }
    }
    self.latitude =  coordinate.latitude;
    self.longitude =  coordinate.longitude;
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive)
    {
        //前台运行
    }
        else
        {
            //后台运行
//            HBLog(@"App is backgrounded. New location is %@", locations);
        }
    // 2.停止定位
//    [manager stopUpdatingLocation];
    if (location.altitude >= 0) {
        self.altitude = location.altitude;
    }
    else
    {
        self.altitude = 0;

    }
    if (location.speed >= 0) {
        self.speed = location.speed;
    }
    else
    {
        self.speed = 0;
        return ;
    }
    if (location.course >= 0) {
        self.course = location.course;
    }
    else
    {
        self.course = 0;
    }

    if (_lastLocation.coordinate.latitude == self.latitude && _lastLocation.coordinate.longitude == self.longitude) {
        return ;
    }
    
    int nowTime = [[NSDate date] timeIntervalSince1970];
    
    HBLog(@"Info, Retrieved location, Lat = %f, Long = %f", _latitude, _longitude);
    _collectTimeStamp =  nowTime;
        if (_gpsIsStart) {
            [self addToQueen];
            _lastCollectTimeStamp = nowTime;
            _lastLocation = location;
            NSDate *date = [NSDate date];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            NSString *dateTime = [formatter stringFromDate:date];
            //    NSString *gpsContent = [NSString stringWithFormat:@"%@ lat = %f lon = %f speed = %f",dateTime,coordinate.latitude,coordinate.longitude,location.speed];
            NSDictionary *dic =     @{  @"time":dateTime,
                                        @"latitude":[NSString stringWithFormat:@"%f",coordinate.latitude],
                                        @"longitude":[NSString stringWithFormat:@"%f",coordinate.longitude],
                                        @"speed":[NSString stringWithFormat:@"%f",location.speed],
                                        @"horizontalAccuracy":[NSString stringWithFormat:@"%f",location.horizontalAccuracy],
                                        @"verticalAccuracy":[NSString stringWithFormat:@"%f",location.verticalAccuracy]
                                        };
            [[HBUploadManager shareInstance] postLogWithTopic:AliTopicLocation andKey:AliLogKEYGps andDictionary:dic];

            HBLog(@"Info, Retrieved location, Lat = %f, Long = %f", _latitude, _longitude);

            if (_timeblock && _longitude > 0 && _gpsIsStart) {
                self.timeblock(dateTime,_longitude,_latitude);
            }
       
    }
    else
    {
        if (location.speed > SpeedLimit/3.6 && nowTime - _lastCollectTimeStamp < KillTimeOut)
        {
            _killTimeStamp = nowTime;

            if (self.timerOn == NO) {
                [self.timer setFireDate:[NSDate distantPast]];
                _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
                self.timerOn = YES;
            }
        }
        if (self.timerOn) {

            [self addToQueen];
            _lastCollectTimeStamp = nowTime;
            _lastLocation = location;
            NSDate *date = [NSDate date];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            
            [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
            NSString *dateTime = [formatter stringFromDate:date];
            //    NSString *gpsContent = [NSString stringWithFormat:@"%@ lat = %f lon = %f speed = %f",dateTime,coordinate.latitude,coordinate.longitude,location.speed];
            NSDictionary *dic =     @{  @"time":dateTime,
                                        @"latitude":[NSString stringWithFormat:@"%f",coordinate.latitude],
                                        @"longitude":[NSString stringWithFormat:@"%f",coordinate.longitude],
                                        @"speed":[NSString stringWithFormat:@"%f",location.speed],
                                        @"horizontalAccuracy":[NSString stringWithFormat:@"%f",location.horizontalAccuracy],
                                        @"verticalAccuracy":[NSString stringWithFormat:@"%f",location.verticalAccuracy]
                                        };
            [[HBUploadManager shareInstance] postLogWithTopic:AliTopicLocation andKey:AliLogKEYGps andDictionary:dic];
            
            HBLog(@"Info, Retrieved location, Lat = %f, Long = %f", _latitude, _longitude);

            if (_timeblock && _longitude > 0 && _gpsIsStart) {
                self.timeblock(dateTime,_longitude,_latitude);
            }
        }
    }
}

- (void)addToQueen
{
    if (!_queenData) {
        NSMutableData *data = [[NSUserDefaults standardUserDefaults]objectForKey:@"queenData"];
        if (data) {
            _queenData = [[NSMutableData alloc]initWithData:data];;
        }
        else
        {
            _queenData = [[NSMutableData alloc]init];
        }
    }
    NSData *now = [self getNowGPS];
    [_queenData appendData:now];
    [[NSUserDefaults standardUserDefaults]setObject:_queenData forKey:@"queenData"];
}

- (NSData*)getNowGPS
{
    Byte tripInfo[16] = {0};
    if (_firstCollectTimeStamp == 0)
    {
        _firstCollectTimeStamp = _collectTimeStamp;
    }
    if (_lastCollectTimeStamp == _collectTimeStamp && _queenData.length >= 16) {
        [_queenData replaceBytesInRange:NSMakeRange(_queenData.length -16, 16) withBytes:NULL length:0];
    }
    int time = _collectTimeStamp - _firstCollectTimeStamp;
    
    for (int i = 0; i < 2; i ++) {
        tripInfo[i] = (time & 0xFF);
        time >>= 8;
    }
    
    if (_longitude) {
        int longitude = _longitude * 100000;
        for (int i = 2; i < 6; i ++) {
            tripInfo[i] = (longitude & 0xFF);
            longitude >>= 8;
        }
    }
    
    if (_latitude) {
        int latitude = _latitude * 100000;
        for (int i = 6; i < 10; i ++) {
            tripInfo[i] = (latitude & 0xFF);
            latitude >>= 8;
        }
    }
    
    if (_speed) {
        int speed = _speed * 3.6;
        //        for (int i = 12; i < 14; i ++) {
        //            tripInfo[i] = (speed & 0xFF);
        //            speed >>= 8;
        //        }
        tripInfo[10] = (speed & 0xFF);
    }
    if (_course) {
        int course = _course * 10;
        for (int i = 11; i < 13; i ++) {
            tripInfo[i] = (course & 0xFF);
            course >>= 8;
        }
    }
    if (_altitude) {
        int altitude = _altitude;
        for (int i = 13; i < 15; i ++) {
            tripInfo[i] = (altitude & 0xFF);
            altitude >>= 8;
        }
    }
    if (_latitude && _longitude) {
        tripInfo[15] = 'Y';
    }
    else
    {
        tripInfo[15] = 'N';
    }
    NSData* bodyData = [NSData dataWithBytes:&tripInfo length:16];
    return bodyData;

}

- (void)uploadQueen
{
    @try {
        //执行的代码，如果异常,就会抛出，程序不继续执行啦
        if (!_queenData) {
            NSMutableData *data = [[NSUserDefaults standardUserDefaults]objectForKey:@"queenData"];
            if (data) {
                _queenData = [[NSMutableData alloc]initWithData:data];;
            }
            else
            {
                _queenData = [[NSMutableData alloc]init];
            }
        }
        int count = (int)_queenData.length/16;
        if (count == 0) {
            return ;
        }
        Byte dev[22] = {0};
        NSString *DeviceId = [[HBBlueToothManager shareInstance] getCurrentPeripheralDeviceID];
        if (!DeviceId) {
            return ;
        }
        char css[DeviceId.length];
        
        memcpy(css, [DeviceId cStringUsingEncoding:NSASCIIStringEncoding], 2*[DeviceId length]);
        
        for (int i = 0; i < 8; i ++) {
            dev[i] = css[i];
        }
        int tempCount = count;
        //    for (int i = 16; i < 18; i++) {
        //        dev[i] = (tempCount & 0xFF);
        //        tempCount >>= 8;
        //    }
        dev[16] = tempCount & 0xFF;
        dev[17] = 0x01 & 0xFF;
        int time = _firstCollectTimeStamp;
        if (time == 0) {
            return;
        }
        for (int i = 18; i < 22; i ++) {
            dev[i] =  (time & 0xFF);
            time >>= 8;
        }
        
        _firstCollectTimeStamp = 0;
        
        NSData* bodyData = [NSData dataWithBytes:&dev length:22];
        
        NSData *dataHeader = [self getHeadWithType:0x13 andLength:(int)(bodyData.length + _queenData.length + HeaderLength)];
        
        NSMutableData *wholeData = [NSMutableData dataWithData:dataHeader];
        
        [wholeData appendData:bodyData];
        [wholeData appendData:_queenData];
        
        [[HBDBManager shareInstance]addMQTTBuffer:wholeData];
        
        _queenData = [NSMutableData new];
        [[NSUserDefaults standardUserDefaults]setObject:_queenData forKey:@"queenData"];
    } @catch (NSException *exception) {
        //捕获异常
    } @finally {
        //这里一定执行，无论你异常与否
    }
    
}

- (NSData *)getHeadWithType:(int)type andLength:(int)length
{
    Byte head[12] = {0};
    head[0] = length&0xff;
    head[1] = (length>>8)&0xff;
    head[2] = 11&0xff;
    head[3] = type&0xff;
    head[4] = 3&0xff;
    head[5] = 0&0xff;
    head[6] = 0&0xff;
    head[7] = 0&0xff;
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    int time = interval;
    for (int i = 8; i < 12; i ++) {
        head[i] = (time & 0xFF);
        time >>= 8;
    }
    
    
    NSData* bodyData = [NSData dataWithBytes:&head length:12];
    
    return bodyData;
}

- (BOOL)validateLocation:(CLLocation *)location
{
    if (!_lastLocation) {
        return YES;
    }

    int now = [[NSDate date] timeIntervalSince1970];

    if (now == _collectTimeStamp) {
        return NO;
    }

    double  distance  = [location distanceFromLocation:_lastLocation];

    float speed = distance/(now - _collectTimeStamp); // 两点间的速度

    float acceleration = (location.speed - _lastLocation.speed)/(now - _collectTimeStamp); //两点间的加速度

    if (speed > _speedLimit ||acceleration  > _accelerationLimit) {
        return NO;
    }
    else
    {
        return YES;
    }
}


- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) {
        // 提示用户出错原因，可按住Option键点击 KCLErrorDenied的查看更多出错信息，可打印error.code值查找原因所在
    }
}


- (void) initDetectedBeaconsList{
    if (!self.detectedBeacons) {
        self.detectedBeacons = [[NSMutableArray array] init];
    }
}

- (void)setNewRegion
{
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:[MY_UUID uppercaseString] ];
    NSUUID *proximityAdjustUUID = [[NSUUID alloc] initWithUUIDString:[MY_UUID_ADJUST uppercaseString] ];
    //
        if (BindperipheralName)
        {
            NSString *subString = [BindperipheralName substringFromIndex:BindperipheralName.length -4];//截取后四位
            NSString *reserveString = [self getReverseString:subString]; //倒序
            NSString *finalString = [NSString stringWithFormat:@"%@%@",[reserveString substringFromIndex:2],[reserveString substringToIndex:2]];
            //小端转换
            NSString *value = [NSString stringWithFormat:@"%lu",strtoul([finalString UTF8String],0,16)];//转16进制
            if (self.region.major.intValue == value.intValue)
            {
                return;
            }
            else
            {
                [self.locationManager stopRangingBeaconsInRegion:_region];
                [self.locationManager stopMonitoringForRegion:_region];
                self.region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:value.intValue identifier:@"iBeacons"];
                self.region_adjust = [[CLBeaconRegion alloc] initWithProximityUUID:proximityAdjustUUID major:value.intValue identifier:@"region_adjust"];

                [self.locationManager startRangingBeaconsInRegion:self.region];
                [self.locationManager startMonitoringForRegion:self.region];
                [_locationManager requestStateForRegion:self.region];
                [self.locationManager startRangingBeaconsInRegion:self.region_adjust];
                [self.locationManager startMonitoringForRegion:self.region_adjust];
                [_locationManager requestStateForRegion:self.region_adjust];
            }
            
        }
}
- (void) initBeaconRegion{
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:[MY_UUID uppercaseString] ];
    NSUUID *proximityAdjustUUID = [[NSUUID alloc] initWithUUIDString:[MY_UUID_ADJUST uppercaseString] ];
//
    if (BindperipheralName) {

        NSString *subString = [BindperipheralName substringFromIndex:BindperipheralName.length -4];//截取后四位
        NSString *reserveString = [self getReverseString:subString]; //倒序
        NSString *finalString = [NSString stringWithFormat:@"%@%@",[reserveString substringFromIndex:2],[reserveString substringToIndex:2]];
        //小端转换
        NSString *value = [NSString stringWithFormat:@"%lu",strtoul([finalString UTF8String],0,16)];//转16进制
        if (self.region.major.intValue == value.intValue)
        {
            return;
        }
        else
        {
            self.region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:value.intValue identifier:@"iBeacons"];
            self.region_adjust = [[CLBeaconRegion alloc] initWithProximityUUID:proximityAdjustUUID major:value.intValue identifier:@"region_adjust"];
        }
    }
    else
    {
        self.region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID  identifier:@"iBeacons"];
        self.region_adjust = [[CLBeaconRegion alloc] initWithProximityUUID:proximityAdjustUUID  identifier:@"region_adjust"];

    }
   
//    self.region.notifyEntryStateOnDisplay = YES;
    self.region.notifyOnEntry = YES;
    self.region_adjust.notifyOnEntry = YES;
//    self.region.notifyOnExit = YES;
//    [self.locationManager startMonitoringForRegion:self.region];
    
    
    [self.locationManager startRangingBeaconsInRegion:self.region_adjust];
    [self.locationManager startMonitoringForRegion:self.region_adjust];
    [self.locationManager requestStateForRegion:self.region_adjust];
    
    [self.locationManager startRangingBeaconsInRegion:self.region];
    [self.locationManager startMonitoringForRegion:self.region];
    [self.locationManager requestStateForRegion:self.region];
    NSString *power  = [[NSUserDefaults standardUserDefaults]objectForKey:@"localPower"];
    if (power) {
        _localPower = power.intValue;
    }
    else
    {
        _localPower = 0;
    }
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
//    _killTimeStamp = 0;
    NSDate *date = [NSDate date];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    [formatter setDateStyle:NSDateFormatterMediumStyle];

    [formatter setTimeStyle:NSDateFormatterShortStyle];


    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    
    NSString *dateTime = [formatter stringFromDate:date];

    [[HBUploadManager shareInstance] postLogWithTopic:AliTopiciBeacon andKey:@"didEnterRegion" andContent:dateTime];

    HBLog(@"didEnterRegion");
    [self startBeaconRanging];
//    [self pushEnterNotification];
}


//- (void)locationManager:(CLLocationManager *)manager
//          didExitRegion:(CLRegion *)region
//{
////    HBLog(@"stopBeacon");
////    [self uploadQueen];
////    _killTimeStamp = [[NSDate new]timeIntervalSince1970];
//   [self pushExitNotification];
//
//}

#pragma mark Beacons Ranging

- (void) startBeaconRanging{
    
//   CLBeaconRegion *region = [self.locationManager.rangedRegions.allObjects firstObject];
//    if (region.major.intValue ) {
//        <#statements#>
//    }
    if (!self.locationManager || !self.region) {
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0 ) {
//        HBLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self.locationManager startRangingBeaconsInRegion:self.region];
    [self.locationManager startRangingBeaconsInRegion:self.region_adjust];
}


- (void) stopBeaconRanging{
    if (!self.locationManager || !self.region) {
        return;
    }
    [self.locationManager stopRangingBeaconsInRegion:_region];
}

//Location manager delegate method
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region{
    if (beacons.count == 0) {
        if (!self.isInCar) {
            return ;
        }
        if ([HBDBManager shareInstance].callWasStarted) {
            [HBBlueToothManager shareInstance].btStamp = [[NSDate new]timeIntervalSince1970];
            self.ibeaconTimeStamp = [[NSDate new]timeIntervalSince1970];
//            HBLog(@"Calling.");
        }
        else
        {
//            HBLog(@"Call was ended.");
        }
        int btDuring = [[NSDate new]timeIntervalSince1970] - [HBBlueToothManager shareInstance].btStamp;
        int ibDuring = [[NSDate new]timeIntervalSince1970] - self.ibeaconTimeStamp;
        BOOL isBleToothOutput = [self isBleToothOutput];
        int time = 0;

        if (isBleToothOutput) {
            time = 180 - _nearCarTimeout;
        }
        
        if ((btDuring >= _nearCarTimeout +time)&& (ibDuring >= _nearCarTimeout +time) ) {
            [[HBUploadManager shareInstance] reporTAtIntervals];
            HBLog(@"detected %@ ibeacon %ds btDisconnet %ds",[HBTools getNowTimeString],ibDuring,btDuring);
            self.isInCar = NO;
            [[HBBlueToothManager shareInstance].baby cancelAllPeripheralsConnection];
            [self stopGPSCollect];
//            [self pushNotification];
            NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
            if (BindperipheralName) {
                NSString *content = [NSString stringWithFormat:@"detected %@ ibeacon %ds btDisconnet %ds",[HBTools getNowTimeString],ibDuring,btDuring];
                [[HBUploadManager shareInstance] postLogWithTopic:AliTopicBLEStatus andKey:AliLogKEYIbeacon andContent:content];
            }
            [HBEventManager shareInstance].isEngineon = NO;
        }
    } else
        {
        self.detectedBeacons = [[NSMutableArray alloc]initWithArray:beacons] ;
        for (CLBeacon *beacon in beacons) {
             {
                if ([self validateBeaconMajor:beacon.major]) {
                    _ibeaconTimeStamp = [[NSDate date] timeIntervalSince1970];
                    int btDuring = [[NSDate new]timeIntervalSince1970] - [HBBlueToothManager shareInstance].btStamp;
                    int ibDuring = [[NSDate new]timeIntervalSince1970] - self.ibeaconTimeStamp;
                    BOOL isBleToothOutput = [self isBleToothOutput];
                    int time = 0;

                    if (isBleToothOutput) {
                        time = 180 - _nearCarTimeout;
                    }
                    if ((btDuring < _nearCarTimeout +time)|| (ibDuring <_nearCarTimeout +time)) {
                        self.isInCar = YES;
                        [self startGPSCollect];
                        
                    }
                    
                    int iminor=((beacon.minor.intValue<<8)&0x0000ff00) | ((beacon.minor.intValue>>8)&0x000000ff);
                    int power=iminor&0x0000007f;
                    int key=(iminor>>7)&0x0000000f;
                    int eventflag = (iminor>>15)&0x00000001;
                    if (key > 0 & key != _lastClickTimes) {
                        NSData *data = [self alertData];
                        if (data) {
                            NSMutableData *muData = [[NSMutableData alloc]initWithData:[self getHeadWithType:0x32]];
                            [muData appendData:data];
                            [[HBDBManager shareInstance]addMQTTBuffer:muData];
                            HBLog(@"User Alert");
                            [self pushAlertNotification];
                        }
                    }
                    if (key > 0) {
                        HBLog(@"Info, click %d times",key);
                    }
                    if (power != _localPower) {
                        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%d",power] forKey:@"localPower"];
                        _localPower = power;
                        [self sendPower:power];
                    }
                    
                    if (![HBBlueToothManager shareInstance].isConnected) {
                        if (_block)
                        self.block(beacon,[NSString stringWithFormat:@"%d",power],[NSString stringWithFormat:@"%d",key],eventflag);
                    }
                    _lastClickTimes = key;
                }
            }
        }

                if ([[NSDate date] timeIntervalSince1970] - _logTimeStamp > 5) {
                HBLog(@"Info, Beacons count:%lu", beacons.count);
                    for (CLBeacon *beacon in beacons) {
                        if ([self validateBeaconMajor:beacon.major]) {
                            int iminor=((beacon.minor.intValue<<8)&0x0000ff00) | ((beacon.minor.intValue>>8)&0x000000ff);
//                            int power=iminor&0x0000007f;
//                            int key=(iminor>>7)&0x0000000f;
                            int eventflag = (iminor>>15)&0x00000001;
                            if (eventflag) {
                                HBLog(@"Info, Need connect bluetooth");
                            }
                            else
                            {
                                HBLog(@"Info, No connection is needed");

                            }
//                            HBLog(@"TT请求连接蓝牙 ？ %@",(eventflag ==  1)? @"是":@"否");
//                            HBLog(@"绑定beacon %@", [self detailsStringForBeacon:beacon]);
                            [[HBUploadManager shareInstance]postLogWithTopic:AliLogKEYIbeacon andKey:@"connect" andDictionary:@{@"eventflag":[NSString stringWithFormat:@"%d",eventflag],
                                                                                                                                @"time":[HBTools getNowTimeString]
                                                                                                                                }];
                        }
                        else
                        {
//                            HBLog(@"未绑定beacon%@", [self detailsStringForBeacon:beacon]);
                        }
                    }
                _logTimeStamp = [[NSDate date] timeIntervalSince1970];
        }
    }
}

- (void)sendPower:(int)power
{
    NSData *headData = [self getHeadWithType:0x05 andLength:(34+12)];
    Byte powerInfo[34] = {0};
    NSString *DeviceId = [[HBBlueToothManager shareInstance] getCurrentPeripheralDeviceID];
//    HBLog(@"DeviceId = %@",DeviceId);
    if (!DeviceId) {
        return ;
    }
    NSString *uuid = [[[HBTools uuidString]  stringByReplacingOccurrencesOfString:@"-" withString:@""]uppercaseString];
    char css[DeviceId.length];
    
    memcpy(css, [DeviceId cStringUsingEncoding:NSASCIIStringEncoding], 2*[DeviceId length]);
    
    for (int i = 0; i < 8; i ++) {
        powerInfo[i] = css[i];
    }
    
    int j=8;
    
    for(int i=0;i<[uuid length];i++)
        
    {
        
        int int_ch; // 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [uuid characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        
        int int_ch1;
        
        if(hex_char1 >= '0' && hex_char1 <='9')
            
            int_ch1 = (hex_char1-48)*16;  //// 0 的Ascll - 48
        
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        
        else
            
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        
        i++;
        
        unichar hex_char2 = [uuid characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        
        int int_ch2;
        
        if(hex_char2 >= '0' && hex_char2 <='9')
            
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        
        else if(hex_char2 == 'A' && hex_char2 <='F')
            
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        
        else
            
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        
        powerInfo[j] = int_ch; ///将转化后的数放入Byte数组里
        
        j++;
        
    }
    int time = [[NSDate new]timeIntervalSince1970];
    for (int i = 24; i < 28; i ++) {
        powerInfo[i] = (time & 0xFF);
        time >>= 8;
    }
    powerInfo[32] = power&0xFF;
    NSData *restData = [NSData dataWithBytes:powerInfo length:34];
    
    NSMutableData *muData = [[NSMutableData alloc]initWithData:headData];
    [muData appendData:restData];
    [[HBDBManager shareInstance]addMQTTBuffer:muData];
    
}

#pragma mark Process Beacon Information
//将beacon的信息转换为NSString并返回
- (NSString *)detailsStringForBeacon:(CLBeacon *)beacon
{
    
    NSString *format = @"major%@ • minor%@ • %@ • %f • %li";
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, [self stringForProximity:beacon.proximity], beacon.accuracy, beacon.rssi];
}

- (NSString *)stringForProximity:(CLProximity)proximity{
    NSString *proximityValue;
    switch (proximity) {
        case CLProximityNear:
            proximityValue = @"Near";
            break;
        case CLProximityImmediate:
            proximityValue = @"Immediate";
            break;
        case CLProximityFar:
            proximityValue = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximityValue = @"Unknown";
            break;
    }
    return proximityValue;
}

- (void)checkLocationAccessForRanging {
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }
}

- (void)setIbeaconBlock:(IBeaconManagerBlock )block
{
    _block = block;
}

- (void)setGPSBlock:(GPSCollectBlock)block
{
    _timeblock = block;
}

- (void)startGPSCollect
{
    if (!_gpsIsStart) {
        NSDate *date = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        
        
        [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        NSString *dateTime = [formatter stringFromDate:date];
        
        if (_timeblock && _longitude > 0 ) {
            self.timeblock(dateTime,_longitude,_latitude);
        }
//        HBLog(@"开始GPS采集");
        HBLog(@"Info, Start GPS collection");

        [[NSNotificationCenter defaultCenter]postNotificationName:EnterCarNotification object:nil];
        if (self.timerOn == NO) {
            [self.timer setFireDate:[NSDate distantPast]];
            self.timerOn = YES;
        }
        _gpsIsStart = YES;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _killTimeStamp = 0;
    }
}

- (void)stopGPSCollect
{
    if (_gpsIsStart) {
        
        if ([FOTAUpDateManager shareInstance].isStart) {
            return ;
        }
        
        HBLog(@"Info, Stop GPS collection");
        [[NSNotificationCenter defaultCenter]postNotificationName:LeftCarNotification object:nil];
        
        if (self.timerOn == YES) {
            [self.timer setFireDate:[NSDate distantFuture]];
            self.timerOn = NO;
        }
        [self uploadQueen];
        _gpsIsStart = NO;
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        _killTimeStamp = [[NSDate new]timeIntervalSince1970];
    }
}

- (NSData *)getGPSData
{
    Byte tripInfo[61] = {0};
    NSString *DeviceId = [[HBBlueToothManager shareInstance] getCurrentPeripheralDeviceID];
    if (!DeviceId) {
        return nil;
    }
    NSString *uuid = [[[HBTools uuidString]  stringByReplacingOccurrencesOfString:@"-" withString:@""]uppercaseString];
    char css[DeviceId.length];
    
    memcpy(css, [DeviceId cStringUsingEncoding:NSASCIIStringEncoding], 2*[DeviceId length]);
    
    for (int i = 0; i < 8; i ++) {
        tripInfo[i] = css[i];
    }
    
    int j=8;
    
    for(int i=0;i<[uuid length];i++)
        
    {
        
        int int_ch; /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [uuid characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        
        int int_ch1;
        
        if(hex_char1 >= '0' && hex_char1 <='9')
            
            int_ch1 = (hex_char1-48)*16; //// 0 的Ascll - 48
        
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        
        else
            
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        
        i++;
        
        unichar hex_char2 = [uuid characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        
        int int_ch2;
        
        if(hex_char2 >= '0' && hex_char2 <='9')
            
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        
        else if(hex_char2 == 'A' && hex_char2 <='F')
            
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        
        else
            
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        
        tripInfo[j] = int_ch; ///将转化后的数放入Byte数组里
        
        j++;
        
    }
    int time = _collectTimeStamp;
    for (int i = 40; i < 44; i ++) {
        tripInfo[i] = (time & 0xFF);
        time >>= 8;
    }
    
    if (_longitude) {
        int longitude = _longitude * 100000;
        for (int i = 44; i < 48; i ++) {
            tripInfo[i] = (longitude & 0xFF);
            longitude >>= 8;
        }
    }
    
    if (_latitude) {
        int latitude = _latitude * 100000;
        for (int i = 48; i < 52; i ++) {
            tripInfo[i] = (latitude & 0xFF);
            latitude >>= 8;
        }
    }
    
    if (_speed) {
        int speed = _speed * 3.6 * 100;
        for (int i = 52; i < 56; i ++) {
            tripInfo[i] = (speed & 0xFF);
            speed >>= 8;
        }
    }
    if (_course) {
        int course = _course * 10;
        for (int i = 56; i < 58; i ++) {
            tripInfo[i] = (course & 0xFF);
            course >>= 8;
        }
    }
    if (_altitude) {
        int altitude = _altitude;
        for (int i = 58; i < 60; i ++) {
            tripInfo[i] = (altitude & 0xFF);
            altitude >>= 8;
        }
    }
    
    
    
    if (_latitude && _longitude) {
        tripInfo[60] = 'Y';
    }
    else
    {
        tripInfo[60] = 'N';
    }
    NSData* bodyData = [NSData dataWithBytes:&tripInfo length:61];
    
    return bodyData;
}


- (NSData *)getHeadWithType:(int)type
{
    Byte head[12] = {0};

    if (type == 0x11) {
        head[0] = 73&0xff;
        head[1] = (73>>8)&0xff;
    }
    if (type == 0x32) {
        head[0] = 48&0xff;
        head[1] = (48>>8)&0xff;
    }
    head[2] = 10&0xff;
    head[3] = type&0xff;
    head[4] = 3&0xff;
    head[5] = 0&0xff;
    head[6] = 0&0xff;
    head[7] = 0&0xff;
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    int time = interval;
    for (int i = 8; i < 12; i ++) {
        head[i] = (time & 0xFF);
        time >>= 8;
    }


    NSData* bodyData = [NSData dataWithBytes:&head length:12];
    
    return bodyData;
}

- (NSData *)alertData
{
    Byte tripInfo[36] = {0};
    NSString *DeviceId = [[HBBlueToothManager shareInstance] getCurrentPeripheralDeviceID];
    HBLog(@"DeviceId = %@",DeviceId);
    if (!DeviceId) {
        return nil;
    }
    NSString *uuid = [[[HBTools uuidString]  stringByReplacingOccurrencesOfString:@"-" withString:@""]uppercaseString];
    char css[DeviceId.length];
    
    memcpy(css, [DeviceId cStringUsingEncoding:NSASCIIStringEncoding], 2*[DeviceId length]);
    
    for (int i = 0; i < 8; i ++) {
        tripInfo[i] = css[i];
    }
    
    int j=8;
    
    for(int i=0;i<[uuid length];i++)
        
    {
        
        int int_ch; // 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [uuid characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        
        int int_ch1;
        
        if(hex_char1 >= '0' && hex_char1 <='9')
            
            int_ch1 = (hex_char1-48)*16;  //// 0 的Ascll - 48
        
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        
        else
            
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        
        i++;
        
        unichar hex_char2 = [uuid characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        
        int int_ch2;
        
        if(hex_char2 >= '0' && hex_char2 <='9')
            
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        
        else if(hex_char2 == 'A' && hex_char2 <='F')
            
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        
        else
            
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        
        tripInfo[j] = int_ch; ///将转化后的数放入Byte数组里
        
        j++;
        
    }
    int time = [[NSDate new]timeIntervalSince1970];
    for (int i = 24; i < 28; i ++) {
        tripInfo[i] = (time & 0xFF);
        time >>= 8;
    }
    
    if (_longitude) {
        int longitude = [IBeaconManager shareInstance].longitude * 100000;
        for (int i = 28; i < 32; i ++) {
            tripInfo[i] = (longitude & 0xFF);
            longitude >>= 8;
        }
    }
    
    if (_latitude) {
        int latitude = [IBeaconManager shareInstance].latitude * 100000;
        for (int i = 32; i < 36; i ++) {
            tripInfo[i] = (latitude & 0xFF);
            latitude >>= 8;
        }
    }
    
    NSData* bodyData = [NSData dataWithBytes:&tripInfo length:36];
    
    return bodyData;
}

/*
 ValidateBeaconMajorByName
*/
- (BOOL)validateBeaconMajor:(NSNumber*)major
{
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    if (BindperipheralName)
    {
        NSString *subString = [BindperipheralName substringFromIndex:BindperipheralName.length -4];//截取后四位
        NSString *reserveString = [self getReverseString:subString]; //倒序
        NSString *finalString = [NSString stringWithFormat:@"%@%@",[reserveString substringFromIndex:2],[reserveString substringToIndex:2]];
        //小端转换
        NSString *value = [NSString stringWithFormat:@"%lu",strtoul([finalString UTF8String],0,16)];//转16进制
        if (value.intValue == major.intValue) {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    return NO;
}

-(NSString *)getReverseString:(NSString *)tempString
{
    NSMutableString * reverseString = [NSMutableString string];
    for(int i = 0 ; i < tempString.length; i ++){
        //倒序读取字符并且存到可变数组数组中
        unichar c = [tempString characterAtIndex:tempString.length- i -1];
        [reverseString appendFormat:@"%c",c];
    }
    tempString = [NSString stringWithFormat:@"%@",reverseString];
    return tempString;
    
}

- (void)pushNotification
{
    if (_push) {
        // 1.创建本地通知
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        
        // 2.设置本地通知的内容
        // 2.1.设置通知发出的时间
        localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        // 2.2.设置通知的内容
        localNote.alertBody = @"恭喜您已安全到达目的地！";
        // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
        localNote.alertAction = @"解锁";
        // 2.4.决定alertAction是否生效
        localNote.hasAction = NO;
        // 2.5.设置点击通知的启动图片
        localNote.alertLaunchImage = @"AppIcon";
        // 2.6.设置alertTitle
//        localNote.alertTitle = @"华保体贴提醒您";
        localNote.alertTitle =  HBLocalizedString(@"UserAlertTitle", nil) ;
        // 2.7.设置有通知时的音效
        localNote.soundName = @"end.caf";//UILocalNotificationDefaultSoundName;
        // 2.8.设置应用程序图标右上角的数字
        localNote.applicationIconBadgeNumber = 0;
        
        localNote.repeatInterval = 0;
        
        // 2.9.设置额外信息
        localNote.userInfo = @{@"type" : @1};
        
        // 3.调用通知
        [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        
    }
   
}

- (void)pushExitNotification
{
        // 1.创建本地通知
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        
        // 2.设置本地通知的内容
        // 2.1.设置通知发出的时间
        localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        // 2.2.设置通知的内容
        localNote.alertBody = @"我走啦！";
        // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
        localNote.alertAction = @"解锁";
        // 2.4.决定alertAction是否生效
        localNote.hasAction = NO;
        // 2.5.设置点击通知的启动图片
        localNote.alertLaunchImage = @"AppIcon";
        // 2.6.设置alertTitle
        localNote.alertTitle = @"华保体贴提醒您";
        // 2.7.设置有通知时的音效
        localNote.soundName = UILocalNotificationDefaultSoundName;//UILocalNotificationDefaultSoundName;
        // 2.8.设置应用程序图标右上角的数字
        localNote.applicationIconBadgeNumber = 0;
        
        localNote.repeatInterval = 0;
        
        // 2.9.设置额外信息
        localNote.userInfo = @{@"type" : @1};
        
        // 3.调用通知
        [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        
    
}
- (void)pushEnterNotification
{
    // 1.创建本地通知
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        
        // 2.设置本地通知的内容
        // 2.1.设置通知发出的时间
        localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        // 2.2.设置通知的内容
        localNote.alertBody = @"我来了！";
        // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
        localNote.alertAction = @"解锁";
        // 2.4.决定alertAction是否生效
        localNote.hasAction = NO;
        // 2.5.设置点击通知的启动图片
        localNote.alertLaunchImage = @"AppIcon";
        // 2.6.设置alertTitle
        localNote.alertTitle = @"华保体贴提醒您";
        // 2.7.设置有通知时的音效
        localNote.soundName = UILocalNotificationDefaultSoundName;//UILocalNotificationDefaultSoundName;
        // 2.8.设置应用程序图标右上角的数字
        localNote.applicationIconBadgeNumber = 0;
        
        localNote.repeatInterval = 0;
        
        // 2.9.设置额外信息
        localNote.userInfo = @{@"type" : @1};
        
        // 3.调用通知
        [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        
    
}

- (void)pushAlertNotification
{
    // 1.创建本地通知
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    
    // 2.设置本地通知的内容
    // 2.1.设置通知发出的时间
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    // 2.2.设置通知的内容
//    localNote.alertBody = @"功能按钮触发，请求已送往服务商";
    localNote.alertBody = HBLocalizedString(@"UserAlert", nil) ;
    // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
    localNote.alertAction = @"解锁";
    // 2.4.决定alertAction是否生效
    localNote.hasAction = NO;
    // 2.5.设置点击通知的启动图片
    localNote.alertLaunchImage = @"AppIcon";
    // 2.6.设置alertTitle
//    localNote.alertTitle = @"华保体贴提醒您";
    localNote.alertTitle =  HBLocalizedString(@"UserAlertTitle", nil) ;
    // 2.7.设置有通知时的音效
    localNote.soundName = UILocalNotificationDefaultSoundName;//;
//    localNote.soundName =     @"end.caf";//;
    // 2.8.设置应用程序图标右上角的数字
    localNote.applicationIconBadgeNumber = 0;
    
    localNote.repeatInterval = 0;
    
    // 2.9.设置额外信息
    localNote.userInfo = @{@"type" : @1};
    
    // 3.调用通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
}

/**
 检测是否连接蓝牙
 
 @return 是否为蓝牙音频输出
 */
-(BOOL)isBleToothOutput
{
    AVAudioSessionRouteDescription *currentRount = [AVAudioSession sharedInstance].currentRoute;
    AVAudioSessionPortDescription *outputPortDesc = currentRount.outputs[0];
    if([outputPortDesc.portType isEqualToString:@"BluetoothA2DPOutput"]){
//        HBLog(@"Info, Audio output = Bluetooth Audio Device");
        return YES;
    }else{
//        HBLog(@"Info, Audio output = Phone Speaker");
        return NO;
    }
}
@end
