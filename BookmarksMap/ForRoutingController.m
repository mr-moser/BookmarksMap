//
//  ForRoutingController.m
//  BookmarksMap
//
//  Created by moser on 31/03/15.
//  Copyright (c) 2015 Moser. All rights reserved.
//

#import "ForRoutingController.h"
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "AppDelegate.h"
#import "ViewController.h"

@interface ForRoutingController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) CLLocationCoordinate2D coord;

@end

@implementation ForRoutingController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Create route";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.annotations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* identifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    MapAnnotation* annotation = [[MapAnnotation alloc] init];
    
    if ([[[self.annotations objectAtIndex:indexPath.row] title] isEqualToString:@""])
        annotation.title = @"Unnamed";
    else
        annotation.title = [[self.annotations objectAtIndex:indexPath.row] title];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@",
                           indexPath.row + 1,
                           annotation.title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MapAnnotation* annotation = [[MapAnnotation alloc] init];
    annotation.title = [[self.annotations objectAtIndex:indexPath.row] title];
    CLLocation* locationOurCoreData = (CLLocation*)[[self.annotations objectAtIndex:indexPath.row] locations];
    annotation.coordinate = locationOurCoreData.coordinate;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showRoutForAnnotation" object:annotation];
}

@end
