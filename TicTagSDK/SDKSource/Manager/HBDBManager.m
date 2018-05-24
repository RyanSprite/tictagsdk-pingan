//
//  HBDBManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/10/20.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBDBManager.h"
#import <objc/runtime.h>
#import "RealReachability.h"
#import "HBDemo-Prefix.pch"
@implementation HBDBManager
+ (instancetype)shareInstance {
    static HBDBManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBDBManager alloc]init];
        [share needSendArray];
    });
    return share;
}

static sqlite3 *db;//是指向数据库的指针,我们其他操作都是用这个指针来完成

#pragma mark - 2.打开数据库

- (instancetype)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.olinone.synchronize.serialQueue", NULL);
        dispatch_queue_t dQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_set_target_queue(_queue, dQueue);
        self.callCenter = [[CTCallCenter alloc] init];
        self.callWasStarted = NO;
        __weak __typeof__(self) weakSelf = self;
        
        [self.callCenter setCallEventHandler:^(CTCall *call) {
            
            if ([[call callState] isEqual:CTCallStateIncoming] ||
                [[call callState] isEqual:CTCallStateDialing]) {
                
                if (weakSelf.callWasStarted == NO) {
                    
                    weakSelf.callWasStarted = YES;
                    
                    HBLog(@"Call was started.");
                }
                
            } else if ([[call callState] isEqual:CTCallStateDisconnected]) {
                
                if (weakSelf.callWasStarted == YES)
                {
                    weakSelf.callWasStarted = NO;
                    
                    HBLog(@"Call was ended.");
                }
            }
        }];
//        GLobalRealReachability.hostForPing = HBMQTTHost;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkChanged:)
                                                     name:kRealReachabilityChangedNotification
                                                   object:nil];

    }
    return self;
}

- (void)networkChanged:(NSNotification *)notification
{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    switch (status)
    {
        case RealStatusNotReachable:
        {
            break;
        }
            
        case RealStatusViaWiFi:
        {
            
            [self queenSend];

            
            break;
        }
            
        case RealStatusViaWWAN:
        {
            WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
            if (accessType == WWANType2G)
            {
            }
            else if (accessType == WWANType3G)
            {
            }
            else if (accessType == WWANType4G)
            {
                [self queenSend];
            }
            else
            {
            }
            
            break;
        }
            
        default:
            break;
    }}

- (void)openSqlite {
    sqlite3_shutdown();
    int err=sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    if (err == SQLITE_OK) {
//        HBLog(@"Can now use sqlite on multiple threads, using the same connection");
    } else {
        HBLog(@"setting sqlite thread safe mode to serialized failed!!! return code: %d", err);
    }
    //判断数据库是否为空,如果不为空说明已经打开
    if(db != nil) {
//        HBLog(@"数据库已经打开");
        return;
    }
    
    //获取文件路径
    NSString *str = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *strPath = [str stringByAppendingPathComponent:@"my.sqlite"];
//    HBLog(@"%@",strPath);
    //打开数据库
    //如果数据库存在就打开,如果不存在就创建一个再打开
    int result = sqlite3_open([strPath UTF8String], &db);
    //判断
    if (result == SQLITE_OK) {
        HBLog(@"Info, The database has been successfully opened");
    } else {
        HBLog(@"Info, The database open failed");
    }
    [self createTable];
}

- (void)queenSend
{
    dispatch_async(_queue, ^{
        [self continueSend];
    });
}

#pragma mark - 3.增删改查
//创建表格
- (void)createTable {
    //1.准备sqlite语句
    NSString *sqlite = [NSString stringWithFormat:@"create table if not exists 'MQTTBuffer' (mid INTEGER PRIMARY KEY AUTOINCREMENT,'content' BLOB)"];
    //2.执行sqlite语句
    char *error = NULL;//执行sqlite语句失败的时候,会把失败的原因存储到里面
    int result = sqlite3_exec(db, [sqlite UTF8String], nil, nil, &error);
    //3.sqlite语句是否执行成功
    
    if (result == SQLITE_OK) {
//        HBLog(@"创建表成功");
    } else {
        HBLog(@"Info, Create table failed");
    }
}

