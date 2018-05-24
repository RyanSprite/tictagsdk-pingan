//
//  HBUploadManager.m
//  BabyBluetoothAppDemo
//
//  Created by 陈宇 on 2017/10/18.
//  Copyright © 2017年 刘彦玮. All rights reserved.
//

#import "HBUploadManager.h"

@interface HBUploadManager()
@end
@implementation HBUploadManager
+ (instancetype)shareInstance {
    static HBUploadManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBUploadManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
//        NSString* log_mode = [[NSUserDefaults standardUserDefaults]objectForKey:@"log_mode"];
//        switch (log_mode.intValue) {
//            case immediately_log:
//            {
//                self.logStatus = immediately_log;
//            }
//                break;
//            case fast_log:
//            {
//                self.logStatus = fast_log;
//            }
//                break;
//            case slow_log:
//            {
//                self.logStatus = slow_log;
//
//            }
//                break;
//            case disable_log:
//            {
//                self.logStatus = disable_log;
//            }
//                break;
//
//            default:
//                break;
//        }
        self.logStatus = fast_log;
//        self.logStatus = immediately_log;

    }
    return self;
}

- (void)postLogWithTopic:(NSString*)topic andKey:(NSString*)key andDictionary:(NSDictionary*)dictionary
{
    switch (_logStatus) {
        case disable_log:
        {
            
        }
            break;
        case immediately_log:
        {
            if (![self isValid]) {
                if (_isConnecting) {
                    return ;
                }
                _isConnecting = YES;
                [HBHttpManager getAliAccessSuccessBlock:^(id result, id data) {
                    if (data[@"SecurityToken"]) {
                        self.client = [[LogClient alloc] initWithApp: @"cn-shanghai.log.aliyuncs.com" accessKeyID:data[@"AccessKeyId"] accessKeySecret:data[@"AccessKeySecret"] projectName:@"log-tt-sdk"];
                        [self.client SetToken:data[@"SecurityToken"]];
                        self.lastExpiration = data[@"Expiration"];
                        _isConnecting = NO;
                        
                        [self reporTAtIntervals];
                        
                    }
                    else
                    {
//                        [SVProgressHUD showInfoWithStatus:data];
                        _isConnecting = NO;
                    }
                    
                    
                } failedBlock:^(id result, id data) {
                    
                }];
                return ;
            }

            if (!_client) {
                return ;
            }
            NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
            if (!BindperipheralName) {
                return;
            }
            LogGroup *logGroup = [[LogGroup alloc] initWithTopic: topic andSource:BindperipheralName];
            Log *log1 = [[Log alloc] init];
            for (NSString *key in dictionary) {
                NSString *content = [dictionary objectForKey:key];
                [log1 PutContent: content withKey: key];
            }
            [logGroup PutLog:log1];
            
            [_client PostLog:logGroup logStoreName: @"logstore-tt-sdk" call:^(NSURLResponse* _Nullable response,NSError* _Nullable error) {
                if (error != nil) {
                    
                }
                else
                {
                    HBLog(@"%@ uploadSuccess",key);
                }
            }];
        }
            break;
        case fast_log:
        case slow_log:
        {
            
            NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
            if (!BindperipheralName) {
                return;
            }
            if (!self.logGroupArray) {
                self.logGroupArray = [[NSMutableArray alloc]init];
            }
            BOOL hasInit = NO;
            if ([_logGroupArray count] == 0) {
                LogGroup *logGroup = [[LogGroup alloc] initWithTopic: topic andSource:BindperipheralName];
                [self.logGroupArray addObject:logGroup];
                
            }
            for (LogGroup *_logGroup in _logGroupArray) {
                NSString *json = [_logGroup GetJsonPackage];
                NSDictionary *dic = [HBTools dictionaryWithJsonString:json];
                if ([dic[@"__topic__"]isEqualToString:topic]) {
                    Log *log1 = [[Log alloc] init];
                    for (NSString *key in dictionary) {
                        [log1 PutContent: dictionary[key] withKey: key];
                    }
                    [_logGroup PutLog:log1];
                    hasInit = YES;
                }
            }
            if (hasInit == NO) {
                LogGroup *logGroup = [[LogGroup alloc] initWithTopic: topic andSource:BindperipheralName];
                [_logGroupArray addObject:logGroup];
                Log *log1 = [[Log alloc] init];
                for (NSString *key in dictionary) {
                    [log1 PutContent: dictionary[key] withKey: key];
                }
                [logGroup PutLog:log1];
            }
            
        }
            break;
            
        default:
            break;
    }
    
}

