//
//  ViewController.m
//  BookmarksMap
//
//  Created by Moser on 28/03/15.
//  Copyright (c) 2015 Moser. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "AppDelegate.h"
#import "PopoverBookmarks.h"
#import "ForRoutingController.h"

@interface ViewController () <MKMapViewDelegate, UIPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView* mapView;
@property (weak, nonatomic) UIPopoverController* myPopover;
@property (assign, nonatomic) CLLocationCoordinate2D tempPointAnnototion;
@property (assign, nonatomic) BOOL isShowAnnotations;
@property (strong, nonatomic) MKMapItem* destination;
@property (strong, nonatomic) UIPopoverController* popoverForRouting;
@property (strong, nonatomic) UIPopoverController* popoverForBookmarks;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonRoute;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonBookmarks;
@property (strong, nonatomic) NSString* type;
@property (strong, nonatomic) NSMutableArray* resultForSelectOutCoreData;
@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    self.isShowAnnotations = false;
    self.type = @"Normal";
    
    UILongPressGestureRecognizer* longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longGesture.minimumPressDuration = 1;
    [self.view addGestureRecognizer:longGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showAnnotationInMap:)
                                                 name:@"showAnnotationInMap"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showRoutForAnnotation:)
                                                 name:@"showRoutForAnnotation"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTitle)
                                                 name:@"reloadTitle"
                                               object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Create routing
- (void)getDirections {
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = self.destination;
    request.requestsAlternateRoutes = NO;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error) {
             NSLog(@"%@", [error description]);
             UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Ошибка создания маршрута" message:@"" delegate:self cancelButtonTitle:@"На нет и суда нет" otherButtonTitles: nil];
             [alert show];
         } else {
             [self showRoute:response];
         }
     }];
}
-(void)showRoute:(MKDirectionsResponse *)response {
    for (MKRoute *route in response.routes) {
        [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
        for (MKRouteStep *step in route.steps) {
            NSLog(@"%@", step.instructions);
        }
    }
}
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.strokeColor = [UIColor blueColor];
    renderer.lineWidth = 5.0;
    return renderer;
}

#pragma mark - Show routing
- (void) showRoutForAnnotation:(NSNotification*)notification {
    [self.popoverForRouting dismissPopoverAnimated:YES];
    MapAnnotation* annotationForNotification = [notification object];
    
    MKMapRect zoomRect = MKMapRectNull;

    CLLocationCoordinate2D location = annotationForNotification.coordinate;
    MKMapPoint center = MKMapPointForCoordinate(location);
    static double delta = 20000;
    MKMapRect rect = MKMapRectMake(center.x - delta, center.y - delta, delta * 2, delta * 2);

    CLLocationCoordinate2D location2 = self.mapView.userLocation.coordinate;
    MKMapPoint center2 = MKMapPointForCoordinate(location2);
    MKMapRect rect2 = MKMapRectMake(center2.x - delta, center2.y - delta, delta * 2, delta * 2);

    zoomRect = MKMapRectUnion(rect, rect2);

    zoomRect = [self.mapView mapRectThatFits:zoomRect];
    [self.mapView setVisibleMapRect:zoomRect
                        edgePadding:UIEdgeInsetsMake(50, 50, 50, 50)
                           animated:YES];
    
    CLLocationCoordinate2D coordinate = annotationForNotification.coordinate;
    MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    self.destination = [[MKMapItem alloc] initWithPlacemark:placemark];
    
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if (annotation.coordinate.latitude != annotationForNotification.coordinate.latitude && annotation.coordinate.longitude != annotationForNotification.coordinate.longitude)
            [self.mapView removeAnnotation:annotation];
    }
    [self getDirections];
    self.buttonRoute.title = @"Clear route";
    self.type = @"Clear route";
}

#pragma mark - Show Routing popover
-  (IBAction) actionAddPopover:(UIBarButtonItem*)sender {
    ForRoutingController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ForRoutingController"];
    vc.annotations = self.resultForSelectOutCoreData;
    if ([self.type isEqualToString:@"Normal"]) {
        vc.preferredContentSize = CGSizeMake(300, 500);
        UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
        UIPopoverController* popover = [[UIPopoverController alloc] initWithContentViewController:nav];
        popover.delegate = self;
        self.popoverForRouting = popover;
        [popover presentPopoverFromBarButtonItem:sender
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
    } else {
        self.buttonRoute.title = @"Route";
        self.type = @"Normal";
        for (id <MKAnnotation> annotation in self.mapView.annotations) {
            [self.mapView removeAnnotation:annotation];
        }
        [self loadAnnotationsOutCoreData];
        [self showAllAnnotation:nil];
        [self.mapView removeOverlays:self.mapView.overlays];
    }
}

#pragma mark - Show Bookmarks popover
-  (IBAction) actionAddBookmarksPopover:(UIBarButtonItem*)sender {
    PopoverBookmarks* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"popover"];
    vc.annotations = self.resultForSelectOutCoreData;
    vc.preferredContentSize = CGSizeMake(300, 500);
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UIPopoverController* popover = [[UIPopoverController alloc] initWithContentViewController:nav];
    popover.delegate = self;
    self.popoverForBookmarks = popover;
    [popover presentPopoverFromBarButtonItem:sender
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:YES];
}