//添加数据
- (void)addMQTTBuffer:(NSData *)buffer {
    if (!buffer) {
        return ;
    }
    [self openSqlite];
    sqlite3_stmt *stmt = nil;

    //1.准备sqlite语句
    NSString *sqlite = [NSString stringWithFormat:@"insert into MQTTBuffer(mid) values(null)"];
    int64_t newid = sqlite3_last_insert_rowid(db);
    //2.执行sqlite语句
    NSString *sqlstr_data = [NSString stringWithFormat:@"update MQTTBuffer set content=? where mid='%lld'",newid];
    int result = sqlite3_exec(db, [sqlite UTF8String], nil, nil, nil);
    // 执行 update 语句
    int result2 = sqlite3_prepare(db, [sqlstr_data UTF8String], -1, &stmt, nil);
    if (result == SQLITE_OK && result2 == SQLITE_OK) {

        // 使用 sqlite3_bind_blob64 语句用绑定的方式插入数据，查询的时候 bytes 才正确
        sqlite3_bind_blob64(stmt, 1, [buffer bytes], [buffer length], nil);
        if (sqlite3_step(stmt) == SQLITE_DONE) {
//            HBLog(@"添加成功");
            HBLog(@"Info, The data has been successfully added");

            dispatch_async(_queue, ^{
                [self.needSendArray addObject:buffer];
                [self continueSend];
            });

            

        }
 else {
     HBLog(@"Info, The data add failed");
        }
    }
}



- (void)continueSend
{
    if (self.callWasStarted)
    {
        HBLog(@"I'm calling!");
        return ;
    }
//    SEL keepAliveSelector = NSSelectorFromString(@"keepAlive");
    if ([HBMQTTManager shareInstance].session.status != MQTTSessionStatusConnected) {
        HBLog(@"Info, MQTT disconnected");

    }
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    switch (status)
    {
        case RealStatusNotReachable:
        {
            HBLog(@"Info, Nothing to do! offlineMode");

            return ;
            break;
        }
            
        case RealStatusViaWiFi:
        {
            HBLog(@"Info, RealStatusViaWiFiMode");
            break;
        }
            
        case RealStatusViaWWAN:
        {
            
//            HBLog(@"===Take care of your money! You are in charge!");

            WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
            if (accessType == WWANType2G)
            {
                HBLog(@"Info, WeakRealStatusViaWWAN - 2G");

                return;
                
            }
            else if (accessType == WWANType3G)
            {
                HBLog(@"Info, WeakRealStatusViaWWAN - 3G");

                return;
                
            }
            else if (accessType == WWANType4G)
            {
                HBLog(@"Info, GoodRealStatusViaWWAN - 4G");
            }
            else
            {
                HBLog(@"Info, Unknown RealReachability WWAN Status, might be iOS6");
                return ;
            }
            
            break;
        }
            
        default:
            break;
    }

//    if ([[HBMQTTManager shareInstance].session respondsToSelector:keepAliveSelector]) {
//        HBLog(@"Info, MQTT startkeepAlive");
//
//        [[HBMQTTManager shareInstance].session performSelector:keepAliveSelector withObject:nil];
//        HBLog(@"Info, MQTT endkeepAlive");
//
//    }
        if ([HBMQTTManager shareInstance].session.status != MQTTSessionStatusConnected) {
            [[HBMQTTManager shareInstance].session connect];
            return ;
        }

    [self.needSendArray.copy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSData *data = obj;
        if (data.length == 0)
        {
            [self.needSendArray removeObject:obj];
        }
        if ([[HBMQTTManager shareInstance]sendMessageData:obj]) {
            [self.needSendArray removeObject:obj];
//            HBLog(@"obj = %@",obj);
            [self deleteMQTTBufferMin];
        }
    }];
}

