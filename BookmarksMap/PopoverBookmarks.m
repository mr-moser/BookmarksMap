//
//  PopoverBookmarks.m
//  BookmarksMap
//
//  Created by Moser on 29/03/15.
//  Copyright (c) 2015 Moser. All rights reserved.
//

#import "PopoverBookmarks.h"
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import "BookmarksDetails.h"

@interface PopoverBookmarks () <UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) CLLocationCoordinate2D coord;
@property (strong, nonatomic) UIPopoverController* popoverForBookmarksDetails;

@end

@implementation PopoverBookmarks

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable)
                                                 name:@"reloadTitle"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) reloadTable {
    [self.tableView reloadData];
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
        
    CLLocation* locationOurCoreData = (CLLocation*)[[self.annotations objectAtIndex:indexPath.row] locations];
    annotation.coordinate = locationOurCoreData.coordinate;
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@ <%f, %f>",
                                indexPath.row + 1,
                                annotation.title,
                                annotation.coordinate.latitude,
                                annotation.coordinate.longitude];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BookmarksDetails * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"BookmarksDetail"];
    vc.preferredContentSize = CGSizeMake(500, 500);
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    vc.annotations = self.annotations;
    vc.indexAnnotation = indexPath.row;
}

@end