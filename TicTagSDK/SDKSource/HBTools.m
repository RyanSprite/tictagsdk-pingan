//
//  HBTools.m
//  HBBluetooth
//
//  Created by 陈宇 on 2017/9/25.
//  Copyright © 2017年 陈宇. All rights reserved.
//

#import "HBTools.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import "HBEventManager.h"
#import "HBDemo-Prefix.pch"
@implementation HBTools
+(NSString *)transformNumber:(NSString *)str withNumberSystem:(NSString *)sys
{
    NSMutableString *mstring = [NSMutableString stringWithFormat:@"X"];
    NSString *bitString = [NSString stringWithFormat:@"0123456789ABCDEF"];
    long int tmp = [str intValue],num = [sys intValue], p, a, b;
    if(num ==2)
    {
        a = 1;
        b = 1;
    }else if (num == 8)
    {
        a = 7;
        b = 3;
    }else if (num == 16)
    {
        a = 15;
        b = 4;
    }
    else
    {
        HBLog(@"您输入的进制错误!请输入2,8,16进制!");
        return nil;
    }
    while(tmp!=0)
    {
        p=tmp&a;
        NSString *str1=[NSString stringWithFormat:@"%c",[bitString characterAtIndex:p]];
        [mstring insertString:str1 atIndex:0];
        tmp=tmp>>b;
    }
    [mstring deleteCharactersInRange:NSMakeRange([mstring length]-1, 1)];
//    if (num == 2) {
//        while (mstring.length < 16) {
//            [mstring insertString:@"0" atIndex:0];
//        }
//    }
    return mstring;
}

+ (NSString *)toDecimalSystemWithBinarySystem:(NSString *)binary
{
    int ll = 0 ;
    int  temp = 0 ;
    for (int i = 0; i < binary.length; i ++)
    {
        temp = [[binary substringWithRange:NSMakeRange(i, 1)] intValue];
        temp = temp * powf(2, binary.length - i - 1);
        ll += temp;
    }
    
    NSString * result = [NSString stringWithFormat:@"%d",ll];
    
    return result;
}


