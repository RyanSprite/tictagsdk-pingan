//
//  FOTAUpDateManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/10/10.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "FOTAUpDateManager.h"
#import "BluetoothManager.h"
#import "Defines.h"
#import "DeviceStorage.h"
#import "SUOTAServiceManager.h"
#import "ParameterStorage.h"
#import "HBDemo-Prefix.pch"
@interface FOTAUpDateManager()
{
    int step, nextStep;
    int expectedValue;
    
    int chunkSize;
    int blockStartByte;
    
    SUOTAServiceManager *manager;
    ParameterStorage *storage;
    NSDate *uploadStart;
    
}
@property int memoryBank;
@property UInt16 blockSize;


@property char memoryType;

@property int patchBaseAddress;

@property int i2cAddress;
@property char i2cSDAAddress;
@property char i2cSCLAddress;

@property char spiMOSIAddress;
@property char spiMISOAddress;
@property char spiCSAddress;
@property char spiSCKAddress;
@end
@implementation FOTAUpDateManager
@synthesize blockSize;
@synthesize fileData,imgArray;

+ (instancetype)shareInstance {
    static FOTAUpDateManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[FOTAUpDateManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        NSURL *fileURL = [[NSBundle mainBundle]URLForResource:@"fota_27" withExtension:@".img"];
        
//        fileData = [NSMutableData dataWithContentsOfURL:fileURL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didUpdateValueForCharacteristic:)
                                                     name:GenericServiceManagerDidReceiveValue
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didSendValueForCharacteristic:)
                                                     name:GenericServiceManagerDidSendValue
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didConnectToDevice:)
                                                     name:BluetoothManagerConnectedToDevice
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveDevices:)
                                                     name:BluetoothManagerReceiveDevices
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(discoverCharacteristics)
                                                     name:@"DiscoverCharacteristics"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(discoverBindCharacteristics)
                                                     name:@"DiscoverBindCharacteristics"
                                                   object:nil];
        
        // Enable notifications on the status characteristic
        
        
     
        [self addObserver: self forKeyPath: @"isNewDevice" options: NSKeyValueObservingOptionNew context: nil];
        [self addObserver: self forKeyPath: @"isStart" options: NSKeyValueObservingOptionNew context: nil];
        [self addObserver: self forKeyPath: @"imgAready" options: NSKeyValueObservingOptionNew context: nil];
    }
    return self;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    HBLog(@"change = %@",change);
    HBLog(@"keyPath = %@",keyPath);
    HBLog(@"object = %@",object);
}

- (void) receiveDevices:(NSNotification*)notification {
    HBLog(@"Retrieved devices: %@", notification.object);
    
    NSString *content = [NSString stringWithFormat:@"receiveDevices at %@ conntent:%@",[HBTools getNowTimeString],notification.object];
    
    [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"receiveDevices" andContent:content];

    NSArray *array = notification.object;
    if ([array count] > 0) {
        
        for (CBPeripheral *peripheral in array) {
            NSString *needUUID = [[NSUserDefaults standardUserDefaults]objectForKey:@"needUUID"];
            if (needUUID.boolValue) {
                if ([peripheral.name isEqualToString:BindPeripheralName]) {
                    self.isNewDevice = YES;
                    [[BluetoothManager getInstance] stopScanning];
                    [[BluetoothManager getInstance]connectToDevice:peripheral];
                    manager = [[SUOTAServiceManager alloc] initWithDevice:peripheral];
                    return ;
                }
            }
            else
            {
                if ([peripheral.name isEqualToString:@"DIALOG-OTA0"]||[peripheral.name isEqualToString:BindPeripheralName]) {
                    if ([peripheral.name isEqualToString:@"DIALOG-OTA0"]) {
                        self.isNewDevice = NO;
                    }
                    else
                    {
                        self.isNewDevice = YES;
                    }
                    [[BluetoothManager getInstance] stopScanning];
                    [[BluetoothManager getInstance]connectToDevice:peripheral];
                    manager = [[SUOTAServiceManager alloc] initWithDevice:peripheral];
                    return ;
                }
            }


        }
        
       
    }
}

