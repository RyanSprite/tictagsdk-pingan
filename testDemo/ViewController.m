//
//  ViewController.m
//  TicTagDemo
//
//  Created by 陈宇 on 2018/3/23.
//  Copyright © 2018年 陈宇. All rights reserved.
//

#import "ViewController.h"
#import <TicTagSDK/TTBlueToothManager.h>
#import <SVProgressHUD.h>
@interface ViewController ()
{
    NSMutableArray *peripheralDataArray;
}

@property (strong, nonatomic) TTBlueToothManager *ticSDK;
@property (weak, nonatomic) IBOutlet UILabel *tictagName;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
@property (weak, nonatomic) IBOutlet UILabel *clickTimesLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    __weak typeof(self) weakSelf = self;
    peripheralDataArray = [[NSMutableArray alloc]init];
    self.ticSDK = [TTBlueToothManager shareTTBlueToothManager];
    [self.ticSDK getiBeaconInfo:^(NSString *electric, NSString *clickTimes) {
        weakSelf.batteryLabel.text = electric;
        weakSelf.clickTimesLabel.text = clickTimes;
    }];
    if (self.ticSDK.name) {
        self.tictagName.text = self.ticSDK.name;
    }
    [self.ticSDK receiveGPSBlock:^(NSString *nowtime, CGFloat longitude, CGFloat latitude) {
        self.locationLabel.text = [NSString stringWithFormat:@"longitude = %f\nlatitude = %f",longitude,latitude];
    }];
    
    [self.ticSDK stateChanged:^(TicTagState state) {
        switch (state) {
            case State_Connected:
            {
                NSLog(@"State_Connected");
            }
                break;
            case State_DISCONNECTED:
            {
                NSLog(@"State_DISCONNECTED");
            }
                break;
            case State_DataSyncing:
            {
                NSLog(@"State_DataSyncing");
            }
            case State_Unbind:
            {
                NSLog(@"State_Unbind");
            }
                break;
            default:
                break;
        }
    }];
}

- (IBAction)startSearch:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self.ticSDK startSearchTicTagWithBlock:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        [weakSelf insertTableView:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
}
- (IBAction)disBindClick:(id)sender {
    [self.ticSDK ticTagDisBind:^{
        
    }];
    [self.ticSDK disBindTicTag];

}

#pragma mark -UIViewController 方法
//插入table数据
-(void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSArray *peripherals = [peripheralDataArray valueForKey:@"peripheral"];
    if(![peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setValue:peripheral forKey:@"peripheral"];
        [item setValue:RSSI forKey:@"RSSI"];
        [item setValue:advertisementData forKey:@"advertisementData"];
        [peripheralDataArray addObject:item];
        
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark -table委托 table delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return peripheralDataArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *item = [peripheralDataArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
    NSDictionary *advertisementData = [item objectForKey:@"advertisementData"];
    NSNumber *RSSI = [item objectForKey:@"RSSI"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //peripheral的显示名称,优先用kCBAdvDataLocalName的定义，若没有再使用peripheral name
    NSString *peripheralName;
    if ([advertisementData objectForKey:@"kCBAdvDataLocalName"]) {
        peripheralName = [NSString stringWithFormat:@"%@",[advertisementData objectForKey:@"kCBAdvDataLocalName"]];
    }else if(!([peripheral.name isEqualToString:@""] || peripheral.name == nil)){
        peripheralName = peripheral.name;
    }else{
        peripheralName = [peripheral.identifier UUIDString];
    }
    
    cell.textLabel.text = peripheralName;
    //信号和服务
    cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI:%@",RSSI];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //停止扫描
    [self.ticSDK stopSearchTicTag];
    NSDictionary *item = [peripheralDataArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
    [SVProgressHUD show];
    [self.ticSDK bindTicTagWithPeripheral:peripheral withSuccessBlock:^{
        _tictagName.text = peripheral.name;
        [SVProgressHUD showInfoWithStatus:@"BIND SUCCESS"];
        NSLog(@"BIND SUCCESS");
    } andFailure:^{
        [SVProgressHUD showInfoWithStatus:@"BIND FAIL"];
        NSLog(@"BIND FAIL");

    }];
}

- (IBAction)unbindClick:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self.ticSDK ticTagDisBind:^{
        //设备主动解绑
    }];
    if ([self.ticSDK disBindTicTag]) {
        weakSelf.batteryLabel.text = @"--";
        weakSelf.clickTimesLabel.text = @"0";
        weakSelf.tictagName.text = @"Unbind";
        weakSelf.locationLabel.text = @"--";
    };
}

@end
