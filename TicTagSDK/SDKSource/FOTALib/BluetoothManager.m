/*
 *******************************************************************************
 *
 * Copyright (C) 2016 Dialog Semiconductor, unpublished work. This computer
 * program includes Confidential, Proprietary Information and is a Trade
 * Secret of Dialog Semiconductor. All use, disclosure, and/or reproduction
 * is prohibited unless authorized in writing. All Rights Reserved.
 *
 * bluetooth.support@diasemi.com
 *
 *******************************************************************************
 */

#import "BluetoothManager.h"
#import "Defines.h"
#import "DeviceStorage.h"
#import "HBDemo-Prefix.pch"
NSString * const BluetoothManagerReceiveDevices         = @"BluetoothManagerReceiveDevices";
NSString * const BluetoothManagerConnectingToDevice     = @"BluetoothManagerConnectingToDevice";
NSString * const BluetoothManagerConnectedToDevice      = @"BluetoothManagerConnectedToDevice";
NSString * const BluetoothManagerDisconnectedFromDevice = @"BluetoothManagerDisconnectedFromDevice";
NSString * const BluetoothManagerConnectionFailed       = @"BluetoothManagerConnectionFailed";

static BluetoothManager *instance;

@implementation BluetoothManager

@synthesize bluetoothReady, device;

+ (BluetoothManager*) getInstance {
    if (!instance)
        instance = [[BluetoothManager alloc] init];
    return instance;
}

+ (void) destroyInstance {
    instance = nil;
}

- (id) init {
    self = [super init];
    if (self) {
        manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        UInt16 cx = [BluetoothManager swap:SPOTA_SERVICE_UUID];
        NSData *cdx = [[NSData alloc] initWithBytes:(char *)&cx length:2];
        mainServiceUUID = [CBUUID UUIDWithData:cdx];
        cx = [BluetoothManager swap:HOMEKIT_UUID];
        cdx = [[NSData alloc] initWithBytes:(char *)&cx length:2];
        homekitUUID = [CBUUID UUIDWithData:cdx];
        knownPeripherals = [[NSMutableArray alloc] init];
        instance = self;
//        NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:@"Bindperipheral"];
//        bleUUID = [CBUUID UUIDWithString:uuid];
    }
    
    return self;
}

- (void) connectToDevice: (CBPeripheral*) _device {
    self.device = _device;
    
    NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @TRUE};
    [manager connectPeripheral:_device options:options];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerConnectingToDevice object:_device];
}

- (void) disconnectDevice {
    if (self.device.state != CBPeripheralStateConnected && self.device.state != CBPeripheralStateConnecting) {
        return;
    }
    [manager cancelPeripheralConnection:self.device];
}

- (void) startScanning {
    if (!self.bluetoothReady) {
        HBLog(@"Bluetooth not yet ready, trying again in a few seconds...");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startScanning) object:nil];
        [self performSelector:@selector(startScanning) withObject:nil afterDelay:1.0];
        return;
    }

    HBLog(@"Started scanning for devices ...");
    
    knownPeripherals = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerReceiveDevices object:knownPeripherals];
    
//    NSArray         *uuids      = [NSArray arrayWithObjects:mainServiceUUID, homekitUUID,bleUUID, nil];
    NSArray         *uuids      = [NSArray arrayWithObjects:mainServiceUUID, homekitUUID, nil];
    NSDictionary	*options	= [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    
    [manager scanForPeripheralsWithServices:uuids options:options];
}

- (void) stopScanning {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startScanning) object:nil];
    [manager stopScan];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    bluetoothReady = FALSE;
    switch (manager.state) {
        case CBCentralManagerStatePoweredOff:
            HBLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            HBLog(@"CoreBluetooth BLE hardware is powered on and ready");
            self.bluetoothReady = TRUE;
            break;
        case CBCentralManagerStateResetting:
            HBLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBCentralManagerStateUnauthorized:
            HBLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            HBLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            HBLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            HBLog(@"Unknown state");
            break;
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    HBLog(@"Discovered item %@ (advertisement: %@)", peripheral, advertisementData);
    
    NSArray *services = [advertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey];
    NSArray *servicesOvfl = [advertisementData valueForKey:CBAdvertisementDataOverflowServiceUUIDsKey];
    if ([services containsObject:mainServiceUUID] || [servicesOvfl containsObject:mainServiceUUID]) {
        HBLog(@"%@ [%@]: Found SUOTA service UUID in advertising data", peripheral.name, peripheral.identifier.UUIDString);
    }
    if ([services containsObject:homekitUUID] || [servicesOvfl containsObject:homekitUUID]) {
        HBLog(@"%@ [%@]: Found HomeKit service UUID in advertising data", peripheral.name, peripheral.identifier.UUIDString);
    }

    [peripheral setValue:RSSI forKey:@"RSSI"];
    if (![knownPeripherals containsObject:peripheral]) {
        [knownPeripherals addObject:peripheral];
    }
    
    NSMutableArray *uuids = [[NSMutableArray alloc] init];
    for (CBPeripheral *p in knownPeripherals) {
        [uuids addObject:(id)p.identifier];
        HBLog(@"Looking for UUID: %@", p.identifier.UUIDString);
    }
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    [manager retrievePeripheralsWithIdentifiers:uuids];
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerReceiveDevices object:knownPeripherals];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    HBLog(@"Did connect device: %@", peripheral);
    
    self.userDisconnect = NO;
    GenericServiceManager *m = [[DeviceStorage sharedInstance] deviceManagerWithIdentifier:[peripheral.identifier UUIDString]];
    if (m == nil) {
        m = [[GenericServiceManager alloc] initWithDevice:peripheral andManager:self];
    }
    [m setDevice:peripheral];

    [[DeviceStorage sharedInstance] save];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerConnectedToDevice object:peripheral];
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    HBLog(@"Disconnected device");
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerDisconnectedFromDevice object:peripheral];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    HBLog(@"Error connecting device");
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerConnectionFailed object:peripheral];
}

- (void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    HBLog(@"Retreived connected devices");
}

- (void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    HBLog(@"Retrieved periphs: %@", peripherals);
    HBLog(@"Retrieved known periphs: %@", knownPeripherals);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothManagerReceiveDevices object:knownPeripherals];
    //[manager stopScan];
}

/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

+ (UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

@end
