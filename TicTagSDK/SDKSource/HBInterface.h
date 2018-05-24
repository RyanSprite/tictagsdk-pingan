//
//  HBInterface.h
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/27.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#ifndef HBInterface_h
#define HBInterface_h
//测试环境
#define HBMQTTHost_Test  @"1826tn8412.iask.in"
#define HBMQTTPort_Test  @"11878"
//#define CLIENT_TOPIC_Test @"data/event/dev/local"
#define CLIENT_TOPIC_Test @"data/event/dev"
#define CLIENT_userName @"hbclient"
#define CLIENT_password @"huabao308"


//生产环境
#define HBMQTTHost  @"auto.huabaotech.com"
#define HBMQTTPort  @"18830"
#define CLIENT_TOPIC @"huabao/event"

//ALILog
#define AliLogInterface @"http://gw.devops.huabao.io:3000"

//RequestVersion
#define RequestVersionInterface @"http://auto.huabaotech.com/devicemanage/fota/v1/upgrade/metadata"
//#define RequestVersionInterface @"http://192.168.10.231/devicemanage/fota/v1/upgrade/metadata"
//#define RequestVersionInterface @"http://192.168.10.85:16107/fota/v1/upgrade/metadata"

//Download
#define DownloadInterface @"http://auto.huabaotech.com/devicemanage/fota/v2/img/download"
//#define DownloadInterface @"http://192.168.10.231/devicemanage/fota/v2/img/download"

//Report
#define ReportInterface @"http://auto.huabaotech.com/devicemanage/fota/v1/upgrade/result"
//#define ReportInterface @"http://192.168.10.231/devicemanage/fota/v1/upgrade/result"

#endif /* HBInterface_h */


