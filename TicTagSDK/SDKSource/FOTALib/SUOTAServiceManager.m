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

#import "SUOTAServiceManager.h"
#import "Defines.h"
#import "HBDemo-Prefix.pch"
NSString * const SUOTAServiceNotFound = @"SUOTAServiceNotFound";

@implementation SUOTAServiceManager

- (void) peripheral:(CBPeripheral *)_peripheral didDiscoverServices:(NSError *)error {
    NSArray *services = [_peripheral services];
    
    for (CBService *service in services) {
        if ([service.UUID isEqual:[self IntToCBUUID:SPOTA_SERVICE_UUID]]) {
            self.suotaReady = TRUE;
        }
    }
    
    [super peripheral:_peripheral didDiscoverServices:error];
    
    if (!self.suotaReady) {
        // It appears this device does not support the SUOTA service.
        [[NSNotificationCenter defaultCenter] postNotificationName:SUOTAServiceNotFound object:_peripheral];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSArray *characteristics = [service characteristics];
    for (CBCharacteristic *characteristic in characteristics) {
        
        HBLog(@"Characteristic UUID: %@", characteristic.UUID);
        
        if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID]]) {
            HBLog(@"MEM DEV FOUND!");
        }
        
        /*if ([[characteristic UUID] isEqual:[self IntToCBUUID:ORG_BLUETOOTH_SERVICE_BATTERY_LEVEL]]) {
            [self notification:ORG_BLUETOOTH_SERVICE_BATTERY_SERVICE characteristicUUID:ORG_BLUETOOTH_SERVICE_BATTERY_LEVEL p:self.device on:YES];
            [self readValue:ORG_BLUETOOTH_SERVICE_BATTERY_SERVICE characteristicUUID:ORG_BLUETOOTH_SERVICE_BATTERY_LEVEL p:self.device];
        }*/
    }
    
    [super peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
}

@end
