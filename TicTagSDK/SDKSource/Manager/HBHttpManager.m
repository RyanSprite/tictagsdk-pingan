//
//  HBHttpManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/11/29.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBHttpManager.h"
#import "HBDemo-Prefix.pch"
@implementation HBHttpManager
+ (instancetype)shareInstance {
    static HBHttpManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBHttpManager alloc]init];

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

+ (void)getAliAccessSuccessBlock:(HBMessageHandleCallBack)successed
         failedBlock:(HBMessageHandleCallBack)failed
{
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    [session GET:AliLogInterface parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successed(@"success",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(@"fail",error);
    }];
}

- (NSDictionary *)header
{
    _header = @{@"pv":@"1.0",
                  @"enc":@"0",
                    @"ev":@"01",
                    @"sig":@"0",
                    @"msgid":[[[HBTools uuidString]  stringByReplacingOccurrencesOfString:@"-" withString:@""]uppercaseString]
                    };
    return _header;
}

+ (void)vs_sendAPI:(NSString*)apiUrl
              parm:(NSDictionary*)parm
      successBlock:(HBMessageHandleCallBack)successed
       failedBlock:(HBMessageHandleCallBack)failed
     completeBlock:(HBMessageHandleCallBack)completed
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;

    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSDictionary *parmDic = @{@"header":[self convertToJsonData:[HBHttpManager shareInstance].header],
                          @"body":[self convertToJsonData:parm]
                          };
    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager POST:apiUrl parameters:parmDic progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        successed(@"success",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(@"fail",error);
    }];
}

+(void)checkImgVersion
{
    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
    if (BindperipheralName) {
        if ([[NSUserDefaults standardUserDefaults]objectForKey:@"fwVersion"]) {
            NSString *fwVersion = [[NSUserDefaults standardUserDefaults]objectForKey:@"fwVersion"];
            NSString *hwVersion = [[NSUserDefaults standardUserDefaults]objectForKey:@"hwVersion"];
            if (!hwVersion) {
                return;
            }
            if (!fwVersion) {
                return;
            }
            NSString *did = [BindperipheralName substringFromIndex:3];
            [HBHttpManager shareInstance].did = did;
            NSDictionary *parm = @{@"did":did,
                                   @"hwv":hwVersion,
                                   @"fwv":fwVersion,
                                   };
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSDictionary *parmDic = @{@"header":[self convertToJsonData:[HBHttpManager shareInstance].header],
                              @"body":[self convertToJsonData:parm]
                              };
//    HBLog(@"baseUrl = %@,parm =%@",RequestVersionInterface,parmDic);
    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager POST:RequestVersionInterface parameters:parmDic progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        HBLog(@"responseObject = %@",responseObject);
        NSDictionary *data =  responseObject;
        NSDictionary *parm = @{@"did":did,
                               @"sign":data[@"body"][@"sig"],
                               @"fwid":data[@"body"][@"fwid"],
                               };
        [HBHttpManager shareInstance].rid = data[@"header"][@"rid"];
        [HBHttpManager shareInstance].serverFwVersion = data[@"body"][@"fwuv"];
        [HBHttpManager shareInstance].crc = data[@"body"][@"fwcrc"];

        
        [HBHttpManager  downloadImg:parm];
        [[NSUserDefaults standardUserDefaults]setObject:[HBHttpManager shareInstance].rid forKey:@"rid"];
        [[NSUserDefaults standardUserDefaults]setObject:[HBHttpManager shareInstance].serverFwVersion forKey:@"serverFwVersion"];
        [[NSUserDefaults standardUserDefaults]setObject:[HBHttpManager shareInstance].did forKey:@"did"];
        [[NSUserDefaults standardUserDefaults]setObject:[HBHttpManager shareInstance].crc forKey:@"crc"];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    
        NSHTTPURLResponse *response = error.userInfo[@"com.alamofire.serialization.response.error.response"];
        switch (response.statusCode) {
            case unexpected_system_error:
            {
                HBLog(@"unexpected_system_error");
            }
                break;
            case Request_decryption_fail:
            {
                HBLog(@"Request_decryption_fail");

            }
                break;
            case Request_data_invalid:
            {
                HBLog(@"Request_data_invalid");

            }
                break;
            case No_need_to_update:
            {
                HBLog(@"No_need_to_update");

            }
                break;
            case Device_not_found:
            {
                HBLog(@"Device_not_found");

            }
                break;
            case Signature_key_not_match:
            {
                HBLog(@"Signature_key_not_match");

            }
                break;
            case Image_need_to_download_not_exist:
            {
                HBLog(@"Image_need_to_download_not_exist");

            }
                break;
            case encode_key_not_match:
            {
                HBLog(@"encode_key_not_match");
            }
                break;
            default:
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5*60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [HBHttpManager checkImgVersion];
                });
                break;
        }    }];
            
        }
    }

}
- (void)sf{

}
+ (NSString *)convertToJsonData:(NSDictionary *)dict

