//
//  HBDefine.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/22.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#ifndef HBDefine_h
#define HBDefine_h
typedef enum _status_code{
    unexpected_system_error = 400,
    Request_decryption_fail = 411,
    Request_data_invalid,
    No_need_to_update,
    Device_not_found,
    Signature_key_not_match,
    Image_need_to_download_not_exist,
    encode_key_not_match
}status_code;

typedef enum _log_status{
    immediately_log = 0,
    fast_log,
    slow_log,
    disable_log
}Log_status;

#define SUCCESS 1
#define FAIL -1

//logtime
#define LOGFastUpdateinterveal 30
#define LOGSlowUpdateinterveal 3600

#define UUID_SERVER @"edfec62e-9910-0bac-5251-d8ada6932a2f"
//request event
#define UUID_NOTIFY_REQ_EVENT @"2d86686a-53dc-25b3-0c4a-f0e10c8dee20"
//event happen
#define UUID_NOTIFY_HAP_EVENT @"15005991-b131-3396-014c-664c9867b917"
//data request
//#define UUID_NOTIFY_REQ_DATA @"87444368-648c-05a3-2d86-686a53dc25b3"
////data block
//#define UUID_NOTIFY_DATA_BLOCK @"90116709-ea21-3143-ccad-6fef7757eda5"
//transmit result
#define UUID_NOTIFY_RESULT @"8e404254-81d1-e009-8c12-327833aa4358"
#define BindPeripheralName      [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"]

//AliLogTopic
#define AliTopicBLEStatus @"bluetooth"
#define AliTopiciBeacon @"ibeacon"
#define AliTopicFota @"fota"
#define AliTopicLocation @"location"
#define AliTopicEvent @"event"
#define AliTopicOsapp     @"osapp"
#define AliTopicMovement     @"movement"
#define AliTopicMQTT    @"mqtt"



//AliLogKEY
#define AliLogKEYConnected @"connected"
#define AliLogKEYIbeacon @"ibeacon"
#define AliLogKEYData @"data"
#define AliLogKEYStarted @"started"
#define AliLogKEYGps @"gps"
#define AliLogKEYMove @"move"
#define AliLogKEYEvent @"event"

#endif /* HBDefine_h */