- (void) didUpdateValueForCharacteristic: (NSNotification*)notification {
    CBCharacteristic *characteristic = (CBCharacteristic*) notification.object;
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SPOTA_SERV_STATUS_UUID]]) {
        char value;
        [characteristic.value getBytes:&value length:sizeof(char)];
        
        
//        NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
//        if (BindperipheralName) {
//
//            NSString *content = [NSString stringWithFormat:@"exceptValue at %@ value:%d fileIndex:%d",[HBTools getNowTimeString],value,_imgIndex];
//            [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"exceptValue" andContent:content];
//        }
        //        NSString *message = [self getErrorMessage:value];
        //        [self debug:message UILog:(value != SPOTAR_CMP_OK)];
        if (value == 0x20 ||value == 0x21 || value == 0x22|| value == 0x23) {
            HBLog(@"value = %d",value);
            if (value == SPOTAR_BOND_FAIL) {
//                [SVProgressHUD showInfoWithStatus:@"设备已经被其他手机绑定"];
                _isStart = NO;
                _imgAready = NO;
                [HBHttpManager reportResultCode:100021];
                return ;
            }
//            if (value == SPOTAR_NO_BOND) {
//                [SVProgressHUD showInfoWithStatus:@"设备已经被其他手机绑定"];
//                _isStart = NO;
//                _imgAready = NO;
//                [HBHttpManager reportResultCode:100022];
//                return ;
//            }
            if (value == SPOTAR_FOTA_TIMEOUT) {
//                [SVProgressHUD showInfoWithStatus:@"写入UUID长度错误"];
                _isStart = NO;
                _imgAready = NO;
                [HBHttpManager reportResultCode:100023];
                return ;
            }
            step = 1;
            [self nextFota];

        }

        if (expectedValue != 0) {
            // Check if value equals the expected value
            if (value == expectedValue) {
                // If so, continue with the next step
                step = nextStep;
                
                expectedValue = 0; // Reset
                HBLog(@"")
                [self doStep];
            } else {
                // Else display an error message
                //                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //                [alertView show];
                HBLog(@"Error expectedValue = %d",expectedValue);
                expectedValue = 0; // Reset

                int code = [self getErrorMessage:value];
                if (code != 0) {
                    if (value == SPOTAR_SAME_IMG_ERR && _imgIndex == 0 &&imgArray.count > 1) {
                        _imgIndex ++;
                        fileData = [NSMutableData dataWithData:imgArray[_imgIndex]] ;
                        [self nextFota];
                    }
                    if (_lastCode == code) {
                        _imgAready = NO;
                    }
                    [HBHttpManager reportResultCode:code];
                    _lastCode = code;
                    _isStart = NO;
                }

            }
        }
       
    }
}

- (void) didSendValueForCharacteristic: (NSNotification*)notification {
    
    NSString *content = [NSString stringWithFormat:@"writeSuccess at %@ write fileIndex:%d",[HBTools getNowTimeString],_imgIndex];

    [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"writeSuccess" andContent:content];

    if (step && step != 7) {
        HBLog(@"didSendValueForCharacteristic");
        [self doStep];
    }
}

- (void)startFOTA
{
    if (!_imgAready) {
        return;
    }
    if (!fileData) {
        
        if (!imgArray) {
            [[HBZIPManager shareInstance]archiveExistData];
        }
        if (imgArray.count > 0) {
            _imgIndex = 0;
            fileData = [NSMutableData dataWithData:imgArray[_imgIndex]] ;
        }
    }

    if (!fileData) {
        _imgAready = NO;
        _isStart = NO;
        return ;
    }
    HBLog(@"FotaStart");
    int blockSize;
    unsigned int  spiMOSI, spiMISO, spiCS, spiSCK = 0;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:@"1" forKey:@"memoryType"];
    [self gpioScannerWithString:@"P0_5" toInt:&spiMISO];
    [self gpioScannerWithString:@"P0_6" toInt:&spiMOSI];
    [self gpioScannerWithString:@"P0_3" toInt:&spiCS];
    [self gpioScannerWithString:@"P0_0" toInt:&spiSCK];
    
    self.memoryType = MEM_TYPE_SUOTA_SPI;
    self.spiMOSIAddress = spiMOSI;
    self.spiMISOAddress = spiMISO;
    self.spiCSAddress = spiCS;
    self.spiSCKAddress = spiSCK;
    
    [defaults setObject:@"P0_5" forKey:@"spiMISOAddress"];
    [defaults setObject:@"P0_6" forKey:@"spiMOSIAddress"];
    [defaults setObject:@"P0_3" forKey:@"spiCSAddress"];
    [defaults setObject:@"P0_0" forKey:@"spiSCKAddress"];
    int memoryBank = 0;
    [defaults setObject:[NSNumber numberWithInt:memoryBank] forKey:@"memoryBank"];
    self.memoryBank = memoryBank;
    
    [[NSScanner scannerWithString:@"240"] scanInt:&blockSize];
    [defaults setObject:[NSNumber numberWithInt:blockSize] forKey:@"blockSize"];
    self.blockSize = blockSize;
    
    [defaults synchronize];
    NSData *data = [HBTools coverToByteWithDataWithType:2];
    
