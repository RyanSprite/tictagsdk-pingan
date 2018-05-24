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
#import "BluetoothManager.h"

extern NSString * const GenericServiceManagerDidReceiveValue;
extern NSString * const GenericServiceManagerDidSendValue;
extern NSString * const GenericServiceManagerReadError;
extern NSString * const GenericServiceManagerWriteError;

@protocol GenericServiceDelegate
- (void) deviceReady:(id)device;
- (void) didUpdateData:(id)device;
@end

@interface GenericServiceManager : NSObject <CBPeripheralDelegate> {
    BluetoothManager *manager;
    //CBPeripheral *peripheral;
    
    NSTimer *rssiTimer;
}

@property (weak, nonatomic) id<GenericServiceDelegate> delegate;
@property (weak, nonatomic) CBPeripheral *device;
@property double RSSI;
@property (nonatomic) NSString *deviceName;
@property (nonatomic) NSString* identifier;
@property BOOL autoconnect;

+ (id) getInstanceForDevice:(CBPeripheral*)device;
+ (void) destroyInstanceForDevice:(CBPeripheral*)device;

- (id) initWithDevice:(CBPeripheral*) _device;
- (id) initWithDevice:(CBPeripheral*)device andManager:(BluetoothManager*)manager;
- (id) initWithCoder:(NSCoder *) decoder;
- (void) encodeWithCoder:(NSCoder*) encoder;

- (void) discoverServices;

- (void) connect;
- (void) disconnect;

- (NSString*) deviceName;

- (void) writeValue:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
- (void) writeValueWithoutResponse:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;

- (void) readValue: (CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p;
- (void) notification:(CBUUID*)serviceUUID characteristicUUID:(CBUUID*)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on;
- (const char *) CBUUIDToString:(CBUUID *) UUID;
- (const char *) UUIDToString:(CFUUIDRef)UUID;
- (int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
- (int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2;
- (UInt16) CBUUIDToInt:(CBUUID *) UUID;
- (CBUUID *) IntToCBUUID:(UInt16)UUID;
- (CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
- (CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;

@end
