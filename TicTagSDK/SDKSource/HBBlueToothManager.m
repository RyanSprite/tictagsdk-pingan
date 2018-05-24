//
//  HBBlueToothManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/20.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBBlueToothManager.h"
#import "HBDemo-Prefix.pch"

@implementation HBBlueToothManager

+ (instancetype)shareInstance {
    static HBBlueToothManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBBlueToothManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.baby = [BabyBluetooth shareBabyBluetooth];
        if ([[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"]) {
            NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"];
            self.isBind = YES;
            _btStamp = [[NSDate new]timeIntervalSince1970];
            [self.baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
                if (central.state == CBCentralManagerStatePoweredOn) {
                    _currentPeripheral = [_baby retrievePeripheralWithUUIDString:uuid];
                    _isPowerOn = YES;
                    [[NSNotificationCenter defaultCenter]postNotificationName:BlueToothPowerOnNotification object:nil];

                }
                else
                {
                    _isPowerOn = NO;
                    [[NSNotificationCenter defaultCenter]postNotificationName:BlueToothPowerOffNotification object:nil];
                }
            }];
        }
        else
        {
            [self.baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
                if (central.state == CBCentralManagerStatePoweredOn) {
                    _isPowerOn = YES;
                    [[NSNotificationCenter defaultCenter]postNotificationName:BlueToothPowerOnNotification object:nil];
                    
                }
                else
                {
                    _isPowerOn = NO;
                    [[NSNotificationCenter defaultCenter]postNotificationName:BlueToothPowerOffNotification object:nil];
                }
            }];
            self.isBind = NO;
        }
    }
    return self;
}

- (void)setIsConnected:(BOOL)isConnected
{
    _isConnected = isConnected;
//    _isBind = YES;
    _btStamp = [[NSDate new]timeIntervalSince1970];
    [_baby cancelScan];
}

- (void)disconnect
{
    [_baby cancelPeripheralConnection:_currentPeripheral];
}

- (void)connect
{
    _baby.having(_currentPeripheral).connectToPeripherals().discoverServices().discoverCharacteristics().begin();
}
- (NSString *)getCurrentPeripheralDeviceID
{
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"]) {
        NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"];
//        self.isBind = YES;
        _currentPeripheral = [_baby retrievePeripheralWithUUIDString:uuid];
    }
    else
    {
        self.isBind = NO;
    }

    if (_currentPeripheral) {
        return [_currentPeripheral.name substringFromIndex:3];
    }
    else
    {
        HBLog(@"暂未获取到绑定设备");
        return nil;
    }
}

- (void)setBindPeripheral:(CBPeripheral *)bindPeripheral
{
    _bindPeripheral = bindPeripheral;
    if (bindPeripheral) {
        _isBind = YES;
    }
    else
    {
        _isBind = NO;
    }
}

- (void)setCurrentPeripheral:(CBPeripheral *)currentPeripheral
{
    _currentPeripheral = currentPeripheral;
//    if (currentPeripheral) {
//        _isBind = YES;
//    }
//    else
//    {
//        _isBind = NO;
//    }
}

//- (BOOL)isBind
//{
//    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"]) {
//        return YES;
//    }
//    else
//    {
//        return NO;
//    }
//}

@end