//删除数据
- (void)deleteMQTTBufferMin
{
    //1.准备sqlite语句
    NSString *sqlite = [NSString stringWithFormat:@"delete from MQTTBuffer where mid=(select min(mid) from MQTTBuffer)"];
    //2.执行sqlite语句
    char *error = NULL;//执行sqlite语句失败的时候,会把失败的原因存储到里面
    int result = sqlite3_exec(db, [sqlite UTF8String], nil, nil, &error);
    if (result == SQLITE_OK) {
//        HBLog(@"删除数据成功");
    } else {
        HBLog(@"删除数据失败%s",error);
    }
}

////修改数据
//- (void)updataWithStu:(student *)stu {
//    //1.sqlite语句
//    NSString *sqlite = [NSString stringWithFormat:@"update student set name = '%@',sex = '%@',age = '%ld' where number = '%ld'",stu.name,stu.sex,stu.age,stu.number];
//    //2.执行sqlite语句
//    char *error = NULL;//执行sqlite语句失败的时候,会把失败的原因存储到里面
//    int result = sqlite3_exec(db, [sqlite UTF8String], nil, nil, &error);
//    if (result == SQLITE_OK) {
//        HBLog(@"修改数据成功");
//    } else {
//        HBLog(@"修改数据失败");
//    }
//}

//查询所有数据
- (NSMutableArray*)selectALLMQTTBuffer {
    [self openSqlite];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    //1.准备sqlite语句
    NSString *sqlite = [NSString stringWithFormat:@"select * from MQTTBuffer"];
    //2.伴随指针

    sqlite3_stmt *stmt = NULL;
    //3.预执行sqlite语句
    int result = sqlite3_prepare(db, sqlite.UTF8String, -1, &stmt, NULL);//第4个参数是一次性返回所有的参数,就用-1
    if (result == SQLITE_OK)
    {
        HBLog(@"Info, Query was successful");
        //4.执行n次
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            const void *op = sqlite3_column_blob(stmt, 1);
            int size = sqlite3_column_bytes(stmt, 1);
            NSData *data = [NSData dataWithBytes:op length:size];
            if (size != 0) {
                [array addObject:data];
            }
        }
    }
    else
    {
        HBLog(@"Info, Query was failed");
    }
    //5.关闭伴随指针
    sqlite3_finalize(stmt);


    return array;
}

- (void)checkArrayCache
{
    if (!_needSendArray) {
//        dispatch_queue_t queue = dispatch_queue_create("specific", DISPATCH_QUEUE_CONCURRENT);
//        void *queueSpecificKey = &queueSpecificKey;
//        void *queueContext = (__bridge void *)self;
//        // 使用dispatch_queue_set_specific 标记队列
//        dispatch_queue_set_specific(queue, queueSpecificKey, queueContext, NULL);
//
//        dispatch_async(queue, ^{
//            dispatch_block_t block = ^{
//                _needSendArray = [[NSMutableArray alloc]initWithArray:[self selectALLMQTTBuffer]];
//                [self continueSend];
//
//            };
//
//            // dispatch_get_specific就是在当前队列中取出标识,如果是在当前队列就执行，非当前队列，就同步执行，防止死锁
//            if (dispatch_get_specific(queueSpecificKey)) {
//                block();
//            } else {
//                dispatch_sync(queue, block);
//            }
//        });

        dispatch_async(_queue, ^{
            _needSendArray = [[NSMutableArray alloc]initWithArray:[self selectALLMQTTBuffer]];
            [self continueSend];
        });
    }
}

#pragma mark - 4.关闭数据库
- (void)closeSqlite {
    
    int result = sqlite3_close(db);
    if (result == SQLITE_OK) {
        HBLog(@"数据库关闭成功");
        HBLog(@"Info, Database closure success");

    } else {
        HBLog(@"Info, Database shutdown failure");
    }
}
@end