{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
//        HBLog(@"%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
    
}


+(void)downloadImg:(NSDictionary*)dic
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSDictionary *parmDic = @{@"header":[self convertToJsonData:[HBHttpManager shareInstance].header],
                              @"body":[self convertToJsonData:dic]
                              };
    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager POST:DownloadInterface parameters:parmDic progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        successed(@"success",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSData *fileData = error.userInfo[@"com.alamofire.serialization.response.error.data"];
        
//        HBLog(@"data = %@",fileData);
        NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
        if (BindperipheralName) {

            NSString *content = [NSString stringWithFormat:@"download at %@ version:%@",[HBTools getNowTimeString],[HBHttpManager shareInstance].serverFwVersion];
            [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"download" andContent:content];
        }
        unsigned short crccode = [HBTools crc16:fileData];
        if ( [HBTools coverFromHexStrToInt:[HBHttpManager shareInstance].crc] != crccode)
        {
            
            NSString *content = [NSString stringWithFormat:@"crc error at %@ version:%@",[HBTools getNowTimeString],[HBHttpManager shareInstance].serverFwVersion];
            [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"crc" andContent:content];
            return ;
        }
        [[HBZIPManager shareInstance]archiveData:fileData];
    }];
}



+ (void)reportResultCode:(int)code
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    HBHttpManager *selfmanager = [HBHttpManager shareInstance];
    if (selfmanager.did == nil ||selfmanager.rid == nil ||selfmanager.serverFwVersion == nil) {
        selfmanager.did = [[NSUserDefaults standardUserDefaults]objectForKey:@"did"];
        selfmanager.rid = [[NSUserDefaults standardUserDefaults]objectForKey:@"rid"];
        selfmanager.serverFwVersion = [[NSUserDefaults standardUserDefaults]objectForKey:@"serverFwVersion"];
    }
    if (code == 100200) {
        [[NSUserDefaults standardUserDefaults]setObject:[HBHttpManager shareInstance].serverFwVersion forKey:@"fwVersion"];
        [[NSNotificationCenter defaultCenter]postNotificationName:FWUPDATENotification object:[HBHttpManager shareInstance].serverFwVersion];
    }
    NSString *content = [NSString stringWithFormat:@"code at %@ value:%d time:%@",[HBTools getNowTimeString],code,BindPeripheralName];

    [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"code" andContent:content];

    NSDictionary *parm = @{@"did":selfmanager.did,
                           @"rid":selfmanager.rid,
                           @"urc":[NSString stringWithFormat:@"%zi",code]
                           };
    NSDictionary *parmDic = @{@"header":[self convertToJsonData:[HBHttpManager shareInstance].header],
                              @"body":[self convertToJsonData:parm]
                              };
    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [manager POST:ReportInterface parameters:parmDic progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
//        HBLog(@"responseObject = %@",responseObject);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        HBLog(@"error = %@",error);

    }];
}

@end