- (void)postLogWithTopic:(NSString*)topic andKey:(NSString*)key andContent:(NSString*)content
{
    switch (_logStatus) {
        case disable_log:
        {
            
        }
            break;
        case immediately_log:
        {
            if (![self isValid]) {
                [HBHttpManager getAliAccessSuccessBlock:^(id result, id data) {
                    if (data[@"SecurityToken"]) {
                        self.client = [[LogClient alloc] initWithApp: @"cn-shanghai.log.aliyuncs.com" accessKeyID:data[@"AccessKeyId"] accessKeySecret:data[@"AccessKeySecret"] projectName:@"log-tt-sdk"];
                        [self.client SetToken:data[@"SecurityToken"]];
                        self.lastExpiration = data[@"Expiration"];
                        [self postLogWithTopic:topic andKey:key andContent:content];
                    }
                    else
                    {
//                        [SVProgressHUD showInfoWithStatus:data];
                    }
                    
                    
                } failedBlock:^(id result, id data) {
                    
                }];
            }
            if (!_client) {
                return ;
            }
            NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
            if (!BindperipheralName) {
                return;
            }
            LogGroup *logGroup = [[LogGroup alloc] initWithTopic: topic andSource:BindperipheralName];
            Log *log1 = [[Log alloc] init];
            [log1 PutContent: content withKey: key];
            [logGroup PutLog:log1];
            [_client PostLog:logGroup logStoreName: @"logstore-tt-sdk" call:^(NSURLResponse* _Nullable response,NSError* _Nullable error) {
                if (error != nil) {
                    
                }
                else
                {
                    HBLog(@"%@ uploadSuccess",key);
                }
            }];
        }
            break;
        case fast_log:
        case slow_log:
        {

            NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
            if (!BindperipheralName) {
                return;
            }
            if (!_logGroupArray) {
                _logGroupArray = [[NSMutableArray alloc]init];
                LogGroup *logGroup = [[LogGroup alloc] initWithTopic: topic andSource:BindperipheralName];
                [_logGroupArray addObject:logGroup];
            }
            BOOL hasInit = NO;
            for (LogGroup *_logGroup in _logGroupArray) {
                NSString *json = [_logGroup GetJsonPackage];
                NSDictionary *dic = [HBTools dictionaryWithJsonString:json];
                if ([dic[@"__topic__"]isEqualToString:topic]) {
                    Log *log1 = [[Log alloc] init];
                    [log1 PutContent: content withKey: key];
                    [_logGroup PutLog:log1];
                    hasInit = YES;
                }
            }
            if (hasInit == NO) {
                LogGroup *logGroup = [[LogGroup alloc] initWithTopic: topic andSource:BindperipheralName];
                [_logGroupArray addObject:logGroup];
                Log *log1 = [[Log alloc] init];
                [log1 PutContent: content withKey: key];
                [logGroup PutLog:log1];
            }
          

        }
            break;
            
        default:
            break;
    }

}

