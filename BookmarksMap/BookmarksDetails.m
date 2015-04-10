//
//  BookmarksDetails.m
//  BookmarksMap
//
//  Created by Moser on 29/03/15.
//  Copyright (c) 2015 Moser. All rights reserved.
//

#import "BookmarksDetails.h"
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "AppDelegate.h"
#import "AFNetworking.h"

@interface BookmarksDetails () <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate>

@property (strong, nonatomic) UILabel* labelName;
@property (nonatomic, retain) IBOutlet UITextField* textFieldForName;
@property (strong, nonatomic) CLGeocoder* geoCoder;
@property (strong, nonatomic) NSString* message;
@property (strong, nonatomic) NSString* type;
@property (retain, nonatomic) UIBarButtonItem* backButton;
@property (retain, nonatomic) UIBarButtonItem* editButton;
@property (retain, nonatomic) UIBarButtonItem* saveButton;
@property (strong, nonatomic) MapAnnotation* annotation;
@property (strong, nonatomic) UITableView* tableView;
@property (strong, nonatomic) NSArray *arrayNearbyPlacesList;
@property (assign, nonatomic) int limitPlaces;
@property (strong, nonatomic) UIButton *buttonShowNearbyPlaces;
@end

@implementation BookmarksDetails

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.limitPlaces = 20;
    
    self.backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(actionBack:)];
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(actionEdit:)];
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(actionSave:)];
    
    UIBarButtonItem* deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(actionDelete:)];
    UIBarButtonItem* flexibButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    self.navigationItem.leftBarButtonItems = @[self.backButton, flexibButton, self.saveButton, flexibButton];
    self.navigationItem.rightBarButtonItems = @[deleteButton, flexibButton, self.editButton, flexibButton];
    
    [self addLabel:@"Name" andRect:CGRectMake(100,100,100,20)];
    [self addLabel:@"Coordinate" andRect:CGRectMake(100,150,100,20)];
    [self addLabel:@"Details" andRect:CGRectMake(100,200,100,20)];
    
    self.saveButton.enabled = FALSE;
    
    [self showDetail];
    
    self.type = @"Normal";
    
    UIButton *buttonShowAnnotationInMap = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [buttonShowAnnotationInMap setTitle:@"Показать на карте" forState:UIControlStateNormal];
    [buttonShowAnnotationInMap sizeToFit];
    buttonShowAnnotationInMap.center = CGPointMake(250, 300);
    [buttonShowAnnotationInMap addTarget:self action:@selector(showInMap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonShowAnnotationInMap];
}

- (void) createTablePlaces {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(50, 350, 430, 250) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
}

- (void)showTablePlaces {
    [self createTablePlaces];
    [self getNearbyPlacesList:self.annotation.coordinate.latitude andLongitude:self.annotation.coordinate.longitude];
    self.buttonShowNearbyPlaces.hidden = YES;
}

- (void)showInMap {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showAnnotationInMap" object:self.annotation];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showDetail {
    self.annotation = [[MapAnnotation alloc] init];
    self.annotation.title = [self.annotations[self.indexAnnotation] title];
    CLLocation* location = (CLLocation*)[self.annotations[self.indexAnnotation] locations];
    self.annotation.coordinate = location.coordinate;
    
    self.geoCoder = [[CLGeocoder alloc] init];
    
    if ([self.geoCoder isGeocoding]) {
        [self.geoCoder cancelGeocode];
    }
    [self.geoCoder
     reverseGeocodeLocation:location
     completionHandler:^(NSArray *placemarks, NSError *error) {
         self.message = nil;
         if (error) {
             self.message = [error localizedDescription];
         } else {
             if ([placemarks count] > 0) {
                 MKPlacemark* placeMark = [placemarks firstObject];
                 self.message = [placeMark.addressDictionary description];
             } else {
                 self.message = @"No Placemarks Found";
             }
         }
     }];
    
    self.labelName = [[UILabel alloc] initWithFrame:CGRectMake(250,100,150,20)];
    
    if ([self.annotation.title isEqualToString:@""])
        self.annotation.title = @"Unnamed";
    else
        self.annotation.title = self.annotation.title;
    
    self.labelName.text = self.annotation.title;
    
    [self.view addSubview:self.labelName];
    
    [self addLabel:[NSString stringWithFormat:@"%f, %f", self.annotation.coordinate.latitude, self.annotation.coordinate.longitude] andRect:CGRectMake(250,150,250,20)];
    
    if ([self.annotation.title isEqualToString:@"Unnamed"]) {
        [self showTablePlaces];
        [self addLabel:@"Выберите место для названия своей закладки" andRect:CGRectMake(80,320,400,20)];
    } else {
        self.buttonShowNearbyPlaces = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.buttonShowNearbyPlaces setTitle:@"Загрузить, что находится рядом..." forState:UIControlStateNormal];
        [self.buttonShowNearbyPlaces sizeToFit];
        self.buttonShowNearbyPlaces.center = CGPointMake(270, 350);
        [self.buttonShowNearbyPlaces addTarget:self action:@selector(showTablePlaces) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.buttonShowNearbyPlaces];
    }
    
    [self addLabel:self.message andRect:CGRectMake(250,200,100,20)];
}