//    if ([HBBlueToothManager shareInstance].service.req_event_characteristics)
//    {
        [[HBBlueToothManager shareInstance].currentPeripheral writeValue:data forCharacteristic:[HBBlueToothManager shareInstance].service.req_event_characteristics type:CBCharacteristicWriteWithResponse];
        NSString *content = [NSString stringWithFormat:@"write02 at %@ write fileIndex:%d",[HBTools getNowTimeString],_imgIndex];
        [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"write" andContent:content];
//    }
    _isStart = YES;
    sleep(1);
    [[BluetoothManager getInstance] startScanning];
}

- (void)nextFota
{
    self.blockSize = 240;
    if (_isNewDevice)
    {
        HBLog(@"newImgFotaStart");
        //传下一个

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            step = 1;
            if (step) {
                [self doStep];
            }
        });
    }
    else
    {
        HBLog(@"oldImgFotaStart");
        [[BluetoothManager getInstance] startScanning];
    }
}
- (void)discoverBindCharacteristics
{
    Byte a[1] = {0};
    NSData *data = [NSData dataWithBytes:&a length:1];
    NSMutableData *mudata = [NSMutableData dataWithData:data];
    Byte uuidByte[10] = {0};
    NSString *uuid =[[ [UIDevice currentDevice].identifierForVendor.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""]uppercaseString];
    
    int j= 0;
    for(int i=0;i<10;i++)
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
        
        uuidByte[j] = int_ch; ///将转化后的数放入Byte数组里
        
        j++;
    }
    
    NSData* bodyData = [NSData dataWithBytes:&uuidByte length:10];
    
    [mudata appendData:bodyData];
    
    [manager writeValue:[CBUUID UUIDWithString:SPOTA_REQUEST_IS_BIND_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_REQUEST_IS_BIND_UUID] p:manager.device  data:mudata];
    step = 0;
    
}
- (void)discoverCharacteristics{
    [manager notification:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_SERV_STATUS_UUID] p:manager.device on:YES];
    if (self.isNewDevice) {
      
    }
    else
    {
        step = 1;
        if (step) {
            HBLog(@"discoverCharacteristics");
            [self doStep];
        }
    }

}
- (void)didConnectToDevice:(NSNotification*)noti
{
    [manager discoverServices];
}