- (void)postLogWithTopic:(NSString*)topic andKey:(NSString*)key andOperation:(NSString*)operation
{
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSSS"];
    NSString *DateTime = [formatter stringFromDate:date];
    
    //获取所有信息字典
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    //    HBLog(@"%@",infoDictionary);
    //    CFShow((__bridge CFTypeRef)(infoDictionary));
    
    NSString *executableFile = [infoDictionary objectForKey:(NSString *)kCFBundleExecutableKey]; //获取项目名称
    
    //    HBLog(@"executableFile == %@",executableFile);
    
    NSString *version = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]; //获取项目版本号
    //    HBLog(@"version .. %@",version);
    //
    //    // app名称
    //    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    //    HBLog(@"app_Name == %@",app_Name);
    //
    //    // app版本
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    //    HBLog(@"app_Version .. %@",app_Version);
    //    // app build版本
    //    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    //    HBLog(@"app_build >> %@",app_build);
    NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString* phoneType = [HBTools iphoneType];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = true;
    
    CGFloat batteryLevel = [[UIDevice currentDevice]batteryLevel];
    
    NSString *str = [NSString stringWithFormat:@"%@ %@[390:77604] >>> %@ phoneVersion:%@ phoneType:%@ batteryLevel:%@ AppVersion:%@ Build:%@\n",DateTime,executableFile,operation,phoneVersion,phoneType,(batteryLevel == -1?@"Unknown":[NSString stringWithFormat:@"%f",batteryLevel]),app_Version,version];
    
    [self postLogWithTopic:topic andKey:key andContent:str];
    
}

- (int)getTimeinterval:(NSString*)expirationString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *date = [formatter dateFromString:expirationString];
    
    int expiration =[date timeIntervalSince1970];
    
    int now =[[NSDate new] timeIntervalSince1970];
    
    return expiration-now;
}

- (BOOL)isValid
{
    if ([self getTimeinterval:self.lastExpiration] > 0) {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)setLogStatus:(Log_status)logStatus
{
    _logStatus = logStatus;
    switch (logStatus) {
        case disable_log:
        {
                
        }
            break;
        case immediately_log:
        {
            
        }
            break;
        case fast_log:
        {
            if (_timer) {
                [_timer invalidate];
            }
            if (_timer.timeInterval != LOGFastUpdateinterveal) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:LOGFastUpdateinterveal target:self selector:@selector(reporTAtIntervals) userInfo:nil repeats:YES];
                [_timer fire];
                
            }
        }
        case slow_log:
        {
            if (_timer) {
                [_timer invalidate];
                
            }
            if (_timer.timeInterval != LOGSlowUpdateinterveal) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:LOGSlowUpdateinterveal target:self selector:@selector(reporTAtIntervals) userInfo:nil repeats:YES];
                [_timer fire];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)reporTAtIntervals
{
    if (![self isValid]) {
        if (_isConnecting) {
            return ;
        }
        _isConnecting = YES;
        [HBHttpManager getAliAccessSuccessBlock:^(id result, id data) {
            if (data[@"SecurityToken"]) {
                self.client = [[LogClient alloc] initWithApp: @"cn-shanghai.log.aliyuncs.com" accessKeyID:data[@"AccessKeyId"] accessKeySecret:data[@"AccessKeySecret"] projectName:@"log-tt-sdk"];
                [self.client SetToken:data[@"SecurityToken"]];
                self.lastExpiration = data[@"Expiration"];
                _isConnecting = NO;
                [self reporTAtIntervals];
            }
            else
            {
//                [SVProgressHUD showInfoWithStatus:data];
                _isConnecting = NO;
            }
            
            
        } failedBlock:^(id result, id data) {
            
        }];
        return ;
    }
    if (!_client) {
        return;
    }
    for (LogGroup *_logGroup in _logGroupArray) {
        if (_logGroup) {
            [_client PostLog:_logGroup logStoreName: @"logstore-tt-sdk" call:^(NSURLResponse* _Nullable response,NSError* _Nullable error) {
                if (error != nil) {
                    HBLog(@"error = %@ reporTAtIntervals",error);
                    [self performSelector:@selector(reporTAtIntervals) withObject:nil afterDelay:100];
                }
                else
                {
                    [_logGroupArray removeObject:_logGroup];
                }
            }];
        }
    }
   

}
@end
