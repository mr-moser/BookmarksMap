//
//  ASMapAnnotation.h
//  BookmarksMap
//
//  Created by Moser on 28/03/15.
//  Copyright (c) 2015 Moser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface MapAnnotation : NSObject <MKAnnotation>


@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end