- (void) doStep {
    HBLog(@"*** Next step: %d", step);
    
    
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    if (BindperipheralName) {
        
        NSString *content = [NSString stringWithFormat:@"exceptValue at %@ step:%d fileIndex:%d",[HBTools getNowTimeString],step,_imgIndex];
        [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"step" andContent:content];
    }
    switch (step) {
        case 1: {
            // Step 1: Set memory type
            step = 0;
            expectedValue = 0x10;
            nextStep = 2;
            uploadStart = [NSDate date];
            
            int _memDevData = (self.memoryType << 24) | (self.memoryBank & 0xFF);
            HBLog(@"Sending data: %#10x", _memDevData);
            NSData *memDevData = [NSData dataWithBytes:&_memDevData length:sizeof(int)];
            [manager writeValue:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID] p:manager.device data:memDevData];
            break;
        }
            
        case 2: {
            // Step 2: Set memory params
            int _memInfoData;
            if (self.memoryType == MEM_TYPE_SUOTA_SPI) {
                _memInfoData = (self.spiMISOAddress << 24) | (self.spiMOSIAddress << 16) | (self.spiCSAddress << 8) | self.spiSCKAddress;
            } else if (self.memoryType == MEM_TYPE_SUOTA_I2C) {
                _memInfoData = (self.i2cAddress << 16) | (self.i2cSCLAddress << 8) | self.i2cSDAAddress;
            }
            //            [self debug:[NSString stringWithFormat:@"Set SPOTA_GPIO_MAP: %#010x", _memInfoData] UILog:YES];
            NSData *memInfoData = [NSData dataWithBytes:&_memInfoData length:sizeof(int)];
            
            step = 3;
            [manager writeValue:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_GPIO_MAP_UUID] p:manager.device data:memInfoData];
            break;
        }
            
        case 3: {
            // Load patch data
            //            [self debug:[NSString stringWithFormat:@"Loading data from %@", [storage.file_url absoluteString]] UILog:YES];
            //            fileData = [[NSData dataWithContentsOfURL:storage.file_url] mutableCopy];
            [self appendChecksum];
            [self debug:[NSString stringWithFormat:@"Size: %d", (int) [fileData length]] UILog:YES];
            
            // Step 3: Set patch length
            chunkSize = 20;
            
            blockStartByte = 0;
            
            step = 4;
            [self doStep];
            break;
        }
            
        case 4: {
            // Set patch length
            //UInt16 blockSizeLE = (blockSize & 0xFF) << 8 | (((blockSize & 0xFF00) >> 8) & 0xFF);
            //            [self debug:[NSString stringWithFormat:@"Set SPOTA_PATCH_LEN: %d", blockSize] UILog:YES];
            NSData *patchLengthData = [NSData dataWithBytes:&blockSize length:sizeof(UInt16)];

            step = 5;

            [manager writeValue:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_PATCH_LEN_UUID] p:manager.device data:patchLengthData];
            //[manager readValue:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_PATCH_LEN_UUID] p:manager.device];
            break;
        }
            
        case 5: {
            // Send current block in chunks of 20 bytes
            if (blockStartByte == 0)
                [self debug:@"Upload procedure started" UILog:YES];
            
            step = 0;
            expectedValue = 0x02;
            nextStep = 5;
            
            int dataLength = (int) [fileData length];
            int chunkStartByte = 0;
            sleep(self.needWaitTime);
            while (chunkStartByte < blockSize) {
                
                // Check if we have less than current block-size bytes remaining
                int bytesRemaining = blockSize - chunkStartByte;
                int currChunkSize = bytesRemaining >= chunkSize ? chunkSize : bytesRemaining;
                
                [self debug:[NSString stringWithFormat:@"Sending bytes %d to %d (%d/%d) of %d", blockStartByte + chunkStartByte + 1, blockStartByte + chunkStartByte + currChunkSize, chunkStartByte + currChunkSize, blockSize, dataLength] UILog:NO];
                
                //                double progress = (double)(blockStartByte + chunkStartByte + currChunkSize) / (double)dataLength;
                //                [self.progressView setProgress:progress];
                //                [self.progressTextLabel setText:[NSString stringWithFormat:@"%d%%", (int)(100 * progress)]];
                
                // Step 4: Send next n bytes of the patch
                char bytes[currChunkSize];
                [fileData getBytes:bytes range:NSMakeRange(blockStartByte + chunkStartByte, currChunkSize)];
                NSData *byteData = [NSData dataWithBytes:bytes length:currChunkSize];
                
                // On to the chunk
                chunkStartByte += currChunkSize;
                
                // Check if we are passing the current block
                if (chunkStartByte >= blockSize) {
                    // Prepare for next block
                    blockStartByte += blockSize;
                    
                    int bytesRemaining = dataLength - blockStartByte;
                    if (bytesRemaining == 0) {
                        nextStep = 6;
                        
                    } else if (bytesRemaining < blockSize) {
                        blockSize = bytesRemaining;
                        nextStep = 4; // Back to step 4, setting the patch length
                    }
                }
                
                [manager writeValueWithoutResponse:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_PATCH_DATA_UUID] p:manager.device data:byteData];
            }
            
            break;
        }
            
        case 6: {
            // Send SUOTA END command
            step = 0;
            expectedValue = 0x02;
            nextStep = 7;
            
            int suotaEnd = 0xFE000000;
            HBLog(@"end %#010x", suotaEnd);
            //            [self debug:[NSString stringWithFormat:@"Send SUOTA END command: %#010x", suotaEnd] UILog:YES];
            NSData *suotaEndData = [NSData dataWithBytes:&suotaEnd length:sizeof(int)];
            [manager writeValue:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID] p:manager.device data:suotaEndData];
            break;
        }
            
        case 7: {
            //            [self debug:@"Upload completed" UILog:YES];
            HBLog(@"complete");
//            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:uploadStart];
            //            [self debug:[NSString stringWithFormat:@"Elapsed time: %.3f", elapsed] UILog:YES];
            // Wait for user to confirm reboot
            //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Device has been updated" message:@"Do you wish to reboot the device?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes, reboot", nil];
            //            [alert setTag:UIALERTVIEW_TAG_REBOOT];
            //            [alert show];
            step = 8;
            int suotaEnd = 0xFD000000;
            //            [self debug:[NSString stringWithFormat:@"Send SUOTA REBOOT command: %#010x", suotaEnd] UILog:YES];
            NSData *suotaEndData = [NSData dataWithBytes:&suotaEnd length:sizeof(int)];
            if (_isNewDevice && _imgIndex == 0 && imgArray.count > 1)
            {
                HBLog(@"_isNewDevice && _imgIndex == 0 && imgArray.count > 1 doStep");
                [self doStep];
            }
            else
            {
                HBLog(@"Send SUOTA REBOOT command");
                if (BindperipheralName) {
                    NSString *content = [NSString stringWithFormat:@"REBOOT at %@ step:%d fileIndex:%d",[HBTools getNowTimeString],step,_imgIndex];
                    [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"REBOOT" andContent:content];
                }
                [manager writeValue:[manager IntToCBUUID:SPOTA_SERVICE_UUID] characteristicUUID:[CBUUID UUIDWithString:SPOTA_MEM_DEV_UUID] p:manager.device data:suotaEndData];
            }
            break;
        }
            
        case 8: {
            // Go back to overview of devices
            fileData = nil;
            if (imgArray.count > 1 && _imgIndex == 0)
                {
                    HBLog(@"imgArray.count > 1 && _imgIndex == 0");
                    _imgIndex ++;
                    fileData = [NSMutableData dataWithData:imgArray[_imgIndex]] ;
                    [self nextFota];
                    return ;
                }
                
            if (imgArray.count > 1 && _imgIndex == 1) {
                HBLog(@"imgArray.count > 1 && _imgIndex == 1");

                    fileData = nil;
                    [HBHttpManager reportResultCode:100200];
                    [[NSUserDefaults standardUserDefaults]setObject:@"1" forKey:@"needUUID"];
                    _imgIndex = 0;
                    _isStart = NO;
                    _imgAready = NO;
                return ;
                }
                
            if (imgArray.count == 1 && _imgIndex == 0) {
                HBLog(@"imgArray.count== 1 && _imgIndex == 0");
                    fileData = nil;
                    [HBHttpManager reportResultCode:100200];
                    [[NSUserDefaults standardUserDefaults]setObject:@"0" forKey:@"needUUID"];
                    _isStart = NO;
                    _imgAready = NO;
                return ;
                }
            
            break;
        }
    }
}

