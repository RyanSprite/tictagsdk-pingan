//
//  HBEventManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/26.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBEventManager.h"
#import "HBDemo-Prefix.pch"

@implementation HBEventManager
+ (instancetype)shareInstance {
    static HBEventManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBEventManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setTotalEvent:(NSMutableString *)totalEvent
{
    if (!_totalEvent) {
        _totalEvent = [[NSMutableString alloc]init];
//        _connectionEvent = [[NSMutableString alloc]init];
    }
    _totalEvent = totalEvent;
}

- (void)setCurrentEvent:(NSString *)currentEvent
{
    
    [HBBlueToothManager shareInstance].btStamp = [[NSDate date] timeIntervalSince1970];;
    _currentEvent = currentEvent;
    if ([currentEvent hasPrefix:@"14"]) {
        self.address = [currentEvent substringWithRange:NSMakeRange(2, 8)];
        if (!_address) {
            return ;
        }
//        self.address = [NSString stringWithFormat:@"%zi",[HBTools coverFromHexStrToInt:_address]];
        self.totalSize = [currentEvent substringWithRange:NSMakeRange(10, 4)];
        self.totalSize = [NSString stringWithFormat:@"%zi",[HBTools coverFromHexStrToInt:_totalSize]];
        self.totalEvent = [NSMutableString stringWithString:@""];

        self.lastEvent = nil;
        if (self.totalSize.intValue > 0) {
            [self.totalEvent appendString:[currentEvent substringFromIndex:10]];
            HBLog(@"Info, Start collect Tictag data");
        }
        else
        {
            HBLog(@"Info, BT-SDK No Event");
            [[FOTAUpDateManager shareInstance]startFOTA];
        }
    }
    else if ([currentEvent hasPrefix:@"15"])
    {
        [self.totalEvent appendString:[currentEvent substringFromIndex:2]];
        int length = self.totalEvent.length/2.0;
    }
    else if ([currentEvent hasPrefix:@"16"])
    {
        if (_lastEvent) {
            self.lastEvent = nil;
            self.totalEvent = [NSMutableString stringWithString:@""];
            return ;
        }
        [self.totalEvent appendString:[currentEvent substringFromIndex:2]];
//        HBLog(@"事件数据  = %@ ",self.totalEvent);
        NSString *eventType = [self.totalEvent substringWithRange:NSMakeRange(6, 2)];
        HBLog(@"Info, BT-SDK Event transmit finished, Event ID =%@",eventType);
        if (eventType.integerValue == 2) {
            
            NSString *hw ;
            NSString *fw ;
            
            hw = [self.totalEvent substringWithRange:NSMakeRange(216, 8)];
            fw = [self.totalEvent substringWithRange:NSMakeRange(224, 8)];
            hw = [self dataTransfromBigOrSmall:hw];
            fw = [self dataTransfromBigOrSmall:fw];
            [[NSNotificationCenter defaultCenter]postNotificationName:FWUPDATENotification object:fw];
            [[NSNotificationCenter defaultCenter]postNotificationName:HWUPDATENotification object:hw];
            [[NSUserDefaults standardUserDefaults]setObject:fw forKey:@"fwVersion"];
            [[NSUserDefaults standardUserDefaults]setObject:hw forKey:@"hwVersion"];
        }
        else
        {
            
        }
//        [_connectionEvent appendString:self.totalEvent];
//        [_connectionEvent appendString:@"\n"];

        NSString *string = [NSString stringWithFormat:@" eventType %d \n %@",eventType.intValue,_totalEvent];
        [[HBUploadManager shareInstance]postLogWithTopic:AliTopicEvent andKey:AliLogKEYEvent andContent:string];
        [[HBMQTTManager shareInstance]sendMessage:self.totalEvent];
        if (eventType.integerValue == 10 && self.isEngineon == NO) {
            [self pushNotification];
        }
        _lastEvent = _currentEvent;
    }
    else if ([currentEvent hasPrefix:@"17"])
    {
        HBLog(@"紧急事件 = %@",self.currentEvent);
        NSData *data = [self alertData];
        if (data) {
            NSMutableData *muData = [[NSMutableData alloc]initWithData:[self getHeadWithType:0x32]];
            [muData appendData:data];
            [[HBDBManager shareInstance]addMQTTBuffer:muData];
//            [[HBMQTTManager shareInstance]sendMessageData:muData];
        }
        self.emergencyCount ++;
        [self pushAlertNotification];
        if (_block) {
            _block(self.emergencyCount);
        }
    }
    else if ([currentEvent hasPrefix:@"18"])
    {
        HBLog(@"currentEvent = %@",currentEvent);
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"needUUID"];
        if ([currentEvent hasSuffix:@"01"]) {
//            [SVProgressHUD showInfoWithStatus:@"该体贴已被绑定"];
            [[NSNotificationCenter defaultCenter]postNotificationName:DisbindNotification object:nil];
        }
        else if ([currentEvent hasSuffix:@"02"])
        {
//            [SVProgressHUD showInfoWithStatus:HBLocalizedString(@"ConnectFail", nil)];
            [[NSNotificationCenter defaultCenter]postNotificationName:DisbindNotification object:nil];

        }
        else if  ([currentEvent hasSuffix:@"03"])
        {
            [[HBBlueToothManager shareInstance] disconnect];
            [[HBBlueToothManager shareInstance] connect];
        }
        else
        {
            
        }
    }
    else
    {
        
    }
}


