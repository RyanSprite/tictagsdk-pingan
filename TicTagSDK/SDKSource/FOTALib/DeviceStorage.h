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

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "GenericServiceManager.h"
#import <UIKit/UIKit.h>

extern NSString * const DeviceStorageUpdated;

@interface DeviceStorage : NSObject /*<UITableViewDataSource>*/

+ (DeviceStorage*) sharedInstance;
- (id) init;

- (CBPeripheral*) deviceForIndex: (int) index;
- (GenericServiceManager*) deviceManagerForIndex: (int)index;
- (GenericServiceManager*) deviceManagerWithIdentifier:(NSString*)identifier;
- (int) indexOfDevice:(CBPeripheral*) device;
- (int) indexOfIdentifier:(NSString*) identifier;

- (void) unpairDevice:(GenericServiceManager*)device;
- (void) load;
- (void) save;

@property (strong) NSMutableArray *devices;

@end