- (void) gpioScannerWithString:(NSString*)gpio toInt:(unsigned*)output {
    NSArray *values = [NSArray arrayWithObjects:@"0x00", @"0x01", @"0x02", @"0x03", @"0x04", @"0x05", @"0x06", @"0x07", @"0x10", @"0x11", @"0x12", @"0x13", @"0x20", @"0x21", @"0x22", @"0x23", @"0x24", @"0x25", @"0x26", @"0x27", @"0x28", @"0x29", @"0x30", @"0x31", @"0x32", @"0x33", @"0x34", @"0x35", @"0x36", @"0x37", nil];
    NSArray *titles = [NSArray arrayWithObjects:@"P0_0", @"P0_1", @"P0_2", @"P0_3", @"P0_4", @"P0_5", @"P0_6", @"P0_7", @"P1_0", @"P1_1", @"P1_2", @"P1_3", @"P2_0", @"P2_1", @"P2_2", @"P2_3", @"P2_4", @"P2_5", @"P2_6", @"P2_7", @"P2_8", @"P2_9", @"P3_0", @"P3_1", @"P3_2", @"P3_3", @"P3_4", @"P3_5", @"P3_6", @"P3_7", nil];
    
    for (int n=0; n<[values count]; n++) {
        if ([gpio isEqualToString:[titles objectAtIndex:n]]) {
            [[NSScanner scannerWithString:[values objectAtIndex:n]] scanHexInt:output];
        }
    }
}