#pragma mark - Load Annotations Out CoreData
- (void)loadAnnotationsOutCoreData {
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* description = [NSEntityDescription entityForName:@"Annotation" inManagedObjectContext:self.context];
    [request setEntity:description];
    NSError* requestError = nil;
    NSArray* result = [self.context executeFetchRequest:request error:&requestError];
    if (requestError) {
        NSLog(@"Error %@", [requestError localizedDescription]);
    }
    self.resultForSelectOutCoreData = [[NSMutableArray alloc] initWithArray:result];
    
    for (int i=0; i< [result count]; i++) {
        MapAnnotation* annotation = [[MapAnnotation alloc] init];
        annotation.title = [[result objectAtIndex:i] title];
        CLLocation* locationOurCoreData = (CLLocation*)[[result objectAtIndex:i] locations];
        annotation.coordinate = locationOurCoreData.coordinate;
        [self.mapView addAnnotation:annotation];
    }
}

-(void)reloadTitle {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self loadAnnotationsOutCoreData];
}

#pragma mark - Long Press
- (void)handleLongPress:(UILongPressGestureRecognizer*)tapGesture {
    if (tapGesture.state == UIGestureRecognizerStateBegan) {
        self.tempPointAnnototion = [self.mapView convertPoint:[tapGesture locationInView:self.view] toCoordinateFromView:self.view];
        
        UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Новая закладка" message:@"Введите название закладки" delegate:self cancelButtonTitle:@"Отмена" otherButtonTitles: nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert addButtonWithTitle:@"Сохранить"];
        [alert show];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // if you have multiple segues, check segue.identifier
    self.myPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
}

#pragma mark - Show Annotation In Map From Bookmarks
- (void) showAnnotationInMap:(NSNotification*)notification {
    [self.popoverForBookmarks dismissPopoverAnimated:YES];
    MapAnnotation* annotationForNotification = [notification object];
    MKMapRect zoomRect = MKMapRectNull;
    CLLocationCoordinate2D location = annotationForNotification.coordinate;
    MKMapPoint center = MKMapPointForCoordinate(location);
    static double delta = 20000;
    MKMapRect rect = MKMapRectMake(center.x - delta, center.y - delta, delta * 2, delta * 2);
    zoomRect = MKMapRectUnion(zoomRect, rect);
    zoomRect = [self.mapView mapRectThatFits:zoomRect];
    [self.mapView setVisibleMapRect:zoomRect
                        edgePadding:UIEdgeInsetsMake(500, 500, 500, 500)
                           animated:YES];
}

#pragma mark - Show All Annotation
- (void) showAllAnnotation:(UIButton*)sender {
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        CLLocationCoordinate2D location = annotation.coordinate;
        MKMapPoint center = MKMapPointForCoordinate(location);
        static double delta = 20000;
        MKMapRect rect = MKMapRectMake(center.x - delta, center.y - delta, delta * 2, delta * 2);
        zoomRect = MKMapRectUnion(zoomRect, rect);
    }
    zoomRect = [self.mapView mapRectThatFits:zoomRect];
    [self.mapView setVisibleMapRect:zoomRect
                        edgePadding:UIEdgeInsetsMake(50, 50, 50, 50)
                           animated:YES];
}

#pragma mark - Load New Annotation
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *textfield = [alertView textFieldAtIndex:0];
        NSString* temtTextIsTextfield;
        
        if ([textfield.text isEqualToString:@""])
            temtTextIsTextfield = @"Unnamed";
        else
            temtTextIsTextfield = textfield.text;
        
        CLLocation* locationForCoreData = [[CLLocation alloc] initWithLatitude:self.tempPointAnnototion.latitude longitude:self.tempPointAnnototion.longitude];
        
        NSManagedObject* annotation = [NSEntityDescription insertNewObjectForEntityForName:@"Annotation" inManagedObjectContext:self.context];
        [annotation setValue:temtTextIsTextfield forKey:@"title"];
        [annotation setValue:locationForCoreData forKey:@"locations"];
        [self.resultForSelectOutCoreData insertObject:annotation atIndex:[self.resultForSelectOutCoreData count]];
        
        MapAnnotation* marker = [[MapAnnotation alloc] init];
        marker.title = temtTextIsTextfield;
        marker.coordinate = locationForCoreData.coordinate;
        
        [self.mapView addAnnotation:marker];
    }
}

#pragma mark - MKMapViewDelegate -
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {}
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {}
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {}
- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {}
- (void)mapViewWillStartRenderingMap:(MKMapView *)mapView {}
- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    if (!self.isShowAnnotations) {
        [self loadAnnotationsOutCoreData];
        
        self.buttonRoute.enabled = TRUE;
        self.buttonBookmarks.enabled = TRUE;
        
        UIButton* showAllAnnotations = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [showAllAnnotations setTitle:@"Показать все закладки" forState:UIControlStateNormal];
        showAllAnnotations.frame = CGRectMake(750, 700, 220, 45);
        showAllAnnotations.backgroundColor = [UIColor colorWithRed:100 green:100 blue:100 alpha:.7];
        [showAllAnnotations addTarget:self action:@selector(showAllAnnotation:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:showAllAnnotations];
    }
    self.isShowAnnotations = true;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    static NSString* identifier = @"Annotation";
    MKPinAnnotationView* pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!pin) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        pin.pinColor = MKPinAnnotationColorPurple;
        pin.animatesDrop = YES;
        pin.canShowCallout = YES;
    } else {
        pin.annotation = annotation;
    }
    return pin;
}

@end
