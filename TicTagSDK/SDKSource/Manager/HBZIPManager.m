//
//  HBZIPManager.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/12/28.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBZIPManager.h"
#import "SSZipArchive.h"
#import "HBDemo-Prefix.pch"
@implementation HBZIPManager
+ (instancetype)shareInstance {
    static HBZIPManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[HBZIPManager alloc]init];
        
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

- (void)archiveData:(NSData*)data
{
    NSFileManager* fileMgr = [NSFileManager defaultManager];

    NSArray *arrDocumentPaths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    
    NSString *documentPath=[arrDocumentPaths objectAtIndex:0];
    
    NSString *destinationPath = [documentPath stringByAppendingString:@"/FotaIMG"]; ;

    NSString *pStr = [documentPath stringByAppendingString:@"/Fota.zip"];
    if ([fileMgr fileExistsAtPath:destinationPath]) {
        [fileMgr createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    [data writeToFile:pStr atomically:YES];
    
    NSString *zipPath = pStr;
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {

    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        
        NSArray* tempArray = [fileMgr contentsOfDirectoryAtPath:destinationPath error:nil];
        
        [self.imgArray removeAllObjects];
        
        for (NSString* fileName in tempArray) {
            
            BOOL flag = YES;
            
            NSString* fullPath = [destinationPath stringByAppendingPathComponent:fileName];
            
            if ([fileMgr fileExistsAtPath:fullPath isDirectory:&flag]) {
                
                if (!flag) {
                    
                }
                else
                {
                    NSArray* subtempArray = [[fileMgr contentsOfDirectoryAtPath:fullPath error:nil]sortedArrayUsingSelector:@selector(compare:)];

                    for (NSString* subfileName in subtempArray) {
                        NSString* subPath = [fullPath stringByAppendingPathComponent:subfileName];
                        if ([subfileName hasPrefix:@"."]||[subfileName hasPrefix:@"_"]) {
                            continue ;
                        }
                        HBLog(@"subPath = %@",subPath);

                        NSData *data = [NSData dataWithContentsOfFile:subPath];
                        [self.imgArray addObject:data];
                    }
                }
                
                if ([fileMgr removeItemAtPath:fullPath error:NULL]) {
                    
                    HBLog(@"achive successfully and removed floder");
                }
                if ([fileMgr removeItemAtPath:pStr error:NULL]) {

                    NSString *BindperipheralName = [[NSUserDefaults standardUserDefaults]objectForKey:@"BindperipheralName"];
                    if (BindperipheralName) {
                        
                        NSString *content = [NSString stringWithFormat:@"achive successfully%@ version:%@",[HBTools getNowTimeString],[HBHttpManager shareInstance].serverFwVersion];
                        [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"achive" andContent:content];
                    }
                }
            }
        }
        
        if (error) {
            
            NSString *content = [NSString stringWithFormat:@"achive error:%@ time:%@ version:%@",error,[HBTools getNowTimeString],[HBHttpManager shareInstance].serverFwVersion];

            [[HBUploadManager shareInstance] postLogWithTopic:AliTopicFota andKey:@"achive" andContent:content];

            return ;
        }
        [FOTAUpDateManager shareInstance].imgAready = YES;
        
        [FOTAUpDateManager shareInstance].imgArray = self.imgArray;
        
    }];

    
//    BOOL isDir = YES;
//
//    BOOL isExist = [fileMgr fileExistsAtPath:destinationPath isDirectory:&isDir];
//    if (isExist) {
//        if (isDir) {
//            NSArray * dirArray = [fileMgr contentsOfDirectoryAtPath:destinationPath error:nil];
//            NSString * subPath = nil;
//            for (NSString * str in dirArray)
//            {
//                subPath  = [destinationPath stringByAppendingPathComponent:str];
//                BOOL issubDir = NO;
//                [fileMgr fileExistsAtPath:subPath isDirectory:&issubDir];
////                [self showAllFileWithPath:subPath];
//            }
//        }else{
//
//        }
//    }
//

}

- (void)archiveExistData
{
    NSArray *arrDocumentPaths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    
    NSString *documentPath=[arrDocumentPaths objectAtIndex:0];
    
    NSString *pStr = [documentPath stringByAppendingString:@"/Fota.zip"];
    
    NSString *zipPath = pStr;
    
    NSString *destinationPath = documentPath;
    
    [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    
    NSArray* tempArray = [fileMgr contentsOfDirectoryAtPath:destinationPath error:nil];
    
    [self.imgArray removeAllObjects];
    
    for (NSString* fileName in tempArray) {
        
        BOOL flag = YES;
        
        NSString* fullPath = [destinationPath stringByAppendingPathComponent:fileName];
        
        if ([fileMgr fileExistsAtPath:fullPath isDirectory:&flag]) {
            
            if (!flag) {
                
                HBLog(@"fullPath = %@",fullPath);
                NSData *data = [NSData dataWithContentsOfFile:fullPath];
                [self.imgArray addObject:data];
            }
            
        }
        
    }
    
    [FOTAUpDateManager shareInstance].imgAready = YES;
    
    [FOTAUpDateManager shareInstance].imgArray = self.imgArray;
    
}

- (NSMutableArray*)imgArray
{
    if (!_imgArray) {
        _imgArray = [[NSMutableArray alloc]init];
    }
    return _imgArray;
}


@end