- (void)addLabel:(NSString*)name andRect:(CGRect)frame {
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    label.text = name;
    [self.view addSubview:label];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) actionBack:(UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) actionEdit:(UIBarButtonItem*)sender {
    if ([self.type isEqualToString:@"Normal"]) {
        self.type = @"Edit";
        self.editButton.title = @"Stop edit";
        self.textFieldForName = [[UITextField alloc] initWithFrame:CGRectMake(self.labelName.frame.origin.x, self.labelName.frame.origin.y, 150, 20)];
        self.labelName.hidden = TRUE;
        self.textFieldForName.text = self.labelName.text;
        [self.textFieldForName setBorderStyle:UITextBorderStyleLine];
        [self.view addSubview:self.textFieldForName];
        self.saveButton.enabled = TRUE;
    } else {
        self.type = @"Normal";
        self.editButton.title = @"Edit";
        self.labelName.hidden = FALSE;
        self.textFieldForName.hidden = TRUE;
        self.saveButton.enabled = FALSE;
    }
}

- (void) actionSave:(UIBarButtonItem*)sender {
    [self.annotations[self.indexAnnotation] setTitle:self.textFieldForName.text];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTitle" object:nil];
}

- (void) actionDelete:(UIBarButtonItem*)sender {
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Удаление закладки" message:@"Вы действительно хотите удалить эту закладку?" delegate:self cancelButtonTitle:@"Отмена" otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Удалить"];
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        [context deleteObject:self.annotations[self.indexAnnotation]];
        
        [self.annotations removeObjectAtIndex: self.indexAnnotation];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTitle" object:nil];
    }
}

-(void) getNearbyPlacesList:(CGFloat)latitude andLongitude:(CGFloat)longitude {
    AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
    operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [operationManager.requestSerializer setValue:@"Content-Type" forHTTPHeaderField:@"application/json"];
    
    NSString* httpAddress = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?client_id=J34BTMDL11I3UQB1MJD2CDUU0JTANGFM51YX3E4O5QAWH3JF&client_secret=LT13KM4A30TZGSRX5X2DDQW0D5RIZ3OIKYKHPZ0GBR44FGOH&v=20130815&ll=%f,%f&limit=%d", latitude, longitude, self.limitPlaces];
    
    [operationManager POST:httpAddress parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        self.arrayNearbyPlacesList = [[[responseObject objectForKey:@"response"] objectForKey:@"venues"] valueForKey:@"name"];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.limitPlaces;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Nearby places list";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* identifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if ([self.arrayNearbyPlacesList count] > 0) {
        cell.textLabel.text = [self.arrayNearbyPlacesList objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.annotation.title isEqualToString:@"Unnamed"]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.annotations[self.indexAnnotation] setTitle:[self.arrayNearbyPlacesList objectAtIndex:indexPath.row]];
        self.labelName.text = [self.arrayNearbyPlacesList objectAtIndex:indexPath.row];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTitle" object:nil];
    }
}

@end





