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

#import "DeviceStorage.h"
#import "BluetoothManager.h"
//#import "DeviceListTableViewCell.h"
#import "HBDemo-Prefix.pch"
NSString * const DeviceStorageUpdated = @"DeviceStorageUpdated";

@implementation DeviceStorage

static DeviceStorage* sharedDeviceStorage = nil;

+ (DeviceStorage*) sharedInstance {
    if (sharedDeviceStorage == nil) {
        sharedDeviceStorage = [[DeviceStorage alloc] init];
    }
    return sharedDeviceStorage;
}

- (id) init {
    if (self = [super init]) {
        self.devices = [[NSMutableArray alloc] init];
                
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveDevices:)
                                                     name:BluetoothManagerReceiveDevices
                                                   object:nil];
    }
    return self;
}

- (void) receiveDevices:(NSNotification *) notification {
    [self.devices removeAllObjects];
    
    for (CBPeripheral *device in [notification object]) {
        GenericServiceManager *dm = [self deviceManagerWithIdentifier:[device.identifier UUIDString]];
        dm.device = device;
        
        if (!dm) {
            dm = [[GenericServiceManager alloc] initWithDevice:device andManager:[BluetoothManager getInstance]];
            [self.devices addObject:dm];
        }
        
        if (dm.autoconnect)
            [dm connect];
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceStorageUpdated object:self];
}

#pragma mark - Storage

- (CBPeripheral*) deviceForIndex: (int)index {
    GenericServiceManager *deviceManager = [self.devices objectAtIndex:index];
    return deviceManager.device;
}

- (GenericServiceManager*) deviceManagerForIndex: (int)index {
    GenericServiceManager *deviceManager = [self.devices objectAtIndex:index];
    return deviceManager;
}

- (GenericServiceManager*) deviceManagerWithIdentifier:(NSString*)identifier {
    for (GenericServiceManager *device in self.devices) {
        if ([device.identifier isEqualToString:identifier]) {
            return device;
        }
    }
    return nil;
}

- (int) indexOfDevice:(CBPeripheral*) device {
    for (int n=0; n < [self.devices count]; n++) {
        CBPeripheral *p = [self deviceForIndex:n];
        if (p == device)
            return n;
    }
    return -1;
}

- (int) indexOfIdentifier:(NSString*) identifier {
    for (int n=0; n < [self.devices count]; n++) {
        GenericServiceManager *p = [self deviceManagerForIndex:n];
        if ([p.identifier isEqualToString:identifier])
            return n;
    }
    return -1;
}

- (void) unpairDevice:(GenericServiceManager*)device {
    int index = [self indexOfIdentifier:device.identifier];
    [self.devices removeObjectAtIndex:index];
    
    //[self.devices removeObject:device];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceStorageUpdated object:self];
}

- (void) load {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *devices = [defaults objectForKey:@"deviceList"];
    
    self.devices = [[NSMutableArray alloc] init];
    for (NSData *encodedDevice in devices) {
        [self.devices addObject:(GenericServiceManager*) [NSKeyedUnarchiver unarchiveObjectWithData:encodedDevice]];
    }
    
    HBLog(@"Retrieved devices.");
    //self.devices = [defaults objectForKey:@"devices"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DeviceStorageUpdated object:self];
}

- (void) save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *deviceList = [[NSMutableArray alloc] init];
    for (GenericServiceManager *device in self.devices) {
        NSData *encodedDevice = [NSKeyedArchiver archivedDataWithRootObject:device];
        [deviceList addObject:encodedDevice];
    }
    
    [defaults setObject:deviceList forKey:@"deviceList"];
    [defaults synchronize];
}

@end