- (void) appendChecksum {
    uint8_t crc_code = 0;
    
    const char *bytes = [fileData bytes];
    for (int i = 0; i < [fileData length]; i++) {
        crc_code ^= bytes[i];
    }
    
    //    [self debug:[NSString stringWithFormat:@"Checksum for file: %#4x", crc_code] UILog:YES];
    
    [fileData appendBytes:&crc_code length:sizeof(uint8_t)];
}

- (void) debug:(NSString*)message UILog:(BOOL)uiLog {
    if (uiLog) {
        //        self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"\n%@", message]];
        //        [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
    }
    HBLog(@"%@", message);
}

- (int) getErrorMessage:(SPOTA_STATUS_VALUES)status {
//    NSString *message;
    
    switch (status) {
        case SPOTAR_SRV_STARTED:
//            message = @"Valid memory device has been configured by initiator. No sleep state while in this mode";
            return 0;
            break;
            
        case SPOTAR_CMP_OK:
//            message = @"SPOTA process completed successfully.";
            return 0;
            break;
            
        case SPOTAR_SRV_EXIT:
//            message = @"Forced exit of SPOTAR service.";
            return 0;
            break;
            
        case SPOTAR_CRC_ERR:
//            message = @"Overall Patch Data CRC failed";
            return 100445;

            break;
            
        case SPOTAR_PATCH_LEN_ERR:
//            message = @"Received patch Length not equal to PATCH_LEN characteristic value";
            return 100005;
            break;
            
        case SPOTAR_EXT_MEM_WRITE_ERR:
//            message = @"External Mem Error (Writing to external device failed)";
            return 100006;
            break;
            
        case SPOTAR_INT_MEM_ERR:
//            message = @"Internal Mem Error (not enough space for Patch)";
            return 100007;
            break;
            
        case SPOTAR_INVAL_MEM_TYPE:
//            message = @"Invalid memory device";
            return 100008;
            break;
            
        case SPOTAR_APP_ERROR:
//            message = @"Application error";
            return 100009;
            break;
            
            // SUOTAR application specific error codes
        case SPOTAR_IMG_STARTED:
//            message = @"SPOTA started for downloading image (SUOTA application)";
            return 0;
            break;
            
        case SPOTAR_INVAL_IMG_BANK:
//            message = @"Invalid image bank";
            return 100011;
            break;
            
        case SPOTAR_INVAL_IMG_HDR:
//            message = @"Invalid image header";
            return 100012;
            break;
            
        case SPOTAR_INVAL_IMG_SIZE:
//            message = @"Invalid image size";
            return 100013;
            break;
            
        case SPOTAR_INVAL_PRODUCT_HDR:
//            message = @"Invalid product header";
            return 100014;
            break;
            
        case SPOTAR_SAME_IMG_ERR:
//            message = @"Same Image Error";
            return 100448;
            break;
            
        case SPOTAR_EXT_MEM_READ_ERR:
//            message = @"Failed to read from external memory device";
            return 100016;
            break;
            
        default:
//            message = @"Unknown error";
            return 0;
            break;
    }
    
//    return message;
}

- (BOOL)isNextImg
{
    if (_imgIndex > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