//发送数据时,16进制数－>Byte数组->NSData,加上校验码部分
+(NSData *)hexToByteToNSData:(NSString *)str{
    int j=0;
    Byte bytes[[str length]/2];
    for(int i=0;i<[str length];i++)
    {
        int int_ch;  ///两位16进制数转化后的10进制数
        unichar hex_char1 = [str characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        unichar hex_char2 = [str characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        int_ch = int_ch1+int_ch2;
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        //        if (j==[str length]/2-2) {
        //            int k=2;
        //            int_ch=bytes[0]^bytes[1];
        //            while (k
        //                int_ch=int_ch^bytes[k];
        //                k++;
        //            }
        //            bytes[j] = int_ch;
        //        }
        j++;
    }
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:[str length]/2 ];
    HBLog(@"%@",newData);
    return newData;
}
//接收数据时,NSData－>Byte数组->16进制数
+(NSString *)NSDataToByteTohex:(NSData *)data{
    Byte *bytes = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    HBLog(@"hexStr:%@",hexStr);
    return hexStr;
}

+(NSString*)coverFromStringToHexStr:(NSString*)string
{
    NSString * hexStr = [NSString stringWithFormat:@"%@",
                         [NSData dataWithBytes:[string cStringUsingEncoding:NSUTF8StringEncoding]
                                        length:strlen([string cStringUsingEncoding:NSUTF8StringEncoding])]];
    
    for(NSString * toRemove in [NSArray arrayWithObjects:@"<", @">", nil])
        hexStr = [hexStr stringByReplacingOccurrencesOfString:toRemove withString:@""];
    return hexStr;
}






//  eg： NSString *hexString = @"3e435fab9c34891f"; //16进制字符串

+(NSData*)coverFromHexStrToData:(NSString*)hexString
{
    int j=0;
    Byte bytes[hexString.length/2];  ///3ds key的Byte 数组， 128位
    for(int i=0;i<[hexString length];i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;

        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    return [[NSData alloc] initWithBytes:bytes length:hexString.length/2];
}


+(NSString*)coverFromStringToAsciiStr:(NSString*)string
{
    NSString *str = @"123456789ABCDEFG";
    const char *s = [str cStringUsingEncoding:NSASCIIStringEncoding];
    size_t len = strlen(s);
    
    NSMutableString *asciiCodes = [NSMutableString string];
    for (int i = 0; i < len; i++) {
        [asciiCodes appendFormat:@"%02x ", (int)s[i]];
    }
    return asciiCodes;
    
}


+(NSString *)stringAppendSpace:(NSString *)string
{
    if(![string isEqualToString:@""])
    {
        NSMutableString *spaceString = [[NSMutableString alloc]init];
        if(string.length > 8)  //字符串个数大于8时
        {
            NSMutableArray *spaceIndexs = [NSMutableArray new];
            for (int index = 0; index < string.length; index++) {
                NSString *tmpStr = [string substringWithRange:NSMakeRange(index, 1)];
                if ([tmpStr isEqualToString:@" "]) {
                    [spaceIndexs addObject:[NSNumber numberWithInt:index]];
                }
            }
            
            int lastIndex = (int)[[spaceIndexs lastObject] integerValue]+1;
            [spaceString appendString:[string substringWithRange:NSMakeRange(0, lastIndex)]];
            NSMutableString   *newStr =[NSMutableString stringWithString:[string substringFromIndex:lastIndex]];
            if(newStr.length == 8)
            {
                [newStr appendString:@" "];
            }
            [spaceString appendString:newStr];
            return spaceString;
        }else if(string.length == 8){  //字符串个数为8时，添加空格
            [spaceString appendString:string];
            [spaceString appendString:@" "];
            return spaceString;
        }
    }
    return  string;
    
}


+(NSString*)coverFromHexDataToStr:(NSData*)hexData
{
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[hexData bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [hexData length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength ; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
    
}


+(NSData*)coverFromStringToHexData:(NSString*)string
{
    return  [string dataUsingEncoding: NSUTF8StringEncoding];
}


+(void)coverFromBytesArrToData
{
    Byte byte[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23};
    NSData *adata = [[NSData alloc] initWithBytes:byte length:24];
    HBLog(@"字节数组转换的data 数据为: %@",adata);
}


+(void)coverFromBytesArrToHexStr
{
    NSString *aString = @"1234abcd";
    NSData *aData = [aString dataUsingEncoding: NSUTF8StringEncoding];
    
    //    NSData* aData = [[NSData alloc] init];
    Byte *bytes = (Byte *)[aData bytes];
    
    /**
     
     注: bytes  即为字节数组  类似于 Byte bts[] = {1,2,3,4,5};
     
     **/
    
    HBLog(@"%s",bytes);
    
    NSString *hexStr=@"";
    for(int i=0;i<[aData length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    
    HBLog(@"bytes 的16进制数为:%@",hexStr);
    HBLog(@"data 的16进制数为:%@",aData);
    
}

+(NSString*)coverFromDataToHexStr:(NSData *)data
{
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    return [NSString stringWithString:hexString];
}

+(UInt64)coverFromHexStrToInt:(NSString *)hexStr
{
    UInt64 mac1 =  strtoul([hexStr UTF8String], 0, 16);
    return mac1;
}

+(NSString *)coverFromIntToHex:(NSInteger)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    long long int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:nLetterValue=[[NSString alloc]initWithFormat:@"%lli",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
        
    }
    
    if(str.length == 1){
        return [NSString stringWithFormat:@"0%@",str];
    }else{
        return str;
    }
    
}


+(NSData *) setId:(int)Id {
    //用4个字节接收
    Byte bytes[4];
    bytes[0] = (Byte)(Id>>24);
    bytes[1] = (Byte)(Id>>16);
    bytes[2] = (Byte)(Id>>8);
    bytes[3] = (Byte)(Id);
    NSData *data = [NSData dataWithBytes:bytes length:4];
    return data;
}

+(NSData*)coverToByteWithDataWithType:(int)type
{
//    char *p_time = (char *)&timeInterval;
//    char str_time[4] = {0};
//    for(int i= 0 ;i < 4 ;i++)
//    {
//        str_time[i] = *p_time;
//        p_time ++;
//    }
    NSData* bodyData = nil;
    Byte value[5];
    value[0] = (type & 0xFF);
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    int time = interval;
    for(int i = 1; i <= 4; i++) {
        value[i] = (time & 0xFF);
        time >>= 8;
    }
    NSData* data = [NSData dataWithBytes:&value length:5];
    
    NSString *needUUID = [[NSUserDefaults standardUserDefaults]objectForKey:@"needUUID"];
//    HBLog(@"needUUID = %@",needUUID);
    if (needUUID.boolValue) {
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
        
        NSData* tempData = [NSData dataWithBytes:&uuidByte length:10];
        
        [mudata appendData:tempData];
        
        bodyData = [NSData dataWithData:mudata];

    }
    else
    {
        bodyData = data;
    }
//    HBLog(@"Info, GPS data added");
    return bodyData;
}

+(NSData*)coverToByteWithDataEventSuccess
{
    Byte str_time[5] = {0};
//    Byte value[5];
    NSString *address = [HBEventManager shareInstance].address;
    if (!address) {
        return nil;
    }
    for(int i = 0; i <= 3; i++) {
        const char *s = [[address substringWithRange:NSMakeRange(i*2, 2)]UTF8String];
        str_time[i] = (Byte)strtol(s, NULL, 16);
//        address >>= 8;
    }
    
    str_time[4] = (0 & 0xFF);;

    NSData* bodyData = [NSData dataWithBytes:&str_time length:sizeof(str_time)];
    return bodyData;
}

+(NSData*)coverToByteWithMessage:(NSString*)message
{
    int j=0;
    
    Byte bytes[message.length/2];
    
    for(int i=0;i<[message length];i++)
        
    {
        
        int int_ch; /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [message characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        
        int int_ch1;
        
        if(hex_char1 >= '0' && hex_char1 <='9')
            
            int_ch1 = (hex_char1-48)*16; //// 0 的Ascll - 48
        
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        
        else
            
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        
        i++;
        
        unichar hex_char2 = [message characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        
        int int_ch2;
        
        if(hex_char2 >= '0' && hex_char2 <='9')
            
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        
        else if(hex_char2 == 'A' && hex_char2 <='F')
            
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        
        else
            
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
        
        bytes[j] = int_ch; ///将转化后的数放入Byte数组里
        
        j++;
        
    }
    
//    str_time[4] = (0 & 0xFF);;
    
    NSData* bodyData = [NSData dataWithBytes:&bytes length:sizeof(bytes)];
    return bodyData;
}

+(int) setDa:(NSData*)intData
{
    int value = CFSwapInt32BigToHost(*(int*)([intData bytes]));//655650
    return value;
}

+ (NSString *)uuidString
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}

+ (NSString *)iphoneType {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
    
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
    
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
    
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
    
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
    
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
    
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone 7";
    
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";
    
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G";
    
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G";
    
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch 3G";
    
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPod Touch 4G";
    
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch 5G";
    
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G";
    
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"i386"])      return @"iPhone Simulator";
    
    if ([platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    
    return platform;
    
}

+ (NSString*)getNowHexTimeSpam
{
    NSMutableString * hexString = [[NSMutableString alloc]init];
    Byte value[5];
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    int time = interval;
    for(int i = 0; i <= 3; i++) {
        value[i] = (time & 0xFF);
        time >>= 8;
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)value[i]]];

    }
    return [NSString stringWithString:hexString];
}

+ (NSString *)getNowTimeString
{
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    
    NSString *dateTime = [formatter stringFromDate:date];
    
    return dateTime;
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        
        return nil;
        
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    
    if(err) {
        
        HBLog(@"json解析失败：%@",err);
        
        return nil;
        
    }
    
    return dic;
    
}

//第一种高低位的crc16校验
static unsigned char auchCRCHi[] = {
    0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40
};
//低位字节表
/* Table of CRC values for low–order byte */
static unsigned char auchCRCLo[] = {
    0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06, 0x07, 0xC7, 0x05, 0xC5, 0xC4, 0x04, 0xCC, 0x0C, 0x0D, 0xCD, 0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09, 0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A, 0x1E, 0xDE, 0xDF, 0x1F, 0xDD, 0x1D, 0x1C, 0xDC, 0x14, 0xD4, 0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3, 0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3, 0xF2, 0x32, 0x36, 0xF6, 0xF7, 0x37, 0xF5, 0x35, 0x34, 0xF4, 0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A, 0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38, 0x28, 0xE8, 0xE9, 0x29, 0xEB, 0x2B, 0x2A, 0xEA, 0xEE, 0x2E, 0x2F, 0xEF, 0x2D, 0xED, 0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26, 0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60, 0x61, 0xA1, 0x63, 0xA3, 0xA2, 0x62, 0x66, 0xA6, 0xA7, 0x67, 0xA5, 0x65, 0x64, 0xA4, 0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F, 0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68, 0x78, 0xB8, 0xB9, 0x79, 0xBB, 0x7B, 0x7A, 0xBA, 0xBE, 0x7E, 0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5, 0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71, 0x70, 0xB0, 0x50, 0x90, 0x91, 0x51, 0x93, 0x53, 0x52, 0x92, 0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C, 0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B, 0x99, 0x59, 0x58, 0x98, 0x88, 0x48, 0x49, 0x89, 0x4B, 0x8B, 0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C, 0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42, 0x43, 0x83, 0x41, 0x81, 0x80, 0x40
};
+ (unsigned short)crc16:(NSData*)data
{
    Byte *puchMsg = (Byte *)[data bytes];
    
    long usDataLen = [data length];
    
    unsigned char uchCRCHi = 0xFF ; /* 初始化高字节*/
    unsigned char uchCRCLo = 0xFF ; /* 初始化低字节*/
    unsigned uIndex ; /*把CRC表*/
    while (usDataLen--) /*通过数据缓冲器*/
    {
        uIndex = uchCRCHi ^ *(puchMsg++) ; /*计算CRC */
        uchCRCHi = uchCRCLo ^ auchCRCHi[uIndex] ;
        uchCRCLo = auchCRCLo[uIndex] ;
    }
    return (uchCRCHi << 8 | uchCRCLo) ;
}
@end

