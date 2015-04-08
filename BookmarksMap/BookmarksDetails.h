//
//  BookmarksDetails.h
//  BookmarksMap
//
//  Created by Moser on 29/03/15.
//  Copyright (c) 2015 Moser. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapAnnotation;

@interface BookmarksDetails : UIViewController

@property (strong, nonatomic) NSMutableArray* annotations;
@property (assign, nonatomic) NSInteger indexAnnotation;
//@property (strong, nonatomic) MapAnnotation* annotation;

@end