-(void)writeStartValue{
    NSData *data = [HBTools coverToByteWithDataWithType:5];
    if ([HBBlueToothManager shareInstance].service.req_event_characteristics)
    {
        [[HBBlueToothManager shareInstance].currentPeripheral writeValue:data forCharacteristic:[HBBlueToothManager shareInstance].service.req_event_characteristics type:CBCharacteristicWriteWithResponse];
    }
    
}
- (void)setemergencyCountBlock:(HBEventManagerBlock)block
{
    _block = block;
}

- (NSData *)alertData
{
    Byte tripInfo[36] = {0};
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
    int time = [[NSDate new]timeIntervalSince1970];
    for (int i = 24; i < 28; i ++) {
        tripInfo[i] = (time & 0xFF);
        time >>= 8;
    }
    
    if ([IBeaconManager shareInstance].longitude) {
        int longitude = [IBeaconManager shareInstance].longitude * 100000;
        for (int i = 28; i < 32; i ++) {
            tripInfo[i] = (longitude & 0xFF);
            longitude >>= 8;
        }
    }
    
    if ([IBeaconManager shareInstance].latitude) {
        int latitude = [IBeaconManager shareInstance].latitude * 100000;
        for (int i = 32; i < 36; i ++) {
            tripInfo[i] = (latitude & 0xFF);
            latitude >>= 8;
        }
    }

    NSData* bodyData = [NSData dataWithBytes:&tripInfo length:36];
    
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

-(NSString *)dataTransfromBigOrSmall:(NSString *)tmpStr{
    
    NSMutableArray *tmpArra = [NSMutableArray array];
    for (int i = 0 ;i<tmpStr.length ;i+=2) {
        NSString *str = [tmpStr substringWithRange:NSMakeRange(i, 2)];
        [tmpArra addObject:str];
    }
    
    NSArray *lastArray = [[tmpArra reverseObjectEnumerator] allObjects];
    
    NSMutableString *lastStr = [NSMutableString string];

    for (int i = 0; i < [lastArray count]; i++) {
        NSString *str = lastArray[i];
        UInt64 tmp = [HBTools coverFromHexStrToInt:str];
        [lastStr appendString:[NSString stringWithFormat:@"%llu",tmp]];
        if (i!= [lastArray count]-1) {
            [lastStr appendString:@"."];
        }
    }
//    NSData *lastData = [self HexStringToData:lastStr];
    
    return lastStr;
    
}

- (void)pushNotification
{
    // 1.创建本地通知
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    
    // 2.设置本地通知的内容
    // 2.1.设置通知发出的时间
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    // 2.2.设置通知的内容
    localNote.alertBody = @"请小心开车，享受驾驶乐趣";
    // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
    localNote.alertAction = @"解锁";
    // 2.4.决定alertAction是否生效
    localNote.hasAction = NO;
    // 2.5.设置点击通知的启动图片
    localNote.alertLaunchImage = @"AppIcon";
    // 2.6.设置alertTitle
    localNote.alertTitle = @"华保体贴提醒您";
    // 2.7.设置有通知时的音效
    localNote.soundName = @"start.caf";//UILocalNotificationDefaultSoundName;
    // 2.8.设置应用程序图标右上角的数字
    localNote.applicationIconBadgeNumber = 0;
    
    localNote.repeatInterval = 0;

    // 2.9.设置额外信息
    localNote.userInfo = @{@"type" : @1};
    
    self.isEngineon = YES;
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
    localNote.alertBody = @"功能按钮触发，请求已送往服务商";
    // 2.3.设置滑块的文字（锁屏状态下：滑动来“解锁”）
    localNote.alertAction = @"解锁";
    // 2.4.决定alertAction是否生效
    localNote.hasAction = NO;
    // 2.5.设置点击通知的启动图片
    localNote.alertLaunchImage = @"AppIcon";
    // 2.6.设置alertTitle
    localNote.alertTitle = @"华保体贴提醒您";
    // 2.7.设置有通知时的音效
    localNote.soundName = UILocalNotificationDefaultSoundName;//;
    // 2.8.设置应用程序图标右上角的数字
    localNote.applicationIconBadgeNumber = 0;
    
    localNote.repeatInterval = 0;
    
    // 2.9.设置额外信息
    localNote.userInfo = @{@"type" : @1};
    
    // 3.调用通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
}
@end
